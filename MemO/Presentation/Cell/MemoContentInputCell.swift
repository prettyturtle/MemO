//
//  MemoContentInputCell.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class MemoContentInputCell: UITableViewCell {
    // MARK: - UI Components
    lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.text = "내용 입력..."
        textView.font = .systemFont(ofSize: 16.0, weight: .regular)
        textView.textColor = .placeholderText
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 4.0
        textView.configureKeyboard()
        textView.delegate = self
        return textView
    }()
    private lazy var contentCountLabel: UILabel = {
        let label = UILabel()
        label.text = "글자 수 0"
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = .mainColor
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - setup
    func setupView() {
        layout()
    }
    func setupModifyView(content: String) { // 수정 타입일 때, 수정할 메모 정보를 적용한다
        contentTextView.text = content
        contentTextView.textColor = .label
        contentCountLabel.text = "글자 수 \(contentTextView.text!.count)"
    }
}

// MARK: - UITextViewDelegate
extension MemoContentInputCell: UITextViewDelegate {
    // textView의 placeholder
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    // textView의 placeholder
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "내용 입력..."
            textView.textColor = .placeholderText
        }
    }
    // 글자 수 계산
    func textViewDidChange(_ textView: UITextView) {
        contentCountLabel.text = "글자 수 \(textView.text!.count)"
    }
}

// MARK: - UI Methods
private extension MemoContentInputCell {
    func layout() {
        [
            contentTextView,
            contentCountLabel
        ].forEach { contentView.addSubview($0) }
        
        let commonSpacing: CGFloat = 16.0
        
        contentTextView.snp.makeConstraints {
            $0.height.equalTo(200.0)
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalToSuperview().inset(commonSpacing / 2.0)
            $0.trailing.equalToSuperview().inset(commonSpacing)
        }
        contentCountLabel.snp.makeConstraints {
            $0.leading.equalTo(contentTextView.snp.leading)
            $0.top.equalTo(contentTextView.snp.bottom).offset(commonSpacing / 4.0)
            $0.trailing.equalTo(contentTextView.snp.trailing)
            $0.bottom.equalToSuperview()
        }
    }
}
