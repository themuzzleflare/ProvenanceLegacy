import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData

    @State private var selection: Tab = .transactions

    enum Tab {
        case transactions
        case accounts
        case tags
        case categories
        case about
    }

    var body: some View {
        if modelData.connectivity {
            TabView(selection: $selection) {
                TransactionList()
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet")
                    }
                    .tag(Tab.transactions)
                AccountList()
                    .tabItem {
                        Label("Accounts", systemImage: "list.bullet.rectangle")
                    }
                    .tag(Tab.accounts)
                AllTagsList()
                    .tabItem {
                        Label("Tags", systemImage: "tag")
                    }
                    .tag(Tab.tags)
                CategoriesView()
                    .tabItem {
                        Label("Categories", systemImage: "arrow.up.arrow.down.circle")
                    }
                    .tag(Tab.categories)
                About()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
                    .tag(Tab.about)
            }
        } else {
            VStack(alignment: .center, spacing: 0) {
                Text("Error")
                    .foregroundColor(.red)
                    .font(.custom("CircularStd-Bold", size: 17))
                Text("This app requires an active internet connection.")
                    .font(.custom("CircularStd-Book", size: 17))
                    .multilineTextAlignment(.center)
                    .opacity(0.65)
            }
            .padding()
        }
    }
}
