import Swinject
import TMDB_Shared_Backend

public struct TMDB_Clean_Profile {
    public static func configure(_ container: Container) {
        let assembly = ProfileAssembly()
        assembly.assemble(container: container)
    }
    
    private init() {}
} 