//
//  Memo.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import Foundation

struct Memo: Codable, Equatable, Hashable {
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
    var id: String = UUID().uuidString
    var isSecret: Bool
    let title: String
    let content: String
    var password: String?
    var createdDate: Date
    
    var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy.MM.dd(E) HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: createdDate)
    }
    func dateCalc() -> String {
        let dateDiff = Calendar(identifier: .gregorian)
            .dateComponents(
                [.day, .hour, .minute, .second],
                from: createdDate, to: Date.now
            )
        if dateDiff.day! >= 1 {
            return date
        } else if dateDiff.hour! >= 1 {
            return "\(dateDiff.hour!)시간 전"
        } else if dateDiff.minute! >= 1 {
            return "\(dateDiff.minute!)분 전"
        } else if dateDiff.second! >= 0 {
            return "방금 전"
        }
        return date
    }
}
