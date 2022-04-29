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
    var memo: Memo
    
    // MARK: - Delegate
    weak var delegate: DetailViewControllerDelegate?
    
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
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /*
         상세 뷰컨의 willDisappear 시점에
         DetailViewControllerDelegate의 willDisappearRefreshTableView를 호출한다
         그러면 만약 메인 뷰컨으로 이동한다면, 메인 뷰컨의 테이블 뷰가 새로고침 된다
        */
        delegate?.willDisappearRefreshTableView()
    }
}

// MARK: - WriteViewControllerDelegate
extension DetailViewController: WriteViewControllerDelegate {
    func modifySuccessThenRefresh(newMemo: Memo) { // 수정에 성공하면, 수정된 메모를 받아와 화면을 새로고침한다
        memo = newMemo
        reloadView(memo: memo)
    }
    func uploadSuccessThenRefresh() {}
}

// MARK: - @objc Methods
private extension DetailViewController {
    @objc func didTapModifyButton() { // 수정 버튼을 눌렀을 때, 수정하는 뷰로 이동
        let rootVC = WriteViewController(writeType: .modify, memo: memo)
        rootVC.delegate = self
        let modifyVC = UINavigationController(rootViewController: rootVC)
        modifyVC.modalPresentationStyle = .fullScreen
        present(modifyVC, animated: true)
    }
}

// MARK: - UI Methods
private extension DetailViewController {
    // 메모 수정이 완료되면 화면을 새로고침하는 메서드
    func reloadView(memo: Memo) {
        titleLabel.text = memo.title
        contentLabel.text = memo.content
        dateLabel.text = memo.date
        setupNavigationBar()
    }
    func setupNavigationBar() {
        if memo.isSecret {
            navigationItem.title = "🔒메모 상세"
        } else {
            navigationItem.title = "메모 상세"
        }
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .mainColor
        
        let modifyButton = UIBarButtonItem(
            title: "수정",
            style: .plain,
            target: self,
            action: #selector(didTapModifyButton)
        )
        navigationItem.rightBarButtonItem = modifyButton
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
