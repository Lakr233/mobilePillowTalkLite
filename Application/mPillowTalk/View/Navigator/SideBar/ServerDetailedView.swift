//
//  AllServerView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import PTFoundation
import SwiftUI

struct DetailedServerBoard: View {
    let serverDescriptor: PTServerManager.ServerDescriptor
    var body: some View {
        ScrollView {
            DetailedServerView(serverDescriptor: serverDescriptor)
        }
        .navigationTitle(PTServerManager.shared.obtainServer(withKey: serverDescriptor)?.obtainPossibleName() ?? "Broken Server Resource")
    }
}

struct DetailedServerBoard_Previews: PreviewProvider {
    static var previews: some View {
        DetailedServerBoard(serverDescriptor: "")
    }
}
