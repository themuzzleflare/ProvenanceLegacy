import SwiftUI

struct AllTagsList: View {
    @EnvironmentObject var modelData: ModelData

    @State private var searchText: String = ""

    private let pageName: String = "Tags"

    private var bottomText: String {
        switch modelData.tags.filter({
            searchText.isEmpty || $0.id.localizedStandardContains(searchText)
        }).count {
            case 0: return "No Tags"
            default: return "No More Tags"

        }
    }

    var body: some View {
        NavigationView {
            if modelData.tags.isEmpty && modelData.tagsError.isEmpty && modelData.tagsErrorResponse.isEmpty {
                ProgressView {
                    Text("Fetching \(pageName)...")
                }
                .navigationTitle(pageName)
            } else if !modelData.tagsError.isEmpty {
                VStack(alignment: .center, spacing: 0) {
                    Text("Error")
                        .foregroundColor(.red)
                        .bold()
                    Text(modelData.tagsError)
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
                            .bold()
                        Text(apiError.detail)
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
                    SearchBar(text: $searchText, placeholder: "Search \(modelData.tags.count) \(pageName)")
                    ForEach(modelData.tags.filter {
                        searchText.isEmpty ||
                            $0.id.localizedStandardContains(searchText)
                    }) { tag in
                        Text(tag.id)
                            .font(.custom("CircularStd-Book", size: 17.0))
                    }
                    Text(bottomText)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                }
                .navigationTitle(pageName)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(GroupedListStyle())
            }
        }
    }
}
