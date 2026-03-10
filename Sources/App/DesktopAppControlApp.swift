import SwiftUI

@main
struct LaunchShieldApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.bootstrap()
                }
        }
    }
}
