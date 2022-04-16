//
//  ViewController.swift
//  ExWebView
//
//  Created by 김종권 on 2022/04/16.
//

import UIKit
import RxSwift
import RxCocoa
import RxWebKit
import SnapKit
import WebKit

fileprivate let html = """
<!DOCTYPE html>
<meta content="width=device-width,user-scalable=no" name="viewport">

<html>
<body>

<p><웹뷰 화면></p>

<button onclick="sendScriptMessage()">native로 보내기!</button>

<p id="myButton"></p>

<script>
function sendScriptMessage() {
    window.webkit.messageHandlers.HandlerName.postMessage('여기에 처리할 메시지 입력')
}
</script>

</body>
</html>
"""

class ViewController: UIViewController {
  
  private let myWebView = WKWebView()
  private let sendButton: UIButton = {
    let button = UIButton()
    button.setTitle("javascript로 메세지 보내기", for: .normal)
    button.setTitleColor(.systemBlue, for: .normal)
    button.setTitleColor(.blue, for: .highlighted)
    return button
  }()
  private let messageLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 15)
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }()
  
  private let disposeBag = DisposeBag()
  var testCount = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = .secondarySystemBackground
    self.view.addSubview(self.myWebView)
    self.view.addSubview(self.sendButton)
    self.view.addSubview(self.messageLabel)
    
    self.myWebView.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide)
      $0.left.right.equalToSuperview()
      $0.height.equalTo(200)
    }
    self.sendButton.snp.makeConstraints {
      $0.top.equalTo(self.myWebView.snp.bottom).inset(-10)
      $0.left.right.equalToSuperview()
    }
    self.messageLabel.snp.makeConstraints {
      $0.top.equalTo(self.sendButton.snp.bottom).inset(-10)
      $0.left.right.equalToSuperview()
    }
    
    // message 수신: javascript -> webView
    // window.webkit.messageHandlers.HandlerName.postMessage('여기에 처리할 메시지 입력')
    self.myWebView.configuration.userContentController.rx.scriptMessage(forName: "HandlerName")
      .bind { [weak self] scriptMessage in
        guard let postMessage = scriptMessage.body as? String else { return }
        switch postMessage {
        case "여기에 처리할 메시지 입력":
          self?.messageLabel.text = "<이벤트 수신>\nname = \(scriptMessage.name),\nbody(postMessage) = \(postMessage)"
        default:
          print("none")
        }
        print(postMessage)
      }
      .disposed(by: self.disposeBag)
    
    // message 송신: webView -> javascript
    self.sendButton.rx.tap
      .throttle(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
      .bind { [weak self] in
        guard let ss = self else { return }
        ss.testCount += 1
        let script = "document.getElementById('myButton').innerText = '테스트 = \(ss.testCount)'"
        ss.myWebView.evaluateJavaScript(script, completionHandler: { result, error in
          if let result = result {
            print(result)
          } else if let error = error {
            print(error)
          }
        })
      }
      .disposed(by: self.disposeBag)
    
    self.myWebView.loadHTMLString(html, baseURL: nil)
  }
}
