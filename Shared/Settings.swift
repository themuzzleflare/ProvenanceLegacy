import SwiftUI

struct Settings: View {
    @EnvironmentObject var modelData: ModelData
    
    @Binding var showingSettings: Bool
    
    @AppStorage("Settings.apiToken") private var apiToken: String = ""
    
    @AppStorage("Settings.dateStyle") private var dateStyle: DateStyle = .absolute
    
    enum DateStyle: String, CaseIterable, Identifiable {
        case absolute = "Absolute"
        case relative = "Relative"
        
        var id: DateStyle {
            return self
        }
    }
    
    private let pageName: String = "Settings"
    
    private var apiKeyCellValue: String {
        switch apiToken {
            case "": return "None"
            default: return apiToken
        }
    }
    
    private var dateStyleHeaderText: String {
        switch dateStyle {
            case .absolute: return "Dates will be displayed as absolute values reflecting the date and time on which a transaction took place."
            case .relative: return "Dates will be displayed as relative values reflecting the time interval since a transaction took place."
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("The personal access token used to communicate with the Up Banking Developer API.")
                            .font(.custom("CircularStd-Book", size: 12))) {
                    NavigationLink(destination: APIKeyEditor()) {
                        HStack(alignment: .center, spacing: 0) {
                            Text("API Key")
                                .font(.custom("CircularStd-Book", size: 17))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(apiKeyCellValue)
                                .font(.custom("CircularStd-Book", size: 17))
                                .multilineTextAlignment(.trailing)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                Section(footer: Text("The styling of dates associated with transactions.\n\n\(dateStyleHeaderText)")
                            .font(.custom("CircularStd-Book", size: 12))) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Date Style")
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Date Style", selection: $dateStyle) {
                            ForEach(DateStyle.allCases) { style in
                                Text(style.rawValue)
                                    .tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .font(.custom("CircularStd-Book", size: 17))
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(pageName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close", action: {
                    showingSettings.toggle()
                })
            }
        }
    }
}

struct APIKeyEditor: View {
    @State private var showingAlert = false
    @State private var tokenString: String = ""
    @State private var isEditing = false
    
    @AppStorage("Settings.apiToken")
    private var apiToken: String = ""
    
    private let pageName: String = "API Key"
    
    var footer: String?
    
    var body: some View {
        List {
            Section(footer: Text(footer ?? "")
                        .foregroundColor(.red)) {
                TextField(pageName, text: $tokenString) { isEditing in
                    self.isEditing = isEditing
                } onCommit: {
                    DispatchQueue.main.async {
                        if tokenString != apiToken && !tokenString.isEmpty {
                            self.showingAlert.toggle()
                            apiToken = tokenString
                        }
                    }
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle(pageName)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Success"), message: Text("Successfully changed \(pageName)."), dismissButton: .default(Text("Dismiss")))
        }
    }
}
