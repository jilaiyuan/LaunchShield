import Core
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var searchText: String = ""

    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return viewModel.installedApps
        }
        return viewModel.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LaunchShield")
                .font(.title2)
                .bold()

            GroupBox("Password") {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("New password", text: $viewModel.password)
                    SecureField("Confirm password", text: $viewModel.confirmPassword)

                    HStack(spacing: 10) {
                        Button(viewModel.hasPassword ? "Reset (Admin Mode)" : "Create Password") {
                            if viewModel.hasPassword {
                                viewModel.resetPasswordUsingAdminMode()
                            } else {
                                viewModel.createPassword()
                            }
                        }

                        Text(viewModel.hasPassword ? "Password configured" : "No password configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Blacklist (only these apps require password)") {
                VStack(spacing: 8) {
                    TextField("Search app name or bundle ID", text: $searchText)
                    List(filteredApps) { app in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                Text(app.id)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { viewModel.isBlacklisted(app) },
                                set: { viewModel.setBlacklisted($0, for: app) }
                            ))
                            .labelsHidden()
                        }
                    }
                    .frame(minHeight: 320)

                    HStack {
                        Button("Refresh App List") {
                            viewModel.refreshApplications()
                        }
                        Spacer()
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Protection & Uninstall") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.protectionStateSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("Refresh Protection State") {
                            viewModel.refreshProtectionState()
                        }
                        Button("Prepare Admin Full Uninstall") {
                            viewModel.prepareAdminUninstallCommand()
                        }
                    }

                    if !viewModel.uninstallCommand.isEmpty {
                        Text("Run in Terminal:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.uninstallCommand)
                            .textSelection(.enabled)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding(.top, 4)
            }

            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 640)
    }
}
