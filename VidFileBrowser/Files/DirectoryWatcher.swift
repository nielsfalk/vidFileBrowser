import Foundation

final class DirectoryWatcher {
    private let queue = DispatchQueue(label: "VidFileBrowser.DirectoryWatcher")
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var onChange: (() -> Void)?

    deinit {
        stop()
    }

    func watch(_ url: URL, onChange: @escaping () -> Void) {
        stop()
        self.onChange = onChange

        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend, .attrib],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.scheduleChange()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        self.source = source
        source.resume()
    }

    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        source?.cancel()
        source = nil
    }

    private func scheduleChange() {
        debounceWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self, let onChange = self.onChange else { return }
            DispatchQueue.main.async {
                onChange()
            }
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
