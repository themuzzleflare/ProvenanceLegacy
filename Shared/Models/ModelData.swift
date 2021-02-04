import SwiftUI
import Network

final class ModelData: ObservableObject {
    @Published var connectivity: Bool = true
    
    @Published var transactions = [TransactionResource]()
    @Published var transactionsErrorResponse = [ErrorObject]()
    @Published var transactionsError: String = ""
    @Published var transactionsPagination = Pagination()
    @Published var loadMoreTransactionsError: String = ""
    @Published var transactionsStatusCode: Int = 0
    
    @Published var accounts = [AccountResource]()
    @Published var accountsErrorResponse = [ErrorObject]()
    @Published var accountsError: String = ""
    @Published var accountsStatusCode: Int = 0
    
    @Published var categories = [CategoryResource]()
    @Published var categoriesErrorResponse = [ErrorObject]()
    @Published var categoriesError: String = ""
    @Published var categoriesStatusCode: Int = 0
    
    @Published var tags = [TagResource]()
    @Published var tagsErrorResponse = [ErrorObject]()
    @Published var tagsError: String = ""
    @Published var tagsPagination = Pagination()
    @Published var loadMoreTagsError: String = ""
    @Published var tagsStatusCode: Int = 0
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
    let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"
}
// MARK: - GIF Images
var up1: UIImage = UIImage(named: "UpLogoSequence/1")!
var up2: UIImage = UIImage(named: "UpLogoSequence/2")!
var up3: UIImage = UIImage(named: "UpLogoSequence/3")!
var up4: UIImage = UIImage(named: "UpLogoSequence/4")!
var up5: UIImage = UIImage(named: "UpLogoSequence/5")!
var up6: UIImage = UIImage(named: "UpLogoSequence/6")!
var up7: UIImage = UIImage(named: "UpLogoSequence/7")!
var up8: UIImage = UIImage(named: "UpLogoSequence/8")!
var upImages: [UIImage] = [up1, up2, up3, up4, up5, up6, up7, up8]
let upAnimation: UIImage =  UIImage.animatedImage(with: upImages, duration: 0.65)!
// MARK: - Protocols & Extensions for URL Parameter Support
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
// MARK: - Date Formatters
func formatDate(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: date)
    } else {
        return dateString
    }
}

func formatDateRelative(dateString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: dateString) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.zeroFormattingBehavior = .dropAll
        return "\(formatter.string(from: date.timeIntervalSinceNow)!.replacingOccurrences(of: "-", with: "")) ago"
    } else {
        return dateString
    }
}
// MARK: - Search String Extension
extension String {
    /// Returns `true` if this string contains the provided substring,
    /// or if the substring is empty. Otherwise, returns `false`.
    ///
    /// - Parameter substring: The substring to search for within
    ///   this string.
    func hasSubstring(_ substring: String) -> Bool {
        substring.isEmpty || localizedStandardContains(substring)
    }
}
