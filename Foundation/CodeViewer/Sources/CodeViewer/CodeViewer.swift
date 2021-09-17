import SwiftUI
import WebKit

#if os(OSX)
    import AppKit
    public typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
    import UIKit
    public typealias ViewRepresentable = UIViewRepresentable
#endif


public struct CodeViewer: ViewRepresentable {
    
    @Binding var content: String
    @Environment(\.colorScheme) var colorScheme
    var textDidChanged: ((String) -> Void)?
    
    private let mode: CodeWebView.Mode
    private let darkTheme: CodeWebView.Theme
    private let lightTheme: CodeWebView.Theme
    private let isReadOnly: Bool
    private let fontSize: Int
    
    public init(
        content: Binding<String>,
        mode: CodeWebView.Mode = .json,
        darkTheme: CodeWebView.Theme = .solarized_dark,
        lightTheme: CodeWebView.Theme = .solarized_light,
        isReadOnly: Bool = false,
        fontSize: Int = 12,
        textDidChanged: ((String) -> Void)? = nil
    ) {
        self._content = content
        self.mode = mode
        self.darkTheme = darkTheme
        self.lightTheme = lightTheme
        self.isReadOnly = isReadOnly
        self.fontSize = fontSize
        self.textDidChanged = textDidChanged
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(content: $content, colorScheme: colorScheme)
    }
    
    private func getWebView(context: Context) -> CodeWebView {
        let codeView = CodeWebView()
        
        codeView.setReadOnly(isReadOnly)
        codeView.setMode(mode)
        codeView.setFontSize(fontSize)
        
        codeView.setContent(content)
        codeView.clearSelection()
        
        codeView.textDidChanged = { text in
            context.coordinator.set(content: text)
            self.textDidChanged?(text)
        }
        
        colorScheme == .dark ? codeView.setTheme(darkTheme) : codeView.setTheme(lightTheme)

        return codeView
    }
    
    private func updateView(_ webview: CodeWebView, context: Context) {
        if context.coordinator.colorScheme != colorScheme {
            colorScheme == .dark ? webview.setTheme(darkTheme) : webview.setTheme(lightTheme)
            context.coordinator.set(colorScheme: colorScheme)
        }
    }
    
    // MARK: macOS
    public func makeNSView(context: Context) -> CodeWebView {
        getWebView(context: context)
    }
    
    public func updateNSView(_ webview: CodeWebView, context: Context) {
        updateView(webview, context: context)
    }
    
    // MARK: iOS
    public func makeUIView(context: Context) -> CodeWebView {
        getWebView(context: context)
    }
    
    public func updateUIView(_ webview: CodeWebView, context: Context) {
        updateView(webview, context: context)
    }
}

public extension CodeViewer {
    class Coordinator: NSObject {
        @Binding private(set) var content: String
        private(set) var colorScheme: ColorScheme
        
        init(content: Binding<String>, colorScheme: ColorScheme) {
            _content = content
            self.colorScheme = colorScheme
        }
        
        func set(content: String) {
            if self.content != content {
                self.content = content
            }
        }
        
        func set(colorScheme: ColorScheme) {
            if self.colorScheme != colorScheme {
                self.colorScheme = colorScheme
            }
        }
    }
}

#if DEBUG
struct CodeViewer_Previews : PreviewProvider {
    static private var jsonString = """
    {
        "hello": "world"
    }
    """
    static var previews: some View {
        CodeViewer(content: .constant(jsonString))
    }
}
#endif
