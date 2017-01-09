import Foundation

extension UIButton {
    
    func setBackgroundColor(_ color: UIColor, forControlState controlState: UIControlState) {
        let colorImage = UIImage.onePixel(withColor: color)
        setBackgroundImage(colorImage, for: controlState)
    }
}


public protocol ViewCornerMasking : class {
    
    var bounds: CGRect { get }
    var maskingCorners : UIRectCorner { get }
    var layerMask : CALayer { get }
    func layoutSubviews()
}


extension ViewCornerMasking {
    
    var layerMask : CALayer {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        
        let size = CGSize(width: self.bounds.height/2.0,height: self.bounds.width/2.0)
        maskLayer.path = UIBezierPath(roundedRect: maskLayer.bounds, byRoundingCorners: self.maskingCorners, cornerRadii: size).cgPath
        return maskLayer
        
    }
}

class ButtonCornerMask : UIButton , ViewCornerMasking {
    
    var maskingCorners : UIRectCorner { return UIRectCorner.allCorners }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard self.bounds.isEmpty == false else {
            return
        }
        
        if self.layer.mask == nil {
            self.layer.mask = self.layerMask
        }
    }
}



extension UIImage {
    
    static func onePixel(withColor color: UIColor) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        if let cgImage = context?.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}
