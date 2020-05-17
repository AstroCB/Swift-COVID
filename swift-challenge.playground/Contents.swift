//: A MapKit based Playground

import MapKit
import AppKit
import PlaygroundSupport

//class StateOverlay: NSObject, MKOverlay {
//    var name: String
//    var coordinate: CLLocationCoordinate2D
//    var boundingMapRect: MKMapRect
//    
//    init(name: String) {
//        self.name = name
//        
//        
//    }
//}

struct Coord: Codable {
    var lat: Float
    var lng: Float
    
    func toCL() -> CLLocationCoordinate2D {
        let clLat = CLLocationDegrees(exactly: lat) ?? CLLocationDegrees()
        let clLng = CLLocationDegrees(exactly: lng) ?? CLLocationDegrees()
        
        return CLLocationCoordinate2D(latitude: clLat, longitude: clLng)
    }
}

typealias Border = [Coord]

struct State: Codable {
    var state: String
    var borders: [Border]
}

class MapDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(overlay: poly)
            renderer.lineWidth = 3
            renderer.strokeColor = .red
            renderer.fillColor = NSColor.red.withAlphaComponent(0.3)
            
            return renderer
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

let US_CENTER = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
let US_SPAN = MKCoordinateSpan(latitudeDelta: 57, longitudeDelta: 30)
let MAP_SIZE = 800

// Set up map
let mapView = MKMapView(frame: CGRect(x: 0, y: 0,
                                      width: MAP_SIZE, height: MAP_SIZE))
let delegate = MapDelegate()
mapView.delegate = delegate

var mapRegion = MKCoordinateRegion()
mapRegion.center = US_CENTER
mapRegion.span = US_SPAN
mapView.setRegion(mapRegion, animated: true)

// Read border data
var states: [State] = []
if let filePath = Bundle.main.path(forResource: "borders", ofType: "json"),
    let borderData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
    
    let decoder = JSONDecoder()
    if let readStates = try? decoder.decode([State].self, from: borderData) {
        states = readStates
    }
}

for state in states {
    for border in state.borders {
        let coords = border.map { $0.toCL() }
        let poly = MKPolygon(coordinates: coords, count: coords.count)
        mapView.addOverlay(poly)
    }
}

// Add the created mapView to our Playground Live View
PlaygroundPage.current.liveView = mapView
