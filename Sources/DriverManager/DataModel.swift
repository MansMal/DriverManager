//
//  Person.swift
//  Ride
//
//  Created by Malek Mansour on 21/06/2023.
//

import Foundation
import CoreLocation
import UIKit

enum CarKind: String, Codable {
    case ride, van, comfort
    var title: String {
        switch self {
        case .ride: return "Ryde+"
        case .van: return "Ryde Van"
        case .comfort: return "Ryde Confort"
        }
    }
}
enum NotifKind: String, Codable {
    case rydeRequest, paymentRequest, rydeCanceled
}
struct RidesHistoryResponse: Codable {
    var rides: [Ride]
}
struct Ride: Codable {
    
    var price: Double
    var photo: Data?
    var passengerLat, passengerLng, arrivalLat, arrivalLng, rideIdentifier: String
    var passengerFirstName, passengerLastName, passengerAddress, arrivalAddress: String?
    var driverStatus: RideStatus?
    var createdAt: Double
    var requestDate: Date? {
        get {
            return Date(timeIntervalSince1970: createdAt)
        }
    }
    var passengerProfilePicture, carPicture: String?
        
    func departureLocation() -> CLLocation? {
        guard let latitude = Double(passengerLat), let longitude = Double(passengerLng) else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    func arrivalLocation() -> CLLocation? {
        return CLLocation(latitude: Double(arrivalLat)!, longitude: Double(arrivalLng)!)
    }
}
enum RideStatus: String, Codable {
    case pending, accepted, paid, started, finished, stopped, canceled
}
struct BalanceResponse: Codable {
    var balance, next_payment_at: Double
}
struct APIError: Error, Codable {
    var status, title: String
    var detail: String?
}
struct APIERRORS: Error, Codable {
    var errors: [APIError]
}
struct REGISTERResponse: Codable {
    var registrationSuccess: Bool
}
struct OTPResponse: Codable {
    var jwtToken: String
}
struct SuccessResponse: Codable {
    var success: Bool
}
enum EngineTypeEnum: String, Codable {
    case thermic, electric, hybrid
    var title: String {
        switch self {
        case .thermic: return "Thermique"
        case .electric: return "Electrique"
        case .hybrid: return "Hybrid"
        }
    }
}
struct DriverResponse: Codable {

    var sponsoredCount: Int
    let driverIdentifier: String

    var token, refreshToken, email, profilePictureUrl, phone, firstName, lastName,
        iban, jwtToken, stripeCustomerId, sponsorCode, sponsoredCode: String?
    var carKind: CarKind?
    var state: State?
    var preferences: Preferences?
    var engineType: EngineTypeEnum?
    var deadline: Double?
    var trial: Bool?
    var verificationState: DriverStateEnum
    var identityR,
        drivingLicenseR,
        professionalCardR,
        carInsuranceR,
        professionalInsuranceR,
        kbis,
        carRegistrationR,
        carPicture,
        profilePicture,
        ibanFile,
        identityV,
        drivingLicenseV,
        professionalCardV,
        carInsuranceV,
        professionalInsuranceV,
        carRegistrationV: Bool
}

struct SubscriptionDetail: Codable {
    var monthly, half_yearly, yearly: Double
    var discounted_yearly, discounted_half_yearly, discounted_monthly: Double?
}
struct SubscriptionPricesResponses: Codable {
    var electric: SubscriptionDetail
    var hybrid: SubscriptionDetail
    var thermic: SubscriptionDetail
    var discount: Int?
}
enum SubscriptionKind: String {
    case yearly, monthly, half_yearly
}
struct SubscriptionPaymentDetails: Codable {
    var ephemeralKey, clientSecret: String
}
struct SetupPaymentDetails: Codable {
    var client_secret, ephemeral_key: String
}
enum DriverStateEnum: String, Codable {
    case pending, waiting, validated, rejected, activated
}
enum State: String, Codable {
    case active, inactive
}
struct Preferences: Codable {
    var pets: Bool
    var baby: Bool
    var accept_rides_as_comfort: Bool
}
func downloadImageData(from url: URL) async throws -> Data {
    let request = URLRequest(url: url)
    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}
