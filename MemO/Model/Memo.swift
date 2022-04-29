//
//  Memo.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import Foundation

struct Memo: Codable, Equatable {
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
    var id: String = UUID().uuidString
    let isSecret: Bool
    let title: String
    let content: String
    var password: String?
    var createdDate: Date
    
    var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d(E) h:m:s"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: createdDate)
    }
}
