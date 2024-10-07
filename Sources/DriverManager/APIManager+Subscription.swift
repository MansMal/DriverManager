//
//  APIManager+Subscription.swift
//  Mryde driver
//
//  Created by Malek Mansour on 10/08/2024.
//

import Foundation

//MARK: Subscription
extension APIManager {
    
    func getSubscriptionsDetails(completion: @escaping completionHandler<SubscriptionPricesResponses>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/subscription/prices"), let token = self.bearerToken() else {
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
                dump("getSubscriptionsDetails: " + (String(data: data, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let value = try JSONDecoder().decode(SubscriptionPricesResponses.self, from: data)
                            completion(.success(value))
                        } catch {
                            completion(.failure(error))
                        }
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.getSubscriptionsDetails(completion: completion)
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
    
    func createSubscriptionsDetails(price: Double, kind: String, completion: @escaping completionHandler<SubscriptionPaymentDetails>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/subscription/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "POST"
        let body: [String: Any] = ["kind": kind, "price": price]
        let data = try? JSONSerialization.data(withJSONObject: body)
        let finalBody = Crypto.ecbStaticEncrypt(inputData: data!)
        request.httpBody = finalBody
        
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData,
                    let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
                dump("createSubscriptionsDetails: " + (String(data: data, encoding: .utf8) ?? "error"))
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let value = try JSONDecoder().decode(SubscriptionPaymentDetails.self, from: data)
                            completion(.success(value))
                        } catch {
                            completion(.failure(error))
                        }
                    case 401:
                        Task {
                            await self.refreshToken { result in
                                switch result {
                                case .success(_):
                                    Task {
                                        await self.createSubscriptionsDetails(price: price, kind: kind,
                                                                              completion: completion)
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
    
    func getPaymentSecret(completion: @escaping completionHandler<SetupPaymentDetails>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/payments/setup_payment_method"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let data = Crypto.ecbStaticDecrypt(input: responseData!) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("getPaymentSecret: " + (String(data: data, encoding: .utf8) ?? "error"))
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let value = try JSONDecoder().decode(SetupPaymentDetails.self, from: data)
                        completion(.success(value))
                    } catch {
                        completion(.failure(error))
                    }
                case 401:
                    Task {
                        await self.refreshToken { result in
                            switch result {
                            case .success(_):
                                Task {
                                    await self.getPaymentSecret(completion: completion)
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
    
    func updateDeadline(frequency: SubscriptionKind, completion: @escaping completionHandler<SuccessResponse>) async {
        guard let url = URL(string: self.apiRoute+"/drivers/"), let token = self.bearerToken() else {
            return completion(.failure(APIError(status: "Erreur", title: "business error")))
        }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Crypt")
        request.httpMethod = "PATCH"
        var addedPeriod: Int = 0
        switch frequency {
        case .yearly:
            addedPeriod = 12
        case .half_yearly:
            addedPeriod = 6
        case .monthly:
            addedPeriod = 1
        }
        let newDate = Date(timeIntervalSince1970: self.driver!.deadline!).adding(.month, value: addedPeriod)
        let newtimeStamp = newDate.timeIntervalSince1970
        let body: [String: Double] = ["deadline": newtimeStamp]
        let data = try? JSONSerialization.data(withJSONObject: body)
        let finalBody = Crypto.ecbStaticEncrypt(inputData: data!)
        request.httpBody = finalBody
        URLSession.shared.dataTask(with: request) { responseData, response, error in
            guard let respData = responseData, let data = Crypto.ecbStaticDecrypt(input: respData) else {
                return completion(.failure(APIError(status: "Erreur", title: "business error")))
            }
            dump("updateDeadline: " + (String(data: data, encoding: .utf8) ?? "error"))
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
                                    await self.updateDeadline(frequency: frequency, completion: completion)
                                }
                            default:
                                completion(.failure(APIError(status: "Erreur", title: "business error")))
                            }
                        }
                    }
                default:
                    completion(.failure(APIError(status: "Erreur", title: "business error")))
                }
            }
        }.resume()
    }

}

public extension Date {
    func noon(using calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    func day(using calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: self)
    }
    func adding(_ component: Calendar.Component, value: Int, using calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: component, value: value, to: self)!
    }
    func monthSymbol(using calendar: Calendar = .current) -> String {
        calendar.monthSymbols[calendar.component(.month, from: self)-1]
    }
}
