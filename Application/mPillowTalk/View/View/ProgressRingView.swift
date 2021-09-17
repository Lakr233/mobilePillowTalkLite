//
//  ProgressRingView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/30.
//

import SwiftUI

struct ProgressRingView: View {
    @Binding var progressPercent: CGFloat
    @Binding var colors: [Color]

    let size: CGFloat
    let strokeWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.05), style: StrokeStyle(lineWidth: strokeWidth))
                .frame(width: size * 0.9, height: size * 0.9)
            Circle()
                .trim(from: 1 - progressPercent, to: 1)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: colors),
                                   startPoint: .topTrailing,
                                   endPoint: .bottomLeading),
                    style: StrokeStyle(lineWidth: strokeWidth,
                                       lineCap: .round,
                                       lineJoin: .round,
                                       miterLimit: .infinity,
                                       dash: [20, 0],
                                       dashPhase: 0)
                )
                .rotationEffect(Angle(degrees: 90))
                .rotation3DEffect(
                    Angle(degrees: 180),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )
                .frame(width: size * 0.9, height: size * 0.9)
                .animation(.easeOut)
        }
        .frame(width: size, height: size)
    }
}

struct ProgressRingView_Previews: PreviewProvider {
    @State static var percent0: CGFloat = 0
    @State static var percent10: CGFloat = 0.1
    @State static var percent20: CGFloat = 0.2
    @State static var percent30: CGFloat = 0.3
    @State static var percent40: CGFloat = 0.4
    @State static var percent50: CGFloat = 0.5
    @State static var percent60: CGFloat = 0.6
    @State static var percent70: CGFloat = 0.7
    @State static var percent80: CGFloat = 0.8
    @State static var percent90: CGFloat = 0.9
    @State static var percent100: CGFloat = 1

    @State static var colors = [Color.blue]

    static let size: CGFloat = 60
    static let width: CGFloat = 8

    static var previews: some View {
        VStack {
            HStack {
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent0,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent10,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent20,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent30,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent40,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent50,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
            }
            HStack {
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent60,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent70,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent80,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent90,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
                ProgressRingView(progressPercent: ProgressRingView_Previews.$percent100,
                                 colors: ProgressRingView_Previews.$colors,
                                 size: size, strokeWidth: width)
            }
        }
        .previewLayout(.fixed(width: 500, height: 200))
    }
}
