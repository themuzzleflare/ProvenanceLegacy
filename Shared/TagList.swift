import SwiftUI

struct TagList: View {
    @EnvironmentObject var modelData: ModelData

    private var tagFilter: [TagResource] {
        modelData.tags.filter { tag in
            transaction.relationships.tags.data.contains(.init(type: "tags", id: tag.id))
        }
    }

    var transaction: TransactionResource

    var body: some View {
        List(tagFilter) { tag in
            NavigationLink(destination: TransactionsByTag(tagName: tag)) {
                TagRow(tag: tag)
                    .tag(tag)
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(GroupedListStyle())
    }
}
