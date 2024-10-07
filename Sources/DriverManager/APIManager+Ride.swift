//
//  APIManager+Ride.swift
//  Mryde driver
//
//  Created by Malek Mansour on 16/02/2024.
//

import Foundation


extension APIManager {
    
    func responseRyde(accept: Bool, rydeIdentifier: String, 
                      completion: @escaping completionHandler<SuccessResponse?>) async {
        let actionString = accept == true ? "/accept" :"/deny"
        guard let url = URL(string: self.apiRoute+"/rides/"+rydeIdentifier+actionString), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                  let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            if let httpResponse = response as? HTTPURLResponse {
                dump("\(httpResponse.statusCode) " + "responseRyde: " + actionString + " " + (String(data: data, encoding: .utf8) ?? "error"))
                switch httpResponse.statusCode {
                case 200...299:
                    completion(.success(SuccessResponse(success: true)))
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.responseRyde(accept: accept, rydeIdentifier: rydeIdentifier,
                                                            completion: completion)
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
    func startRyde(rydeIdentifier: String, completion: @escaping completionHandler<Bool?>) async {
        guard let url = URL(string: self.apiRoute+"/rides/"+rydeIdentifier+"/start"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                  let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("startRyde: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    completion(.success(true))
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.startRyde(rydeIdentifier: rydeIdentifier, completion: completion)
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
    func cancelRyde(rydeIdentifier: String, completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/rides/"+rydeIdentifier+"/cancel"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                    let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("cancelRyde: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    completion(.success(SuccessResponse(success: true)))
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.cancelRyde(rydeIdentifier: rydeIdentifier, completion: completion)
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
    func finishRyde(rydeIdentifier: String, completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/rides/"+rydeIdentifier+"/finish"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                    let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("finishRyde: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    return completion(.success(SuccessResponse(success: true)))
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.finishRyde(rydeIdentifier: rydeIdentifier, completion: completion)
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
    func stopRyde(rydeIdentifier: String, completion: @escaping completionHandler<Bool?>) async {
        guard let url = URL(string: self.apiRoute+"/rides/"+rydeIdentifier+"/stop"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
                guard let respData = responseData,
                        let data = Crypto.ecbStaticDecrypt(input: respData) else {
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
                dump("stopRyde: " + (String(data: data, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        completion(.success(true))
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.stopRyde(rydeIdentifier: rydeIdentifier, completion: completion)
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
    func getCurrentRide(completion: @escaping completionHandler<Ride>) async {
        guard let url = URL(string: self.apiRoute+"/rides/current"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                    let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
                dump("getCurrentRide: " + (String(data: data, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let value = try JSONDecoder().decode(Ride.self, from: data)
                            completion(.success(value))
                        } catch {
                            return completion(.failure(APIError(status: "Erreur", title: "business error")))
                        }
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.getCurrentRide(completion: completion)
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
    func getPurchaseOrderPDF(completion: @escaping completionHandler<URL>) async {
        guard let url = URL(string: self.apiRoute+"/rides/current.pdf"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
//                dump("getPurchaseOrderPDF: " + (String(data: respData, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        let pdfData = NSMutableData(bytes: (respData as NSData).bytes,
                                                    length: (respData as NSData).length)
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let localPath = "\(documentsPath)/purchaseOrder.pdf"
                        pdfData.write(toFile: localPath, atomically: true)
                        return completion(.success(URL(fileURLWithPath: localPath)))
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.getPurchaseOrderPDF(completion: completion)
                                    }
                                default:
                                    completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                                }
                            }
                        }
                    default:
                        completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                    }
                }
        }.resume()
    }
    func getRidesHistory(completion: @escaping completionHandler<[Ride]>) async {
        guard let url = URL(string: self.apiRoute+"/rides"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                    let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
                dump("getRidesHistory: " + (String(data: data, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let value = try JSONDecoder().decode(RidesHistoryResponse.self, from: data)
                            completion(.success(value.rides))
                        } catch {
                            return completion(.failure(APIError(status: "Erreur", title: "business error")))
                        }
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.getRidesHistory(completion: completion)
                                    }
                                default:
                                    completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                                }
                            }
                        }
                    default:
                        completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
                    }
                }
        }.resume()
    }
}
