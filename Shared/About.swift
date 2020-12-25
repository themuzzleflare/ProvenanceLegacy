import SwiftUI

struct About: View {
    @EnvironmentObject var modelData: ModelData

    @State private var showingSettings = false

    private var settingsButton: some View {
        Button(action: {
            self.showingSettings.toggle()
        }) {
            Image(systemName: "gear")
                .imageScale(.large)
                .accessibilityLabel("Settings")
        }
    }

    private var networkConnectivity: Text {
        switch modelData.connectivity {
            case true: return Text("You are connected to the Internet.")
                .foregroundColor(.green)
            case false: return Text("You are not connected to the Internet.")
                .foregroundColor(.red)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(footer: networkConnectivity) {
                    VStack(spacing: 5) {
                        GIFImage(image: upAnimation)
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        Text(modelData.appDisplayName ?? modelData.appName ?? "Provenance")
                            .font(.custom("CircularStd-Bold", size: 34))
                    }
                    .padding(.vertical)
                    HStack(alignment: .center, spacing: 0) {
                        Text("Version")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(modelData.appVersion ?? "Unknown")
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack(alignment: .center, spacing: 0) {
                        Text("Build")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(modelData.appBuild ?? "Unknown")
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section(footer: Text(modelData.appCopyright ?? "Copyright © 2020 Paul Tavitian")
                            .font(.custom("CircularStd-Book", size: 12))) {
                    Link(destination: URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!) {
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "square.and.pencil")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("Contact Developer")
                                .font(.custom("CircularStd-Bold", size: 17))
                        }
                    }
                    .disabled(!modelData.connectivity)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                settingsButton
            }
            .listStyle(GroupedListStyle())
            .sheet(isPresented: $showingSettings) {
                Settings()
            }
        }
    }
}
