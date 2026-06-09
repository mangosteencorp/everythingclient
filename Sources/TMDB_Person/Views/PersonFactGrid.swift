import Foundation
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonFactGrid: View {
    let person: PersonDetail

    var body: some View {
        let displayFacts = facts

        if !displayFacts.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(displayFacts) { fact in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fact.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(fact.value)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    private var facts: [PersonFact] {
        let candidates = [
            (LocalizedStringResource.personLife, lifeValue),
            (LocalizedStringResource.personBirthplace, person.placeOfBirth),
            (LocalizedStringResource.personAlsoKnownAs, aliasesValue),
        ]

        return candidates.compactMap { title, value in
            guard let value, !value.isEmpty else { return nil }
            return PersonFact(title: title, value: value)
        }
    }

    private var lifeValue: String? {
        switch (person.birthday, person.deathday) {
        case let (birthday?, deathday?):
            return String(localized: LocalizedStringResource.personLifespanFormat(birthday, deathday))
        case let (birthday?, nil):
            return String(localized: LocalizedStringResource.personBornFormat(birthday))
        default:
            return nil
        }
    }

    private var aliasesValue: String? {
        let aliases = Array(person.alsoKnownAs.prefix(2))
        guard !aliases.isEmpty else { return nil }
        return ListFormatter.localizedString(byJoining: aliases)
    }
}

@available(iOS 16.0, *)
private struct PersonFact: Identifiable {
    let title: LocalizedStringResource
    let value: String

    var id: String { String(localized: title) }
}
