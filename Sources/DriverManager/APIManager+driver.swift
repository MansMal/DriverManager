//
//  APIManager+driver.swift
//  Mryde driver
//
//  Created by Malek Mansour on 25/01/2024.
//

import Foundation
import Foundation
import MapKit

public typealias completionHandler<T> = (Result<T, Error>) -> Void

extension APIManager {

    func connect(login: String, password: String, code: String = "",
                 completion: @escaping completionHandler<DriverResponse>) async {

        let url = URL(string: self.apiRoute+"/drivers/token/sign_in")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        
        dump(login+password+code)
        
        request.httpMethod = "POST"
        let encoder = JSONEncoder()
        let body: [String: String] = ["login": login,
                                      "password": password,
                                      "code": code]
        guard let finalBody = try? encoder.encode(body) else { return }
        let encBody = Crypto.ecbStaticEncrypt(inputData: finalBody)
        request.httpBody = encBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("connect: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    KeychainService.saveString(login, withKey: Constants.login)
                    KeychainService.saveString(password, withKey: Constants.password)
                    return self.refreshDriverData(with: data, completion: completion)
                case 422:
                    do {
                        let errors = try JSONDecoder().decode(APIERRORS.self, from: data)
                        return completion(.failure(errors))
                    } catch {
                        dump(error)
                        return completion(.failure(error))
                    }
                default:
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
            }
        }.resume()
    }
    
    func refreshDriverData(with data: Data, completion: @escaping completionHandler<DriverResponse>) {
        self.connectionState = .loggedin
        self.notifState = .available
        do {
            KeychainService.saveData(data, withKey: Constants.driver)
            let value = try JSONDecoder().decode(DriverResponse.self, from: data)
            let texte = "driver::"+value.driverIdentifier
            let encryptedData = Crypto.ecbStaticEncrypt(inputData: texte.data(using: .utf8)!)!
            let qrTexte = String(data: encryptedData, encoding: .utf8)!
            self.qrCode = self.generateQRCode(from: qrTexte)
            return completion(.success(value))
        } catch {
            dump(error)
            return completion(.failure(error))
        }
    }
    
    func updatePosition(coordinate: CLLocationCoordinate2D, heading: CLHeading, 
                        completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        let body: [String: Any] = ["lat": coordinate.latitude, "lng": coordinate.longitude, "bearing": heading.headingAccuracy]
        let data = try? JSONSerialization.data(withJSONObject: body)
        let finalBody = Crypto.ecbStaticEncrypt(inputData: data!)
        request.httpBody = finalBody

        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("updatePosition" + (String(data: data, encoding: .utf8) ?? "error") + "\(Date())")
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        completion(.success(value))
                    } catch {
                        return completion(.failure(APIError(status: "Erreur", title: "business error")))
                    }
                case 401:
                    Task(priority: .userInitiated) {
                        await self.refreshToken() { result in
                            switch result {
                            case .success(_):
                                Task(priority: nil) {
                                    await self.updatePosition(coordinate: coordinate, heading: heading, completion: completion)
                                }
                            default:
                                completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
            }
        }.resume()
    }
    
    func updatePreferences(pets: Bool, baby: Bool, acceptRidesAsComfort: Bool? = nil, completion: @escaping completionHandler<Preferences>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/preferences"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        var body: [String: Bool] = ["baby": baby, "pets": pets]
        if let value = acceptRidesAsComfort {
            body = ["baby": baby, "pets": pets, "acceptRidesAsComfort": value]
        }
        let data = try? JSONSerialization.data(withJSONObject: body)
        let finalBody = Crypto.ecbStaticEncrypt(inputData: data!)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("updatePreferences" + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(Preferences.self, from: data)
                        completion(.success(value))
                    } catch {
                        return completion(.failure(APIError(status: "Erreur", title: "business error")))
                    }
                case 401:
                    Task(priority: .userInitiated) {
                        await self.refreshToken() { result in
                            switch result {
                            case .success(_):
                                Task(priority: nil) {
                                    await self.updatePreferences(pets: pets, baby: baby, acceptRidesAsComfort: acceptRidesAsComfort, completion: completion)
                                }
                            default:
                                completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                }
            }
        }.resume()
    }
    
    func updateState(active: Bool, completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        let state = active == true ? "active" : "inactive"
        let body: [String: String] = ["state": state]
        let data = try? JSONSerialization.data(withJSONObject: body)
        let finalBody = Crypto.ecbStaticEncrypt(inputData: data!)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("updateState: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        completion(.success(value))
                    } catch {
                        return completion(.failure(APIError(status: "Erreur", title: "business error")))
                    }
                case 401:
                    Task(priority: .userInitiated) {
                        await self.refreshToken() { result in
                            switch result {
                            case .success(_):
                                Task(priority: nil) {
                                    await self.updateState(active: active, completion: completion)
                                }
                            default:
                                return completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
            }
        }.resume()
    }
    
    func deleteAccount(completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")

        request.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                completion(.failure(APIError(status: "Erreur", title: "business error")))
                return
            }
            dump("deleteAccount: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        completion(.success(value))
                    } catch {
                        return completion(.failure(APIError(status: "Erreur", title: "business error")))
                    }
                case 401:
                    Task(priority: .userInitiated) {
                        await self.refreshToken() { result in
                            switch result {
                            case .success(_):
                                Task(priority: nil) {
                                    await self.deleteAccount(completion: completion)
                                }
                            default:
                                completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                }
            }
        }.resume()
    }
    
    func updateToken(fcmToken: String, completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PATCH"
        let encoder = JSONEncoder()
        let body: [String: String] = ["deviceToken": fcmToken, "deviceType": "ios"]
        let finalBody = try? encoder.encode(body)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let data = responseData else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("updateToken: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    let range = fcmToken.index(fcmToken.startIndex, offsetBy: 0)..<fcmToken.index(fcmToken.endIndex, offsetBy: -131)
                    let cryptKey = String(fcmToken[range])
                    KeychainService.saveString(cryptKey, withKey: Constants.encryptionKey)
                    do {
                        let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                        completion(.success(value))
                    } catch {
                        return completion(.failure(APIError(status: "Erreur", title: "business error")))
                    }
                case 401:
                    Task(priority: .userInitiated) {
                        await self.refreshToken() { result in
                            switch result {
                            case .success(_):
                                Task(priority: nil) {
                                    await self.updateToken(fcmToken: fcmToken, completion: completion)
                                }
                            default:
                                return completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
            }
        }.resume()   
    }
}
