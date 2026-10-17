import SwiftUI

@main
struct KursanzeigeApp: App {
    /// One model for the full app life. See `AppModel`.
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            MainView(appModel: appModel)
        }
    }
}
