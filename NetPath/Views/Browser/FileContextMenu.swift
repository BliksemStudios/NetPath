import SwiftUI

struct FileContextMenu: View {
    let item: FileItem
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        // Open
        Button {
            if item.isDirectory { viewModel.navigateIntoFolder(item) }
            else { viewModel.openFile(item) }
        } label: {
            Label(item.isDirectory ? "Open" : "Open", systemImage: item.isDirectory ? "folder" : "doc")
        }

        if !item.isDirectory {
            Button {
                viewModel.openWith(item)
            } label: {
                Label("Open With...", systemImage: "arrow.up.forward.app")
            }
        }

        Divider()

        // Info
        Button {
            viewModel.getFileInfo(item)
        } label: {
            Label("Get Info", systemImage: "info.circle")
        }
        .keyboardShortcut("i", modifiers: .command)

        Divider()

        // Copy options
        Menu {
            Button {
                viewModel.copyUNCPath(item)
            } label: {
                Label("UNC Path", systemImage: "network")
            }

            Button {
                viewModel.copySMBURL(item)
            } label: {
                Label("SMB URL", systemImage: "link")
            }

            Button {
                viewModel.copyFileName(item)
            } label: {
                Label("File Name", systemImage: "textformat")
            }

            Button {
                viewModel.copyRelativePath(item)
            } label: {
                Label("Relative Path", systemImage: "arrow.right")
            }
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        Divider()

        // Finder integration
        Button {
            viewModel.revealInFinder(item)
        } label: {
            Label("Reveal in Finder", systemImage: "arrow.forward.to.line")
        }

        Divider()

        // Destructive
        Button(role: .destructive) {
            viewModel.moveToTrash(item)
        } label: {
            Label("Move to Trash", systemImage: "trash")
        }
    }
}

/// Context menu shown when right-clicking empty space in the browser
struct DirectoryContextMenu: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        Button {
            viewModel.newFolder()
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])

        Divider()

        Button {
            viewModel.refresh()
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: .command)

        Divider()

        Button {
            viewModel.copyCurrentDirectoryUNC()
        } label: {
            Label("Copy Folder Path", systemImage: "doc.on.doc")
        }

        Button {
            viewModel.revealInFinder(
                FileItem(id: "", name: "", path: URL(fileURLWithPath: "/"),
                         isDirectory: true, size: nil, dateModified: nil, contentType: nil)
            )
        } label: {
            Label("Open in Finder", systemImage: "arrow.forward.to.line")
        }
    }
}
