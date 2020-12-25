import SwiftUI

struct Settings: View {
    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    private let pageName: String = "Settings"

    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("The personal access token used to communicate with the Up Banking Developer API.")) {
                    NavigationLink(destination: APIKeyEditor()) {
                        HStack(alignment: .center, spacing: 0) {
                            Text("API Key")
                                .foregroundColor(.accentColor)
                            Spacer()
                            Text(apiToken)
                                .opacity(0.65)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(pageName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct APIKeyEditor: View {
    @State private var showingAlert = false
    @State private var tokenString: String = ""
    @State private var isEditing = false

    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""

    var body: some View {
        List {
            TextField("API Token", text: $tokenString) { isEditing in
                self.isEditing = isEditing
            } onCommit: {
                DispatchQueue.main.async {
                    if tokenString != apiToken {
                        self.showingAlert.toggle()
                    }
                    apiToken = tokenString
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("API Key")
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Success"), message: Text("Successfully changed API key."), dismissButton: .default(Text("Dismiss")))
        }
    }
}
