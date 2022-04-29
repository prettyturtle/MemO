//
//  WriteViewControllerDelegate.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import Foundation

protocol WriteViewControllerDelegate: AnyObject {
    func uploadSuccessThenRefresh()
    func modifySuccessThenRefresh(newMemo: Memo)
}
