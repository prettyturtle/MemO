//
//  MemoTitleInputCell.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class MemoTitleInputCell: UITableViewCell {
    // MARK: - UI Components
    lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "제목 입력..."
        textField.font = .systemFont(ofSize: 18.0, weight: .semibold)
        textField.configureKeyboard()
        return textField
    }()
    
    // MARK: - setup
    func setupView() {
        layout()
    }
    func setupModifyView(title: String) { // 수정 타입일 때, 수정할 메모 정보를 적용한다
        titleTextField.text = title
    }
}

// MARK: - UI Methods
private extension MemoTitleInputCell {
    func layout() {
        contentView.addSubview(titleTextField)
        
        let commonSpacing: CGFloat = 16.0
        
        titleTextField.snp.makeConstraints {
            $0.height.equalTo(48.0)
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalToSuperview()
            $0.trailing.equalToSuperview().inset(commonSpacing)
            $0.bottom.equalToSuperview().inset(commonSpacing / 2.0)
        }
    }
}
