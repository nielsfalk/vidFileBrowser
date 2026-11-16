import Foundation

final class AppSettings {
    enum Key {
        static let sortProperty = "sortProperty"
        static let sortAscending = "sortAscending"
    }

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
}
