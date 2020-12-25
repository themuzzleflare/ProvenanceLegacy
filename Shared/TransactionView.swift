import SwiftUI

struct TransactionView: View {
    @EnvironmentObject var modelData: ModelData

    var transaction: TransactionResource

    private var statusIcon: Image {
        switch transaction.attributes.status {
            case .held: return Image(systemName: "clock")
            case .settled: return Image(systemName: "checkmark.circle")
        }
    }

    private var statusColour: Color {
        switch transaction.attributes.status {
            case .held: return .yellow
            case .settled: return .green
        }
    }
    
    var body: some View {
        List {
            Group {
                HStack(alignment: .center, spacing: 5) {
                    Text("Status")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Group {
                        Text(transaction.attributes.status.rawValue.capitalized)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                        statusIcon
                            .foregroundColor(statusColour)
                    }
                    .multilineTextAlignment(.trailing)
                }
                if transaction.attributes.rawText != nil {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Raw Text")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(transaction.attributes.rawText!)
                            .font(.custom("Menlo-Regular", size: 17))
                            .multilineTextAlignment(.trailing)
                            .opacity(0.65)
                    }
                }
                if transaction.attributes.message != nil && transaction.attributes.message != "" {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Message")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(transaction.attributes.message!)
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                            .opacity(0.65)
                    }
                }
            }
            Group {
                if transaction.attributes.holdInfo != nil {
                    if transaction.attributes.holdInfo!.amount.value != transaction.attributes.amount.value {
                        HStack(alignment: .center, spacing: 0) {
                            Text("Hold \(transaction.attributes.holdInfo!.amount.transType)")
                                .font(.custom("CircularStd-Bold", size: 17))
                            Spacer()
                            Group {
                                Text(transaction.attributes.holdInfo!.amount.valueSymbol)
                                Text(transaction.attributes.holdInfo!.amount.valueString)
                                Text(" \(transaction.attributes.holdInfo!.amount.currencyCode)")
                            }
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    if transaction.attributes.holdInfo!.foreignAmount != nil {
                        if transaction.attributes.holdInfo!.foreignAmount!.value != transaction.attributes.foreignAmount!.value {
                            HStack(alignment: .center, spacing: 0) {
                                Text("Hold Foreign \(transaction.attributes.holdInfo!.foreignAmount!.transType)")
                                    .font(.custom("CircularStd-Bold", size: 17))
                                Spacer()
                                Group {
                                    Text(transaction.attributes.holdInfo!.foreignAmount!.valueSymbol)
                                    Text(transaction.attributes.holdInfo!.foreignAmount!.valueString)
                                    Text(" \(transaction.attributes.holdInfo!.foreignAmount!.currencyCode)")
                                }
                                .font(.custom("CircularStd-Book", size: 17))
                                .opacity(0.65)
                                .multilineTextAlignment(.trailing)
                            }
                        }

                    }
                }
            }
            Group {
                if transaction.attributes.foreignAmount != nil {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Foreign \(transaction.attributes.foreignAmount!.transType)")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Group {
                            Text(transaction.attributes.foreignAmount!.valueSymbol)
                            Text(transaction.attributes.foreignAmount!.valueString)
                            Text(" \(transaction.attributes.foreignAmount!.currencyCode)")
                        }
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                    }
                }
                HStack(alignment: .center, spacing: 0) {
                    Text(transaction.attributes.amount.transType)
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Group {
                        Text(transaction.attributes.amount.valueSymbol)
                        Text(transaction.attributes.amount.valueString)
                        Text(" \(transaction.attributes.amount.currencyCode)")
                    }
                    .font(.custom("CircularStd-Book", size: 17))
                    .opacity(0.65)
                    .multilineTextAlignment(.trailing)
                }
            }
            Group {
                HStack(alignment: .center, spacing: 0) {
                    Text("Created At")
                        .font(.custom("CircularStd-Bold", size: 17))
                    Spacer()
                    Text(transaction.attributes.createdDate)
                        .font(.custom("CircularStd-Book", size: 17))
                        .opacity(0.65)
                        .multilineTextAlignment(.trailing)
                }
                if transaction.attributes.settledDate != nil {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Settled At")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(transaction.attributes.settledDate!)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            if transaction.relationships.parentCategory.data != nil {
                ForEach(modelData.categories.filter {
                    $0.id == transaction.relationships.parentCategory.data!.id
                }) { pcategory in
                    HStack(alignment: .center, spacing: 0) {
                        Text("Parent Category")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(pcategory.attributes.name)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            if transaction.relationships.category.data != nil {
                ForEach(modelData.categories.filter {
                    $0.id == transaction.relationships.category.data!.id
                }) { category in
                    HStack(alignment: .center, spacing: 0) {
                        Text("Category")
                            .font(.custom("CircularStd-Bold", size: 17))
                        Spacer()
                        Text(category.attributes.name)
                            .font(.custom("CircularStd-Book", size: 17))
                            .opacity(0.65)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            if transaction.relationships.tags.data != [] {
                NavigationLink(destination: TagList(transaction: transaction)) {
                    Text("Tags (\(transaction.relationships.tags.data.count))")
                        .font(.custom("CircularStd-Bold", size: 17))
                }
            }
        }
        .navigationTitle(transaction.attributes.description)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(GroupedListStyle())
    }
}
