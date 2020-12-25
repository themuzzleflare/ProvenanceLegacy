import Foundation
import SwiftUI

struct Account: Hashable, Codable {
    var data: [AccountResource]
    var links: Pagination
}

struct AccountResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var attributes: AccountAttribute
    var relationships: AccountRelationship
    var links: SelfLink?
}

struct AccountAttribute: Hashable, Codable {
    var displayName: String
    var accountType: AccountTypeEnum
    var balance: MoneyObject

    private var createdAt: String
    var createdDate: String {
        if let date = ISO8601DateFormatter().date(from: createdAt) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
            dateFormatter.amSymbol = "AM"
            dateFormatter.pmSymbol = "PM"
            return dateFormatter.string(from: date)
        } else {
            return createdAt
        }
    }

    enum AccountTypeEnum: String, CaseIterable, Codable, Hashable, Identifiable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"

        var id: AccountTypeEnum {
            return self
        }
    }
}

struct AccountRelationship: Hashable, Codable {
    var transactions: TransactionsObject
}

struct TransactionsObject: Hashable, Codable {
    var links: AccountRelationshipsLink?
}

struct AccountRelationshipsLink: Hashable, Codable {
    var related: String
}
