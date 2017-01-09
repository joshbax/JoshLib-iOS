import Foundation
import CoreLocation


public class LocationManager {
    
    fileprivate let _locationManager : CLLocationManager = CLLocationManager()
    fileprivate var _managerDelegate : LocationManagerDelegate! = LocationManagerDelegate()


    init() {
        _locationManager.delegate = _managerDelegate
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        _locationManager.distanceFilter = 50
        _locationManager.headingFilter = 5
        
    }
    
    deinit {
        _managerDelegate = nil
    }
    
    public var currentData : LocationData {
            return self._managerDelegate.locationData
    }
    
    public func requestInUseAuthorization(_ handler: ((CLAuthorizationStatus) -> Void)?) {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            self._managerDelegate.authorizationHandler = handler
            _locationManager.requestWhenInUseAuthorization()
        } else {
            handler?(authStatus)
        }
    }
    
    public func startMonitoring() {
        _locationManager.startUpdatingLocation()
        _locationManager.startUpdatingHeading()
    }
    
    public func stopMonitoring() {
        _locationManager.stopUpdatingLocation()
        _locationManager.stopUpdatingHeading()
    }


    public struct LocationData {
        var location : CLLocation
        var heading : CLHeading
        
        var isValid : Bool { return CLLocationCoordinate2DIsValid(location.coordinate) }
        
        init(location: CLLocation?, heading: CLHeading?) {
            self.location = (location?.copy() as? CLLocation) ??
                            CLLocation(coordinate: kCLLocationCoordinate2DInvalid, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: -1, timestamp: Date())
            
            self.heading = (heading?.copy() as? CLHeading) ?? CLHeading()
        }
    }

    
    fileprivate class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
        
        var authorizationHandler : ((CLAuthorizationStatus) -> Void)?
        var locationUpdateHandler : ((LocationData) -> Void)?
        
        var location : CLLocation? {
            didSet {
                guard self.location != nil else { return }
                locationUpdateHandler?(self.locationData)
            }
        }
        
        var heading : CLHeading? {
            didSet {
                guard self.location != nil else { return }
                locationUpdateHandler?(self.locationData)
            }
        }
        
        
        var locationData : LocationData {
            return LocationData(location: self.location  , heading: self.heading)
        }
        
        deinit {
            authorizationHandler = nil
            locationUpdateHandler = nil
        }
        
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            authorizationHandler?(status)
            authorizationHandler = nil
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            location = locations.last
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            heading = newHeading
        }
    }

}
