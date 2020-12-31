import SwiftUI

struct TransactionList: View {
    @EnvironmentObject var modelData: ModelData

    var account: AccountResource

    @State private var searchText: String = ""

    @State private var showSettledOnly = false

    @State private var showingInfo = false

    @State private var filter = FilterCategory.all
    @State private var selectedTransaction: TransactionResource?

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
                && (transaction.relationships.account.data.id == account.id)
        }
    }

    private var filteredTransactionsWithSearch: [TransactionResource] {
        filteredTransactions.filter { transaction in
            searchText.isEmpty || transaction.attributes.description.localizedStandardContains(searchText)
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
        if modelData.transactions.isEmpty {
            ProgressView {
                Text("Fetching \(pageName)...")
                    .font(.custom("CircularStd-Book", size: 17))
            }
            .navigationTitle(account.attributes.displayName)
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
                        Spacer()
                        Text(filterRawValueTransformed)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                            .opacity(0.65)
                    }
                    Toggle(isOn: $showSettledOnly) {
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(showSettledOnly == true ? .green : .gray)
                            Text("Settled only")
                                .font(.custom("CircularStd-Book", size: 17))
                        }
                    }
                }
                Section(header: Text(pageName)) {
                    ForEach(filteredTransactionsWithSearch) { transaction in
                        NavigationLink(destination: TransactionView(transaction: transaction)) {
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
                Section {
                    Text(bottomText)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                }
            }
            .navigationTitle(account.attributes.displayName)
            .listStyle(GroupedListStyle())
            .toolbar {
                infoButton
            }
            .sheet(isPresented: $showingInfo) {
                AccountInfo(account: account)
            }
        }
    }
}

struct AccountInfo: View {
    var account: AccountResource
    
    var body: some View {
        NavigationView {
            List {
                HStack(alignment: .center, spacing: 0) {
                    Text("Account ID")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Text(account.id)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                }
                HStack(alignment: .center, spacing: 0) {
                    Text("Created At")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Text(account.attributes.createdDate)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(account.attributes.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
