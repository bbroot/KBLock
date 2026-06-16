import KBLockKit
import SwiftUI

/// KBLock 设置窗口：macOS 系统设置风格侧边栏
///
/// 用 NavigationSplitView + List 替代原来的 TabView，
/// 视觉上彻底脱离 LockIME 布局，消除抄袭风险。
///
/// tab.label / group / section header 均使用与 xcstrings key 一致的
/// 英文字符串，在渲染时通过 `state.loc()` 获取本地化文本。
enum SettingsTab: Hashable {
    case general, appRules, suggestions,
         shortcuts, permissions, updates, log, backup

    /// 所在分组标题的本地化 key（nil 表示不归组）
    var groupKey: String? {
        switch self {
        case .general:            return nil
        case .appRules:            return "Rules"
        case .suggestions:        return "Intelligence"
        case .shortcuts, .permissions: return "System"
        case .updates, .log, .backup:   return nil
        }
    }

    /// 用于 `state.loc()` 查表的 key（同时也是英文 fallback）
    var labelKey: String {
        switch self {
        case .general:    return "General"
        case .appRules:   return "App Rules"
        case .suggestions:return "Suggestions"
        case .shortcuts:  return "Shortcuts"
        case .permissions:return "Permissions"
        case .updates:    return "Updates"
        case .log:        return "Log"
        case .backup:     return "Backup & Sync"
        }
    }

    var icon: String {
        switch self {
        case .general:    return "gearshape"
        case .appRules:   return "macwindow.on.rectangle"
        case .suggestions:return "lightbulb"
        case .shortcuts:  return "command"
        case .permissions:return "hand.raised"
        case .updates:    return "arrow.down.circle"
        case .log:        return "list.bullet.rectangle"
        case .backup:     return "arrow.up.arrow.down.square"
        }
    }
}

struct SettingsRootView: View {
    @Environment(AppState.self) private var state

    /// 侧边栏所有条目（按分组排序）
    private static let allTabs: [SettingsTab] = [
        .general,
        .appRules,
        .suggestions,
        .shortcuts, .permissions,
        .updates, .log, .backup,
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detailPane
                .frame(minWidth: 480)
        }
        .frame(minWidth: 700, minHeight: 460)
        .onDisappear { state.stopAccessibilityWatch() }
    }

    // MARK: - 侧边栏

    private var sidebar: some View {
        List(selection: Binding(
            get: { state.settingsTab },
            set: { state.settingsTab = $0 }
        )) {
            // 无分组的（General）
            Section {
                sidebarRow(.general)
            } header: {
                Text(verbatim: state.loc("Preferences"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            // Rules 分组
            Section {
                sidebarRow(.appRules)
            } header: {
                Text(verbatim: state.loc("Rules"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            // Intelligence 分组
            Section {
                sidebarRow(.suggestions)
            } header: {
                Text(verbatim: state.loc("Intelligence"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            // System 分组
            Section {
                sidebarRow(.shortcuts)
                sidebarRow(.permissions)
            } header: {
                Text(verbatim: state.loc("System"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            // 底部：服务类
            Section {
                if state.updateController.pendingUpdateVersion != nil {
                    sidebarRow(.updates)
                        .badge(1)
                } else {
                    sidebarRow(.updates)
                }
                sidebarRow(.log)
                sidebarRow(.backup)
            } header: {
                Text(verbatim: state.loc("Service"))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .toolbar(removing: .sidebarToggle) // 不允许隐藏侧边栏
    }

    private func sidebarRow(_ tab: SettingsTab) -> some View {
        Label(state.loc(tab.labelKey), systemImage: tab.icon)
            .tag(tab)
            .font(.body)
    }

    // MARK: - 详情面板

    @ViewBuilder
    private var detailPane: some View {
        switch state.settingsTab {
        case .general:     GeneralSettingsPane()
        case .appRules:    AppRulesSettingsPane()
        case .suggestions: SuggestionsSettingsPane()
        case .shortcuts:   ShortcutsSettingsPane()
        case .permissions: PermissionsSettingsPane()
        case .updates:     UpdatesSettingsPane()
        case .log:         ActivationLogPane()
        case .backup:      BackupSettingsPane()
        }
    }
}
