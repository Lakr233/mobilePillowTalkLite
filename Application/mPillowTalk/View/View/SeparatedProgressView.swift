//
//  SeparatedProgressView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/20/21.
//

import SwiftUI

struct SeparatedProgressView: View {
    let height: Float
    let backgroundColor: Color
    let rounded: Bool

    let progressElements: [(Color, Float)]
    let emptyHolder: Float

    var totalProgress: Float { progressElements.map(\.1).reduce(0, +) }

    var body: some View {
        ZStack {
            backgroundColor
            GeometryReader { reader in
                HStack(spacing: 0) {
                    ForEach(0 ..< progressElements.count, id: \.self) { idx in
                        progressElements[idx].0
                            .frame(width: reader.size.width * CGFloat(progressElements[idx].1 / (totalProgress + emptyHolder)))
                    }
                    Rectangle()
                        .opacity(0)
                        .frame(minWidth: 0, minHeight: 0)
                }
            }
        }
        .frame(height: CGFloat(height))
        .cornerRadius(rounded ? CGFloat(height) / 2 : 0)
    }
}

struct SeparatedProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SeparatedProgressView(
                height: 8,
                backgroundColor: .systemGray,
                rounded: true,
                progressElements:
                [
                    (.red, 10),
                    (.blue, 50),
                    (.yellow, 30),
                    (.purple, 50),
                ],
                emptyHolder: 80
            )
            SeparatedProgressView(
                height: 50,
                backgroundColor: .systemGray,
                rounded: false,
                progressElements:
                [
                    (.red, 10),
                    (.blue, 50),
                    (.yellow, 30),
                    (.purple, 50),
                ],
                emptyHolder: 80
            )
        }
        .padding()
        .previewLayout(.fixed(width: 500, height: 100))
    }
}
