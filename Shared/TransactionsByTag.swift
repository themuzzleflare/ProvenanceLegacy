import SwiftUI

struct TransactionsByTag: View {
    @State private var transactionsByTagData = [TransactionResource]()
    @State private var transactionsByTagPagination = Pagination()
    @State private var transactionsByTagError: String = ""
    @State private var transactionsByTagStatusCode: Int = 0
    @State private var loadMoreTransactionsByTagError: String = ""

    var tagName: TagResource

    private var tag: String {
        return tagName.id
    }

    @State private var loading = false

    @State private var searchText: String = ""
    
    private var pageName: String {
        return tag
    }

    private var bottomText: String {
        switch filteredTransactions.count {
            case 0: return "No Transactions"
            default: return "No More Transactions"
        }
    }

    private var searchPlaceholder: String {
        switch transactionsByTagData.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(transactionsByTagData.count) Transactions"
        }
    }

    private var filteredTransactions: [TransactionResource] {
        transactionsByTagData.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
        }
    }

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    var body: some View {
        Group {
            if transactionsByTagData.isEmpty && transactionsByTagError.isEmpty && transactionsByTagStatusCode == 0 {
                ProgressView {
                    Text("Fetching Transactions...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .onAppear {
                    listTransactionsByTag(tag)
                }
            } else if !transactionsByTagError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Bold", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByTagError)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.center)
                        .opacity(0.65)
                }
                .padding()
                .navigationTitle(pageName)
            } else {
                List {
                    Section {
                        SearchBar(text: $searchText, placeholder: searchPlaceholder)
                    }
                    if filteredTransactions.count != 0 {
                        Section(header: Text("Transactions")) {
                            ForEach(filteredTransactions) { transaction in
                                NavigationLink(destination: TransactionView(transaction: transaction)) {
                                    TransactionRow(transaction: transaction)
                                }
                            }
                        }
                    }
                    Section {
                        Text(bottomText)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                    }
                    if transactionsByTagPagination.next != nil {
                        Section {
                            if loading == true {
                                ProgressView()
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !loadMoreTransactionsByTagError.isEmpty {
                                            loadMoreTransactionsByTagError = ""
                                        }
                                        loading.toggle()
                                        nextPage(transactionsByTagPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                        if !loadMoreTransactionsByTagError.isEmpty {
                                            Text(loadMoreTransactionsByTagError)
                                                .font(.caption)
                                                .opacity(0.65)
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
                if transactionsByTagStatusCode != 0 {
                    transactionsByTagStatusCode = 0
                }
                if transactionsByTagError != "" {
                    transactionsByTagError = ""
                }
            }
        }
    }

    private func listTransactionsByTag(_ tag: String) {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["filter[tag]":tag, "page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    transactionsByTagStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByTagError = decodedResponse.errors.first!.detail
                        }
                    } else {
                        DispatchQueue.main.async {
                            transactionsByTagError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByTagData = decodedResponse.data
                            transactionsByTagPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            transactionsByTagError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    transactionsByTagError = error?.localizedDescription ?? "Unknown error."
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
                            loadMoreTransactionsByTagError = decodedResponse.errors.first!.detail
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByTagError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByTagData.append(contentsOf: decodedResponse.data)
                            transactionsByTagPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByTagError = "JSON Serialisation failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadMoreTransactionsByTagError = error?.localizedDescription ?? "Unknown error."
                    loading.toggle()
                }
            }
        }
        .resume()
    }
}
