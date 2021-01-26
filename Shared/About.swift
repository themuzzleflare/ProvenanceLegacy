import SwiftUI

struct About: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var showingSettings: Bool = false

    private var settingsButton: some View {
        Button(action: {
            showingSettings.toggle()
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

    private let pageName: String = "About"

    var body: some View {
        NavigationView {
            List {
                Section(footer: networkConnectivity
                            .font(.custom("CircularStd-Book", size: 12))) {
                    VStack(spacing: 5) {
                        GIFImage(image: upAnimation)
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                        Text(modelData.appName)
                            .font(.custom("CircularStd-Book", size: 34))
                    }
                    .padding(.vertical)
                    HStack(alignment: .center, spacing: 0) {
                        Text("Version")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(modelData.appVersion)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                    .contextMenu {
                        if modelData.appVersion != "Unknown" {
                            Button("Copy", action: {
                                UIPasteboard.general.string = modelData.appVersion
                            })
                        }
                    }
                    HStack(alignment: .center, spacing: 0) {
                        Text("Build")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(modelData.appBuild)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                    .contextMenu {
                        if modelData.appBuild != "Unknown" {
                            Button("Copy", action: {
                                UIPasteboard.general.string = modelData.appBuild
                            })
                        }
                    }
                }
                Section(footer: Text(modelData.appCopyright)
                            .font(.custom("CircularStd-Book", size: 12))) {
                    Link(destination: URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!) {
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "square.and.pencil")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("Contact Developer")
                                .font(.custom("CircularStd-Book", size: 17))
                        }
                    }
                    .disabled(!modelData.connectivity)
                }
            }
            .navigationTitle(pageName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                settingsButton
            }
            .listStyle(GroupedListStyle())
            .sheet(isPresented: $showingSettings) {
                Settings(showingSettings: $showingSettings)
                    .environmentObject(modelData)
            }
        }
    }
}
