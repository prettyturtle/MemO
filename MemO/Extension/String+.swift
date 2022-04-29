//
//  String+.swift
//  MemO
//
//  Created by yc on 2022/04/29.
//

import Foundation

extension String {
    /// 문자열에 있는 특수문자들을 제거한 후, 공백 없는 문자열로 반환
    var realText: String {
        self.components(
            separatedBy: [
                " ", ".", ",", "/", "?", "!",
                "~", "@", "#", "$", "%", "^",
                "&", "*", "(", ")", "-", "_",
                "+", "=", "[", "]", "{", "}",
                ":", ";",
            ]
        )
        .joined(separator: "")
    }
}
