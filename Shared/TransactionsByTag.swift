import SwiftUI

struct TransactionsByTag: View {
    @State private var transactionsByTagData = [TransactionResource]()
    @State private var transactionsByTagPagination = Pagination()
    @State private var transactionsByTagError: String = ""
    @State private var transactionsByTagStatusCode: Int = 0
    @State private var loadMoreTransactionsByTagError: String = ""

    @State private var showingFailAlert = false

    @EnvironmentObject var modelData: ModelData

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

    @AppStorage("Settings.apiToken") private var apiToken: String = ""

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
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByTagError)
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
                                    Button(action: {
                                        deleteTag(transaction)
                                    }) {
                                        Label("Remove from Transaction", systemImage: "trash")
                                    }
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
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !loadMoreTransactionsByTagError.isEmpty {
                                            Text(loadMoreTransactionsByTagError)
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
                .alert(isPresented: $showingFailAlert) {
                    Alert(title: Text("Failed"), message: Text("The tag was not removed from the transaction."), dismissButton: .default(Text("Dismiss")))
                }
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

    private func deleteTag(_ transaction: TransactionResource) {
        let url = URL(string: transaction.relationships.tags.links?.`self` ?? "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let bodyObject: [String : Any] = [
            "data": [
                [
                    "type": "\(tagName.type)",
                    "id": "\(tagName.id)"
                ]
            ]
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                if statusCode != 204 {
                    DispatchQueue.main.async {
                        showingFailAlert.toggle()
                    }
                } else {
                    DispatchQueue.main.async {
                        transactionsByTagStatusCode = 0
                        transactionsByTagError = ""
                        transactionsByTagData = []
                        listTransactions()
                        listAccounts()
                        listTags()
                        listCategories()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    showingFailAlert.toggle()
                }
            }
        }
        .resume()
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

    private func listAccounts() {
        var url = URL(string: "https://api.up.com.au/api/v1/accounts")!
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
                    modelData.accountsStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.accountsErrorResponse = decodedResponse.errors
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.accountsError = "Authorisation Error!"
                        }
                    }
                    print("Accounts Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.accounts = decodedResponse.data
                        }
                        print("Accounts Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            modelData.accountsError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.accountsError = error?.localizedDescription ?? "Unknown error."
                }
                print(error?.localizedDescription ?? "Unknown error.")
            }
        }
        .resume()
    }

    private func listTransactions() {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
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
                    modelData.transactionsStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.transactionsErrorResponse = decodedResponse.errors
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.transactionsError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.transactions = decodedResponse.data
                            modelData.transactionsPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            modelData.transactionsError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.transactionsError = error?.localizedDescription ?? "Unknown error."
                }
                print(error?.localizedDescription ?? "Unknown error.")
            }
        }
        .resume()
    }

    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    modelData.categoriesStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.categoriesErrorResponse = decodedResponse.errors
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.categoriesError = "Authorisation Error!"
                        }
                    }
                    print("Categories Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.categories = decodedResponse.data
                        }
                        print("Categories Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            modelData.categoriesError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.categoriesError = error?.localizedDescription ?? "Unknown error."
                }
                print(error?.localizedDescription ?? "Unknown error.")
            }
        }
        .resume()
    }

    private func listTags() {
        var url = URL(string: "https://api.up.com.au/api/v1/tags")!
        let urlParams = ["page[size]":"200"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    modelData.tagsStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.tagsErrorResponse = decodedResponse.errors
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.tagsError = "Authorisation Error!"
                        }
                    }
                    print("Tags Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.tags = decodedResponse.data
                        }
                        print("Tags Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            modelData.tagsError = "JSON Serialisation failed!"
                        }
                        print("JSON Serialisation failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.tagsError = error?.localizedDescription ?? "Unknown error."
                }
                print(error?.localizedDescription ?? "Unknown error.")
            }
        }
        .resume()
    }
}
