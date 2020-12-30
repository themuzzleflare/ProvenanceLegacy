import SwiftUI

struct AccountRow: View {
    var account: AccountResource
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(account.attributes.displayName)
                    .font(.custom("CircularStd-Bold", size: 17))
                Text(account.attributes.accountType.rawValue.capitalized)
                    .font(.custom("CircularStd-Book", size: 12))
                    .opacity(0.65)
            }
            Spacer()
            Group {
                Text(account.attributes.balance.valueSymbol)
                Text(account.attributes.balance.valueString)
                Text(" \(account.attributes.balance.currencyCode)")
            }
            .font(.custom("CircularStd-Book", size: 17))
            .opacity(0.65)
            .multilineTextAlignment(.trailing)
        }
    }
}
