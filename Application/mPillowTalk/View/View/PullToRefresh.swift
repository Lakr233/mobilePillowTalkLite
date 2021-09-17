//
//  PullToRefreshWithBigNavTitle.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/27/21.
//

import SwiftUI

struct PullToRefreshWithBigNavTitle: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void

    @State var needRefresh: Bool = false

    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 60 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if geo.frame(in: .named(coordinateSpaceName)).maxY < 20 {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }
                Spacer()
            }
            .offset(y: calc(yInsideCoordinate: geo.frame(in: .named(coordinateSpaceName)).midY))
        }.padding(.top, -160)
    }

    func calc(yInsideCoordinate: CGFloat) -> CGFloat {
        if yInsideCoordinate <= 1 {
            return yInsideCoordinate
        }
        var y = yInsideCoordinate * 2
        let control = CGFloat(75)
        if y > control {
            let v1 = Double(y - control) * 15
            y = control + CGFloat(sqrt(v1))
        }
        return y
    }
}
