//
//  WebViewController.swift
//  FYLE
//
//  Created by Sana Sreeraj on 05/04/25.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    // MARK: - Properties
    private var webView: WKWebView!
    private let urlString = "https://fyle-privacy-policy.vercel.app/"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupWebView()
        loadPrivacyPolicy()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        // Set title
        title = "Privacy Policy"
        
        // Create close button
        let closeButton = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeButtonPressed)
        )
        
        // Add close button to navigation bar
        navigationItem.leftBarButtonItem = closeButton
        
        // Customize navigation bar appearance for both light and dark mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
    }
    
    private func setupWebView() {
        // Create and configure WKWebView with dark mode support
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set background color to system background
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        
        // Add web view to the view hierarchy
        view.addSubview(webView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadPrivacyPolicy() {
        // Load the privacy policy URL with JavaScript to handle dark mode
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
            
            // Inject CSS to handle dark mode
            let css = """
            @media (prefers-color-scheme: dark) {
                body {
                    color: white !important;
                    background-color: #1C1C1E !important;
                }
            }
            """
            
            let js = """
            var style = document.createElement('style');
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
            """
            
            webView.configuration.userContentController.addUserScript(
                WKUserScript(
                    source: js,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
        }
    }
    
    // MARK: - Navigation Delegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Hide loading indicator
        navigationItem.rightBarButtonItem = nil
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Hide loading indicator and show error
        navigationItem.rightBarButtonItem = nil
        showErrorAlert(message: error.localizedDescription)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Loading Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
