//
//  SectionAddServerButton.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 2021/5/30.
//

import PTFoundation
import SwiftUI

struct SectionAddServerButton: View {
    let sectionName: String?
    var body: some View {
        NavigationLink(destination: AddServerView(passedData: .init(underSection: sectionName))) {
            HStack {
                Image(systemName: "plus")
                if sectionName != nil {
                    if sectionName == PTServerManager.Server.defaultSectionName {
                        Text(
                            String(format:
                                NSLocalizedString("ADD_SERVER_UNDER_SECTION", comment: "Add server under %@"),
                                NSLocalizedString("DEFAULT_SECTION_NAME", comment: "Default"))
                        )
                    } else {
                        Text(
                            String(format:
                                NSLocalizedString("ADD_SERVER_UNDER_SECTION", comment: "Add server under %@"),
                                sectionName!)
                        )
                    }
                } else {
                    Text(NSLocalizedString("ADD_SERVER", comment: "Add Server"))
                }
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold, design: .default))
            .padding()
            .background(
                Color
                    .lightGray
                    .frame(height: 40)
                    .cornerRadius(8)
            )
        }
    }
}
