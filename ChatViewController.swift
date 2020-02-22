//
//  ChatViewController.swift
//
//
//  Created by Michael Sidoruk on 11.02.2020.
//  Copyright © 2020 PKP. All rights reserved.
//

import UIKit
import WebKit

class ChatViewController: UIViewController {
    
    //MARK: - @IBOutlets
    
    @IBOutlet weak var webView: WKWebView!
    
    //MARK: - Properties
    
    private var jivoService: JivoService!
    
    private var chatId: String?
    private var token: String!
    private var namePart: String!
    private var langKey: String!
    
    private let defaults = UserDefaults.standard
    
    //MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatId = defaults.string(forKey: "ChatId")
        token = defaults.string(forKey: "Token")
        namePart = defaults.string(forKey: "Name")
        
        langKey = Bundle.main.localizedString(forKey: chatId ?? "", value: nil, table: nil)
        
        jivoService = JivoService(webView: webView, language: langKey)
        jivoService.delegate = self
        jivoService.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Чат"
        checkAccessToChat()
        jivoService.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        jivoService.stop()
    }
    
    //MARK: - Deinit
    
    deinit {
        jivoService.stop()
    }
}

//MARK: - JivoDelegateSwift

extension ChatViewController: JivoServiceDelegate {
    func onEvent(name: String?, data: String?) {
        guard let name = name, let data = data else { return }
        print("event: \(name), data: \(data)")

        if name.lowercased() == "chat.ready" {
            guard let namePart = namePart else { return }
            let contactInfo = "{client_name : \"\(namePart)\"}"
            
            jivoService.callApiMethod(methodName: "setContactInfo", data: contactInfo)
            jivoService.callApiMethod(methodName: "setUserToken", data: token)
        }
    }
}
