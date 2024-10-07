//
//  APIManager+Registration.swift
//  Mryde driver
//
//  Created by Malek Mansour on 16/01/2024.
//

import Foundation

//MARK: Registration
extension APIManager {
    
    func startRegistration(email: String, phone: String, password: String, sponsorCode: String?,
                           completion: @escaping completionHandler<REGISTERResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")

        request.httpMethod = "POST"
        var body: [String: String]
        if let sponsorCodeString = sponsorCode, !sponsorCodeString.isEmpty {
            body = ["email": email, "phone": phone, "password": password, "sponsored_code": sponsorCodeString]
        } else {
            body = ["email": email, "phone": phone, "password": password]
        }
        guard let finalBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        let encBody = Crypto.ecbStaticEncrypt(inputData: finalBody)
        request.httpBody = encBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            do {
                guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
                dump("startRegistration" + (String(data: data, encoding: .utf8) ?? "error"))
                do {
                    let value = try JSONDecoder().decode(REGISTERResponse.self, from: data)
                    completion(.success(value))
                } catch {
                    let errors = try JSONDecoder().decode(APIERRORS.self, from: data)
                    completion(.failure(errors))
                }
            } catch {
                completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
            }
        }.resume()
    }
    func sendOTP(email: String, otp: String, completion: @escaping completionHandler<OTPResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/otp_validations/") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "POST"
        let body: [String: String] = ["email": email, "otpCode": otp]

        guard let finalBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        let encBody = Crypto.ecbStaticEncrypt(inputData: finalBody)

        request.httpBody = encBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            do {
                guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
                dump("sendOTP" + (String(data: data, encoding: .utf8) ?? "error"))
                do {
                    let value = try JSONDecoder().decode(OTPResponse.self, from: data)
                    completion(.success(value))
                } catch {
                    let errors = try JSONDecoder().decode(APIERRORS.self, from: data)
                    completion(.failure(errors))
                }
            } catch {
                completion(.failure(APIError(status: "not HTTPURLResponse", title: "")))
            }
        }.resume()
    }
    func requestNewOTP(email: String, completion: @escaping completionHandler<Bool>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/otp_codes/") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let encoder = JSONEncoder()

        let body: [String: String] = ["email": email]
        let finalBody = try? encoder.encode(body)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let data = responseData else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("requestNewOTP" + (String(data: data, encoding: .utf8) ?? "error"))
            if let result = String(data: data, encoding: .utf8), result == "{}" {
                completion(.success(true))
            } else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
        }.resume()
    }
    func sendDocument(fileContent: String, fileName: String, kind: String, completion: @escaping completionHandler<Bool>) async {
        let url = URL(string: self.apiRoute+"/drivers/documents/")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "POST"

        let body: [String: String] = ["fileContent": fileContent, "fileName": fileName, "kind": kind]
        
        guard let finalBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        let encBody = Crypto.ecbStaticEncrypt(inputData: finalBody)
        request.httpBody = encBody

        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("Send doc: "+String(data: data, encoding: .utf8)!)
            do {
                let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                completion(.success(value.success))
            } catch {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
        }.resume()
    }
    func sendSponsoredCode(code: String, completion: @escaping completionHandler<Bool>) async {
        let url = URL(string: self.apiRoute+"/drivers/update_by_jwt")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"

        let body: [String: String] = ["sponsored_code": code]
        
        guard let finalBody = try? JSONSerialization.data(withJSONObject: body) else { return }
        let encBody = Crypto.ecbStaticEncrypt(inputData: finalBody)
        request.httpBody = encBody

        URLSession.shared.dataTask(with: request) { responseData, response, error in
            do {
                guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                    return completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
                dump("sendSponsoredCode: "+String(data: data, encoding: .utf8)!)
                do {
                    let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                    completion(.success(value.success))
                } catch {
                    let errors = try JSONDecoder().decode(APIERRORS.self, from: data)
                    completion(.failure(errors))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func forgetPassword(email: String, completion: @escaping completionHandler<Bool>) async {
        let url = URL(string: self.apiRoute+"/drivers/password")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let encoder = JSONEncoder()
        let body: [String: String] = ["email": email]
        let finalBody = try? encoder.encode(body)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let data = responseData else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            do {
                let value = try JSONDecoder().decode(SuccessResponse.self, from: data)
                completion(.success(value.success))
            } catch {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
        }.resume()
    }
}
