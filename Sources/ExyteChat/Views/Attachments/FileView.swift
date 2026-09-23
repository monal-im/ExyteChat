//
//  Created by lissine on 05.05.2026.
//

import SwiftUI
import QuickLook
import System

public struct FileView: View {
    @Environment(\.chatLocalization) var localization
    @State private var isChecking = false
    @State private var isDownloading = false
    @State private var previewURL: URL?
    let file: File
    let checkSizeClosure: ((File) -> Void)?
    let downloadClosure: ((File) -> Void)?

    var humanReadableSize: String {
        if file.size != nil {
            return file.size!.formatted(.byteCount(style: .file))
        }
        return localization.unknownSize
    }

    var imageName: String {
        switch(file.downloadState) {
            case .none:
                return "info"
            case .headers:
                return "arrow.down"
            case .complete:
                return "document"
        }
    }

    // We don't have access to Monal's constants or preprocessor symbols
    // So we deduce the appGroupID from the bundle identifier instead
    var appGroupID: String {
        let bundleID = Bundle.main.bundleIdentifier
        if bundleID == "monal.alpha" {
            return "group.monalalpha"
        }
        return "group.monal"
    }

    func buttonAction() {
        switch(file.downloadState) {
            case .none:
                checkSizeClosure?(file)
                isChecking = true
            case .headers:
                downloadClosure?(file)
                isDownloading = true
            case .complete:
                openFile()
        }
    }

    // Creates a temporary hardlink, in order to have the file extension (and name) on the hardlink.
    // This allows QuickLook to preview it correctly
    // (the downloaded files in Monal have a hash as their name and extension)
    func openFile() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            fatalError("Could not access the app group container. If you added a new appGroupID, make sure to include it in this file (FileView.swift in the ExyteChat fork)")
        }

        // By storing the temporary hardlinks in the group container under "documentCache", in a directory
        // whose name starts with "tmp.", Monal will clean up any files that don't get deleted (e.g. if the
        // app gets force-closed while a preview is open, the hardlink doesn't get deleted, and Monal will
        // have to clean it up)
        let documentCacheDirectoryURL = containerURL.appendingPathComponent("documentCache")
            .appendingPathComponent("tmp.filePreviews")

        try? FileManager.default.createDirectory(
            at: documentCacheDirectoryURL,
            withIntermediateDirectories: true
        )

        guard let basePath = FilePath(documentCacheDirectoryURL) else { return }
        let sanitizedFilename = file.name.sanitizedFilename()
        guard let safePath = basePath.lexicallyResolving(FilePath(sanitizedFilename)),
            safePath != basePath else {
            // traversal attempt
            return
        }
        let tempURL = URL(fileURLWithPath: safePath.string)

        try? FileManager.default.removeItem(at: tempURL)
        do {
            try FileManager.default.linkItem(at: file.localURL!, to: tempURL)
            previewURL = tempURL
        } catch {
            print("Hardlinking failed: \(error)")
        }
    }

    public var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                Image(systemName: imageName)
                    .foregroundStyle(Color(.secondarySystemBackground))
                if file.downloadState == .none && isChecking || file.downloadState == .headers && isDownloading {
                    CircularProgress(size: 35, color: Color(.secondarySystemBackground))
                }
            }
            .frame(width: 40)

            VStack(alignment: .leading) {
                Text(file.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    // Reserve vertical space for two lines
                    .fixedSize(horizontal: false, vertical: true)
                Text(humanReadableSize)
                    .font(.caption2)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture(perform: buttonAction)
        .onAppear {
            // file.isBeingDownloaded is true both when checking and when downloading
            isChecking = file.isBeingDownloaded
            isDownloading = file.isBeingDownloaded
        }
        .quickLookPreview($previewURL)
        .onChange(of: previewURL) { oldValue, newValue in
            if newValue == nil {
                // Delete the hardlink
                try? FileManager.default.removeItem(at: oldValue!)
            }
        }
    }
}
