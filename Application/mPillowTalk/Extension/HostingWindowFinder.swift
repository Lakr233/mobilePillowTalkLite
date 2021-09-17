//
//  HostingWindowFinder.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/28/21.
//
import SwiftUI

#if canImport(UIKit)
    typealias Window = UIWindow
#elseif canImport(AppKit)
    typealias Window = NSWindow
#else
    #error("Unsupported platform")
#endif

class WindowObserver: ObservableObject {
    weak var window: Window?
}

#if canImport(UIKit)
    struct HostingWindowFinder: UIViewRepresentable {
        var callback: (Window?) -> Void

        func makeUIView(context _: Context) -> UIView {
            let view = UIView()
            DispatchQueue.main.async { [weak view] in
                self.callback(view?.window)
            }
            return view
        }

        func updateUIView(_: UIView, context _: Context) {}
    }

#elseif canImport(AppKit)
    struct HostingWindowFinder: NSViewRepresentable {
        var callback: (Window?) -> Void

        func makeNSView(context _: Self.Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async { [weak view] in
                self.callback(view?.window)
            }
            return view
        }

        func updateNSView(_: NSView, context _: Context) {}
    }
#else
    #error("Unsupported platform")
#endif
