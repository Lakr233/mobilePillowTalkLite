//
//  InputElementView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/4.
//

import SwiftUI

struct AddServerStepView<Content>: View where Content: View {
    let title: String
    let icon: String

    var content: Content

    @inlinable public init(title: String,
                           icon: String,
                           @ViewBuilder content: () -> Content)
    {
        self.title = title
        self.icon = icon
        self.content = content()
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 25)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(Color("AccentColor"))
            Divider()
            content
        }
    }
}
