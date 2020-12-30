import SwiftUI

struct AllTagsList: View {
    @EnvironmentObject var modelData: ModelData

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

    var body: some View {
        NavigationView {
            if modelData.tags.isEmpty && modelData.tagsError.isEmpty && modelData.tagsErrorResponse.isEmpty {
                ProgressView {
                    Text("Fetching \(pageName)...")
                        .font(.custom("CircularStd-Book", size: 17))
                }
                .navigationTitle(pageName)
            } else if !modelData.tagsError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .foregroundColor(.red)
                        .font(.custom("CircularStd-Bold", size: 17))
                    Text(modelData.tagsError)
                        .font(.custom("CircularStd-Book", size: 17))
                        .multilineTextAlignment(.center)
                        .opacity(0.65)
                }
                .padding()
                .navigationTitle(pageName)
            } else if !modelData.tagsErrorResponse.isEmpty {
                ForEach(modelData.tagsErrorResponse, id: \.self) { apiError in
                    VStack(alignment: .center, spacing: 0) {
                        Text(apiError.title)
                            .foregroundColor(.red)
                            .font(.custom("CircularStd-Bold", size: 17))
                        Text(apiError.detail)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.center)
                            .opacity(0.65)
                        Text(apiError.status)
                            .font(.custom("Menlo-Regular", size: 11))
                            .multilineTextAlignment(.center)
                            .opacity(0.45)
                            .padding(.top)
                    }
                }
                .padding()
                .navigationTitle(pageName)
            } else {
                List {
                    Section {
                        SearchBar(text: $searchText, placeholder: "Search \(modelData.tags.count) \(pageName)")
                    }
                    Section {
                        ForEach(filteredTags) { tag in
                            Text(tag.id)
                                .font(.custom("CircularStd-Book", size: 17.0))
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
            }
        }
    }
}
