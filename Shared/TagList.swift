import SwiftUI

struct TagList: View {
    var transaction: TransactionResource

    var body: some View {
        List(transaction.relationships.tags.data) { tag in
            TagRow(tag: tag)
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(GroupedListStyle())
    }
}
