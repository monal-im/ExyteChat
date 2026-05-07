//
//  Created by lissine on 05.05.2026.
//

import SwiftUI
import QuickLook

public struct FileView: View {
    let file: File
    let isCurrentUser: Bool
    let checkSizeClosure: ((File) -> Void)?
    let downloadClosure: ((File) -> Void)?

    public var body: some View {
        if file.downloadState == .none {
            CheckFileSizeView(file: file, isCurrentUser: isCurrentUser, checkSizeClosure: checkSizeClosure)
        } else if file.downloadState == .headers {
            DownloadFileView(file: file, isCurrentUser: isCurrentUser, downloadClosure: downloadClosure)
        } else {
            OpenFileView(file: file, isCurrentUser: isCurrentUser)
        }
    }
}

public struct CheckFileSizeView: View {
    @State private var isChecking = false
    let file: File
    let isCurrentUser: Bool
    let checkSizeClosure: ((File) -> Void)?
    public var body: some View {
        VStack(alignment: .center) {
            FileDescriptionView(file: file)
            if !isChecking {
                Button(action: {
                    isChecking = true
                    checkSizeClosure?(file)
                }) {
                    Text("Check File Size")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
                .tint(isCurrentUser ? .white : .gray)
            } else {
                HStack {
                    Text("Checking the size")
                        .font(.callout)
                    ProgressView()
                }
            }
        }
        .onAppear {
            // If the size check had already happened,
            // the "Download File" view would've been displayed instead
            isChecking = file.isBeingDownloaded
        }
    }
}

public struct DownloadFileView: View {
    @State private var isDownloading = false
    let file: File
    let isCurrentUser: Bool
    let downloadClosure: ((File) -> Void)?

    public var body: some View {
        VStack(alignment: .center) {
            FileDescriptionView(file: file)
            if !isDownloading {
                Button(action: {
                    isDownloading = true
                    downloadClosure?(file)
                }) {
                    Text("Download File")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
                .tint(isCurrentUser ? .white : .gray)
            } else {
                HStack {
                    Text("Downloading")
                        .font(.callout)
                    ProgressView()
                }
            }
        }
        .onAppear {
            isDownloading = file.isBeingDownloaded
        }
    }
}

public struct OpenFileView: View {
    @State private var previewURL: URL?
    @State private var oldPreviewURL: URL?
    let file: File
    let isCurrentUser: Bool
    public var body: some View {
        VStack(alignment: .center) {
            FileDescriptionView(file: file)
            Button(action: openFile) {
                Text("Open File")
                    .font(.callout)
            }
            .buttonStyle(.bordered)
            .tint(isCurrentUser ? .white : .gray)
            .quickLookPreview($previewURL)
            .onChange(of: previewURL) { newValue in
                //TODO: use the new .onChange instead of this workaround once the minimum version is iOS 17.0
                let oldValue = oldPreviewURL
                oldPreviewURL = newValue

                if newValue == nil {
                    // Delete the temporary file
                    try? FileManager.default.removeItem(at: oldValue!)
                }
            }
        }
    }

    func openFile() {
        // Copy the file to a temporary location, in order to have
        // the file extension (and name) on the copy.
        // This allows QuickLook to preview it correctly
        // (the downloaded files in Monal have a hash as their name and extension)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.name)

        try? FileManager.default.removeItem(at: tempURL)
        do {
            try FileManager.default.copyItem(at: file.localURL!, to: tempURL)
            previewURL = tempURL
        } catch {
            print("Copy failed: \(error)")
        }
    }
}

struct FileDescriptionView : View {
    let file: File
    var body: some View {
        HStack {
            FileThumbnailView(fileName: file.name)
            VStack(alignment: .leading) {
                Text(file.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    // Reserve vertical space for two lines
                    .fixedSize(horizontal: false, vertical: true)
                if file.size != nil {
                    let humanReadableSize = file.size!.formatted(.byteCount(style: .file))
                    Text(humanReadableSize)
                }
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// This view displays an icon based on the file extension.
// That way we can always display an icon, regardless of the download state.
struct FileThumbnailView: View {
    // We have to create an empty file with the desired file extension, because the QuickLook
    // framework only supports generating thumbnails / icons from file URLs.
    @State private var dummyFileURL: URL?
    @State private var thumbnail: Image?
    let fileName: String
    let size: CGSize = CGSize(width: 50, height: 50)

    var fileExtension: String {
        return (fileName as NSString).pathExtension.lowercased()
    }

    var body: some View {
        if let thumbnail = thumbnail {
            thumbnail
                .resizable()
                .frame(width: size.width, height: size.height)
        } else {
            Image(systemName: "doc")
                .onAppear {
                    generateThumbnail()
                }
        }
    }

    func generateThumbnail() {
        dummyFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("emptyFile")
            .appendingPathExtension(fileExtension)
        guard let dummyFileURL else {
            return
        }
        if !FileManager.default.fileExists(atPath: dummyFileURL.path) {
            FileManager.default.createFile(atPath: dummyFileURL.path, contents: Data())
        }
        let request = QLThumbnailGenerator.Request(
            fileAt: dummyFileURL,
            size: size,
            scale: UIScreen.main.scale,
            representationTypes: .icon
        )

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
            if let uiImage = thumbnail?.uiImage {
                DispatchQueue.main.async {
                    self.thumbnail = Image(uiImage: uiImage)
                    // No need to delete the dummy file
                    //try? FileManager.default.removeItem(at: dummyFileURL)
                }
            }
        }
    }
}
