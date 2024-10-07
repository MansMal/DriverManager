//
//  APIManager+payment.swift
//  Mryde driver
//
//  Created by Malek Mansour on 25/01/2024.
//

import Foundation

extension APIManager {
    
    func getBalance(completion: @escaping completionHandler<BalanceResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/payments/balance"), let token = self.bearerToken() else {
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
            dump("getBalance" + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(BalanceResponse.self, from: data)
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
                                    await self.getBalance(completion: completion)
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
