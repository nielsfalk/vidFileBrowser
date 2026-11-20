import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model, model.trimCount > 0 else { return .terminateNow }

        switch QuitTrimPrompt.run(count: model.trimCount) {
        case .wait:
            model.waitForTrimsToFinish {
                NSApp.reply(toApplicationShouldTerminate: true)
            }
            return .terminateLater
        case .cancelTrims:
            model.cancelTrims()
            model.waitForTrimsToFinish {
                NSApp.reply(toApplicationShouldTerminate: true)
            }
            return .terminateLater
        case .stay:
            return .terminateCancel
        }
    }
}
