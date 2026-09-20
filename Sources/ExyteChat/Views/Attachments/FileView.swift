//
//  Created by lissine on 05.05.2026.
//

import SwiftUI
import QuickLook

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

    func openFile() {
        // Create a temporary hardlink, in order to have
        // the file extension (and name) on the hardlink.
        // This allows QuickLook to preview it correctly
        // (the downloaded files in Monal have a hash as their name and extension)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.name)

        try? FileManager.default.removeItem(at: tempURL)
        do {
            // macOS can't preview hardlinks, but iOS can
#if targetEnvironment(macCatalyst)
            try FileManager.default.copyItem(at: file.localURL!, to: tempURL)
#else
            try FileManager.default.linkItem(at: file.localURL!, to: tempURL)
#endif
            previewURL = tempURL
        } catch {
            print("Hardlinking / copying failed: \(error)")
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
