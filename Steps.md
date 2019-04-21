# Google-Maps-workshop
This repo. contains the source code and slides of the workshop. All materials are taken from [Google Maps iOS SDK Tutorial: Getting Started](https://www.raywenderlich.com/197-google-maps-ios-sdk-tutorial-getting-started).

## Step 1 Use Google Maps iOS SDK
# Creating API Keys
- Login with your Google account in to the [Google Developers Console](https://console.developers.google.com/).

# Adding the SDK
- Open `Podfile` and add the following, right above `end`:

`pod 'GoogleMaps'`

- Open Terminal and navigate to the directory that contains your Feed Me.

- Then, run the following command:

```bash
$ pod install
```

- Open `AppDelegate.swift` and replace `"your-Google-API-key"` with your Google API key.

## Step 2 Get the user’s current location
- Open `MapViewController.swift` and add the following property:
```swift
private let locationManager = CLLocationManager()
```

- Next, find `viewDidLoad()` and add these two lines to the bottom:
```swift
locationManager.delegate = self
locationManager.requestWhenInUseAuthorization()
mapView.delegate = self
```

- Add the following key to `Info.plist`:
`Privacy – Location When In Use Usage Description`

- Choose `String` for the type, and enter the following text as the value:
`By accessing your location, this app can find you a good place to eat.`

- Make `MapViewController` conform to the `CLLocationManagerDelegate` protocol, by adding the following extension to the bottom of `MapViewController.Swift`:
```swift
// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

    guard status == .authorizedWhenInUse else {
      return
    }

    locationManager.startUpdatingLocation()

    mapView.isMyLocationEnabled = true
    mapView.settings.myLocationButton = true
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else {
      return
    }

    mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)

    locationManager.stopUpdatingLocation()
  }
}
```

# Implementing Geocoding
- Add the method below to `MapViewController.swift`:
```swift
private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {

    let geocoder = GMSGeocoder()

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
        self.pinImageVerticalConstraint.constant = ((labelHeight - self.view.safeAreaInsets.top) * 0.5)
        self.view.layoutIfNeeded()
      }
    }
  }
```
- Add another extension to the bottom of MapViewController.swift as follows:
```swift
// MARK: - GMSMapViewDelegate
extension MapViewController: GMSMapViewDelegate {

  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
  reverseGeocodeCoordinate(position.target)
  }

  // This method is called every time the map starts to move.
  func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
    // You call the lock() on the addressLabel to give it a loading animation.
    addressLabel.lock()

    if (gesture) {
      mapCenterPinImage.fadeIn(0.25)
      mapView.selectedMarker = nil
    }
  }
}
```

## Step 3 Search for nearby places
- Create a subclass of `GMSMarker`:
```swift
import UIKit
import GoogleMaps

class PlaceMarker: GMSMarker {

  let place: GooglePlace

  init(place: GooglePlace) {
    self.place = place
    super.init()

    position = place.coordinate
    icon = UIImage(named: place.placeType+"_pin")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = .pop
  }
}
```

- Add two more properties to `MapViewController.swift` as follows:
```swift
private let dataProvider = GoogleDataProvider()
private let searchRadius: Double = 1000
```

- Add the following method to `MapViewController.swift`:
```swift
private func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D) {

  mapView.clear()

  dataProvider.fetchPlacesNearCoordinate(coordinate, radius:searchRadius, types: searchedTypes) { places in
    places.forEach {

      let marker = PlaceMarker(place: $0)
      marker.map = self.mapView
    }
  }
}
```

- Search for `locationManager(_:didUpdateLocations:)` and add the following line of code at the end:
```swift
fetchNearbyPlaces(coordinate: location.coordinate)
```

- Search for `typesController(_:didSelectTypes:)` and add the following line of code to the end:
```swift
fetchNearbyPlaces(coordinate: mapView.camera.target)
```

- Add refresh button to `MapViewController.swift`:
```swift
@IBAction func refreshPlaces(_ sender: Any) {
    fetchNearbyPlaces(coordinate: mapView.camera.target)
}
```

- Add the following method to the `GMSMapViewDelegate` extension in `MapViewController.swift`:
```swift
func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {

  guard let placeMarker = marker as? PlaceMarker else {
    return nil
  }

  guard let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView else {
    return nil
  }

  infoView.nameLabel.text = placeMarker.place.name

  if let photo = placeMarker.place.photo {
    infoView.placePhoto.image = photo
  } else {
    infoView.placePhoto.image = UIImage(named: "generic")
  }

  return infoView
}
```

- Add the following method to the `GMSMapViewDelegate` extension:
```swift
func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
  mapCenterPinImage.fadeOut(0.25)
  return false
}
```

- Add the following method to the GMSMapViewDelegate extension:
```swift
func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
  mapCenterPinImage.fadeIn(0.25)
  mapView.selectedMarker = nil
  return false
}
```
