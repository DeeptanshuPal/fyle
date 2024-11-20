import UIKit

class GradientBGViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupBlurOverlay()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "#3F7AC4").cgColor,
            UIColor(hex: "#71C3F7").cgColor,
            UIColor(hex: "#F6F6F6").cgColor
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupBlurOverlay() {
        let blurLayer = CAGradientLayer()
        blurLayer.frame = CGRect(x: 0, y: view.bounds.height - 150, width: view.bounds.width, height: 150)
        blurLayer.colors = [
            UIColor(hex: "#D9D9D9").withAlphaComponent(0.0).cgColor,
            UIColor(hex: "#F5F5F6").withAlphaComponent(0.75).cgColor
        ]
        blurLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        blurLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        view.layer.insertSublayer(blurLayer, above: view.layer.sublayers?.first)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
