import SwiftUI

struct TransactionsByRelatedTag: View {
    @State private var transactionsByRelatedTagData = [TransactionResource]()
    @State private var transactionsByRelatedTagPagination = Pagination()
    @State private var transactionsByRelatedTagError: String = ""
    @State private var transactionsByRelatedTagStatusCode: Int = 0
    @State private var loadMoreTransactionsByRelatedTagError: String = ""
    
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
        switch transactionsByRelatedTagData.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(transactionsByRelatedTagData.count) Transactions"
        }
    }
    
    private var filteredTransactions: [TransactionResource] {
        transactionsByRelatedTagData.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
        }
    }
    
    @AppStorage("Settings.apiToken") private var apiToken: String = ""
    
    var body: some View {
        Group {
            if transactionsByRelatedTagData.isEmpty && transactionsByRelatedTagError.isEmpty && transactionsByRelatedTagStatusCode == 0 {
                ProgressView {
                    Text("Fetching Transactions...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .onAppear {
                    listTransactionsByTag(tag)
                }
            } else if !transactionsByRelatedTagError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(transactionsByRelatedTagError)
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
                    if transactionsByRelatedTagPagination.next != nil {
                        Section {
                            if loading {
                                HStack(alignment: .center, spacing: 0) {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !loadMoreTransactionsByRelatedTagError.isEmpty {
                                            loadMoreTransactionsByRelatedTagError = ""
                                        }
                                        loading.toggle()
                                        nextPage(transactionsByRelatedTagPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !loadMoreTransactionsByRelatedTagError.isEmpty {
                                            Text(loadMoreTransactionsByRelatedTagError)
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
                if transactionsByRelatedTagStatusCode != 0 {
                    transactionsByRelatedTagStatusCode = 0
                }
                if transactionsByRelatedTagError != "" {
                    transactionsByRelatedTagError = ""
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
                    transactionsByRelatedTagStatusCode = statusCode
                }
                if statusCode == 401 {
                    if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedTagError = decodedResponse.errors.first!.detail
                        }
                    } else {
                        DispatchQueue.main.async {
                            transactionsByRelatedTagError = "Authorisation Error!"
                        }
                    }
                    print("Transactions Fetch Unsuccessful: HTTP \(statusCode)")
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedTagData = decodedResponse.data
                            transactionsByRelatedTagPagination = decodedResponse.links
                        }
                        print("Transactions Fetch Successful: HTTP \(statusCode)")
                    } else {
                        DispatchQueue.main.async {
                            transactionsByRelatedTagError = "JSON Decoding Failed!"
                        }
                        print("JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    transactionsByRelatedTagError = error?.localizedDescription ?? "Unknown Error!"
                }
                print(error?.localizedDescription ?? "Unknown Error!")
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
                            loadMoreTransactionsByRelatedTagError = decodedResponse.errors.first!.detail
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByRelatedTagError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            transactionsByRelatedTagData.append(contentsOf: decodedResponse.data)
                            transactionsByRelatedTagPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            loadMoreTransactionsByRelatedTagError = "JSON Decoding Failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    loadMoreTransactionsByRelatedTagError = error?.localizedDescription ?? "Unknown Error!"
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
                            modelData.accountsError = "JSON Decoding Failed!"
                        }
                        print("JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.accountsError = error?.localizedDescription ?? "Unknown Error!"
                }
                print(error?.localizedDescription ?? "Unknown Error!")
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
                            modelData.transactionsError = "JSON Decoding Failed!"
                        }
                        print("JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.transactionsError = error?.localizedDescription ?? "Unknown Error!"
                }
                print(error?.localizedDescription ?? "Unknown Error!")
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
                            modelData.categoriesError = "JSON Decoding Failed!"
                        }
                        print("JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.categoriesError = error?.localizedDescription ?? "Unknown Error!"
                }
                print(error?.localizedDescription ?? "Unknown Error!")
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
                            modelData.tagsError = "JSON Decoding Failed!"
                        }
                        print("JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.tagsError = error?.localizedDescription ?? "Unknown Error!"
                }
                print(error?.localizedDescription ?? "Unknown Error!")
            }
        }
        .resume()
    }
}
