import SwiftUI

struct TransactionsByCategory: View {
    @State private var transactionsByCategoryData = [TransactionResource]()
    @State private var transactionsByCategoryPagination = Pagination()
    @State private var transactionsByCategoryError: String = ""
    @State private var transactionsByCategoryStatusCode: Int = 0
    @State private var loadMoreTransactionsByCategoryError: String = ""

    @EnvironmentObject var modelData: ModelData

    var categoryId: String
    var categoryName: String

    @State private var loading = false

    @State private var searchText: String = ""

    private var pageName: String {
        return categoryName
    }

    private var bottomText: String {
        switch filteredTransactions.count {
            case 0: return "No Transactions"
            default: return "No More Transactions"
        }
    }

    private var searchPlaceholder: String {
        switch transactionsByCategoryData.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(transactionsByCategoryData.count) Transactions"
        }
    }

    private var filteredTransactions: [TransactionResource] {
        transactionsByCategoryData.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
        }
    }

    @AppStorage("Settings.apiToken") private var apiToken: String = ""

    var body: some View {
        Group {
            if transactionsByCategoryData.isEmpty && transactionsByCategoryError.isEmpty && transactionsByCategoryStatusCode == 0 {
                ProgressView {
                    Text("Fetching Transactions...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .onAppear {
                    listTransactionsByCategory(categoryId)
                }
            } else if !transactionsByCategoryError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByCategoryError)
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
                    if transactionsByCategoryPagination.next != nil {
                        Section {
                            if loading == true {
                                ProgressView()
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !loadMoreTransactionsByCategoryError.isEmpty {
                                            loadMoreTransactionsByCategoryError = ""
                                        }
                                        loading.toggle()
                                        nextPage(transactionsByCategoryPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !loadMoreTransactionsByCategoryError.isEmpty {
                                            Text(loadMoreTransactionsByCategoryError)
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
                if transactionsByCategoryStatusCode != 0 {
                    transactionsByCategoryStatusCode = 0
                }
                if transactionsByCategoryError != "" {
                    transactionsByCategoryError = ""
                }
            }
        }
    }

    private func listTransactionsByCategory(_ category: String) {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["filter[category]":category, "page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    transactionsByCategoryStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByCategoryError = decodedResponse.errors.first!.detail
                        }
                    } else {
                        DispatchQueue.main.async {
                            transactionsByCategoryError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByCategoryData = decodedResponse.data
                            transactionsByCategoryPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            transactionsByCategoryError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    transactionsByCategoryError = error?.localizedDescription ?? "Unknown error."
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
                            loadMoreTransactionsByCategoryError = decodedResponse.errors.first!.detail
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByCategoryError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByCategoryData.append(contentsOf: decodedResponse.data)
                            transactionsByCategoryPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByCategoryError = "JSON Serialisation failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadMoreTransactionsByCategoryError = error?.localizedDescription ?? "Unknown error."
                    loading.toggle()
                }
            }
        }
        .resume()
    }
}
