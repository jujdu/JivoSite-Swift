# JivoSite SwiftSDK
This is an updated and ported from Objective-C to Swift JivoSite SDK. To use it, keep following an instruction from [JivoSite's official github profile](https://github.com/JivoSite/MobileSdk), but instead of Objective-C files use these Swift files. Also it was updated to WKWebView in fact that UIWebView is deprecated now. And yes, UIWebView is still working, but it has some bugs, like a blinking when it loads or shows a black strape at the bottom of view (for iPhone X and newer).

### Notice!
Please, take in mind about **webView(_ webView:, decidePolicyFor navigationAction:, decisionHandler:)** method, because it allows any connections in this template.
