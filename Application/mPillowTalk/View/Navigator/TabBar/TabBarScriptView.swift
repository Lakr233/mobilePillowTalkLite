//
//  TabBarScriptView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/4/29.
//

import SwiftUI

struct TabBarScriptView: View {
    @State var presentCreate: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                ScriptCollectionView()
                    .padding()
                    .background(
                        NavigationLink(
                            destination: ScriptCreateView(),
                            isActive: $presentCreate,
                            label: {
                                Text("").hidden()
                            }
                        )
                        .opacity(0)
                    )
            }
            .navigationBarItems(trailing: Group {
                Button(action: {
                    presentCreate = true
                }, label: {
                    Text(NSLocalizedString("CREATE_SCRIPT", comment: "Create Script"))
                })
            })
            .navigationTitle(NSLocalizedString("SIDEBAR_CODE_CLIP", comment: "Script"))
        }
    }
}

struct TabBarScriptView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarScriptView()
    }
}
