//
//  LogFileVC.swift
//  Vendor
//
//  Created by ray on 2018/12/13.
//  Copyright © 2018年 ray. All rights reserved.
//
#if !PUBLISH
import UIKit
import MessageUI

class LogFileVC: UITableViewController {

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var fileNames: [String]!
    convenience init(fileNames: [String]) {
        self.init(style: .plain)
        self.fileNames = fileNames
    }
    
    override init(style: UITableView.Style) {
        super.init(style: style)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Close", style: UIBarButtonItem.Style.done, target: self, action: #selector(close))
    }
    
    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.fileNames[indexPath.row]
        let name = self.fileNames[indexPath.row]
        cell.textLabel?.textColor = name == Console.Log.DiskOutput.curFileName ? .red : .black
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let name = self.fileNames[indexPath.row]
        if name == Console.Log.DiskOutput.curFileName {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let name = self.fileNames[indexPath.row]
        if let logs = Console.Log.DiskOutput.logs(forFileName: name) {
            let logListVC = LogListVC.init(name: name, logs: logs)
            self.navigationController?.pushViewController(logListVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let name = self.fileNames[indexPath.row]
            Console.Log.DiskOutput.removeLogFile(forName: name)
            self.fileNames.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

}


extension LogFileVC {
    
    class LogListVC: UIViewController, MFMailComposeViewControllerDelegate {
        
        override var prefersStatusBarHidden: Bool {
            return true
        }
        
        lazy var tableView: ConsoleVC.LogListView = {
            let tv = ConsoleVC.LogListView.init(frame: self.view.bounds, style: .plain)
            self.view.addSubview(tv)
            return tv
        }()
        
        var logs: [Console.Log]!
        var name: String!
        init(name: String, logs: [Console.Log]) {
            super.init(nibName: nil, bundle: nil)
            self.logs = logs
            self.name = name
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            self.tableView.reloadData(withLogs: self.logs)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "email", style: .plain, target: self, action: #selector(sendEmail))
        }
        
        // https://qiita.com/YumaInaura/items/31838a72678fa09d7e19
        func platform() -> String {
            var size = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            return String(cString: machine)
        }
        
        @objc func sendEmail() {
            let composeViewController = MFMailComposeViewController()
        
            composeViewController.mailComposeDelegate = self
            composeViewController.setSubject("Console Log - \(self.platform()) - \(UIDevice.current.systemVersion) - \(CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey)! as! String)")
            guard !logs.isEmpty else {
                return
            }
            var string = ""
            for log in logs {
                string.append(ConsoleVC.LogListView.attriForLog(log: log).string + "\n")
            }
            composeViewController.addAttachmentData(string.data(using: .utf8)!, mimeType: "Plain text", fileName: self.name)
            self.present(composeViewController, animated: true, completion: nil)
        }
        
        public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
#endif
