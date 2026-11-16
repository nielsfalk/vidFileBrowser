import AppKit
import Foundation

/// Plays media through mpv's client API. Video is drawn into an attached
/// `MPVOpenGLView` via the libmpv render API, because mpv no longer supports
/// embedding an NSView through `wid` on macOS.
final class MPVPlayer: Player {
    var onStateChange: ((PlayerState) -> Void)?
    var onPositionChange: ((PlayerPosition) -> Void)?
    var onEndOfFile: (() -> Void)?

    private let library: MPVLibrary
    private var handle: MPVHandle?
    private var renderContext: OpaquePointer?
    private var renderView: MPVOpenGLView?
    private var renderContextError: String?
    private var autoplay = true
    private var isStopping = false
    private var position = PlayerPosition()

    init(library: MPVLibrary) {
        self.library = library
    }

    deinit {
        destroyRenderContext()
        if let handle {
            library.terminateDestroy(handle)
        }
    }

    func attach(view: NSView) {
        guard let view = view as? MPVOpenGLView else { return }
        if renderView === view, renderContext != nil {
            return
        }

        destroyRenderContext()
        renderView = view
        view.player = self

        createHandleIfNeeded()
        createRenderContextIfNeeded()
    }

    func detach(view: NSView) {
        guard let view = view as? MPVOpenGLView, renderView === view else { return }
        destroyRenderContext()
        renderView = nil
    }

    func load(_ url: URL, autoplay: Bool) throws {
        createHandleIfNeeded()
        createRenderContextIfNeeded()

        guard let handle else {
            throw PlayerError.unavailable("libmpv could not be initialised.")
        }
        guard renderContext != nil else {
            throw PlayerError.unavailable(renderContextError ?? "The video output could not be created.")
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

    /// Draws the current frame into the view's OpenGL context.
    func render(in view: MPVOpenGLView) {
        guard let renderContext else { return }

        view.openGLContext?.makeCurrentContext()

        let scale = view.window?.backingScaleFactor ?? 1
        let width = Int32(max(1, (view.bounds.width * scale).rounded()))
        let height = Int32(max(1, (view.bounds.height * scale).rounded()))

        var fbo = MPVOpenGLFBO(fbo: 0, width: width, height: height, internalFormat: 0)
        var flip: Int32 = 1

        withUnsafeMutablePointer(to: &fbo) { fboPointer in
            withUnsafeMutablePointer(to: &flip) { flipPointer in
                var params = [
                    MPVRenderParam(type: MPVRenderParamType.openGLFBO, data: UnsafeMutableRawPointer(fboPointer)),
                    MPVRenderParam(type: MPVRenderParamType.openGLFlipY, data: UnsafeMutableRawPointer(flipPointer)),
                    MPVRenderParam(type: MPVRenderParamType.invalid, data: nil)
                ]
                params.withUnsafeMutableBufferPointer { buffer in
                    guard let base = buffer.baseAddress else { return }
                    _ = library.renderContextRender(renderContext, params: UnsafeMutableRawPointer(base))
                }
            }
        }

        view.openGLContext?.flushBuffer()
    }

    private func createHandleIfNeeded() {
        guard handle == nil else { return }
        guard let context = library.create() else { return }

        if let logPath = ProcessInfo.processInfo.environment["VIDFB_MPV_LOG"] {
            library.setOptionString(context, "log-file", logPath)
            library.setOptionString(context, "msg-level", "all=v")
        }

        library.setOptionString(context, "terminal", "no")
        library.setOptionString(context, "idle", "yes")
        library.setOptionString(context, "keep-open", "yes")
        library.setOptionString(context, "keep-open-pause", "yes")
        library.setOptionString(context, "input-default-bindings", "no")
        library.setOptionString(context, "input-vo-keyboard", "no")
        library.setOptionString(context, "osc", "no")
        library.setOptionString(context, "load-scripts", "no")
        library.setOptionString(context, "hwdec", "auto-safe")
        // The render API provides the OpenGL context and framebuffer.
        library.setOptionString(context, "vo", "libmpv")
        library.setOptionString(context, "gpu-api", "opengl")

        guard library.initialize(context) >= 0 else {
            library.terminateDestroy(context)
            return
        }

        handle = context
        library.observeProperty(context, replyUserdata: 1, "time-pos", format: MPVFormat.double)
        library.observeProperty(context, replyUserdata: 2, "duration", format: MPVFormat.double)
        startEventLoop(context)
    }

    private func createRenderContextIfNeeded() {
        guard renderContext == nil, let handle, let view = renderView else { return }

        // mpv's OpenGL renderer is initialised against the current context.
        view.openGLContext?.makeCurrentContext()

        let getProcAddress: MPVGetProcAddressFn = { _, name in
            guard let name else { return nil }
            return dlsym(UnsafeMutableRawPointer(bitPattern: -2), name)
        }

        var initParams = MPVOpenGLInitParams(getProcAddress: getProcAddress, getProcAddressCtx: nil)
        var created: UnsafeMutableRawPointer?

        let result: Int32 = "opengl".withCString { apiName in
            withUnsafeMutablePointer(to: &initParams) { initParamsPointer in
                var params = [
                    MPVRenderParam(
                        type: MPVRenderParamType.apiType,
                        data: UnsafeMutableRawPointer(mutating: apiName)
                    ),
                    MPVRenderParam(
                        type: MPVRenderParamType.openGLInitParams,
                        data: UnsafeMutableRawPointer(initParamsPointer)
                    ),
                    MPVRenderParam(type: MPVRenderParamType.invalid, data: nil)
                ]
                return params.withUnsafeMutableBufferPointer { buffer in
                    guard let base = buffer.baseAddress else { return -1 }
                    return library.renderContextCreate(&created, handle: handle, params: UnsafeMutableRawPointer(base))
                }
            }
        }

        guard result >= 0, let created else {
            renderContextError = result < 0 ? library.errorString(result) : "mpv returned no render context."
            return
        }
        let context = OpaquePointer(created)
        renderContext = context

        let updateCallback: MPVRenderUpdateFn = { userdata in
            guard let userdata else { return }
            let view = Unmanaged<MPVOpenGLView>.fromOpaque(userdata).takeUnretainedValue()
            DispatchQueue.main.async {
                view.needsDisplay = true
            }
        }
        library.renderContextSetUpdateCallback(
            context,
            callback: updateCallback,
            userdata: Unmanaged.passUnretained(view).toOpaque()
        )
    }

    private func destroyRenderContext() {
        if let renderContext {
            library.renderContextFree(renderContext)
        }
        renderContext = nil
        renderView?.player = nil
        renderView = nil
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
