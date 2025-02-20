import SwiftUI

struct MovieKeywords: View {
    let keywords: [Keyword]
    let specialKeywordIds: [Int]
    let onSpecialKeywordLongPress: ((Int) -> Void)?
    
    init(
        keywords: [Keyword],
        specialKeywordIds: [Int] = [],
        onSpecialKeywordLongPress: ((Int) -> Void)? = nil
    ) {
        self.keywords = keywords
        self.specialKeywordIds = specialKeywordIds
        self.onSpecialKeywordLongPress = onSpecialKeywordLongPress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.keywordsTitle)
                .titleStyle()
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(keywords) { keyword in
                        if specialKeywordIds.contains(keyword.id) {
                            NavigationLink(destination: Button("Back"){ self.onSpecialKeywordLongPress?(keyword.id) }) {
                                RoundedBadge(text: keyword.name, color: .steamGold)
                            }
                        } else {
                            NavigationLink(destination: EmptyView()) {
                                RoundedBadge(text: keyword.name, color: .steamGold)
                            }
                        }
                    }
                }.padding(.leading)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
}
#if DEBUG
#Preview {
    MovieKeywords(keywords: [
        Keyword(id: 613, name: "new year's eve"),
        Keyword(id: 592, name: "capitalism"),
        Keyword(id: 2449, name: "black market"),
        Keyword(id: 1284, name: "identity"),
        Keyword(id: 10123, name: "dark comedy"),
        Keyword(id: 8201, name: "satire"),
        Keyword(id: 4995, name: "aging"),
        Keyword(id: 6562, name: "celebrity"),
        Keyword(id: 11322, name: "female protagonist"),
        Keyword(id: 12670, name: "los angeles, california"),
        Keyword(id: 163405, name: "aerobics"),
        Keyword(id: 170383, name: "disfigurement"),
        Keyword(id: 187056, name: "woman director"),
        Keyword(id: 214664, name: "beauty standards"),
        Keyword(id: 224636, name: "horror comedy"),
        Keyword(id: 228429, name: "insecure woman"),
        Keyword(id: 245415, name: "toxic masculinity"),
        Keyword(id: 251961, name: "drug"),
        Keyword(id: 283085, name: "body horror"),
        Keyword(id: 295902, name: "actress"),
        Keyword(id: 325778, name: "bold"),
        Keyword(id: 325801, name: "distressing")
    ])
}
#endif
