import Foundation
import NaturalLanguage

extension String {
    public func detectGeographicalEntities(in text: String) -> [String] {
        var geographicalEntities: [String] = []
        let tagger = NSLinguisticTagger(tagSchemes: [.nameType], options: 0)
        tagger.string = text
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let tags: [NSLinguisticTag] = [.placeName]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: [.omitWhitespace, .joinNames]) { tag, tokenRange, _ in
            if let tag = tag, tags.contains(tag) {
                let word = (text as NSString).substring(with: tokenRange)
                geographicalEntities.append(word)
            }
        }
        return geographicalEntities.removingDuplicates()
    }
}
