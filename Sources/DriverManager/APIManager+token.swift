//
//  APIManager+token.swift
//  Mryde driver
//
//  Created by Malek Mansour on 16/01/2024.
//

import Foundation

extension APIManager {
    
    func bearerToken() -> String? {
        if let loadedPerson = driver {
            return ("Bearer "+loadedPerson.token!)
        }
        return nil
    }
    func refreshToken() -> String? {
        if let loadedPerson = driver {
            return ("Bearer "+loadedPerson.refreshToken!)
        }
        return nil
    }

    func refreshToken(completion: @escaping completionHandler<DriverResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/token/refresh"), 
                let refreshToken = self.refreshToken() else { return }
        var request = URLRequest(url: url)
        request.setValue(refreshToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else { return }
            dump("refreshToken: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    self.refreshDriverData(with: data, completion: completion)
                case 422:
                    do {
                        let errors = try JSONDecoder().decode(APIERRORS.self, from: data)
                        completion(.failure(errors))
                    } catch {
                        dump(error)
                        completion(.failure(error))
                    }
                default:
                    completion(.failure(APIError(status: "error", title: "error")))
                }
            }
        }.resume()
    }
    func revokeToken(completion: @escaping((APIERRORS?) -> Void)) async {
        guard let url = URL(string: self.apiRoute+"/drivers/token/revoke"), let token = self.bearerToken() else { return }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let data = responseData else { return }
            dump("revokeToken: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    completion(nil)
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.revokeToken(completion: completion)
                                }
                            default:
                                completion(APIERRORS(errors: [APIError(status: "not HTTPURLResponse", title: "")]))
                            }
                        }
                    }
                default:
                    completion(APIERRORS(errors: [APIError(status: "not HTTPURLResponse", title: "")]))
                }
            }
        }.resume()
    }
}
