import SwiftUI

struct TransactionsByRelatedAccount: View {
    @State private var transactionsByRelatedAccountData = [TransactionResource]()
    @State private var transactionsByRelatedAccountPagination = Pagination()
    @State private var transactionsByRelatedAccountError: String = ""
    @State private var transactionsByRelatedAccountStatusCode: Int = 0
    @State private var loadMoreTransactionsByRelatedAccountError: String = ""

    @EnvironmentObject var modelData: ModelData

    @State private var showingInfo = false
    var accountName: AccountResource

    private var account: String {
        return accountName.id
    }

    private var infoButton: some View {
        Button(action: {
            self.showingInfo.toggle()
        }) {
            Image(systemName: "info.circle")
                .imageScale(.large)
                .accessibilityLabel("Info")
        }
    }

    @State private var loading = false

    @State private var searchText: String = ""

    private var pageName: String {
        return accountName.attributes.displayName
    }

    private var bottomText: String {
        switch filteredTransactions.count {
            case 0: return "No Transactions"
            default: return "No More Transactions"
        }
    }

    private var searchPlaceholder: String {
        switch transactionsByRelatedAccountData.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(transactionsByRelatedAccountData.count) Transactions"
        }
    }

    private var filteredTransactions: [TransactionResource] {
        transactionsByRelatedAccountData.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
        }
    }

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    var body: some View {
        Group {
            if transactionsByRelatedAccountData.isEmpty && transactionsByRelatedAccountError.isEmpty && transactionsByRelatedAccountStatusCode == 0 {
                ProgressView {
                    Text("Fetching Transactions...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .onAppear {
                    listTransactionsByRelatedAccount(account)
                }
            } else if !transactionsByRelatedAccountError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByRelatedAccountError)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle(pageName)
            } else {
                List {
                    Section {
                        SearchBar(text: $searchText, placeholder: searchPlaceholder)
                            .listRowInsets(EdgeInsets())
                    }
                    if filteredTransactions.count != 0 {
                        Section(header: Text("Transactions")
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(filteredTransactions) { transaction in
                                NavigationLink(destination: TransactionView(transaction: transaction)) {
                                    TransactionRow(transaction: transaction)
                                }
                                .contextMenu {
                                    Button("Copy", action: {
                                        UIPasteboard.general.string = transaction.attributes.description
                                    })
                                }
                                .tag(transaction)
                            }
                        }
                    }
                    Section {
                        Text(bottomText)
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                    }
                    if transactionsByRelatedAccountPagination.next != nil {
                        Section {
                            if loading == true {
                                ProgressView()
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !loadMoreTransactionsByRelatedAccountError.isEmpty {
                                            loadMoreTransactionsByRelatedAccountError = ""
                                        }
                                        loading.toggle()
                                        nextPage(transactionsByRelatedAccountPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !loadMoreTransactionsByRelatedAccountError.isEmpty {
                                            Text(loadMoreTransactionsByRelatedAccountError)
                                                .font(.custom("CircularStd-Book", size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(pageName)
                .listStyle(GroupedListStyle())
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                if transactionsByRelatedAccountStatusCode != 0 {
                    transactionsByRelatedAccountStatusCode = 0
                }
                if transactionsByRelatedAccountError != "" {
                    transactionsByRelatedAccountError = ""
                }
            }
        }
    }

    private func listTransactionsByRelatedAccount(_ account: String) {
        var url = URL(string: "https://api.up.com.au/api/v1/accounts/\(account)/transactions")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    transactionsByRelatedAccountStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedAccountError = decodedResponse.errors.first!.detail
                        }
                    } else {
                        DispatchQueue.main.async {
                            transactionsByRelatedAccountError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedAccountData = decodedResponse.data
                            transactionsByRelatedAccountPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            transactionsByRelatedAccountError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    transactionsByRelatedAccountError = error?.localizedDescription ?? "Unknown error."
                }
                print(error?.localizedDescription ?? "Unknown error.")
            }
        }
        .resume()
    }

    private func nextPage(_ paginationString: String) {
        let url = URL(string: paginationString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByRelatedAccountError = decodedResponse.errors.first!.detail
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByRelatedAccountError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedAccountData.append(contentsOf: decodedResponse.data)
                            transactionsByRelatedAccountPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByRelatedAccountError = "JSON Serialisation failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadMoreTransactionsByRelatedAccountError = error?.localizedDescription ?? "Unknown error."
                    loading.toggle()
                }
            }
        }
        .resume()
    }
}
