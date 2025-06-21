import Foundation
import SwiftUI

@available(iOS 16.0, *)
public struct FilterConfigurationView: View {
    @Binding var filters: SearchFilters
    let filterType: FilterType
    @Environment(\.dismiss) private var dismiss

    public init(filters: Binding<SearchFilters>, filterType: FilterType) {
        _filters = filters
        self.filterType = filterType
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                switch filterType {
                case .includeAdult:
                    includeAdultView
                case .language:
                    languageView
                case .primaryReleaseYear:
                    yearView(title: L10n.filterPrimaryReleaseYear, binding: $filters.primaryReleaseYear)
                case .region:
                    regionView
                case .year:
                    yearView(title: L10n.filterYear, binding: $filters.year)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(filterType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.filterCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.filterDone) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var includeAdultView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.filterIncludeAdultDescription)
                .font(.headline)

            Toggle(L10n.filterIncludeAdult, isOn: $filters.includeAdult)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            Text("When enabled, search results will include movies rated for adults (R-rated and above)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var languageView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.filterLanguageDescription)
                .font(.headline)

            Picker(L10n.filterLanguage, selection: $filters.language) {
                Text(L10n.filterAnyLanguage).tag(nil as String?)
                Text("English (US)").tag("en-US" as String?)
                Text("English (UK)").tag("en-GB" as String?)
                Text("Spanish").tag("es" as String?)
                Text("French").tag("fr" as String?)
                Text("German").tag("de" as String?)
                Text("Italian").tag("it" as String?)
                Text("Portuguese").tag("pt" as String?)
                Text("Russian").tag("ru" as String?)
                Text("Japanese").tag("ja" as String?)
                Text("Korean").tag("ko" as String?)
                Text("Chinese").tag("zh" as String?)
            }
            .pickerStyle(.wheel)
        }
    }

    private var regionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.filterRegionDescription)
                .font(.headline)

            Picker(L10n.filterRegion, selection: $filters.region) {
                Text(L10n.filterAnyRegion).tag(nil as String?)
                Text("United States").tag("US" as String?)
                Text("United Kingdom").tag("GB" as String?)
                Text("Canada").tag("CA" as String?)
                Text("Australia").tag("AU" as String?)
                Text("Germany").tag("DE" as String?)
                Text("France").tag("FR" as String?)
                Text("Spain").tag("ES" as String?)
                Text("Italy").tag("IT" as String?)
                Text("Japan").tag("JP" as String?)
                Text("South Korea").tag("KR" as String?)
                Text("China").tag("CN" as String?)
            }
            .pickerStyle(.wheel)
        }
    }

    private func yearView(title: String, binding: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select \(title.lowercased())")
                .font(.headline)

            HStack {
                TextField(L10n.filterEnterYear, text: Binding(
                    get: { binding.wrappedValue ?? "" },
                    set: { binding.wrappedValue = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

                Button(L10n.filterClear) {
                    binding.wrappedValue = nil
                }
                .disabled(binding.wrappedValue == nil)
            }

            Text(L10n.filterYearDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    FilterConfigurationView(
        filters: .constant(SearchFilters()),
        filterType: .language
    )
}
#endif