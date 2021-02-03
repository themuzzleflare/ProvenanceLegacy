import SwiftUI

struct Settings: View {
    @EnvironmentObject var modelData: ModelData
    
    @Binding var showingSettings: Bool
    
    @Environment(\.editMode) private var editMode
    
    @State private var apiTokenString: String = ""
    @State private var dateStyleSelection: DateStyle = .absolute
    
    @AppStorage("Settings.apiToken") private var apiToken: String = ""
    @AppStorage("Settings.dateStyle") private var dateStyle: DateStyle = .absolute
    
    enum DateStyle: String, CaseIterable, Identifiable {
        case absolute = "Absolute"
        case relative = "Relative"
        
        var id: DateStyle {
            return self
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    if editMode?.wrappedValue == .active {
                        Button("Cancel") {
                            apiTokenString = apiToken
                            dateStyleSelection = dateStyle
                            editMode?.animation().wrappedValue = .inactive
                        }
                        .padding(.leading)
                    } else {
                        Button("Close", action: {
                            showingSettings.toggle()
                        })
                        .padding(.leading)
                    }
                    Spacer()
                    Text("Settings")
                        .bold()
                    Spacer()
                    EditButton()
                        .padding(.trailing)
                }
                .padding(.vertical)
                .background(Color(.secondarySystemGroupedBackground))
                Divider()
            }
            if editMode?.wrappedValue == .inactive {
                SettingsSummary(apiToken: $apiToken, dateStyle: $dateStyle)
            } else {
                SettingsEditor(apiTokenString: $apiTokenString, dateStyleSelection: $dateStyleSelection)
                    .onAppear {
                        apiTokenString = apiToken
                        dateStyleSelection = dateStyle
                    }
                    .onDisappear {
                        if showingSettings {
                            apiToken = apiTokenString
                            dateStyle = dateStyleSelection
                        }
                    }
            }
        }
    }
}

struct SettingsEditor: View {
    @Binding var apiTokenString: String
    @Binding var dateStyleSelection: Settings.DateStyle
    
    var body: some View {
        List {
            Section {
                HStack(alignment: .center) {
                    Text("API Token")
                        .foregroundColor(.secondary)
                        .font(.custom("CircularStd-Book", size: 17))
                    Divider()
                    TextField("API Token", text: $apiTokenString)
                        .font(.custom("CircularStd-Book", size: 17))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.trailing)
                }
                
            }
            Section {
                HStack(alignment: .center, spacing: 0) {
                    Text("Date Style")
                        .foregroundColor(.secondary)
                        .font(.custom("CircularStd-Book", size: 17))
                    Spacer()
                    Picker("Date Style", selection: $dateStyleSelection) {
                        ForEach(Settings.DateStyle.allCases) { style in
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
    }
}

struct SettingsSummary: View {
    @EnvironmentObject var modelData: ModelData
    
    @Binding var apiToken: String
    @Binding var dateStyle: Settings.DateStyle
    
    private var apiTokenCellValue: String {
        switch apiToken {
            case "": return "None"
            default: return apiToken
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 0) {
                    Text("API Token")
                        .foregroundColor(.secondary)
                        .font(.custom("CircularStd-Book", size: 17))
                    Spacer()
                    Text(apiTokenCellValue)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.custom("CircularStd-Book", size: 17))
                }
            }
            Section {
                HStack(alignment: .center, spacing: 0) {
                    Text("Date Style")
                        .foregroundColor(.secondary)
                        .font(.custom("CircularStd-Book", size: 17))
                    Spacer()
                    Text(dateStyle.rawValue)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("CircularStd-Book", size: 17))
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}
