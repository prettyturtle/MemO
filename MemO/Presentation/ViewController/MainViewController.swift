//
//  MainViewController.swift
//  MemO
//
//  Created by yc on 2022/04/28.
//

import UIKit
import SnapKit

class MainViewController: UIViewController {
    // MARK: - UI Components
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(
            self,
            action: #selector(beginRefresh(_:)),
            for: .valueChanged
        )
        return refresh
    }()
    private lazy var memoListTableView: UITableView = {
        let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.separatorStyle = .singleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            MemoListTableViewCell.self,
            forCellReuseIdentifier: MemoListTableViewCell.identifier
        )
        return tableView
    }()
    private lazy var writeFloatyButtonWidth = 75.0 // 작성 버튼의 너비
    private lazy var writeFloatyButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .mainColor
        button.layer.cornerRadius = writeFloatyButtonWidth / 2.0
        button.addTarget(
            self,
            action: #selector(didTapWriteFloatyButton),
            for: .touchUpInside
        )
        return button
    }()
    private lazy var emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "questionmark.folder")
        imageView.tintColor = .secondarySystemBackground
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Properties
    private let userDefaultsManager = UserDefaultsManager()
    private var memoList = [Memo]()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        attribute()
        layout()
        getMemoList()
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let memo = memoList[indexPath.row]
        if memo.isSecret {
            let alertController = UIAlertController(
                title: "비밀번호 입력",
                message: nil,
                preferredStyle: .alert
            )
            alertController.addTextField {
                $0.configureKeyboard()
                $0.isSecureTextEntry = true
                $0.placeholder = "비밀번호 입력..."
            }
            let okAction = UIAlertAction(
                title: "확인",
                style: .default
            ) { [weak self] _ in
                if memo.password == alertController.textFields?.first?.text {
                    self?.moveToDetailViewController(memo: memo)
                } else {
                    alertController.message = "비밀번호를 다시 입력하세요..."
                    self?.present(alertController, animated: true)
                }
            }
            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
            [
                okAction,
                cancelAction
            ].forEach { alertController.addAction($0) }
            present(alertController, animated: true)
        } else {
            moveToDetailViewController(memo: memo)
        }
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return memoList.count
    }
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MemoListTableViewCell.identifier,
            for: indexPath
        ) as? MemoListTableViewCell else { return UITableViewCell() }
        let memo = memoList[indexPath.row]
        cell.setupView(memo: memo)
        return cell
    }
}

// MARK: - WriteViewControllerDelegate
extension MainViewController: WriteViewControllerDelegate {
    // 작성 완료되면 새로고침
    func uploadSuccessThenRefresh() {
        getMemoList()
    }
}

// MARK: - @objc Methods
private extension MainViewController {
    // 스크롤해서 저장되어있는 메모들을 받아와 새로고침
    @objc func beginRefresh(_ sender: UIRefreshControl) {
        getMemoList()
        sender.endRefreshing()
    }
    // 메모 작성 버튼을 눌렀을 때, 메모 작성 뷰를 present
    @objc func didTapWriteFloatyButton() {
        let rootVC = WriteViewController()
        rootVC.delegate = self
        let writeVC = UINavigationController(rootViewController: rootVC)
        writeVC.modalPresentationStyle = .fullScreen
        present(writeVC, animated: true)
    }
}

// MARK: - Logics
private extension MainViewController {
    // 메모 상세 보기 뷰로 이동
    func moveToDetailViewController(memo: Memo) {
        let detailViewController = DetailViewController(memo: memo)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    // UserDefaults에 저장된 메모들을 가져온 후, 저장된 메모가 없다면 emptyImageView를 보여주고, 있다면 메모리스트를 보여준다
    func getMemoList() {
        userDefaultsManager.readMemo { [weak self] in
            self?.memoListTableView.isHidden = $0.isEmpty
            self?.emptyImageView.isHidden = !$0.isEmpty
            self?.memoList = $0
            self?.memoListTableView.reloadData()
        }
    }
}

// MARK: - UI Methods
private extension MainViewController {
    func setupNavigationBar() {
        navigationItem.title = "메모 목록"
    }
    func attribute() {
        view.backgroundColor = .systemBackground
    }
    func layout() {
        [
            memoListTableView,
            writeFloatyButton,
            emptyImageView
        ].forEach { view.addSubview($0) }
        
        memoListTableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        writeFloatyButton.snp.makeConstraints {
            $0.size.equalTo(writeFloatyButtonWidth)
            $0.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16.0)
        }
        writeFloatyButton.imageView?.snp.makeConstraints {
            $0.size.equalTo(writeFloatyButtonWidth / 2.5)
        }
        emptyImageView.snp.makeConstraints {
            $0.center.equalTo(view.safeAreaLayoutGuide)
            $0.size.equalTo(200.0)
        }
    }
}
