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
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private lazy var scrollContentView = UIView()
    private lazy var secretTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "비밀 메모"
        label.font = .systemFont(ofSize: 16.0, weight: .semibold)
        return label
    }()
    private lazy var secretToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .mainColor
        toggle.isOn = memo.isSecret
        toggle.addTarget(
            self,
            action: #selector(switchSecretToggle),
            for: .valueChanged
        )
        return toggle
    }()
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
    private let userDefaultsManager = UserDefaultsManager()
    
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
    // secretToggle이 눌렸을 때
    @objc func switchSecretToggle(_ sender: UISwitch) {
        if sender.isOn { // 만약 비밀 메모로 변경하려면 암호 설정하는 얼럿을 띄운다
            let alertController = UIAlertController(
                title: "비밀번호 설정",
                message: nil,
                preferredStyle: .alert
            )
            alertController.addTextField {
                $0.placeholder = "비밀번호 입력..."
                $0.configureKeyboard()
                $0.isSecureTextEntry = true
            }
            let okAction = UIAlertAction(
                title: "확인",
                style: .default
            ) { [weak self] _ in
                guard let self = self else { return }
                let password = alertController.textFields?.first?.text
                if password != "" {
                    self.memo.isSecret = true // 현재 메모 상세 뷰의 메모 정보를 변경
                    self.memo.password = password! // 현재 메모 상세 뷰의 메모 정보를 변경
                    self.updateMemoIsSecret(memo: self.memo) { result in // 변경 사항을 저장
                        switch result {
                        case .success(_):
                            self.setupNavigationBar()
                        case .failure(_):
                            break
                        }
                    }
                } else {
                    sender.isOn = false
                }
            }
            let cancelAction = UIAlertAction(
                title: "취소",
                style: .cancel
            ) { _ in sender.isOn = false } // 변경 사항 없음
            [
                okAction,
                cancelAction
            ].forEach { alertController.addAction($0) }
            present(alertController, animated: true)
        } else { // 만약 일반 메모로 변경하려면 얼럿을 띄운다
            let alertController = UIAlertController(
                title: "일반 메모로 변경 하시겠습니까?",
                message: nil,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(
                title: "확인",
                style: .default
            ) { [weak self] _ in
                guard let self = self else { return }
                self.memo.isSecret = false // 일반 메모로 변경
                self.memo.password = nil // 암호 제거
                self.updateMemoIsSecret(memo: self.memo) { result in // 변경 사항을 저장
                    switch result {
                    case .success(_):
                        self.setupNavigationBar()
                    case .failure(_):
                        break
                    }
                }
            }
            let cancelAction = UIAlertAction(
                title: "취소",
                style: .cancel
            ) { _ in sender.isOn = true } // 변경 사항 없음
            [
                okAction,
                cancelAction
            ].forEach { alertController.addAction($0) }
            present(alertController, animated: true)
        }
    }
}

// MARK: - Logics
private extension DetailViewController {
    // 메모의 isSecret의 변경사항을 수정하는 메서드, UserDefaultsManager의 updateMemo 메서드를 사용
    func updateMemoIsSecret(
        memo: Memo,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        var previousMemo = memo
        previousMemo.isSecret = !previousMemo.isSecret
        userDefaultsManager.updateMemo(
            previousMemo: previousMemo,
            newMemo: memo) { result in
                switch result {
                case .success(_):
                    completionHandler(.success(()))
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
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
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        [
            secretTitleLabel,
            secretToggle,
            titleLabel,
            contentLabel,
            dateLabel
        ].forEach { scrollContentView.addSubview($0) }
        
        let commonSpacing: CGFloat = 16.0
        
        secretTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.centerY.equalTo(secretToggle.snp.centerY)
        }
        secretToggle.snp.makeConstraints {
            $0.top.equalToSuperview().inset(commonSpacing)
            $0.trailing.equalToSuperview().inset(commonSpacing)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(commonSpacing)
            $0.top.equalTo(secretToggle.snp.bottom).offset(commonSpacing)
            $0.trailing.equalToSuperview().inset(commonSpacing)
        }
        contentLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(titleLabel.snp.bottom).offset(commonSpacing)
            $0.trailing.equalTo(titleLabel.snp.trailing)
        }
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(contentLabel.snp.bottom).offset(commonSpacing)
            $0.bottom.equalToSuperview()
        }
    }
}
