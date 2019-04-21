//
//  MapViewController.swift
//  Feed Me
//
/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
  
  @IBOutlet private weak var mapCenterPinImage: UIImageView!
  @IBOutlet private weak var pinImageVerticalConstraint: NSLayoutConstraint!
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var addressLabel: UILabel!
  
  // an instantiate of CLLocationManager property named locationManager.
  private let locationManager = CLLocationManager()
  var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // make MapViewController the delegate of locationManager.
    locationManager.delegate = self
    // request access to the user’s location.
    locationManager.requestWhenInUseAuthorization()
    
    mapView.delegate = self
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let navigationController = segue.destination as? UINavigationController,
      let controller = navigationController.topViewController as? TypesTableViewController else {
        return
    }
    controller.selectedTypes = searchedTypes
    controller.delegate = self
  }
  
  private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
    
    // Creates a GMSGeocoder object to turn a latitude and longitude coordinate into a street address.
    let geocoder = GMSGeocoder()
    
    // It verifies there is an address in the response of type GMSAddress. This is a model class for addresses returned by the GMSGeocoder.
    geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
      self.addressLabel.unlock()
      guard let address = response?.firstResult(), let lines = address.lines else {
        return
      }
      
      // Sets the text of the addressLabel to the address returned by the geocoder.
      self.addressLabel.text = lines.joined(separator: "\n")
      
      // padding
      let labelHeight = self.addressLabel.intrinsicContentSize.height
      self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0,
                                          bottom: labelHeight, right: 0)
      
      // animate the changes in the label.
      UIView.animate(withDuration: 0.25) {
        //2
        self.pinImageVerticalConstraint.constant = ((labelHeight - self.view.safeAreaInsets.top) * 0.5)
        self.view.layoutIfNeeded()
      }
    }
  }
}

// MARK: - TypesTableViewControllerDelegate
extension MapViewController: TypesTableViewControllerDelegate {
  func typesController(_ controller: TypesTableViewController, didSelectTypes types: [String]) {
    searchedTypes = controller.selectedTypes.sorted()
    dismiss(animated: true)
  }
}

// MARK: - CLLocationManagerDelegate
// MapViewController conforms to the CLLocationManagerDelegate protocol.
extension MapViewController: CLLocationManagerDelegate {
  // is called when the user grants or revokes location permissions.
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // Here you verify the user has granted you permission while the app is in use.
    guard status == .authorizedWhenInUse else {
      return
    }
    // Once permissions have been established, ask the location manager for updates on the user’s location.
    locationManager.startUpdatingLocation()
    
    // draws a light blue dot where the user is located.
    mapView.isMyLocationEnabled = true
    // adds a button to the map that, when tapped, centers the map on the user’s location.
    mapView.settings.myLocationButton = true
  }
  
  // executes when the location manager receives new location data.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else {
      return
    }
    
    // This updates the map’s camera to center around the user’s current location.
    mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
    
    // you don’t want to follow a user around as their initial location is enough for you to work with.
    locationManager.stopUpdatingLocation()
  }
}

// MARK: - GMSMapViewDelegate
extension MapViewController: GMSMapViewDelegate {
  
  // call this method every time the user changes their position on the map.
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    reverseGeocodeCoordinate(position.target)
  }
  
  // This method is called every time the map starts to move.
  func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
    // You call the lock() on the addressLabel to give it a loading animation.
    addressLabel.lock()
  }
}
