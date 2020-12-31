import SwiftUI

struct AllTagsRow: View {
    var tag: TagResource
    
    var body: some View {
        Text(tag.id)
            .font(.custom("CircularStd-Book", size: 17.0))
    }
}
