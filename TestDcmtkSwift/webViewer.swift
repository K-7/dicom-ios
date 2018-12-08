//
//  webViewer.swift
//  TestDcmtkSwift
//
//  Created by home on 10/24/18.
//  Copyright © 2018 G Srinivasa. All rights reserved.
//

import Foundation
import WebKit


class webViewer: UIViewController, WKNavigationDelegate, WKUIDelegate {
    fileprivate let fileManager = FileManager.default
    
    var dicomFileUrl : String = ""
    
    lazy var webview : WKWebView = {
        let source =  """
        if (window.location.href.indexOf("?") == -1){
        window.location.href = window.location.href+"?input=\(dicomFileUrl)"
        }
        """
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let webview = WKWebView(frame: CGRect(x:0, y:0, width:100, height:100), configuration: configuration)
        webview.navigationDelegate = self
        webview.uiDelegate = self
        webview.translatesAutoresizingMaskIntoConstraints = false
        return webview
    } ()
    
    init(dicomFileUrl:String="0002.DCM") {
        super.init(nibName: nil, bundle: nil)
        self.dicomFileUrl = "dcm/\(dicomFileUrl)"
        
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        let dcmURL = documentsUrl.first!.appendingPathComponent("DicomViewer/dcm")
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: dcmURL, includingPropertiesForKeys: nil)
            guard let fileURLPath = fileURLs.first?.path else { print("Index out of range!"); return}
            self.dicomFileUrl = fileURLPath
        } catch {
            print("Error while enumerating files")
        }
        print ("======================\(dicomFileUrl)=====================k2a")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.red
        view.addSubview(webview)
        webview.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webview.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }

        do {
            let baseUrl = documentsUrl.first!.appendingPathComponent("DicomViewer/")
            let url = documentsUrl.first!.appendingPathComponent("DicomViewer/index.html")
            webview.loadFileURL(url, allowingReadAccessTo: baseUrl)
            let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webview, action: #selector(webview.reload))
            toolbarItems = [refresh]
            navigationController?.isToolbarHidden = false
        } catch let error as NSError {
            print(error.localizedDescription);
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: message, message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert);
        
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            _ in completionHandler()}
        );
        
        self.present(alertController, animated: true, completion: {});
    }
    
    func webViewDidStartLoad(_ webView: UIWebView)
    {
        print("Started to load")
    }
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        print("Finished loading")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    
}
