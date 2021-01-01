import SwiftUI

struct TagRow: View {
    var tag: TagResource
    
    var body: some View {
        Text(tag.id)
            .font(.custom("CircularStd-Book", size: 17))
    }
}
