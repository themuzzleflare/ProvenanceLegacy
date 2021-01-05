import SwiftUI

struct AccountList: View {
    var modelData: ModelData

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    private let pageName: String = "Accounts"

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
            if modelData.accounts.isEmpty && modelData.accountsError.isEmpty && modelData.accountsErrorResponse.isEmpty && modelData.accountsStatusCode == 0 {
                ProgressView {
                    Text("Fetching \(pageName)...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
            } else if !modelData.accountsError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Bold", size: 17))
                        .foregroundColor(.red)
                    Text(modelData.accountsError)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.center)
                        .opacity(0.65)
                }
                .padding()
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    refreshButton
                }
            } else if !modelData.accountsErrorResponse.isEmpty {
                ForEach(modelData.accountsErrorResponse, id: \.self) { apiError in
                    VStack(alignment: .center, spacing: 0) {
                        Text(apiError.title)
                            .font(.custom("CircularStd-Bold", size: 17))
                            .foregroundColor(.red)
                        Text(apiError.detail)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.center)
                            .opacity(0.65)
                        Text(apiError.status)
                            .font(.custom("Menlo-Regular", size: 11))
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
                    if modelData.accounts.count != 0 {
                        Section(header: Text(pageName)
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(modelData.accounts) { account in
                                NavigationLink(destination: TransactionsByAccount(accountName: account)) {
                                    AccountRow(account: account)
                                }
                                .tag(account)
                            }
                        }
                    }
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    refreshButton
                }
                .listStyle(GroupedListStyle())
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
