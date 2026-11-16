import Darwin
import Foundation

typealias MPVHandle = OpaquePointer

enum MPVFormat {
    static let none: Int32 = 0
    static let string: Int32 = 1
    static let int64: Int32 = 4
    static let double: Int32 = 5
}

enum MPVEventID {
    static let shutdown: Int32 = 1
    static let endFile: Int32 = 7
    static let fileLoaded: Int32 = 8
    static let propertyChange: Int32 = 22
}

/// Mirrors `mpv_event` from client.h.
struct MPVEvent {
    var eventID: Int32
    var error: Int32
    var replyUserdata: UInt64
    var data: UnsafeMutableRawPointer?
}

/// Mirrors `mpv_event_property` from client.h.
struct MPVEventProperty {
    var name: UnsafePointer<CChar>?
    var format: Int32
    var data: UnsafeMutableRawPointer?
}

/// Mirrors `mpv_render_param` from render.h.
struct MPVRenderParam {
    var type: Int32
    var data: UnsafeMutableRawPointer?
}

enum MPVRenderParamType {
    static let invalid: Int32 = 0
    static let apiType: Int32 = 1
    static let openGLInitParams: Int32 = 2
    static let openGLFBO: Int32 = 3
    static let openGLFlipY: Int32 = 4
}

typealias MPVGetProcAddressFn = @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?

/// Mirrors `mpv_opengl_init_params` from render.h.
struct MPVOpenGLInitParams {
    var getProcAddress: MPVGetProcAddressFn?
    var getProcAddressCtx: UnsafeMutableRawPointer?
}

/// Mirrors `mpv_opengl_fbo` from render.h.
struct MPVOpenGLFBO {
    var fbo: Int32
    var width: Int32
    var height: Int32
    var internalFormat: Int32
}

typealias MPVRenderUpdateFn = @convention(c) (UnsafeMutableRawPointer?) -> Void

/// Minimal dlopen-based binding to `libmpv`, so the app links and starts even
/// when mpv is not installed. All calls must go through `MPVLibrary`.
final class MPVLibrary: @unchecked Sendable {
    typealias CreateFn = @convention(c) () -> MPVHandle?
    typealias InitializeFn = @convention(c) (MPVHandle) -> Int32
    typealias TerminateDestroyFn = @convention(c) (MPVHandle) -> Void
    typealias SetOptionStringFn = @convention(c) (MPVHandle, UnsafePointer<CChar>, UnsafePointer<CChar>) -> Int32
    typealias SetOptionFn = @convention(c) (MPVHandle, UnsafePointer<CChar>, Int32, UnsafeMutableRawPointer) -> Int32
    typealias CommandStringFn = @convention(c) (MPVHandle, UnsafePointer<CChar>) -> Int32
    typealias SetPropertyStringFn = @convention(c) (MPVHandle, UnsafePointer<CChar>, UnsafePointer<CChar>) -> Int32
    typealias ObservePropertyFn = @convention(c) (MPVHandle, UInt64, UnsafePointer<CChar>, Int32) -> Int32
    typealias WaitEventFn = @convention(c) (MPVHandle, Double) -> UnsafeMutableRawPointer?
    typealias ErrorStringFn = @convention(c) (Int32) -> UnsafePointer<CChar>?
    typealias RenderContextCreateFn = @convention(c) (UnsafeMutableRawPointer?, MPVHandle, UnsafeMutableRawPointer?) -> Int32
    typealias RenderContextFreeFn = @convention(c) (OpaquePointer?) -> Void
    typealias RenderContextSetUpdateCallbackFn = @convention(c) (OpaquePointer?, MPVRenderUpdateFn?, UnsafeMutableRawPointer?) -> Void
    typealias RenderContextRenderFn = @convention(c) (OpaquePointer?, UnsafeMutableRawPointer?) -> Int32

    private let dlHandle: UnsafeMutableRawPointer
    private let createFn: CreateFn
    private let initializeFn: InitializeFn
    private let terminateDestroyFn: TerminateDestroyFn
    private let setOptionStringFn: SetOptionStringFn
    private let setOptionFn: SetOptionFn
    private let commandStringFn: CommandStringFn
    private let setPropertyStringFn: SetPropertyStringFn
    private let observePropertyFn: ObservePropertyFn
    private let waitEventFn: WaitEventFn
    private let errorStringFn: ErrorStringFn
    private let renderContextCreateFn: RenderContextCreateFn
    private let renderContextFreeFn: RenderContextFreeFn
    private let renderContextSetUpdateCallbackFn: RenderContextSetUpdateCallbackFn
    private let renderContextRenderFn: RenderContextRenderFn

    init?(path: String) {
        guard let dlHandle = dlopen(path, RTLD_NOW | RTLD_LOCAL) else { return nil }

        func load<T>(_ name: String, as _: T.Type) -> T? {
            guard let symbol = dlsym(dlHandle, name) else { return nil }
            return unsafeBitCast(symbol, to: T.self)
        }

        guard let create = load("mpv_create", as: CreateFn.self),
              let initialize = load("mpv_initialize", as: InitializeFn.self),
              let terminateDestroy = load("mpv_terminate_destroy", as: TerminateDestroyFn.self),
              let setOptionString = load("mpv_set_option_string", as: SetOptionStringFn.self),
              let setOption = load("mpv_set_option", as: SetOptionFn.self),
              let commandString = load("mpv_command_string", as: CommandStringFn.self),
              let setPropertyString = load("mpv_set_property_string", as: SetPropertyStringFn.self),
              let observeProperty = load("mpv_observe_property", as: ObservePropertyFn.self),
              let waitEvent = load("mpv_wait_event", as: WaitEventFn.self),
              let errorString = load("mpv_error_string", as: ErrorStringFn.self),
              let renderContextCreate = load("mpv_render_context_create", as: RenderContextCreateFn.self),
              let renderContextFree = load("mpv_render_context_free", as: RenderContextFreeFn.self),
              let renderContextSetUpdateCallback = load("mpv_render_context_set_update_callback", as: RenderContextSetUpdateCallbackFn.self),
              let renderContextRender = load("mpv_render_context_render", as: RenderContextRenderFn.self)
        else {
            dlclose(dlHandle)
            return nil
        }

        self.dlHandle = dlHandle
        createFn = create
        initializeFn = initialize
        terminateDestroyFn = terminateDestroy
        setOptionStringFn = setOptionString
        setOptionFn = setOption
        commandStringFn = commandString
        setPropertyStringFn = setPropertyString
        observePropertyFn = observeProperty
        waitEventFn = waitEvent
        errorStringFn = errorString
        renderContextCreateFn = renderContextCreate
        renderContextFreeFn = renderContextFree
        renderContextSetUpdateCallbackFn = renderContextSetUpdateCallback
        renderContextRenderFn = renderContextRender
    }

    deinit {
        dlclose(dlHandle)
    }

    static func locate(dependencies: Dependencies = DependencyLocator.locate()) -> MPVLibrary? {
        guard let path = dependencies.libmpvPath else { return nil }
        return MPVLibrary(path: path)
    }

    func create() -> MPVHandle? {
        createFn()
    }

    func initialize(_ context: MPVHandle) -> Int32 {
        initializeFn(context)
    }

    func terminateDestroy(_ context: MPVHandle) {
        terminateDestroyFn(context)
    }

    func setOptionString(_ context: MPVHandle, _ name: String, _ value: String) -> Int32 {
        name.withCString { namePointer in
            value.withCString { valuePointer in
                setOptionStringFn(context, namePointer, valuePointer)
            }
        }
    }

    func setOption(_ context: MPVHandle, _ name: String, format: Int32, data: UnsafeMutableRawPointer) -> Int32 {
        name.withCString { namePointer in
            setOptionFn(context, namePointer, format, data)
        }
    }

    func setPropertyString(_ context: MPVHandle, _ name: String, _ value: String) -> Int32 {
        name.withCString { namePointer in
            value.withCString { valuePointer in
                setPropertyStringFn(context, namePointer, valuePointer)
            }
        }
    }

    @discardableResult
    func commandString(_ context: MPVHandle, _ command: String) -> Int32 {
        command.withCString { commandStringFn(context, $0) }
    }

    func observeProperty(_ context: MPVHandle, replyUserdata: UInt64, _ name: String, format: Int32) {
        name.withCString { _ = observePropertyFn(context, replyUserdata, $0, format) }
    }

    func waitEvent(_ context: MPVHandle, timeout: Double) -> MPVEvent? {
        guard let raw = waitEventFn(context, timeout) else { return nil }
        return raw.assumingMemoryBound(to: MPVEvent.self).pointee
    }

    func errorString(_ code: Int32) -> String {
        guard let message = errorStringFn(code) else { return "mpv error \(code)" }
        return String(cString: message)
    }

    /// `params` must point to an array of `MPVRenderParam` terminated by an
    /// entry with type `MPVRenderParamType.invalid`.
    func renderContextCreate(_ out: UnsafeMutableRawPointer?, handle: MPVHandle, params: UnsafeMutableRawPointer) -> Int32 {
        renderContextCreateFn(out, handle, params)
    }

    func renderContextFree(_ context: OpaquePointer) {
        renderContextFreeFn(context)
    }

    func renderContextSetUpdateCallback(
        _ context: OpaquePointer,
        callback: MPVRenderUpdateFn?,
        userdata: UnsafeMutableRawPointer?
    ) {
        renderContextSetUpdateCallbackFn(context, callback, userdata)
    }

    func renderContextRender(_ context: OpaquePointer, params: UnsafeMutableRawPointer) -> Int32 {
        renderContextRenderFn(context, params)
    }
}
