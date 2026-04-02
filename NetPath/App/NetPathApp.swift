import SwiftUI
import SwiftData

@main
struct NetPathApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PathEntry.self, MountSession.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("NetPath Browser", id: "browser") {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(
            width: Design.Browser.minWindowWidth,
            height: Design.Browser.minWindowHeight
        )

        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }

    init() {
        DispatchQueue.main.async { [self] in
            appDelegate.modelContainer = sharedModelContainer
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 48))
                .foregroundStyle(Design.Colors.accent)

            Text("NetPath")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Press ⌘⇧\\ to open the launcher")
                .font(Design.Fonts.pathMono)
                .foregroundStyle(.secondary)

            Text("Or use the menu bar icon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
