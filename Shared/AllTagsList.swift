import SwiftUI

struct AllTagsList: View {
    @EnvironmentObject var modelData: ModelData

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    @State private var searchText: String = ""

    private let pageName: String = "Tags"

    private var filteredTags: [TagResource] {
        modelData.tags.filter { tag in
            searchText.isEmpty || tag.id.localizedStandardContains(searchText)
        }
    }

    private var bottomText: String {
        switch filteredTags.count {
            case 0: return "No Tags"
            default: return "No More Tags"

        }
    }

    private var addButton: some View {
        Button(action: {
            modelData.showingAddForm.toggle()
        }) {
            Image(systemName: "plus.circle")
                .imageScale(.large)
                .accessibilityLabel("Add")
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
            if modelData.tags.isEmpty && modelData.tagsError.isEmpty && modelData.tagsErrorResponse.isEmpty && modelData.tagsStatusCode == 0 {
                ProgressView {
                    Text("Fetching \(pageName)...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .onAppear {
                    if modelData.showingAddForm {
                        DispatchQueue.main.async {
                            listAccounts()
                            listTransactions()
                            listCategories()
                            listTags()
                        }
                    }
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
            } else if !modelData.tagsError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .foregroundColor(.red)
                        .font(.custom("CircularStd-Book", size: 17))
                    Text(modelData.tagsError)
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
            } else if !modelData.tagsErrorResponse.isEmpty {
                ForEach(modelData.tagsErrorResponse, id: \.self) { apiError in
                    VStack(alignment: .center, spacing: 0) {
                        Text(apiError.title)
                            .foregroundColor(.red)
                            .font(.custom("CircularStd-Book", size: 17))
                        Text(apiError.detail)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.center)
                            .opacity(0.65)
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
                        SearchBar(text: $searchText, placeholder: "Search \(modelData.tags.count) \(pageName)")
                    }
                    if filteredTags.count != 0 {
                        Section(header: Text(pageName)
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(filteredTags) { tag in
                                NavigationLink(destination: TransactionsByTag(modelData: modelData, tagName: tag)) {
                                    AllTagsRow(tag: tag)
                                }
                                .contextMenu {
                                    Button("Copy", action: {
                                        UIPasteboard.general.string = tag.id
                                    })
                                }
                                .tag(tag)
                            }
                        }
                    }
                    Section {
                        Text(bottomText)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                    }
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(GroupedListStyle())
                .navigationBarItems(leading: addButton)
                .toolbar {
                    refreshButton
                }
                .sheet(isPresented: $modelData.showingAddForm) {
                    AddTagForm(modelData: modelData)
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

struct AddTagForm: View {
    var modelData: ModelData

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    @State private var loading: Bool = false

    var body: some View {
        NavigationView {
            List {
                if modelData.transactions.count != 0 {
                    Section(header: Text("Transactions")
                                .font(.custom("CircularStd-Book", size: 12))) {
                        ForEach(modelData.transactions) { transaction in
                            NavigationLink(destination: AddTagFormStep2(modelData: modelData, transaction: transaction)) {
                                TransactionRow(transaction: transaction)
                            }
                            .tag(transaction)
                        }
                    }
                    if modelData.transactionsPagination.next != nil {
                        Section {
                            if loading == true {
                                ProgressView()
                            } else {
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if !modelData.loadMoreTransactionsError.isEmpty {
                                            modelData.loadMoreTransactionsError = ""
                                        }
                                        loading.toggle()
                                        nextPage(modelData.transactionsPagination.next!)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("Load More")
                                            .font(.custom("CircularStd-Book", size: 17))
                                        if !modelData.loadMoreTransactionsError.isEmpty {
                                            Text(modelData.loadMoreTransactionsError)
                                                .font(.caption)
                                                .opacity(0.65)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("You don't have any transactions to add tags to. As such, you are unable to proceed.")
                        .font(.custom("CircularStd-Book", size: 17))
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Select Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close", action: {
                    modelData.showingAddForm.toggle()
                })
            }
        }
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
                            modelData.loadMoreTransactionsError = decodedResponse.errors.first!.detail
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.loadMoreTransactionsError = "Authorisation Error!"
                            loading.toggle()
                        }
                    }
                } else {
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                        DispatchQueue.main.async {
                            modelData.transactions.append(contentsOf: decodedResponse.data)
                            modelData.transactionsPagination = decodedResponse.links
                            loading.toggle()
                        }
                    } else {
                        DispatchQueue.main.async {
                            modelData.loadMoreTransactionsError = "JSON Serialisation failed!"
                            loading.toggle()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    modelData.loadMoreTransactionsError = error?.localizedDescription ?? "Unknown error."
                    loading.toggle()
                }
            }
        }
        .resume()
    }
}

struct AddTagFormStep2: View {
    var modelData: ModelData

    var transaction: TransactionResource

    var body: some View {
        List {
            if modelData.tags.count != 0 {
                Section(header: Text("Tags")
                            .font(.custom("CircularStd-Book", size: 12))) {
                    ForEach(modelData.tags) { tag in
                        NavigationLink(destination: AddTagFormStep3(modelData: modelData, transaction: transaction, tag: tag)) {
                            AllTagsRow(tag: tag)
                        }
                        .tag(tag)
                    }
                }
            }
            Section {
                NavigationLink(destination: AddTagFormStep3Alt(modelData: modelData, transaction: transaction)) {
                    Text("New Tag")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Select Tag")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddTagFormStep3Alt: View {
    var modelData: ModelData
    var transaction: TransactionResource

    @State var newTag: String = ""

    @ObservedObject var tagString = TextLimiter(limit: 30)
    @State private var isEditing = false

    var body: some View {
        List {
            TextField("Tag Name", text: $tagString.value) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                DispatchQueue.main.async {
                    if !tagString.value.isEmpty {
                        newTag = tagString.value
                    }
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("New Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink("Next", destination: AddTagFormStep3(modelData: modelData, transaction: transaction, tag: TagResource.init(type: "tags", id: newTag)))
                .disabled(newTag.isEmpty || tagString.value != newTag)
                .tag(newTag)
        }
    }
}

struct AddTagFormStep3: View {
    var modelData: ModelData

    @State private var showingFailAlert = false
    @State private var addTagStatusCode: Int = 0

    private var errorAlert: Alert {
        switch addTagStatusCode {
            case 403: return Alert(title: Text("Forbidden"), message: Text("Too many tags added to this transaction. Each transaction may have up to 6 tags."), dismissButton: .default(Text("Dismiss")))
            default: return Alert(title: Text("Failed"), message: Text("The tag was not added to the transaction."), dismissButton: .default(Text("Dismiss")))
        }
    }

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    var transaction: TransactionResource
    var tag: TagResource

    var body: some View {
        List {
            Section(header: Text("Adding Tag")
                        .font(.custom("CircularStd-Book", size: 12))) {
                AllTagsRow(tag: tag)
            }
            Section(header: Text("To Transaction")
                        .font(.custom("CircularStd-Book", size: 12))) {
                TransactionRow(transaction: transaction)
            }
            Section(header: Text("Summary")
                        .font(.custom("CircularStd-Book", size: 12)), footer: Text("No more than 6 tags may be present on any single transaction. Duplicate tags are silently ignored.")
                            .font(.custom("CircularStd-Book", size: 12))) {
                Text("You are adding the tag \"\(tag.id)\" to the transaction \"\(transaction.attributes.description)\", which was created on \(transaction.attributes.createdDate).")
                    .font(.custom("CircularStd-Book", size: 17))
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingFailAlert) {
            errorAlert
        }
        .toolbar {
            Button("Add", action: {
                DispatchQueue.main.async {
                    addTag(transaction, tag: tag)
                }
            })
        }
    }

    private func addTag(_ transaction: TransactionResource, tag: TagResource) {
        let url = URL(string: transaction.relationships.tags.links?.`self` ?? "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        let bodyObject: [String : Any] = [
            "data": [
                [
                    "type": "tags",
                    "id": "\(tag.id)"
                ]
            ]
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if (error == nil) {
                let statusCode = (response as! HTTPURLResponse).statusCode
                DispatchQueue.main.async {
                    addTagStatusCode = statusCode
                }
                if statusCode != 204 {
                    DispatchQueue.main.async {
                        showingFailAlert.toggle()
                    }
                } else {
                    DispatchQueue.main.async {
                        modelData.tagsStatusCode = 0
                        modelData.tagsError = ""
                        modelData.tagsErrorResponse = []
                        modelData.tags = []
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
}

