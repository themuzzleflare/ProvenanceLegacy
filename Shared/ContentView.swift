import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData

    @State private var selection: Tab = .transactions

    enum Tab {
        case transactions
        case tags
        case about
    }

    var body: some View {
        if modelData.connectivity {
            TabView(selection: $selection) {
                AccountList()
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet")
                    }
                    .tag(Tab.transactions)
                AllTagsList()
                    .tabItem {
                        Label("Tags", systemImage: "tag")
                    }
                    .tag(Tab.tags)
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
                    .bold()
                Text("This app requires an active internet connection.")
                    .multilineTextAlignment(.center)
                    .opacity(0.65)
            }
            .padding()
        }
    }
}
