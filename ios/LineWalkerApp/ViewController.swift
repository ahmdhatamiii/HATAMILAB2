import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var refreshControl: UIRefreshControl!
    private var activityIndicator: UIActivityIndicatorView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupObservers()
        loadWebApp()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 244/255.0, green: 245/255.0, blue: 247/255.0, alpha: 1.0) // App canvas background (#f4f5f7)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptEnabled = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let userContentController = WKUserContentController()

        // Injeksi skrip untuk menyembunyikan banner peringatan Google Apps Script dan mengunci lebar frame 100vw
        let fixGoogleScriptString = """
        (function() {
            var css = `
                .docs-butterbar-container, #docs-butterbar-container, .butterbar, [class*="butterbar"], div[role="alert"], table[class*="butterbar"] {
                    display: none !important;
                    visibility: hidden !important;
                    height: 0 !important;
                    min-height: 0 !important;
                    padding: 0 !important;
                    margin: 0 !important;
                    overflow: hidden !important;
                    opacity: 0 !important;
                    pointer-events: none !important;
                }
                html, body {
                    margin: 0 !important;
                    padding: 0 !important;
                    width: 100vw !important;
                    max-width: 100vw !important;
                    min-width: 100vw !important;
                    overflow-x: hidden !important;
                    overscroll-behavior-x: none !important;
                    touch-action: pan-y !important;
                    -webkit-text-size-adjust: 100% !important;
                    position: relative !important;
                }
                iframe, #sandboxFrame, .punch-present-iframe {
                    width: 100vw !important;
                    max-width: 100vw !important;
                    min-width: 100vw !important;
                    border: 0 !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    overflow-x: hidden !important;
                    position: absolute !important;
                    top: 0 !important;
                    left: 0 !important;
                    bottom: 0 !important;
                    right: 0 !important;
                    height: 100vh !important;
                }
            `;
            var style = document.createElement('style');
            style.type = 'text/css';
            style.appendChild(document.createTextNode(css));
            (document.head || document.documentElement).appendChild(style);

            // Pasang meta viewport pengunci
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                (document.head || document.documentElement).appendChild(meta);
            }
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
        })();
        """

        let fixScriptStart = WKUserScript(source: fixGoogleScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        let fixScriptEnd = WKUserScript(source: fixGoogleScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(fixScriptStart)
        userContentController.addUserScript(fixScriptEnd)

        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.backgroundColor = UIColor(red: 244/255.0, green: 245/255.0, blue: 247/255.0, alpha: 1.0)
        webView.isOpaque = false
        
        // Lock horizontal scrolling and bounce strictly
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.isDirectionalLockEnabled = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Custom Safari User Agent to ensure full Google Auth compatibility
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1 LineWalkerApp/1.0"

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        // Progress View
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = UIColor(red: 0/255.0, green: 162/255.0, blue: 232/255.0, alpha: 1.0) // PLN Cyan
        progressView.trackTintColor = .clear
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = UIColor(red: 254/255.0, green: 219/255.0, blue: 0/255.0, alpha: 1.0) // PLN Yellow
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        // Pull to refresh
        if AppConfig.enablePullToRefresh {
            refreshControl = UIRefreshControl()
            refreshControl.tintColor = UIColor(red: 0/255.0, green: 162/255.0, blue: 232/255.0, alpha: 1.0)
            refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
            webView.scrollView.addSubview(refreshControl)
        }

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.5),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupObservers() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressView.progress = Float(webView.estimatedProgress)
            if webView.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                }) { _ in
                    self.progressView.progress = 0
                }
            } else {
                progressView.alpha = 1.0
            }
        }
    }

    private func loadWebApp() {
        guard let url = URL(string: AppConfig.webAppUrl) else {
            showErrorAlert(message: "Format URL Web App di AppConfig.swift tidak valid.")
            return
        }

        activityIndicator.startAnimating()
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        webView.load(request)
    }

    @objc private func handleRefresh() {
        webView.reload()
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        if let refresh = refreshControl, refresh.isRefreshing {
            refresh.endRefreshing()
        }
        
        // Pembersihan tambahan saat render selesai
        let cleanupJS = """
        var butterbars = document.querySelectorAll('.docs-butterbar-container, #docs-butterbar-container, .butterbar, [class*="butterbar"], div[role="alert"]');
        butterbars.forEach(function(el) { el.remove(); });
        document.body.style.overflowX = 'hidden';
        document.documentElement.style.overflowX = 'hidden';
        """
        webView.evaluateJavaScript(cleanupJS, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        if let refresh = refreshControl, refresh.isRefreshing {
            refresh.endRefreshing()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        if let refresh = refreshControl, refresh.isRefreshing {
            refresh.endRefreshing()
        }
        
        let nsError = error as NSError
        // Ignore NSURLErrorCancelled (-999) caused by rapid redirects or downloads
        if nsError.code != NSURLErrorCancelled {
            showErrorAlert(message: "Gagal memuat aplikasi: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString.lowercased()

        // Check if URL is an explicit download link (Google Drive export download, PDF, Excel, etc.)
        if isDownloadUrl(urlString) {
            decisionHandler(.cancel)
            downloadAndShareFile(url: url)
            return
        }

        // Open non-http schemes (tel:, mailto:, whatsapp:) natively
        if let scheme = url.scheme, scheme != "http" && scheme != "https" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }

        // Handle target="_blank" links
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func isDownloadUrl(_ urlString: String) -> Bool {
        return urlString.contains("export=download") ||
               urlString.hasSuffix(".pdf") ||
               urlString.hasSuffix(".xlsx") ||
               urlString.hasSuffix(".xls") ||
               urlString.hasSuffix(".csv") ||
               urlString.hasSuffix(".zip")
    }

    private func downloadAndShareFile(url: URL) {
        activityIndicator.startAnimating()

        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempUrl, response, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()

                guard let self = self, let tempUrl = tempUrl, error == nil else {
                    self?.showErrorAlert(message: "Gagal mengunduh berkas.")
                    return
                }

                // Determine file name
                let suggestedFilename = response?.suggestedFilename ?? "dokumen.pdf"
                let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)

                try? FileManager.default.removeItem(at: destinationUrl)
                do {
                    try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
                    let activityVC = UIActivityViewController(activityItems: [destinationUrl], applicationActivities: nil)
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self.view
                        popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    self.present(activityVC, animated: true, completion: nil)
                } catch {
                    self.showErrorAlert(message: "Gagal menyimpan berkas ke perangkat.")
                }
            }
        }
        task.resume()
    }

    // MARK: - WKUIDelegate (JavaScript Alerts, Prompts, Confirms)
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: AppConfig.appTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler() }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: AppConfig.appTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel, handler: { _ in completionHandler(false) }))
        alert.addAction(UIAlertAction(title: "Ya", style: .default, handler: { _ in completionHandler(true) }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Perhatian", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Coba Lagi", style: .default, handler: { [weak self] _ in
            self?.loadWebApp()
        }))
        alert.addAction(UIAlertAction(title: "Tutup", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    deinit {
        webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    }
}
