//
//  WriteViewController.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class WriteViewController: UIViewController {
    // MARK: - UI Components
    private lazy var tapGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(didTapWriteTableView)
    )
    private lazy var writeTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.addGestureRecognizer(tapGesture)
        tableView.isUserInteractionEnabled = true
        return tableView
    }()
    
    // MARK: - Properties
    private let userDefaultsManager = UserDefaultsManager()
    let writeType: WriteType
    let willModifyMemo: Memo?
    
    // MARK: - Delegate
    weak var delegate: WriteViewControllerDelegate?
    
    // MARK: - init
    init(writeType: WriteType, memo: Memo? = nil) {
        self.writeType = writeType
        self.willModifyMemo = memo
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

// MARK: - UITableViewDelegate
extension WriteViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if indexPath.row == 0 { // 첫번째 셀을 선택하면 키보드가 내려가도록
            view.endEditing(true)
        }
    }
}

// MARK: - UITableViewDataSource
extension WriteViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return 3
    }
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = SecretToggleCell()
            cell.setupView()
            cell.selectionStyle = .none
            if writeType == .modify,
               let willModifyMemo = willModifyMemo {
                cell.setupModifyView(isSecret: willModifyMemo.isSecret) // 수정될 메모의 정보 보이기
            }
            return cell
        case 1:
            let cell = MemoTitleInputCell()
            cell.setupView()
            cell.selectionStyle = .none
            if writeType == .modify,
               let willModifyMemo = willModifyMemo {
                cell.setupModifyView(title: willModifyMemo.title) // 수정될 메모의 정보 보이기
            }
            return cell
        case 2:
            let cell = MemoContentInputCell()
            cell.setupView()
            cell.selectionStyle = .none
            if writeType == .modify,
               let willModifyMemo = willModifyMemo {
                cell.setupModifyView(content: willModifyMemo.content) // 수정될 메모의 정보 보이기
            }
            return cell
        default:
            break
        }
        return UITableViewCell()
    }
}

// MARK: - @objc Methods
private extension WriteViewController {
    @objc func didTapDismissBarButton() {
        dismiss(animated: true)
    }
    // 작성 완료 버튼을 눌렀을 때 호출되는 메서드
    @objc func didTapWriteDoneBarButton() {
        guard let newMemoInfo = getNewMemoInfo() else { return } // 새로 작성된 메모 정보를 받아와
        
        var newMemo = Memo( // Memo 객체를 생성하고
            isSecret: newMemoInfo.isSecret,
            title: newMemoInfo.title,
            content: newMemoInfo.content,
            password: nil,
            createdDate: Date.now
        )
        
        if newMemoInfo.isSecret { // 만약 비밀 메모인 경우, 암호를 설정하도록
            showPasswordInputAlert { [weak self] pw in
                if let pw = pw {
                    if !pw.isEmpty { // 암호를 입력하면 비밀 메모로 작성
                        newMemo.password = pw
                        self?.uploadNewMemo(newMemo: newMemo)
                    } else { // 암호를 입력하지 않으면 일반 메모로 작성된다
                        newMemo.isSecret = false
                        self?.uploadNewMemo(newMemo: newMemo)
                    }
                }
            }
        } else { // 일반 메모인 경우, 바로 저장
            uploadNewMemo(newMemo: newMemo)
        }
    }
    // 작성 완료 버튼을 눌렀을 때 호출되는 메서드 (수정 타입)
    @objc func didTapModifyDoneBarButton() {
        guard let newMemoInfo = getNewMemoInfo(),
              let previousMemo = willModifyMemo else { return }
        
        var newMemo = Memo(
            id: previousMemo.id, // id는 이전의 메모와 동일
            isSecret: newMemoInfo.isSecret,
            title: newMemoInfo.title,
            content: newMemoInfo.content,
            password: nil,
            createdDate: previousMemo.createdDate // 등록 날짜는 이전의 메모와 동일
        )
        
        if newMemoInfo.isSecret { // 만약 비밀 메모로 수정된 경우, 암호를 설정하도록
            showPasswordInputAlert { [weak self] pw in
                if let pw = pw {
                    if !pw.isEmpty { // 암호를 입력하면 비밀 메모로 수정
                        newMemo.password = pw
                        self?.updateMemo(previousMemo: previousMemo, newMemo: newMemo)
                    } else { // 암호를 입력하지 않으면 일반 메모로 수정된다
                        newMemo.isSecret = false
                        self?.updateMemo(previousMemo: previousMemo, newMemo: newMemo)
                    }
                }
            }
        } else { // 일반 메모로 수정되면 바로 수정
            updateMemo(previousMemo: previousMemo, newMemo: newMemo)
        }
    }
    
    @objc func didTapWriteTableView() {
        view.endEditing(true)
    }
}
// MARK: - Logics
private extension WriteViewController {
    // UserDefaultsManager의 updateMemo 메서드를 통해 메모를 수정한다
    func updateMemo(previousMemo: Memo, newMemo: Memo) {
        userDefaultsManager.updateMemo(previousMemo: previousMemo, newMemo: newMemo) { [weak self] result in
            let alertController = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .alert
            )
            switch result {
            case .success(_):
                alertController.title = "작성 완료!"
                let okAction = UIAlertAction(
                    title: "확인",
                    style: .default
                ) { [weak self] _ in
                    self?.delegate?.modifySuccessThenRefresh(newMemo: newMemo) // 수정 성공
                    self?.dismiss(animated: true)
                }
                alertController.addAction(okAction)
            case .failure(let error):
                alertController.title = "작성 실패ㅠ"
                alertController.message = error.localizedDescription
                let okAction = UIAlertAction(
                    title: "확인",
                    style: .default
                )
                alertController.addAction(okAction)
            }
            self?.present(alertController, animated: true)
        }
    }
    
    // UserDefaultsManager의 createMemo 메서드를 통해 메모를 저장한다
    func uploadNewMemo(newMemo: Memo) {
        userDefaultsManager.createMemo(newMemo: newMemo) { [weak self] result in
            let alertController = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .alert
            )
            switch result {
            case .success(_):
                alertController.title = "작성 완료!"
                let okAction = UIAlertAction(
                    title: "확인",
                    style: .default
                ) { [weak self] _ in
                    self?.delegate?.uploadSuccessThenRefresh()
                    self?.dismiss(animated: true)
                }
                alertController.addAction(okAction)
            case .failure(let error):
                alertController.title = "작성 실패ㅠ"
                alertController.message = error.localizedDescription
                let okAction = UIAlertAction(
                    title: "확인",
                    style: .default
                )
                alertController.addAction(okAction)
            }
            self?.present(alertController, animated: true)
        }
    }
    // 비밀 메모인 경우 암호를 설정할 수 있는 AlertController, 암호를 설정하고 확인을 누르면 비밀번호를 completionHandler를 통해 전달한다
    func showPasswordInputAlert(completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(
            title: "비밀 메모 작성",
            message: "비밀번호를 설정하지 않으면 일반 메모로 작성됩니다",
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
        ) { _ in
            completionHandler(alertController.textFields?.first?.text)
        }
        let cancelAction = UIAlertAction(
            title: "취소",
            style: .cancel
        ) { _ in
            completionHandler(nil)
        }
        [
            okAction,
            cancelAction
        ].forEach { alertController.addAction($0) }
        present(alertController, animated: true)
    }
    // 현재 작성한 메모의 정보를 반환하는 메서드 -> (비밀메모인지, 메모의 제목, 메모의 내용)
    func getNewMemoInfo() -> (isSecret: Bool, title: String, content: String)? {
        guard let secretToggleCell = writeTableView.cellForRow(
            at: IndexPath(row: 0, section: 0)
        ) as? SecretToggleCell,
              let memoTitleInputCell = writeTableView.cellForRow(
                at: IndexPath(row: 1, section: 0)
              ) as? MemoTitleInputCell,
              let memoContentInputCell = writeTableView.cellForRow(
                at: IndexPath(row: 2, section: 0)
              ) as? MemoContentInputCell else { return nil }
        
        let isSecret = secretToggleCell.isSecret
        let memoTitle = memoTitleInputCell.titleTextField.text!.isEmpty ? "제목 없음" : memoTitleInputCell.titleTextField.text!
        let memoContent = memoContentInputCell.contentTextView.textColor == .placeholderText || memoContentInputCell.contentTextView.text == "" ? "내용 없음" : memoContentInputCell.contentTextView.text!
        return (isSecret, memoTitle, memoContent)
    }
}

// MARK: - UI Methods
private extension WriteViewController {
    func setupNavigationBar() {
        navigationItem.title = writeType == .new ? "메모 작성" : "메모 수정"
        let dismissBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapDismissBarButton)
        )
        let customView = UIButton() // 작성 완료 네비게이션 커스텀 바 버튼
        customView.setTitle("완료", for: .normal)
        customView.setTitleColor(.white, for: .normal)
        customView.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .medium)
        customView.backgroundColor = .mainColor
        customView.frame = CGRect(x: 0.0, y: 0.0, width: 56.0, height: 36.0)
        customView.layer.cornerRadius = 18.0
        switch writeType { // 새로운 메모인지, 수정하는 메모인지 다른 액션을 부여한다
        case .new:
            customView.addTarget(
                self,
                action: #selector(didTapWriteDoneBarButton),
                for: .touchUpInside
            )
        case .modify:
            customView.addTarget(
                self,
                action: #selector(didTapModifyDoneBarButton),
                for: .touchUpInside
            )
        }
        let writeDoneBarButtonItem = UIBarButtonItem(customView: customView)
        
        dismissBarButtonItem.tintColor = .label
        
        navigationItem.leftBarButtonItem = dismissBarButtonItem
        navigationItem.rightBarButtonItem = writeDoneBarButtonItem
    }
    func attribute() {
        view.backgroundColor = .systemBackground
    }
    func layout() {
        view.addSubview(writeTableView)
        
        writeTableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
