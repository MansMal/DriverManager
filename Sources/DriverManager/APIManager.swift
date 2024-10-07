//
//  Mryde driver
//
//  Created by Malek Mansour on 20/09/2023.
//

import Foundation
import MapKit

enum AuthenticationState {
    case loggedin, loggedout
}
enum NotificationState {
case unvailable, available
}
final class APIManager {
    
    @MainActor static let shared: APIManager = APIManager()
    
    var prod: Bool = true
    var devRoute: String = "https://rideback-cdc9a1e2fb91.herokuapp.com/drivers_api"
    var prodRoute: String = "https://mfrdmin7b0g8qogokaf5poss.com/drivers_api"

    var connectionState: AuthenticationState = .loggedout
    var notifState: NotificationState = .unvailable
    
    var stripe: String {
        switch prod {
        case false:
            return "pk_test_51Nk3WaKf5voP0vvxiXDZvGQ9HpINx7tFWQY2AXuDCcHeu9AY3lc9XLU1kUxGdA76CjvbljbIE8X2c3QZKp6W7XWI00BRMsZ0nX"
        default:
            return "pk_live_51Nk3WaKf5voP0vvxik4TSBQpLI64ydW4nWR57cp9FkmAA4j96m0i6kfDhMIQIbqVIrkXctnnOD0qVzKNXd6u4CSi00qL7TRO74"
        }
    }
    var apiRoute: String {
        switch prod {
        case false:
            return devRoute
        default:
            return prodRoute
        }
    }
    var jwtToken: String = ""
    var qrCode: UIImage?
    var driver: DriverResponse? {
        get {
            guard let data = KeychainService.loadDataWithKey(Constants.driver) else { return nil }
            let decoder = JSONDecoder()
            return (try? decoder.decode(DriverResponse.self, from: data))
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            if let qrImage = filter.outputImage {
                let scaleX = 300 / qrImage.extent.size.width
                let scaleY = 300 / qrImage.extent.size.height
                let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                let output = qrImage.transformed(by: transform)
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
}
