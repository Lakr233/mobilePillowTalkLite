//
//  InputElementView.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 5/21/21.
//

import SwiftUI

struct InputElementView: View {
    init(title: String,
         placeholder: String,
         required: Bool,
         validator: @escaping () -> (Bool),
         type: UITextContentType?,
         useInlineTextField: Bool,
         binder: Binding<String>)
    {
        self.title = title
        self.placeholder = placeholder
        self.required = required
        self.validator = validator
        self.type = type
        self.useInlineTextField = useInlineTextField
        _value = binder
    }

    let title: String
    let placeholder: String
    let required: Bool
    let validator: () -> (Bool)
    let type: UITextContentType?
    let useInlineTextField: Bool

    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title.uppercased())
                    .opacity(0.5)
                Spacer()
                Group {
                    if required {
                        if value.count < 1 {
                            Text(NSLocalizedString("REQUIRED_TO_FILL", comment: "Required"))
                                .foregroundColor(.red)
                        } else {
                            if validator() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .font(.system(size: 12, weight: .semibold, design: .default))
            if useInlineTextField {
                if type == .password {
                    SecureField(placeholder, text: $value, onCommit: {
                        UIApplication.shared.endEditing()
                    })
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .padding(8)
                        .background(Color.lightGray)
                        .cornerRadius(6)
                        .textContentType(type)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    TextField(placeholder, text: $value, onCommit: {
                        UIApplication.shared.endEditing()
                    })
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .padding(8)
                        .background(Color.lightGray)
                        .cornerRadius(6)
                        .textContentType(type)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
        }
    }
}

struct InputElementView_Previews: PreviewProvider {
    static var previews: some View {
        InputElementView(title: "AAAAA",
                         placeholder: "NNNSADNFASIDDFSAN",
                         required: true,
                         validator: { true },
                         type: nil,
                         useInlineTextField: true,
                         binder: Binding<String>.constant(""))
            .padding()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 300, height: 100))
        InputElementView(title: "AAAAA",
                         placeholder: "NNNSADNFASIDDFSAN",
                         required: true,
                         validator: { false },
                         type: nil,
                         useInlineTextField: true,
                         binder: Binding<String>.constant("AAAAA"))
            .padding()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 300, height: 100))
        InputElementView(title: "AAAAA",
                         placeholder: "NNNSADNFASIDDFSAN",
                         required: false,
                         validator: { true },
                         type: nil,
                         useInlineTextField: true,
                         binder: Binding<String>.constant(""))
            .padding()
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 300, height: 100))
        InputElementView(title: "AAAAA",
                         placeholder: "NNNSADNFASIDDFSAN",
                         required: true,
                         validator: { true },
                         type: nil,
                         useInlineTextField: true,
                         binder: Binding<String>.constant(""))
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 300, height: 100))
    }
}
