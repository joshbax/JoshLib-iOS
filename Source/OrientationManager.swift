import Foundation
import AVFoundation
import CoreMotion

/**
Uses the accelerometer to determine device orientation rather than relying on UIKit. 
This is useful when the user has toggled Portrait lock on their iPhone and we need to know if the device is in landscape

One use is case is properly saving photos in landscape mode when user has portrait lock enabled.
 
Conveniently provides image orientation, interface orientation, device, and raw rotation/transformation values 
**/
public class OrientationManager {

    fileprivate let _motionManager = CMMotionManager()
    fileprivate let _operationQueue = OperationQueue()

    fileprivate var _deviceOrientation : UIDeviceOrientation = UIDevice.current.orientation
    
    public var device : UIDeviceOrientation { return self._deviceOrientation }
    
    public var interface : UIInterfaceOrientation { return self._deviceOrientation.toInterfaceOrientation }
    
    public var image : UIImageOrientation { return self._deviceOrientation.toImageOrientation }
 
    public var rotation : CGFloat { return self._deviceOrientation.toRotation }
 
    public var affineTransform : CGAffineTransform { return self._deviceOrientation.toRotationTransform }

    init() {
        _motionManager.accelerometerUpdateInterval = 0.5
    }
    
    public func startMonitoring() {
        _motionManager.startAccelerometerUpdates(to: _operationQueue) { [weak self]  (data: CMAccelerometerData?, error: Error?) in
            guard let data = data else { return }
            self?.processAccelerometerData(data)
        }
    }
    
    fileprivate func stopMonitoring() {
        _motionManager.stopAccelerometerUpdates()
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        
        switch (acceleration.x,acceleration.y) {
        case (let x, _) where x >= 0.75:
            self._deviceOrientation = UIDeviceOrientation.landscapeRight
        case (let x, _) where x <= -0.75:
            self._deviceOrientation = UIDeviceOrientation.landscapeLeft
        case (_, let y) where y <= -0.75:
            self._deviceOrientation = UIDeviceOrientation.portrait
        case (_, let y) where y >= 0.75:
            self._deviceOrientation = UIDeviceOrientation.portraitUpsideDown
        default: break
        }
    }
}

extension UIDeviceOrientation {
    
    var toInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .portraitUpsideDown: return UIInterfaceOrientation.portraitUpsideDown
        case .landscapeRight: return UIInterfaceOrientation.landscapeLeft
        case .landscapeLeft: return UIInterfaceOrientation.landscapeRight
        default:
            return UIInterfaceOrientation.portrait
        }
    }
    
    var toImageOrientation: UIImageOrientation {
        switch self {
        case .portraitUpsideDown: return UIImageOrientation.down
        case .landscapeRight: return UIImageOrientation.left
        case .landscapeLeft: return UIImageOrientation.right
        default:
            return UIImageOrientation.up
        }
    }
    
    var toRotation: CGFloat {
        switch self {
        case .portraitUpsideDown: return CGFloat(M_PI)
        case .landscapeRight: return CGFloat(-1.0 * M_PI_2)
        case .landscapeLeft: return CGFloat(M_PI_2)
        default:
            return 0
        }
    }
    
    var toRotationTransform: CGAffineTransform {
        return CGAffineTransform(rotationAngle: self.toRotation)
    }
    
    var toVideoOrientation : AVCaptureVideoOrientation {
        switch self {
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .portrait: fallthrough
        default:
                return AVCaptureVideoOrientation.portrait
        }
        
    }
}
