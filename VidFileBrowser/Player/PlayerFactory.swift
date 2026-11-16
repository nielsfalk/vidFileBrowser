import Foundation

enum PlayerFactory {
    static func make(dependencies: Dependencies = DependencyLocator.locate()) -> Player {
        guard let library = MPVLibrary.locate(dependencies: dependencies) else {
            return UnavailablePlayer()
        }
        return MPVPlayer(library: library)
    }
}
