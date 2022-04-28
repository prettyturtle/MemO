//
//  DetailViewController.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class DetailViewController: UIViewController {
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = memo.title
        label.font = .systemFont(ofSize: 18.0, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.text = memo.content
        label.font = .systemFont(ofSize: 16.0, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.text = memo.date
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14.0, weight: .regular)
        return label
    }()
    
    // MARK: - Properties
    let memo: Memo
    
    // MARK: - init
    init(memo: Memo) {
        self.memo = memo
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        attribute()
        layout()
    }
}

// MARK: - UI Methods
private extension DetailViewController {
    func setupNavigationBar() {
        if memo.isSecret {
            navigationItem.title = "🔒메모 상세"
        } else {
            navigationItem.title = "메모 상세"
        }
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .mainColor
    }
    func attribute() {
        view.backgroundColor = .systemBackground
    }
    func layout() {
        [
            titleLabel,
            contentLabel,
            dateLabel
        ].forEach { view.addSubview($0) }
        
        let commonSpacing: CGFloat = 16.0
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(view.safeAreaLayoutGuide).inset(commonSpacing)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(commonSpacing)
            $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(commonSpacing)
        }
        contentLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(titleLabel.snp.bottom).offset(commonSpacing)
            $0.trailing.equalTo(titleLabel.snp.trailing)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(contentLabel.snp.bottom).offset(commonSpacing)
        }
    }
}
