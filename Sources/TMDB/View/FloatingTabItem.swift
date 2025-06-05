import SwiftUI

struct FloatingTabItem<Selection: Hashable> {
    let tag: Selection
    let icon: Image
    let title: String
}

// Define the floating tab bar view
struct FloatingTabBar<Selection: Hashable>: View {
    @Binding var selection: Selection
    @Binding var isHidden: Bool
    let items: [FloatingTabItem<Selection>]
    
    var body: some View {
        ZStack {
            HStack {
                ForEach(items, id: \.tag) { item in
                    Button(action: {
                        selection = item.tag
                    }) {
                        HStack {
                            item.icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            if item.tag == selection {
                                Text(item.title).font(.caption)
                            }
                        }
                        .foregroundColor(item.tag == selection ? .blue : .gray)
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)
            .offset(y: isHidden ? 100 : 0) // Move down when hidden
            .opacity(isHidden ? 0 : 1)     // Fade out when hidden
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHidden)
    }
}
