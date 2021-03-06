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
    private lazy var searchBarTapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(removeAll)
        )
        tapGesture.numberOfTapsRequired = 10
        return tapGesture
    }()
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = .mainColor
        searchController.searchBar.placeholder = "메모 검색"
        searchController.searchBar.addGestureRecognizer(searchBarTapGesture)
        return searchController
    }()
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
    private var memoList = [Memo]() // 테이블 뷰에 보여질 메모 리스트
    private var memoSearchList = [String]() // 메모 검색 결과 리스트
    private var tempMemoList = [Memo]() // 원본 메모 리스트
    private var currentSearchText = "" // 검색하고 있던 text
    
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
        if memo.isSecret { // 비밀 메모인 경우
            let alertController = UIAlertController(
                title: "비밀번호 입력",
                message: nil,
                preferredStyle: .alert
            )
            alertController.addTextField { // 암호를 입력할 수 있는 텍스트필드 얼럿을 띄운다
                $0.configureKeyboard()
                $0.isSecureTextEntry = true
                $0.placeholder = "비밀번호 입력..."
            }
            let okAction = UIAlertAction(
                title: "확인",
                style: .default
            ) { [weak self] _ in
                if memo.password == alertController.textFields?.first?.text { // 만약 암호를 맞췄다면 메모 상세 뷰로 이동
                    self?.moveToDetailViewController(memo: memo)
                } else { // 암호를 맞추지 못했다면 다시 얼럿을 띄우기
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
        } else { // 일반 메모는 바로 메모 상세 뷰로 이동
            moveToDetailViewController(memo: memo)
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool { // edit 가능하도록
        return true
    }
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) { // 메모 삭제
        if editingStyle == .delete {
            let memo = memoList[indexPath.row]
            if memo.isSecret { // 비밀 메모인 경우
                showRemoveSecretAlert(memo: memo, index: indexPath.row) // 암호를 물어보고 맞으면 삭제하는 얼럿을 띄운다
            } else {
                showRemoveAlert(index: indexPath.row) // 삭제할건지 얼럿을 띄운다
            }
        }
    }
    func tableView(
        _ tableView: UITableView,
        titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath
    ) -> String? { // editingStyle (delete -> 삭제) 텍스트 변경
        return "삭제"
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

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    // 서치 바에 입력될 때마다 currentSearchText 갱신, searchText로 메모 검색
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentSearchText = searchText
        searchMemo(text: searchText)
    }
    // 검색 완료하면 키보드 내리기
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    // Cancel 버튼을 클릭하면, 전체 보기
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchMemo(text: "")
    }
}


// MARK: - WriteViewControllerDelegate
extension MainViewController: WriteViewControllerDelegate {
    // 작성 완료되면 새로고침, 검색중인 경우에는 새로고침 후 검색 결과 반영
    func uploadSuccessThenRefresh() {
        if navigationItem.searchController == nil {
            getMemoList()
        } else {
            getMemoList()
            memoSearchList = tempMemoList.map { $0.title.realText }
            searchMemo(text: currentSearchText)
        }
    }
    func modifySuccessThenRefresh(newMemo: Memo) {}
}

// MARK: - DetailViewControllerDelegate
extension MainViewController: DetailViewControllerDelegate {
    // 상세 정보에서 메인 뷰로 넘어올 때 새로고침, 검색중인 경우에는 새로고침 후 검색 결과 반영
    func willDisappearRefreshTableView() {
        if navigationItem.searchController == nil {
            getMemoList()
        } else {
            getMemoList()
            memoSearchList = tempMemoList.map { $0.title.realText }
            searchMemo(text: currentSearchText)
        }
    }
}

// MARK: - @objc Methods
private extension MainViewController {
    @objc func removeAll() {
        userDefaultsManager.removeAll()
        getMemoList()
    }
    // 검색 버튼이 탭 되면
    @objc func didTapSearchButton(_ sender: UIBarButtonItem) {
        if navigationItem.searchController == nil { // 서치 컨트롤러가 없는 경우
            sender.tintColor = .systemCyan
            navigationItem.searchController = searchController // 서치 컨트롤러를 네비게이션 아이템으로 넣는다
            navigationItem.hidesSearchBarWhenScrolling = false // 서치 바가 보이도록
        } else { // 서치 컨트롤러가 있는 경우
            sender.tintColor = .mainColor
            navigationItem.searchController = nil // 서치 컨트롤러를 제거
        }
    }
    // 스크롤해서 저장되어있는 메모들을 받아와 새로고침
    @objc func beginRefresh(_ sender: UIRefreshControl) {
        getMemoList()
        sender.endRefreshing()
    }
    // 메모 작성 버튼을 눌렀을 때, 메모 작성 뷰를 present
    @objc func didTapWriteFloatyButton() {
        let rootVC = WriteViewController(writeType: .new)
        rootVC.delegate = self
        let writeVC = UINavigationController(rootViewController: rootVC)
        writeVC.modalPresentationStyle = .fullScreen
        present(writeVC, animated: true)
    }
}

// MARK: - Logics
private extension MainViewController {
    // 메모 검색 메서드
    func searchMemo(text: String) {
        if text == "" { // 빈 문자열을 검색하면 모든 메모를 보여준다
            memoList = tempMemoList
        } else {
            var searchResult = Set<Memo>()
            for (idx, title) in memoSearchList.enumerated() {
                if title.contains(text) {
                    searchResult.insert(tempMemoList[idx])
                }
            }
            memoList = Array(searchResult).sorted {
                $0.createdDate.compare($1.createdDate) == .orderedDescending
            }
        }
        memoListTableView.reloadData()
    }
    func showRemoveFailAlert() { // 비밀 메모를 삭제할 때, 암호를 틀리면 얼럿을 띄어주는 메서드
        let alertController = UIAlertController(
            title: "비밀번호가 일치하지 않습니다",
            message: nil,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "확인",
            style: .cancel
        )
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
    func showRemoveSecretAlert(memo: Memo, index: Int) { // 비밀 메모를 삭제할 때, 암호를 작성할 수 있는 얼럿을 띄우는 메서드
        let alertController = UIAlertController(
            title: "삭제하시겠습니까?",
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
            if memo.password == alertController.textFields?.first?.text {
                self?.removeMemo(index: index) // 암호가 맞으면 삭제
            } else {
                self?.showRemoveFailAlert() // 암호가 틀리면 얼럿을 띄운다
            }
        }
        let cancelAction = UIAlertAction(
            title: "취소",
            style: .cancel
        )
        [
            okAction,
            cancelAction
        ].forEach { alertController.addAction($0) }
        
        present(alertController, animated: true)
    }
    func showRemoveAlert(index: Int) { // 일반 메모를 삭제하는 메서드
        let alertController = UIAlertController(
            title: "삭제하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "확인",
            style: .default
        ) { [weak self] _ in self?.removeMemo(index: index) }
        let cancelAction = UIAlertAction(
            title: "취소",
            style: .cancel
        )
        [
            okAction,
            cancelAction
        ].forEach { alertController.addAction($0) }
        
        present(alertController, animated: true)
    }
    func removeMemo(index: Int) { // UserDefaultsManager를 통한 메모 삭제 메서드, 메모를 삭제한 뒤 getMemoList() 메서드를 호출하여 새로고침한다
        let willRemovedMemo = memoList[index]
        memoList.remove(at: index)
        userDefaultsManager.removeMemo(memo: willRemovedMemo) { [weak self] in
            self?.getMemoList()
        }
    }
    // 메모 상세 보기 뷰로 이동
    func moveToDetailViewController(memo: Memo) {
        let detailViewController = DetailViewController(memo: memo)
        detailViewController.delegate = self
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    // UserDefaults에 저장된 메모들을 가져온 후, 저장된 메모가 없다면 emptyImageView를 보여주고, 있다면 메모리스트를 보여준다
    func getMemoList() {
        userDefaultsManager.readMemo { [weak self] in
            self?.memoListTableView.isHidden = $0.isEmpty
            self?.emptyImageView.isHidden = !$0.isEmpty
            self?.memoList = $0
            self?.tempMemoList = $0
            self?.memoSearchList = $0.map { $0.title.realText }
            self?.memoListTableView.reloadData()
        }
    }
}

// MARK: - UI Methods
private extension MainViewController {
    func setupNavigationBar() {
        navigationItem.title = "메모 목록"
        
        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(didTapSearchButton(_:))
        )
        searchButton.tintColor = .mainColor
        navigationItem.rightBarButtonItem = searchButton
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
