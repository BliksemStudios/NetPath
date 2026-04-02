import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(filter: #Predicate<PathEntry> { $0.isPinned }, sort: \PathEntry.uncPath) private var pinnedPaths: [PathEntry]
    @Query(filter: #Predicate<PathEntry> { !$0.isPinned }, sort: \PathEntry.lastVisited, order: .reverse) private var recentPaths: [PathEntry]
    @Query(filter: #Predicate<MountSession> { $0.isActive }) private var activeMounts: [MountSession]

    var onNavigate: ((String) -> Void)?

    var body: some View {
        List {
            Section {
                ForEach(pinnedPaths) { entry in
                    sidebarRow(icon: "star.fill", iconColor: Design.Colors.accent, label: shortLabel(entry.uncPath), fullPath: entry.uncPath)
                }
            } header: { Text("Pinned").font(Design.Fonts.sectionHeader).textCase(.uppercase).tracking(0.5) }

            Section {
                ForEach(recentPaths.prefix(10)) { entry in
                    sidebarRow(icon: "clock.arrow.circlepath", iconColor: .secondary, label: shortLabel(entry.uncPath), fullPath: entry.uncPath)
                }
            } header: { Text("Recent").font(Design.Fonts.sectionHeader).textCase(.uppercase).tracking(0.5) }

            Section {
                ForEach(activeMounts) { session in
                    HStack(spacing: 8) {
                        Circle().fill(Design.Colors.connectedGreen).frame(width: 6, height: 6)
                        Text("\(session.server)/\(session.sharePath)").font(.system(size: 13)).lineLimit(1)
                    }
                }
            } header: { Text("Mounted").font(Design.Fonts.sectionHeader).textCase(.uppercase).tracking(0.5) }
        }
        .listStyle(.sidebar)
        .frame(minWidth: Design.Browser.sidebarWidth)
    }

    private func sidebarRow(icon: String, iconColor: Color, label: String, fullPath: String) -> some View {
        Button(action: { onNavigate?(fullPath) }) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(iconColor).font(.system(size: 13))
                Text(label).font(.system(size: 13)).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .help(fullPath)
    }

    private func shortLabel(_ uncPath: String) -> String {
        let parts = uncPath.replacingOccurrences(of: "\\\\", with: "").split(separator: "\\")
        if parts.count <= 2 { return parts.joined(separator: "\\") }
        return parts.suffix(2).joined(separator: "\\")
    }
}
