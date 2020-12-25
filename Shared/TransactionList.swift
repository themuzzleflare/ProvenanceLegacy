import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var modelData: ModelData

    var account: AccountResource

    @State private var searchText: String = ""

    @State private var showingInfo = false

    private var infoButton: some View {
        Button(action: {
            self.showingInfo.toggle()
        }) {
            Image(systemName: "info.circle")
                .imageScale(.large)
                .accessibilityLabel("Info")
        }
    }

    private var bottomText: String {
        switch modelData.transactions.filter({
            (searchText.isEmpty || $0.attributes.description.localizedStandardContains(searchText))
                && ($0.relationships.account.data.id == account.id)
        }).count {
            case 0: return "No Transactions"
            default: return "No More Transactions"
        }
    }

    var body: some View {
        if modelData.transactions.isEmpty {
            ProgressView {
                Text("Fetching Transactions...")
            }
            .navigationTitle(account.attributes.displayName)
        } else {
            List {
                SearchBar(text: $searchText, placeholder: "Search \(modelData.transactions.filter ({$0.relationships.account.data.id == account.id}).count) Transactions")
                ForEach(modelData.transactions.filter { (searchText.isEmpty || $0.attributes.description.localizedStandardContains(searchText)) && ($0.relationships.account.data.id == account.id) }) { transaction in
                    NavigationLink(destination: TransactionView(transaction: transaction)) {
                        HStack(alignment: .center, spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(transaction.attributes.description)
                                    .font(.custom("CircularStd-Bold", size: 20))
                                Text(transaction.attributes.createdDate)
                                    .font(.custom("CircularStd-Book", size: 16))
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
                Text(bottomText)
                    .font(.custom("CircularStd-Book", size: 17))
                    .opacity(0.65)
            }
            .navigationTitle(account.attributes.displayName)
            .listStyle(GroupedListStyle())
            .toolbar {
                infoButton
            }
            .sheet(isPresented: $showingInfo) {
                AccountInfo(account: account)
            }
        }
    }
}

struct AccountInfo: View {
    var account: AccountResource

    var body: some View {
        NavigationView {
            List {
                HStack(alignment: .center, spacing: 0) {
                    Text("Account ID")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Text(account.id)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .center, spacing: 0) {
                    Text("Created At")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Text(account.attributes.createdDate)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(account.attributes.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
