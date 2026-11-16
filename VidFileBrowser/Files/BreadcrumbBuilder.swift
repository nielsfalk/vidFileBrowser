import Foundation

struct Breadcrumb: Identifiable, Hashable {
    let url: URL
    let title: String

    var id: URL { url }
}

enum BreadcrumbBuilder {
    static func segments(for url: URL?) -> [Breadcrumb] {
        guard let url else { return [] }

        let standardized = url.standardizedFileURL
        var components = standardized.pathComponents
        guard components.first == "/" else { return [] }
        components.removeFirst()

        let root = URL(fileURLWithPath: "/")
        var segments = [Breadcrumb(url: root, title: volumeName(for: root))]
        var current = root

        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        var index = 0

        while index < components.count {
            if index == 0, components.count > 1, components[0] == "Users" {
                let candidate = root
                    .appendingPathComponent("Users", isDirectory: true)
                    .appendingPathComponent(components[1], isDirectory: true)
                    .standardizedFileURL

                if candidate.path == home.path {
                    segments.append(Breadcrumb(url: home, title: "~"))
                    current = home
                    index += 2
                    continue
                }
            }

            current.appendPathComponent(components[index], isDirectory: true)
            segments.append(Breadcrumb(url: current, title: components[index]))
            index += 1
        }

        return segments
    }

    private static func volumeName(for url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.volumeLocalizedNameKey])
        return values?.volumeLocalizedName ?? "/"
    }
}
