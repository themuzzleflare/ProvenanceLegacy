import SwiftUI

struct TransactionList: View {
    var modelData: ModelData

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    @State private var searchText: String = ""

    @State private var loading: Bool = false

    @State private var showSettledOnly = false

    @State private var showingInfo = false

    @State private var filter = FilterCategory.all
    @State private var selectedTransaction: TransactionResource?

    var index: Int? {
        modelData.transactions.firstIndex(where: { $0.id == selectedTransaction?.id })
    }

    private enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case gamesAndSoftware = "games-and-software"
        case carInsuranceAndMaintenance = "car-insurance-and-maintenance"
        case family = "family"
        case groceries = "groceries"
        case booze = "booze"
        case clothingAndAccessories = "clothing-and-accessories"
        case cycling = "cycling"
        case homewareAndAppliances = "homeware-and-appliances"
        case educationAndStudentLoans = "education-and-student-loans"
        case eventsAndGigs = "events-and-gigs"
        case fuel = "fuel"
        case internet = "internet"
        case fitnessAndWellbeing = "fitness-and-wellbeing"
        case hobbies = "hobbies"
        case homeMaintenanceAndImprovements = "home-maintenance-and-improvements"
        case parking = "parking"
        case giftsAndCharity = "gifts-and-charity"
        case holidaysAndTravel = "holidays-and-travel"
        case pets = "pets"
        case publicTransport = "public-transport"
        case hairAndBeauty = "hair-and-beauty"
        case lotteryAndGambling = "lottery-and-gambling"
        case homeInsuranceAndRates = "home-insurance-and-rates"
        case carRepayments = "car-repayments"
        case healthAndMedical = "health-and-medical"
        case pubsAndBars = "pubs-and-bars"
        case rentAndMortgage = "rent-and-mortgage"
        case taxisAndShareCars = "taxis-and-share-cars"
        case investments = "investments"
        case restaurantsAndCafes = "restaurants-and-cafes"
        case tollRoads = "toll-roads"
        case utilities = "utilities"
        case lifeAdmin = "life-admin"
        case takeaway = "takeaway"
        case mobilePhone = "mobile-phone"
        case tobaccoAndVaping = "tobacco-and-vaping"
        case newsMagazinesAndBooks = "news-magazines-and-books"
        case tvAndMusic = "tv-and-music"
        case adult = "adult"
        case technology = "technology"

        var id: FilterCategory {
            return self
        }
    }

    private var filteredTransactions: [TransactionResource] {
        modelData.transactions.filter { transaction in
            (!showSettledOnly || transaction.attributes.isSettled)
                && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
        }
    }

    private var filteredTransactionsWithSearch: [TransactionResource] {
        filteredTransactions.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
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
        switch filteredTransactionsWithSearch.count {
            case 0: return "No \(pageName)"
            default: return "No More \(pageName)"
        }
    }

    private var searchPlaceholder: String {
        switch filteredTransactions.count {
            case 1: return "Search 1 Transaction"
            default: return "Search \(filteredTransactions.count) \(pageName)"
        }
    }

    private var filterRawValueTransformed: String {
        switch filter {
            case .gamesAndSoftware: return "Apps, Games & Software"
            case .carInsuranceAndMaintenance: return "Car Insurance, Rego & Maintenance"
            case .tvAndMusic: return "TV, Music & Streaming"
            default: return filter.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    private func categoryNameTransformed(_ category: FilterCategory) -> String {
        switch category {
            case .gamesAndSoftware: return "Apps, Games & Software"
            case .carInsuranceAndMaintenance: return "Car Insurance, Rego & Maintenance"
            case .tvAndMusic: return "TV, Music & Streaming"
            default: return category.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    private let pageName: String = "Transactions"

    var body: some View {
        NavigationView {
            if modelData.transactions.isEmpty && modelData.transactionsError.isEmpty && modelData.transactionsErrorResponse.isEmpty && modelData.transactionsStatusCode == 0 {
                ProgressView {
                    Text("Fetching \(pageName)...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
            } else if !modelData.transactionsError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .font(.custom("CircularStd-Book", size: 17))
                        .foregroundColor(.red)
                    Text(modelData.transactionsError)
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
            } else if !modelData.transactionsErrorResponse.isEmpty {
                ForEach(modelData.transactionsErrorResponse, id: \.self) { apiError in
                    VStack(alignment: .center, spacing: 0) {
                        Text(apiError.title)
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.red)
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
                List(selection: $selectedTransaction) {
                    Section {
                        SearchBar(text: $searchText, placeholder: searchPlaceholder)
                        HStack(alignment: .center, spacing: 0) {
                            Picker("Category", selection: $filter) {
                                ForEach(FilterCategory.allCases) { category in
                                    Text(categoryNameTransformed(category))
                                        .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                            Spacer()
                            Picker(filterRawValueTransformed, selection: $filter) {
                                ForEach(FilterCategory.allCases) { category in
                                    Text(categoryNameTransformed(category))
                                        .tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                        }
                        Toggle(isOn: $showSettledOnly) {
                            HStack(alignment: .center, spacing: 5) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(showSettledOnly == true ? .green : .secondary)
                                Text("Settled only")
                                    .font(.custom("CircularStd-Book", size: 17))
                                    .foregroundColor(showSettledOnly == true ? .primary : .secondary)
                            }
                        }
                    }
                    if filteredTransactionsWithSearch.count != 0 {
                        Section(header: Text(pageName)
                                    .font(.custom("CircularStd-Book", size: 12))) {
                            ForEach(filteredTransactionsWithSearch) { transaction in
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    refreshButton
                }
                .listStyle(GroupedListStyle())
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
