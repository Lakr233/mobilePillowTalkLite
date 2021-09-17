//
//  ServerBlockView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/1/21.
//

import PTFoundation
import SwiftUI

struct ServerBlockView: View {
    let serverDescriptor: PTServerManager.ServerDescriptor

    var body: some View {
        NavigationLink(destination:
            DetailedServerBoard(serverDescriptor: serverDescriptor)
        ) {
            ServerStatusBlockView(descriptor: serverDescriptor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ServerBlockView_Previews: PreviewProvider {
    static var previews: some View {
        Group {}
    }
}
