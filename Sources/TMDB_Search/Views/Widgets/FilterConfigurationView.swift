import Foundation
import SwiftUI

/// The sheet a chip opens: a toggle for adult content, a wheel of values for everything else.
@available(iOS 16.0, *)
public struct FilterConfigurationView: View {
    @Binding var filters: SearchFilters
    let filterType: FilterType
    /// Edits land here and reach `filters` only on Done, so Cancel really cancels and a wheel
    /// spun past ten years runs one search rather than ten.
    @State private var draft: SearchFilters
    @Environment(\.dismiss) private var dismiss

    public init(filters: Binding<SearchFilters>, filterType: FilterType) {
        _filters = filters
        _draft = State(initialValue: filters.wrappedValue)
        self.filterType = filterType
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(filterType.summary)
                    .font(.headline)

                editor

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(filterType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.filterCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.filterDone) {
                        filters = draft
                        dismiss()
                    }
                    .accessibilityIdentifier("search_filter_done")
                }
            }
        }
        // One control needs half a screen, not a full page of white.
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var editor: some View {
        if let keyPath = filterType.valueKeyPath {
            FilterValuePicker(filterType: filterType, selection: $draft[dynamicMember: keyPath])
        } else {
            Toggle(L10n.filterIncludeAdult, isOn: $draft.includeAdult)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .accessibilityIdentifier("search_filter_toggle")

            Text(L10n.filterIncludeAdultFootnote)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// A wheel of one filter's values, led by the row that turns it off.
@available(iOS 16.0, *)
struct FilterValuePicker: View {
    let filterType: FilterType
    @Binding var selection: String?

    var body: some View {
        Picker(filterType.displayName, selection: $selection) {
            Text(filterType.anyValueTitle).tag(nil as String?)
            ForEach(filterType.options, id: \.self) { value in
                Text(filterType.title(for: value)).tag(value as String?)
            }
        }
        .pickerStyle(.wheel)
    }
}

#if DEBUG
#Preview("Include adult") {
    TMDBSearchPreviewCatalog.filterIncludeAdult.view
}

#Preview("Language — French") {
    TMDBSearchPreviewCatalog.filterLanguage.view
}

#Preview("Region — none") {
    TMDBSearchPreviewCatalog.filterRegion.view
}

#Preview("Release year — 2024") {
    TMDBSearchPreviewCatalog.filterReleaseYear.view
}

#Preview("First air year — none") {
    TMDBSearchPreviewCatalog.filterFirstAirYear.view
}

#Preview("Year — 1984") {
    TMDBSearchPreviewCatalog.filterYear.view
}

#Preview("Value wheel") {
    TMDBSearchPreviewCatalog.filterValueWheel.view
}
#endif
