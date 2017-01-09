import Foundation
import AVFoundation
import MediaPlayer

protocol SystemVolumeButtonObservable {
    
    var volumeView : MPVolumeView! { get}
    var systemVolumeButtonObserver : SystemVolumeButtonObserver { get }
    
    func beginObservingVolumeButton()
    func endObservingVolumeButton()

}

extension SystemVolumeButtonObservable {
    
    func beginObservingVolumeButton() {
        systemVolumeButtonObserver.beginObserving()
    }
    
    func endObservingVolumeButton() {
        systemVolumeButtonObserver.endObserving()
    }
}

enum SystemVolumeButtonEvent : CustomStringConvertible {
    case up, down
    
    var description: String {
        switch self {
        case .up: return "Volume Up Pressed"
        case .down: return "Volume Down Pressed"
        }
    }
}

class SystemVolumeButtonObserver : NSObject {

    fileprivate weak var _volumeView : MPVolumeView?
    fileprivate var _observing : Bool = false
    fileprivate let _onVolumeButtonPressed : ((SystemVolumeButtonEvent) -> Void)
    fileprivate var _kvoContextOutputVolume = 1
    
    fileprivate var _priorVolumeClamped : Float = 0
    fileprivate var _priorVolume : Float {
        get {
            return _priorVolumeClamped
        }
        set {
            _priorVolumeClamped = min(max(newValue,0.01),0.99)
        }
    }
    
    /*!
     * @property allowSystemVolumeToChange
     * @abstract
     * When enabled, the system volume will also change when the user presses the sytem volume keys. Default is false.
     * @discussion
     * This class is designed to override the device volume buttons to allow photo capture when the volume buttons are pressed. 
     * Therefore, by default, we do not allow the system volume to change when capturing photos. To override this behavior, set this value to true.
     */
    var allowSystemVolumeToChange : Bool = false {
        willSet {
            endObserving()
        }
        didSet {
            beginObserving()
        }
    }
    
    /*!
     * @property enabled
     * @abstract
     * toggles whether the app will respond to system volume buttons
     * @discussion
     * if enabled, onVolumeButtonPressed() that was passed into the intializer will be called
     */
    var enabled : Bool = true {
        willSet {
            if newValue {
                beginObserving()
            } else {
                endObserving()
            }
        }
    }
    
    init(withVolumeView volumeView: MPVolumeView!, onVolumeButtonPressed: @escaping ((SystemVolumeButtonEvent) -> Void)) {
        _onVolumeButtonPressed = onVolumeButtonPressed
        _volumeView = volumeView
        super.init()
        
        _volumeView?.showsRouteButton = false
        _volumeView?.frame = CGRect.zero
        //setting the volumeView barely visible because the system volume UI will show up if it's completely hidden
        _volumeView?.alpha = 0.01
    }
    
    func beginObserving() {
        guard _observing == false else {
            LogWarn("Attempt to observe more than one \(type(of: self))")
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationActiveChanged(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        if allowSystemVolumeToChange {
            NotificationCenter.default.addObserver(self, selector: #selector(onVolumeChanged(_:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        } else {
            AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: &_kvoContextOutputVolume)

        }
        _priorVolume = AVAudioSession.sharedInstance().outputVolume
        _observing = true
    }
    
    func endObserving() {
        guard _observing == true else {
            return
        }
        
        NotificationCenter.default.removeObserver(self)
        
        if allowSystemVolumeToChange == false {
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume", context:  &_kvoContextOutputVolume)
        }
        _observing = false
    }
    
    @objc fileprivate func onVolumeChanged(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        
        guard
            let volumeChangeType = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
            let volumeChange = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? NSNumber, volumeChangeType == "ExplicitVolumeChange"
        else {
            LogWarn("Ignoring incompatable \(userInfo)")
            return
        }
        
        let newVolume = volumeChange.floatValue
        handleVolumeChanged(newVolume)
    }
    
    @objc fileprivate func onApplicationActiveChanged(_ notification: Notification) {
        switch notification.name {
        case NSNotification.Name.UIApplicationDidBecomeActive:
            _priorVolume = AVAudioSession.sharedInstance().outputVolume
        default: break
        }
    }
    
    fileprivate func handleVolumeChanged(_ newVolume: Float) {
        var volumeButtonEvent : SystemVolumeButtonEvent?
        
        defer {
            if let volumeButtonEvent = volumeButtonEvent {
                LogVerbose("\(volumeButtonEvent). Current Volume: \(newVolume). Previous Volume: \(_priorVolume)")

                if allowSystemVolumeToChange {
                    _priorVolume = newVolume
                } else {
                    changeSystemVolume(_priorVolume)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?._onVolumeButtonPressed(volumeButtonEvent)
                }
            } else {
                if allowSystemVolumeToChange {
                    //ignore this error when system volume is being overridden, this is the desired behavior
                    LogError("Not sure which volume button was pressed. new \(newVolume). initial \(_priorVolume)")
                }
            }
        }
        
        if newVolume > _priorVolume {
            volumeButtonEvent = .up
        } else if newVolume < _priorVolume {
            volumeButtonEvent = .down
        }
    }
    
    fileprivate func changeSystemVolume(_ volume: Float) {
        
        guard let volumeView = _volumeView else { return }
        
        for subview in volumeView.subviews {
            
            if subview.description.range(of: "MPVolumeSlider") != nil {
                if let slider = subview as? UISlider {
                    DispatchQueue.main.async { [weak slider = slider] in
                        slider?.value = volume
                    }
                } 
                break
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      
        if context == &(_kvoContextOutputVolume) {
            guard let newVolume : Float = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue else {
                return
            }
            handleVolumeChanged(newVolume)

        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)

        }
    }
}
