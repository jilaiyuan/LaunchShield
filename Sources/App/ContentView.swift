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
                    Text("Unlock password: users must enter this to open blacklisted apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("Enter unlock password", text: $viewModel.password)
                    SecureField("Confirm unlock password", text: $viewModel.confirmPassword)

                    HStack(spacing: 10) {
                        Button(viewModel.hasPassword ? "Admin Reset Unlock Password" : "Create Unlock Password") {
                            if viewModel.hasPassword {
                                viewModel.resetPasswordUsingAdminMode()
                            } else {
                                viewModel.createPassword()
                            }
                        }

                        Text(viewModel.hasPassword ? "Unlock password is set" : "Unlock password is not set")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.passwordStatusMessage.isEmpty {
                        Text(viewModel.passwordStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Blacklist (auto-saved when toggled)") {
                VStack(spacing: 8) {
                    Text("Checked = added to blacklist, unchecked = removed. Changes are saved automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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

                    if !viewModel.blacklistStatusMessage.isEmpty {
                        Text(viewModel.blacklistStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Blocking Schedule (applies to blacklisted apps)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Block is active only during enabled day/time windows. Unconfigured days are not blocked.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Weekday.allCases) { day in
                        HStack(spacing: 10) {
                            Toggle(day.title, isOn: Binding(
                                get: { viewModel.isScheduled(day) },
                                set: { viewModel.setScheduled($0, for: day) }
                            ))
                            .frame(width: 180, alignment: .leading)

                            DatePicker(
                                "Start",
                                selection: Binding(
                                    get: { viewModel.startDate(for: day) },
                                    set: { viewModel.setStartDate($0, for: day) }
                                ),
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                            .disabled(!viewModel.isScheduled(day))

                            Text("to")
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "End",
                                selection: Binding(
                                    get: { viewModel.endDate(for: day) },
                                    set: { viewModel.setEndDate($0, for: day) }
                                ),
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                            .disabled(!viewModel.isScheduled(day))
                        }
                    }

                    if !viewModel.scheduleStatusMessage.isEmpty {
                        Text(viewModel.scheduleStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Admin Uninstall") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use this to generate a full uninstall command for administrators.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Debug Mode", isOn: Binding(
                        get: { viewModel.isDebugMode },
                        set: { viewModel.setDebugMode($0) }
                    ))

                    HStack(spacing: 10) {
                        Button("Generate Admin Uninstall Command") {
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

                    if viewModel.isDebugMode && !viewModel.uninstallHint.isEmpty {
                        Text(viewModel.uninstallHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.isDebugMode && !viewModel.uninstallDebugLogPath.isEmpty {
                        Text("Debug log file:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.uninstallDebugLogPath)
                            .textSelection(.enabled)
                            .font(.system(.caption, design: .monospaced))
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
