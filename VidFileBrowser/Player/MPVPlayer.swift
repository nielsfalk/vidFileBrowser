import AppKit
import Foundation

/// Plays media through mpv's client API and renders into the attached view.
final class MPVPlayer: Player {
    var onStateChange: ((PlayerState) -> Void)?
    var onPositionChange: ((PlayerPosition) -> Void)?
    var onEndOfFile: (() -> Void)?

    private let library: MPVLibrary
    private var handle: MPVHandle?
    private var volumeView: NSView?
    private var autoplay = true
    private var isStopping = false
    private var position = PlayerPosition()

    init(library: MPVLibrary) {
        self.library = library
    }

    deinit {
        if let handle {
            library.terminateDestroy(handle)
        }
    }

    func attach(view: NSView) {
        volumeView = view
        createHandleIfNeeded()
    }

    func load(_ url: URL, autoplay: Bool) throws {
        createHandleIfNeeded()
        guard let handle else {
            throw PlayerError.unavailable("libmpv could not be initialised.")
        }

        self.autoplay = autoplay
        isStopping = false
        position = PlayerPosition()
        library.setPropertyString(handle, "pause", autoplay ? "no" : "yes")

        let escaped = url.path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let result = library.commandString(handle, "loadfile \"\(escaped)\" replace")
        guard result >= 0 else {
            throw PlayerError.unavailable(library.errorString(result))
        }

        onStateChange?(.loading)
    }

    func play() {
        guard let handle else { return }
        library.setPropertyString(handle, "pause", "no")
        onStateChange?(.playing)
    }

    func pause() {
        guard let handle else { return }
        library.setPropertyString(handle, "pause", "yes")
        onStateChange?(.paused)
    }

    func seek(to time: Double) {
        guard let handle else { return }
        let clamped = max(0, time)
        library.commandString(handle, "seek \(clamped) absolute exact")
        position.time = clamped
        onPositionChange?(position)
    }

    func stop() {
        guard let handle else { return }
        isStopping = true
        library.commandString(handle, "stop")
        position = PlayerPosition()
        onPositionChange?(position)
        onStateChange?(.idle)
    }

    private func createHandleIfNeeded() {
        guard handle == nil, let view = volumeView else { return }
        guard let context = library.create() else { return }

        library.setOptionString(context, "terminal", "no")
        library.setOptionString(context, "idle", "yes")
        library.setOptionString(context, "keep-open", "yes")
        library.setOptionString(context, "keep-open-pause", "yes")
        library.setOptionString(context, "input-default-bindings", "no")
        library.setOptionString(context, "input-vo-keyboard", "no")
        library.setOptionString(context, "osc", "no")
        library.setOptionString(context, "vo", "libmpv")
        library.setOptionString(context, "hwdec", "auto-safe")

        var pointer = Int64(Int(bitPattern: Unmanaged.passUnretained(view).toOpaque()))
        _ = library.setOption(context, "wid", format: MPVFormat.int64, data: &pointer)

        guard library.initialize(context) >= 0 else {
            library.terminateDestroy(context)
            return
        }

        handle = context
        library.observeProperty(context, replyUserdata: 1, "time-pos", format: MPVFormat.double)
        library.observeProperty(context, replyUserdata: 2, "duration", format: MPVFormat.double)
        startEventLoop(context)
    }

    private func startEventLoop(_ context: MPVHandle) {
        let thread = Thread { [weak self] in
            guard let self else { return }
            while true {
                guard let event = self.library.waitEvent(context, timeout: -1) else { break }
                if event.eventID == MPVEventID.shutdown { break }
                DispatchQueue.main.async {
                    self.process(event)
                }
            }
        }
        thread.name = "MPVEventLoop"
        thread.start()
    }

    private func process(_ event: MPVEvent) {
        switch event.eventID {
        case MPVEventID.propertyChange:
            processPropertyChange(event)
        case MPVEventID.fileLoaded:
            onStateChange?(autoplay ? .playing : .paused)
        case MPVEventID.endFile:
            guard !isStopping else { return }
            position.time = position.duration
            onPositionChange?(position)
            onEndOfFile?()
        default:
            break
        }
    }

    private func processPropertyChange(_ event: MPVEvent) {
        guard let data = event.data else { return }
        let property = data.assumingMemoryBound(to: MPVEventProperty.self).pointee
        guard property.format == MPVFormat.double, let value = property.data else { return }
        let time = value.assumingMemoryBound(to: Double.self).pointee

        if property.name.map({ String(cString: $0) }) == "time-pos" {
            position.time = time
        } else {
            position.duration = time
            position.isSeekable = true
        }
        onPositionChange?(position)
    }
}
