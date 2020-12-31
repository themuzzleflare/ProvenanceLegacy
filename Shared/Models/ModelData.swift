import Foundation
import Combine
import SwiftUI
import Network

final class ModelData: ObservableObject {
    @Published var connectivity: Bool = true

    @Published var transactions = [TransactionResource]()
    @Published var transactionsErrorResponse = [ErrorObject]()
    @Published var transactionsError: String = ""

    @Published var accounts = [AccountResource]()
    @Published var accountsErrorResponse = [ErrorObject]()
    @Published var accountsError: String = ""

    @Published var categories = [CategoryResource]()
    @Published var categoriesErrorResponse = [ErrorObject]()
    @Published var categoriesError: String = ""

    @Published var tags = [TagResource]()
    @Published var tagsErrorResponse = [ErrorObject]()
    @Published var tagsError: String = ""

    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
    let appDisplayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
}

// MARK: - GIF Images
var upDuration: TimeInterval = 0.65

var up1: UIImage = UIImage(named: "UpLogoSequence/1")!
var up2: UIImage = UIImage(named: "UpLogoSequence/2")!
var up3: UIImage = UIImage(named: "UpLogoSequence/3")!
var up4: UIImage = UIImage(named: "UpLogoSequence/4")!
var up5: UIImage = UIImage(named: "UpLogoSequence/5")!
var up6: UIImage = UIImage(named: "UpLogoSequence/6")!
var up7: UIImage = UIImage(named: "UpLogoSequence/7")!
var up8: UIImage = UIImage(named: "UpLogoSequence/8")!
var upImages: [UIImage] = [up1, up2, up3, up4, up5, up6, up7, up8]
let upAnimation: UIImage =  UIImage.animatedImage(with: upImages, duration: upDuration)!

var upWide1: UIImage = UIImage(named: "UpLogoWidescreenSequence/1")!
var upWide2: UIImage = UIImage(named: "UpLogoWidescreenSequence/2")!
var upWide3: UIImage = UIImage(named: "UpLogoWidescreenSequence/3")!
var upWide4: UIImage = UIImage(named: "UpLogoWidescreenSequence/4")!
var upWide5: UIImage = UIImage(named: "UpLogoWidescreenSequence/5")!
var upWide6: UIImage = UIImage(named: "UpLogoWidescreenSequence/6")!
var upWide7: UIImage = UIImage(named: "UpLogoWidescreenSequence/7")!
var upWide8: UIImage = UIImage(named: "UpLogoWidescreenSequence/8")!
var upWideImages: [UIImage] = [upWide1, upWide2, upWide3, upWide4, upWide5, upWide6, upWide7, upWide8]
let upWideAnimation: UIImage =  UIImage.animatedImage(with: upWideImages, duration: upDuration)!
// MARK: - NSURLSession Protocols & Extensions
protocol URLQueryParameterStringConvertible {
    var queryParameters: String {
        get
    }
}
extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}
extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}
// MARK: - Colour Extension
extension Color {
    static let rowBackground = Color("RowBackgroundColour")
}
