//
//  SecretToggleCell.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class SecretToggleCell: UITableViewCell {
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "비밀 메모"
        label.font = .systemFont(ofSize: 16.0, weight: .semibold)
        return label
    }()
    private lazy var secretToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .mainColor
        toggle.isOn = false
        toggle.addTarget(
            self,
            action: #selector(switchSecretToggle(_:)),
            for: .valueChanged
        )
        return toggle
    }()
    
    // MARK: - Properties
    var isSecret = false
    
    // MARK: - setup
    func setupView() {
        layout()
    }
}

// MARK: - @objc Methods
private extension SecretToggleCell {
    // 스위치가 눌렸을 때, isSecret을 변경
    @objc func switchSecretToggle(_ sender: UISwitch) {
        isSecret = sender.isOn
    }
}

// MARK: - UI Methods
private extension SecretToggleCell {
    func layout() {
        [
            titleLabel,
            secretToggle
        ].forEach { contentView.addSubview($0) }
        
        let commonSpacing: CGFloat = 16.0
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalToSuperview().inset(commonSpacing)
            $0.bottom.equalToSuperview().inset(commonSpacing)
        }
        secretToggle.snp.makeConstraints {
            $0.top.equalToSuperview().inset(commonSpacing)
            $0.trailing.equalToSuperview().inset(commonSpacing)
            $0.bottom.equalToSuperview().inset(commonSpacing)
        }
    }
}
