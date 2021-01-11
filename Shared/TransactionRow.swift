import SwiftUI

struct TransactionRow: View {
    var transaction: TransactionResource

    @AppStorage("Settings.dateStyle")
    private var dateStyle: Settings.DateStyle = .absolute

    private var createdDate: String {
        switch dateStyle {
            case .absolute: return transaction.attributes.createdDate
            case .relative: return transaction.attributes.createdDateRelative
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.attributes.description)
                    .font(.custom("CircularStd-Book", size: 20))
                Text(createdDate)
                    .font(.custom("CircularStd-Book", size: 14))
                    .opacity(0.65)
            }
            Spacer()
            Group {
                Text(transaction.attributes.amount.valueSymbol)
                Text(transaction.attributes.amount.valueString)
            }
            .font(.custom("CircularStd-Book", size: 17))
            .multilineTextAlignment(.trailing)
        }
    }
}
