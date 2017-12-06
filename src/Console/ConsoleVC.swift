//
//  ConsoleVC.swift
//  Ralyo
//
//  Created by ray on 2017/12/15.
//  Copyright © 2017年 ray. All rights reserved.
//
#if !PUBLISH

import UIKit
import MessageUI

let cellReuseId = "cellReuseId"

class ConsoleVC: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    weak var window: UIWindow?
    var tappedClose: (() -> Void)?
    
    convenience init() {
        
        self.init(nibName: nil, bundle: nil)
    }
    
    struct fieldConst {
        static let height: CGFloat = 25
        static let leftPading: CGFloat = 35
    }
    
    
    var inputText: String?
    var filterText: String?
    lazy var textField: UITextField = {
        let textField = UITextField.init(frame: CGRect.init(x: fieldConst.leftPading, y: 0, width: self.view.bounds.width - fieldConst.leftPading, height: fieldConst.height))
        self.view.addSubview(textField)
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.autocorrectionType = .no
        textField.placeholder = "Filter"
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        return textField
    }()

    lazy var inputLabel: UILabel = {
        let label = UILabel.init()
        label.text = "Input"
        label.font = UIFont.systemFont(ofSize: 10)
        label.frame = CGRect.init(x: 0, y: 0, width: fieldConst.leftPading, height: fieldConst.height/2)
        return label
    }()
    
    lazy var filterLabel: UILabel = {
        let label = UILabel.init()
        label.text = "Filter"
        label.font = UIFont.systemFont(ofSize: 10)
        label.frame = CGRect.init(x: 0, y: fieldConst.height/2, width: fieldConst.leftPading, height: fieldConst.height/2)
        return label
    }()
    
    
    lazy var textFieldView: UIView = {
        let height: CGFloat = 30
        let view = UIView.init(frame: CGRect.init(x: 0, y: self.view.bounds.height - fieldConst.height, width: self.view.bounds.width, height: fieldConst.height))
        view.addSubview(self.textField)
        view.addSubview(self.inputLabel)
        view.addSubview(self.filterLabel)
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(switchInput)))
        self.view.addSubview(view)
        return view
    }()
    
    var selectedInput: Bool?
    @objc func switchInput() {
        let selectedInput = nil != self.selectedInput ? !(self.selectedInput!) : false
        self.selectedInput = selectedInput
        if selectedInput {
            self.textField.text = self.inputText
            self.textField.placeholder = "Input"
            self.inputLabel.textColor = .orange
            self.filterLabel.textColor = .white
            self.reloadData()
        } else {
            self.textField.text = self.filterText
            self.textField.placeholder = "Filter"
            self.inputLabel.textColor = .white
            self.filterLabel.textColor = .orange
            if let text = self.filterText {
                self.filterEditingChanged(preString: nil, curString: text)
            }
        }
    }
    
    lazy var tableView: LogListView = {
        let tv = LogListView.init(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tv)
        tv.contentInset = UIEdgeInsets.init(top: 5 + (self.prefersStatusBarHidden ? 0 : 10) + 30, left: 0, bottom: fieldConst.height, right: 0)
        return tv
    }()
    
    lazy var closeBtn: UIButton = {
        let btn = UIButton.init(type: .custom)
        btn.setTitle("×", for: .normal)
        btn.titleLabel!.font = UIFont.systemFont(ofSize: 30)
        btn.frame = CGRect.init(x: 5, y: 5 + (self.prefersStatusBarHidden ? 0 : 10), width: 30, height: 30)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        self.view.addSubview(btn)
        return btn
    }()
    
    lazy var actionsBtn: UIButton = {
        let btn = UIButton.init(type: .infoLight)
        btn.frame = CGRect.init(x: self.view.bounds.width - 35, y: 5 + (self.prefersStatusBarHidden ? 0 : 10), width: 30, height: 30)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(additionalActions), for: .touchUpInside)
        self.view.addSubview(btn)
        return btn
    }()
    
    weak var keyboardObserver: AnyObject?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        let _ = self.tableView
        let _ = self.textFieldView
        let _ = self.closeBtn
        let _ = self.actionsBtn
        
        self.switchInput()
        
        keyboardObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: nil, using: {[unowned self] noti in
            if let frame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.textFieldView.frame.origin.y = frame.origin.y - self.textFieldView.bounds.height
                var contentInset = self.tableView.contentInset
                contentInset.bottom = fieldConst.height + (self.view.bounds.height - frame.origin.y)
                self.tableView.contentInset = contentInset
            }
        })

        self.view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(didTapView)))
    }
    
    deinit {
        if let observer = self.keyboardObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @objc func didTapView() {
        self.view.endEditing(true)
    }
    
    @objc func filterEditingChanged(preString: String?, curString: String) {

        self.filterQueue.cancelAllOperations()
        if Console.logs.isEmpty {
            self.filterQueue.addOperation {
                self.filteredLogs?.removeAll()
                DispatchQueue.main.async {
                    self.reloadData()
                }
            }
        } else if let text = self.textField.text, !text.isEmpty  {
            self.filterQueue.addOperation {
                let logs = ((nil != preString && !(preString!).isEmpty && curString.contains(preString!)) ? self.filteredLogs ?? Console.logs : Console.logs).filter({ log -> Bool in
                    return log.content.contains(text)
                })
                self.filteredLogs = logs
                DispatchQueue.main.async {
                    self.reloadData()
                }
            }
        } else {
            self.filterQueue.addOperation {
                self.filteredLogs = Console.logs
                DispatchQueue.main.async {
                    self.reloadData()
                }
            }
        }
    }
    
    
    func reloadData() {
        guard let selectedInput = self.selectedInput else {
            return
        }
        if selectedInput {
            self.tableView.reloadData(withLogs: Console.logs)
        } else {
            self.tableView.reloadData(withLogs: self.filteredLogs ?? Console.logs)
        }
    }

    
    @objc func close() {
        self.view.endEditing(true)
        self.tappedClose?()
    }
    
    
    @objc func additionalActions() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let defaultActions = [
            UIAlertAction(title: "clear", style: .default) { (action: UIAlertAction) in
                self.filteredLogs?.removeAll()
                Console.clear()
                self.reloadData()
            },
            UIAlertAction(title: "logs", style: .default) { (action: UIAlertAction) in
                
                if let fileNames = Console.Log.DiskOutput.logFileNames() {
                    let ctrler = LogFileVC.init(fileNames: fileNames)
                    let navi = UINavigationController.init(rootViewController: ctrler)
                    self.present(navi, animated: true, completion: nil)
                }
            }
        ]
        for action in defaultActions{
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    var filteredLogs: [Console.Log]?
    lazy var filterQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.name = "ray.console.vc.filterQueue"
        queue.qualityOfService = .userInteractive
        return queue
    }()
}

extension ConsoleVC: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ConsoleVC {
    
    class LogListView: UITableView, UITableViewDataSource, UITableViewDelegate {
        
        override init(frame: CGRect, style: UITableView.Style) {
            super.init(frame: frame, style: style)
            self.backgroundColor = .black
            self.separatorStyle = .none
            self.delegate = self
            self.dataSource = self
            self.register(LogListViewCell.self, forCellReuseIdentifier: cellReuseId)
            self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        var logs: [Console.Log]?
        lazy var attrForIndexPath = [IndexPath: NSAttributedString]()

        func reloadData(withLogs logs: [Console.Log]?) {
            self.logs = logs
            self.attrForIndexPath.removeAll()
            self.reloadData()
            if let logs = logs, !logs.isEmpty {
                self.scrollToRow(at: IndexPath.init(row: logs.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: false)
            }
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.logs?.count ?? 0
        }
        
        static var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yy-MM-dd HH:mm:ss.SSSZ"
            return formatter
        }()
        
        static func attriForLog(log: Console.Log) -> NSAttributedString {
            var string = dateFormatter.string(from: log.date)
            if !log.isInput, let fileName = log.fileName, let line = log.line {
                string.append(" \(fileName) \(line)")
            }
            string.append(": ")
            let attri = NSMutableAttributedString(string: string)
            var range = NSRange(location: 0, length: attri.length)
            
            attri.addAttributes(Console.textAppearance, range: range)
            
            let text = NSMutableAttributedString(string: log.content)
            range = NSRange(location: 0, length: text.length)
            
            text.addAttributes(Console.textAppearance, range: range)
            text.addAttribute(.foregroundColor, value: log.uiColor() ?? UIColor.white, range: range)
            
            attri.append(text)
            attri.addAttributes([.font: UIFont.systemFont(ofSize: 10)], range: NSRange.init(location: 0, length: attri.length))
            return attri
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            let attri = attrForIndexPath[indexPath] ?? {
                let attri = LogListView.attriForLog(log: (self.logs?[indexPath.row])!)
                attrForIndexPath[indexPath] = attri
                return attri
            }()
            let bound = attri.boundingRect(with: CGSize.init(width: tableView.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
            
            return bound.height
        }
        
        func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 20
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId) as! LogListViewCell
            cell.label!.attributedText = attrForIndexPath[indexPath] ?? {
                let attri = LogListView.attriForLog(log: (self.logs?[indexPath.row])!)
                attrForIndexPath[indexPath] = attri
                return attri
                }()
            return cell
        }
        
    }
    
    class LogListViewCell: UITableViewCell {
        
        var label: UILabel?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.backgroundColor = .clear
            label = UILabel.init()
            self.addSubview(label!)
            label!.numberOfLines = 0
            label!.lineBreakMode = .byCharWrapping
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            label?.frame = self.bounds
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
    }
    
}


extension ConsoleVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let selectedInput = self.selectedInput, selectedInput, let text = textField.text, text.count > 0 {
            textField.text = nil
            self.inputText = nil
            Console.print(text, file: nil, line: nil, isInput: true)
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let selectedInput = self.selectedInput!
        let preText = textField.text ?? ""
        let curText = preText.replacingCharacters(in: Range(range, in: preText)!, with: string)
        self.textField.text = curText
        if selectedInput {
            self.inputText = curText
        } else {
            self.filterText = curText
            self.filterEditingChanged(preString: preText, curString: curText)
        }
        return false
    }
}
#endif
