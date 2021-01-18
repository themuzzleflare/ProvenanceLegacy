import SwiftUI

struct TransactionsByAccount: View {
    @State private var transactionsByAccountData = [TransactionResource]()
    @State private var transactionsByAccountPagination = Pagination()
    @State private var transactionsByAccountError: String = ""
    @State private var transactionsByAccountStatusCode: Int = 0
    @State private var loadMoreTransactionsByAccountError: String = ""

    @EnvironmentObject var modelData: ModelData

    var accountName: AccountResource

    private var account: String {
        return accountName.id
    }

    private var infoButton: some View {
        Button(action: {
            modelData.showingAccountInfo.toggle()
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
        switch transactionsByAccountData.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(transactionsByAccountData.count) Transactions"
        }
    }

    private var filteredTransactions: [TransactionResource] {
        transactionsByAccountData.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
        }
    }

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    var body: some View {
        Group {
            if transactionsByAccountData.isEmpty && transactionsByAccountError.isEmpty && transactionsByAccountStatusCode == 0 {
                ProgressView {
                    Text("Fetching Transactions...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .onAppear {
                    listTransactionsByAccount(account)
                }
            } else if !transactionsByAccountError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByAccountError)
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
                    }
                    if filteredTransactions.count != 0 {
                        Section(header: Text("Transactions")
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(filteredTransactions) { transaction in
                                NavigationLink(destination: TransactionView(modelData: modelData, transaction: transaction)) {
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
                    if transactionsByAccountPagination.next != nil {
                        Section {
                            if loading == true {
                                ProgressView()
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !loadMoreTransactionsByAccountError.isEmpty {
                                            loadMoreTransactionsByAccountError = ""
                                        }
                                        loading.toggle()
                                        nextPage(transactionsByAccountPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !loadMoreTransactionsByAccountError.isEmpty {
                                            Text(loadMoreTransactionsByAccountError)
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
                .toolbar {
                    infoButton
                }
                .sheet(isPresented: $modelData.showingAccountInfo) {
                    AccountInfo(modelData: modelData, account: accountName, transactionsByAccountData: transactionsByAccountData)
                }
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                if transactionsByAccountStatusCode != 0 {
                    transactionsByAccountStatusCode = 0
                }
                if transactionsByAccountError != "" {
                    transactionsByAccountError = ""
                }
            }
        }
    }

    private func listTransactionsByAccount(_ account: String) {
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
                    transactionsByAccountStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByAccountError = decodedResponse.errors.first!.detail
                        }
                    } else {
                        DispatchQueue.main.async {
                            transactionsByAccountError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByAccountData = decodedResponse.data
                            transactionsByAccountPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            transactionsByAccountError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    transactionsByAccountError = error?.localizedDescription ?? "Unknown error."
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
                            loadMoreTransactionsByAccountError = decodedResponse.errors.first?.detail ?? "Authorisation Error!"
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByAccountError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByAccountData.append(contentsOf: decodedResponse.data)
                            transactionsByAccountPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByAccountError = "JSON Serialisation failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadMoreTransactionsByAccountError = error?.localizedDescription ?? "Unknown error!"
                    loading.toggle()
                }
            }
        }
        .resume()
    }
}

struct AccountInfo: View {
    var modelData: ModelData

    var account: AccountResource
    var transactionsByAccountData: [TransactionResource]

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Account Balance")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Group {
                            Text(account.attributes.balance.valueSymbol)
                            Text(account.attributes.balance.valueString)
                            Text(" \(account.attributes.balance.currencyCode)")
                        }
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.trailing)
                    }
                }
                Section {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Latest Transaction")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(transactionsByAccountData.first?.attributes.rawText ?? transactionsByAccountData.first?.attributes.description ?? "None")
                            .font(.custom(transactionsByAccountData.first?.attributes.rawText != nil ? "SFMono-Regular" : "CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Account ID")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(account.id)
                            .font(.custom("SFMono-Regular", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                    HStack(alignment: .center, spacing: 0) {
                        Text("Creation Date")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(account.attributes.createdDate)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(account.attributes.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close", action: {
                    modelData.showingAccountInfo.toggle()
                })
            }
        }
    }
}
