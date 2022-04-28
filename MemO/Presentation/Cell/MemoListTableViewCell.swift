//
//  MemoListTableViewCell.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class MemoListTableViewCell: UITableViewCell {
    static let identifier = "MemoListTableViewCell"
    
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        return label
    }()
    private lazy var secretImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .mainColor
        return imageView
    }()
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 12.0, weight: .regular)
        return label
    }()
    
    // MARK: - setupView
    func setupView(memo: Memo) {
        layout(memo: memo)
        if !memo.isSecret {
            contentLabel.text = memo.content
        } else {
            contentLabel.text = "비밀메모 입니다." // 비밀 메모인 경우, 내용 가리기
        }
        secretImageView.isHidden = !memo.isSecret
        titleLabel.text = memo.title
        dateLabel.text = memo.date
    }
}

// MARK: - UI Methods
private extension MemoListTableViewCell {
    func layout(memo: Memo) {
        [
            secretImageView,
            titleLabel,
            contentLabel,
            dateLabel
        ].forEach { contentView.addSubview($0) }
        
        let commonSpacing: CGFloat = 16.0
        
        if memo.isSecret { // 비밀 메모인 경우
            secretImageView.snp.removeConstraints()
            titleLabel.snp.removeConstraints()
            secretImageView.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(commonSpacing)
                $0.top.equalTo(titleLabel.snp.top)
                $0.bottom.equalTo(titleLabel.snp.bottom)
                $0.width.equalTo(secretImageView.snp.height)
            }
            titleLabel.snp.makeConstraints {
                $0.leading.equalTo(secretImageView.snp.trailing).offset(2.0)
                $0.top.equalToSuperview().inset(commonSpacing)
                $0.trailing.equalToSuperview().inset(commonSpacing)
            }
        } else { // 일반 메모인 경우
            secretImageView.snp.removeConstraints()
            titleLabel.snp.removeConstraints()
            titleLabel.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(commonSpacing)
                $0.top.equalToSuperview().inset(commonSpacing)
                $0.trailing.equalToSuperview().inset(commonSpacing)
            }
        }
        contentLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalTo(titleLabel.snp.bottom).offset(commonSpacing / 2.0)
            $0.trailing.equalToSuperview().inset(commonSpacing)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalTo(contentLabel.snp.bottom).offset(commonSpacing / 4.0)
            $0.trailing.equalToSuperview().inset(commonSpacing)
            $0.bottom.equalToSuperview().inset(commonSpacing)
        }
    }
}
