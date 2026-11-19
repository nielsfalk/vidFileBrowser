import Foundation

final class AppSettings {
    enum Key {
        static let sortProperty = "sortProperty"
        static let sortAscending = "sortAscending"
        static let lastFolderPath = "lastFolderPath"
        static let browserWidth = "browserWidth"
        static let autoTagEnabled = "autoTagEnabled"
        static let autoTagColor = "autoTagColor"
    }

    static let defaultBrowserWidth = 440.0

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var sortProperty: SortProperty {
        get {
            guard let raw = defaults.string(forKey: Key.sortProperty) else { return .date }
            if let property = SortProperty(rawValue: raw) {
                return property
            }
            // Older versions called the tag sort "label".
            return raw == "label" ? .tag : .date
        }
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

    var autoTagEnabled: Bool {
        get { defaults.object(forKey: Key.autoTagEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.autoTagEnabled) }
    }

    var autoTagColor: TagColor {
        get { TagColor(rawValue: defaults.integer(forKey: Key.autoTagColor)) ?? .green }
        set { defaults.set(newValue.rawValue, forKey: Key.autoTagColor) }
    }
}
