//
//  File.swift
//  
//
//  Created by Phuc on 07/10/2020.
//

import Foundation

//column: 4
//raw: "Expected an identifier and instead saw '{a}'."
//row: 8
//text: "Expected an identifier and instead saw 'var'."
//type: "error"
public struct Annotation: Decodable {
    enum AnnotationType: String, Decodable {
        case error
        case warning
        case info
    }
    
    let column: Int
    let row: Int
    let text: String
    let type: AnnotationType
}

extension Annotation {
    init?(dict: [String: Any]) {
        guard
            let column = dict["column"] as? Int,
            let row = dict["row"] as? Int,
            let text = dict["text"] as? String,
            let typeRaw = dict["type"] as? String,
            let type = AnnotationType(rawValue: typeRaw) else {
            return nil
        }
        
        self.column = column
        self.row = row
        self.text = text
        self.type = type
    }
}
