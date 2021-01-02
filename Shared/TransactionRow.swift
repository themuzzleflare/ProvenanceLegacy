import SwiftUI

struct TransactionRow: View {
    var transaction: TransactionResource
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.attributes.description)
                    .font(.custom("CircularStd-Bold", size: 20))
                Text(transaction.attributes.createdDate)
                    .font(.custom("CircularStd-Book", size: 14))
                    .opacity(0.65)
            }
            Spacer()
            Group {
                Text(transaction.attributes.amount.valueSymbol)
                Text(transaction.attributes.amount.valueString)
            }
            .font(.custom("CircularStd-Book", size: 17))
            .opacity(0.65)
            .multilineTextAlignment(.trailing)
        }
    }
}
