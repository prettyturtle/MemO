//
//  Memo.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import Foundation

struct Memo: Codable {
    let isSecret: Bool
    let title: String
    let content: String
    var password: String?
    var createdDate: Date { Date.now }
    
    var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y.M.d(E)"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: createdDate)
    }
}
