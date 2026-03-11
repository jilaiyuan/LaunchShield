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
                    Text("解锁密码：用户打开黑名单 App 时需要输入。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("输入解锁密码", text: $viewModel.password)
                    SecureField("确认解锁密码", text: $viewModel.confirmPassword)

                    HStack(spacing: 10) {
                        Button(viewModel.hasPassword ? "管理员重置解锁密码" : "创建解锁密码") {
                            if viewModel.hasPassword {
                                viewModel.resetPasswordUsingAdminMode()
                            } else {
                                viewModel.createPassword()
                            }
                        }

                        Text(viewModel.hasPassword ? "已设置解锁密码" : "尚未设置解锁密码")
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

            GroupBox("黑名单（勾选后自动加入）") {
                VStack(spacing: 8) {
                    Text("勾选即加入黑名单，取消即移除。保存是自动进行的。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("搜索 App 名称或 Bundle ID", text: $searchText)
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
                        Button("刷新应用列表") {
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

            GroupBox("管理员卸载") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("用于管理员彻底卸载 LaunchShield。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button("生成管理员卸载命令") {
                            viewModel.prepareAdminUninstallCommand()
                        }
                    }

                    if !viewModel.uninstallCommand.isEmpty {
                        Text("请在 Terminal 执行：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.uninstallCommand)
                            .textSelection(.enabled)
                            .font(.system(.body, design: .monospaced))
                    }

                    if !viewModel.uninstallHint.isEmpty {
                        Text(viewModel.uninstallHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
