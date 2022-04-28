//
//  Manager.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import Foundation

/// UserDefaults를 통해 메모의 CRUD를 구현한 구조체
struct UserDefaultsManager {
    private let standard = UserDefaults.standard
    private let key = "MEMOLIST" // UserDefaults의 "MEMOLIST" 키에 저장
    
    /// 새로운 메모를 저장하는 메서드
    ///
    /// 현재 저장되어있는 메모 리스트를 받아와 새로운 메모를 추가하여 저장한다
    func createMemo(
        newMemo: Memo,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        readMemo { memoList in
            do {
                let data = try JSONEncoder().encode([newMemo] + memoList)
                let memoListJsonObject = try JSONSerialization.jsonObject(with: data)
                standard.setValue(memoListJsonObject, forKey: key)
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    /// 현재 저장되어있는 메모 리스트를 받아오는 메서드
    func readMemo(completionHandler: @escaping ([Memo]) -> Void) {
        if let value = standard.value(forKey: key) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let memoList = try JSONDecoder().decode([Memo].self, from: data)
                let sortedMemoList = memoList.sorted { $0.createdDate.compare($1.createdDate) == .orderedDescending }
                completionHandler(sortedMemoList)
            } catch {
                completionHandler([])
            }
        } else {
            completionHandler([])
        }
    }
    /// 현재 저장되어있는 모든 메모를 삭제하는 메서드
    func removeAll() {
        standard.removeObject(forKey: key)
    }
}
