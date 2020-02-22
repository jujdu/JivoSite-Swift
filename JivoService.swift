//
//  JivoService.swift
//
//
//  Created by Michael Sidoruk on 11.02.2020.
//  Copyright © 2020 PKP. All rights reserved.
//

import Foundation
import WebKit

protocol JivoServiceDelegate: class {
    func onEvent(name: String?, data: String?)
}

class JivoService: NSObject {
    
    //MARK: - Views
    
    private let webView: WKWebView
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        return activityIndicatorView
    }()
    
    //MARK: - Inits
    
    init(webView: WKWebView, language: String = "") {
        self.webView = webView
        self.language = language
    }
    
    //MARK: - Properties
    
    private var language: String
    weak var delegate: JivoServiceDelegate?
    
    //MARK: - Methods
    
    func prepare() {
        webView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: webView.centerYAnchor).isActive = true
        
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false //выключаем scrollView чтобы он не пересекался со scrollView из JavaScript
        registerForKeyboardNotification()
    }
        
    func start() {
        activityIndicatorView.startAnimating()
        
        var indexFile: String
        
        if language.count > 0 {
            indexFile = "index_\(language)"
        } else {
            indexFile = "index"
        }
        
        guard let htmlFilePath = Bundle.main.path(forResource: indexFile, ofType: "html", inDirectory: "/html") else { return }
        
        do {
            let htmlString = try String(contentsOfFile: htmlFilePath, encoding: .utf8)
            let baseURL = URL(fileURLWithPath: "\(Bundle.main.bundlePath)/html")
            webView.loadHTMLString(htmlString, baseURL: baseURL)
        } catch let error as NSError {
            debugPrint(error)
        }
    }
    
    func stop() {
        webView.removeInputAccessoryView()
    }
    
    //MARK: - Call Java Script API
    
    ///Вызывает указанный метод из JavaScript. Нужен для установления связи в чате.
    func callApiMethod(methodName: String, data: String) {
        let jsString = "window.jivo_api.\(methodName)(\(data));"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    //MARK: - Notification Center Setup
    
    ///Добавляет себя в observers для получения нотификаций появления и скрытия клавиатуры. Перед деинициализации удаляет себя из observers.
    private func registerForKeyboardNotification() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(kbWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(kbWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc private func kbWillShow(_ notification: Notification) {
        //при вызове появляется ошибка с констрейтами, но все продолжает работать. В итнернете нашел что это баг WKWebView.
        webView.removeInputAccessoryView()

        //получаем высоту клавиатуры
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        
        let window = UIApplication.shared.keyWindow
        //считаем высоту из: клавитуры, поля ввода в webView, safeArea(для iPhoneX).
        let kbHeightAndInputHeightAndSafeArea = (kbFrameSize?.size.height ?? 0) - 50 - (window?.safeAreaInsets.bottom ?? 0)
        
        //Поднимаем контент webView. Данный метод не совсем корректно работает, но это не должно мешать пользователю. Если будет мало сообщений, то их можно проскролить под клавиатуру. Чтобы это исправить нужно лезть в JavaScript код. В legacy такая же ошибка.
        let onKeyBoardScript = "window.onKeyBoard({visible:true, height: \(kbHeightAndInputHeightAndSafeArea)});"
        webView.evaluateJavaScript(onKeyBoardScript, completionHandler: nil)
    }
    
    @objc private func kbWillHide(_ notification: Notification) {
        //Опускаем контент webView
        let onKeyBoardScript = "window.onKeyBoard({visible:false, height: 0});"
        webView.evaluateJavaScript(onKeyBoardScript, completionHandler: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - WKNavigationDelegate

extension JivoService: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else { return }
        
        //Если пользователь нажал на ссылку, открываем Safari по этой ссылке
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        //Запускаем сессию для чата
        if url.scheme?.lowercased() == "jivoapi" {
            let components = url.absoluteString.replacingOccurrences(of: "jivoapi://", with: "").components(separatedBy: "/")
            let apiKey = components.first
            var data: String? = nil
            
            if components.count > 1 {
                data = components[1].removingPercentEncoding
            }
            
            delegate?.onEvent(name: apiKey, data: data)
        }
        decisionHandler(.allow)
    }
}
