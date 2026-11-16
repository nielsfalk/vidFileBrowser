import Foundation

final class AppSettings {
    enum Key {
        static let sortProperty = "sortProperty"
        static let sortAscending = "sortAscending"
        static let lastFolderPath = "lastFolderPath"
        static let browserWidth = "browserWidth"
    }

    static let defaultBrowserWidth = 440.0

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var sortProperty: SortProperty {
        get { SortProperty(rawValue: defaults.string(forKey: Key.sortProperty) ?? "") ?? .date }
        set { defaults.set(newValue.rawValue, forKey: Key.sortProperty) }
    }

    var sortAscending: Bool {
        get { defaults.object(forKey: Key.sortAscending) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.sortAscending) }
    }

    var lastFolderPath: String? {
        get { defaults.string(forKey: Key.lastFolderPath) }
        set { defaults.set(newValue, forKey: Key.lastFolderPath) }
    }

    var browserWidth: Double {
        get { defaults.object(forKey: Key.browserWidth) as? Double ?? Self.defaultBrowserWidth }
        set { defaults.set(newValue, forKey: Key.browserWidth) }
    }
}
