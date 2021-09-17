//
//  SwiftUIView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/29.
//

import SwiftTerm
import SwiftUI

struct TerminalViewWrapper: UIViewRepresentable {
    let terminalView = TerminalView()

    func makeUIView(context _: Context) -> TerminalView {
        terminalView.backgroundColor = .clear
        terminalView.isOpaque = true
        terminalView.backgroundColor = UIColor.clear
        terminalView.nativeBackgroundColor = UIColor.clear
        terminalView.nativeForegroundColor = UIColor(named: "AccentColor")!
        return terminalView
    }

    func updateUIView(_: TerminalView, context _: Context) {}

    func feed(text: String) {
        DispatchQueue.main.async {
            terminalView.feed(text: text)
        }
    }
}
