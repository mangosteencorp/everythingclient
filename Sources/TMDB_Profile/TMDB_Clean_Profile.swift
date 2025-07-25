import Swinject
import TMDB_Shared_Backend
// swiftlint:disable type_name
public struct TMDB_Profile {
    public static func configure(_ container: Container) {
        let assembly = ProfileAssembly()
        assembly.assemble(container: container)
    }

    private init() {}
}

// swiftlint:enable type_name