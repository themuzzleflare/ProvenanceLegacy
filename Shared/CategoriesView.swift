import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var modelData: ModelData

    @AppStorage("Settings.apiToken") private var apiToken: String = ""

    @State private var searchText: String = ""

    private let pageName: String = "Categories"

    private var filteredCategories: [CategoryResource] {
        modelData.categories.filter { category in
            searchText.isEmpty || category.attributes.name.localizedStandardContains(searchText)
        }
    }

    private var bottomText: String {
        switch filteredCategories.count {
            case 0: return "No Categories"
            default: return "No More Categories"

        }
    }

    private var refreshButton: some View {
        Button(action: {
            DispatchQueue.main.async {
                modelData.accounts = []
                modelData.transactions = []
                modelData.categories = []
                modelData.tags = []
                if !modelData.accountsError.isEmpty {
                    modelData.accountsError = ""
                }
                if !modelData.transactionsError.isEmpty {
                    modelData.transactionsError = ""
                }
                if !modelData.categoriesError.isEmpty {
                    modelData.categoriesError = ""
                }
                if !modelData.tagsError.isEmpty {
                    modelData.tagsError = ""
                }
                if !modelData.accountsErrorResponse.isEmpty {
                    modelData.accountsErrorResponse = []
                }
                if !modelData.transactionsErrorResponse.isEmpty {
                    modelData.transactionsErrorResponse = []
                }
                if !modelData.categoriesErrorResponse.isEmpty {
                    modelData.categoriesErrorResponse = []
                }
                if !modelData.tagsErrorResponse.isEmpty {
                    modelData.tagsErrorResponse = []
                }
                if !modelData.loadMoreTransactionsError.isEmpty {
                    modelData.loadMoreTransactionsError = ""
                }
                if !modelData.loadMoreTagsError.isEmpty {
                    modelData.loadMoreTagsError = ""
                }
                if modelData.transactionsStatusCode != 0 {
                    modelData.transactionsStatusCode = 0
                }
                if modelData.accountsStatusCode != 0 {
                    modelData.accountsStatusCode = 0
                }
                if modelData.tagsStatusCode != 0 {
                    modelData.tagsStatusCode = 0
                }
                if modelData.categoriesStatusCode != 0 {
                    modelData.categoriesStatusCode = 0
                }
            }
            listAccounts()
            listTransactions()
            listCategories()
            listTags()
        }) {
            Image(systemName: "arrow.clockwise.circle")
                .imageScale(.large)
                .accessibilityLabel("Refresh")
        }
    }

    var body: some View {
        NavigationView {
            if modelData.categories.isEmpty && modelData.categoriesError.isEmpty && modelData.categoriesErrorResponse.isEmpty && modelData.categoriesStatusCode == 0 {
                ProgressView {
                    Text("Fetching \(pageName)...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
            } else if !modelData.categoriesError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .foregroundColor(.red)
                        .font(.custom("CircularStd-Book", size: 17))
                    Text(modelData.categoriesError)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    refreshButton
                }
            } else if !modelData.categoriesErrorResponse.isEmpty {
                ForEach(modelData.categoriesErrorResponse, id: \.self) { apiError in
                    VStack(alignment: .center, spacing: 0) {
                        Text(apiError.title)
                            .foregroundColor(.red)
                            .font(.custom("CircularStd-Book", size: 17))
                        Text(apiError.detail)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Text(apiError.status)
                            .font(.custom("SFMono-Regular", size: 11))
                            .multilineTextAlignment(.center)
                            .opacity(0.45)
                            .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    refreshButton
                }
            } else {
                List {
                    Section {
                        SearchBar(text: $searchText, placeholder: "Search \(modelData.categories.count) \(pageName)")
                            .listRowInsets(EdgeInsets())
                    }
                    if filteredCategories.count != 0 {
                        Section(header: Text(pageName)
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(filteredCategories) { category in
                                NavigationLink(destination: TransactionsByCategory(categoryId: category.id, categoryName: category.attributes.name)) {
                                    CategoriesRow(category: category)
                                }
                                .contextMenu {
                                    Button("Copy", action: {
                                        UIPasteboard.general.string = category.attributes.name
                                    })
                                }
                                .tag(category)
                            }
                        }
                    }
                    Section {
                        Text(bottomText)
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(GroupedListStyle())
                .toolbar {
                    refreshButton
                }
            }
        }
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
