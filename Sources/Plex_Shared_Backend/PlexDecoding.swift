import Foundation

/// Plex JSON mixes strings, numbers and booleans for the same field across server versions,
/// and returns a single object where an array is expected when only one element exists.
extension KeyedDecodingContainer {
    func flexibleString(forKey key: Key) throws -> String? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let string = try? decode(String.self, forKey: key) { return string }
        if let value = try? decode(Int64.self, forKey: key) { return String(value) }
        return String(try decode(Double.self, forKey: key))
    }

    func requiredString(forKey key: Key) throws -> String {
        guard let value = try flexibleString(forKey: key) else {
            throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: key.stringValue))
        }
        return value
    }

    func flexibleInteger<Value: FixedWidthInteger & Decodable>(forKey key: Key) throws -> Value? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Value.self, forKey: key) { return value }
        let string = try decode(String.self, forKey: key)
        guard let value = Value(string) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: key.stringValue)
        }
        return value
    }

    func flexibleDouble(forKey key: Key) throws -> Double? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Double.self, forKey: key) { return value }
        guard let value = Double(try decode(String.self, forKey: key)) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: key.stringValue)
        }
        return value
    }

    func flexibleBool(forKey key: Key) throws -> Bool? {
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key), value == 0 || value == 1 { return value == 1 }
        switch try decode(String.self, forKey: key).lowercased() {
        case "1", "true": return true
        case "0", "false": return false
        default: throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: key.stringValue)
        }
    }

    /// Strict: a malformed element fails the whole decode. Used inside one media item.
    func flexibleArray<Value: Decodable>(forKey key: Key) throws -> [Value] {
        guard contains(key), try !decodeNil(forKey: key) else { return [] }
        if let array = try? decode([Value].self, forKey: key) { return array }
        return [try decode(Value.self, forKey: key)]
    }

    /// Lenient: skips elements that fail to decode, like Plezy does for list pages and hubs,
    /// so one unusual item cannot blank an entire library page.
    func lossyArray<Value: Decodable>(forKey key: Key) throws -> [Value] {
        guard contains(key), try !decodeNil(forKey: key) else { return [] }
        guard var elements = try? nestedUnkeyedContainer(forKey: key) else {
            return (try? decode(Value.self, forKey: key)).map { [$0] } ?? []
        }
        var values: [Value] = []
        while !elements.isAtEnd {
            if let value = try? elements.decode(Value.self) { values.append(value) } else { _ = try elements.decode(PlexSkippedElement.self) }
        }
        return values
    }
}

private struct PlexSkippedElement: Decodable {
    init(from decoder: any Decoder) throws {}
}

/// A dynamic key for containers whose element key depends on the endpoint.
struct PlexCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ stringValue: String) { self.stringValue = stringValue }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// An element listed under `MediaContainer.{plexListKey}`, such as `Setting`, `Activity` or `Stream`.
protocol PlexListElement: Decodable, Sendable {
    static var plexListKey: String { get }
}

/// Decodes `{"MediaContainer": {"<key>": [...]}}`, skipping elements that fail to decode.
struct PlexListEnvelope<Element: PlexListElement>: Decodable, Sendable {
    let elements: [Element]

    init(from decoder: any Decoder) throws {
        elements = try decoder.container(keyedBy: PlexCodingKey.self)
            .nestedContainer(keyedBy: PlexCodingKey.self, forKey: PlexCodingKey("MediaContainer"))
            .lossyArray(forKey: PlexCodingKey(Element.plexListKey))
    }
}
