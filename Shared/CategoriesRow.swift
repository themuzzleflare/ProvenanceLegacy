import SwiftUI

struct CategoriesRow: View {
    var category: CategoryResource
    
    var body: some View {
        Text(category.attributes.name)
            .font(.custom("CircularStd-Book", size: 17.0))
    }
}
