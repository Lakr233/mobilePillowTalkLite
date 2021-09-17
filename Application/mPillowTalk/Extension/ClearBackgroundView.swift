//
//  ClearBackgroundView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/3.
//

import SwiftUI

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context _: Context) -> some UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}

struct ClearBackgroundViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ClearBackgroundView())
    }
}

extension View {
    func clearModalBackground() -> some View {
        modifier(ClearBackgroundViewModifier())
    }
}
