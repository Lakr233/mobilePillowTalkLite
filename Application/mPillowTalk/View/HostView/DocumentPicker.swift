//
//  DocumentPicker.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/4.
//

import PTFoundation
import SwiftUI
import UIKit

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContent: String
    let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(fileContent: $fileContent)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var fileContent: String

    init(fileContent: Binding<String>) {
        _fileContent = fileContent
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let file = urls.first {
            do {
                fileContent = try String(contentsOf: file, encoding: .utf8)
            } catch {
                PTLog.shared.join(self,
                                  "failed to open file on \(file.path) with reason: \(error.localizedDescription)",
                                  level: .error)
                let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("DONE", comment: "Done"), style: .default, handler: nil))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    let vc: UIViewController? = UIApplication.shared.windows.first?.topMostViewController
                    vc?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
