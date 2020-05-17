//: A MapKit based Playground

import MapKit
import AppKit
import PlaygroundSupport

// MARK:- Deserialized representation of JSON data
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

// MARK:- MapView classes and auxiliary funcs
var polyStates: [MKPolygon : String] = [:]

class StateOverlayRenderer: MKOverlayRenderer {
    var image: NSImage
    
    init(overlay: MKPolygon, image: NSImage) {
        self.image = image
        super.init(overlay: overlay)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale,
                       in context: CGContext) {
        
        let rect = self.rect(for: overlay.boundingMapRect)
        var nsRect = NSRectFromCGRect(rect)
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        if let img = self.image.cgImage(forProposedRect: &nsRect,
                                     context: nsContext,
                                     hints: nil) {
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -rect.height)
            context.draw(img, in: rect)
        }
    }
}

func getImage(for state: String) -> NSImage? {
    if let url = Bundle.main.url(forResource: state, withExtension: "png",
                                 subdirectory: "flags") {
        return NSImage(contentsOf: url)
    }
    return nil
}

class MapDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolygon, let state = polyStates[poly] {
            let img = getImage(for: state) ?? NSImage()
            let renderer = StateOverlayRenderer(overlay: poly, image: img)
//            renderer.lineWidth = 1
//            renderer.strokeColor = .red
//            renderer.fillColor = NSColor(patternImage: img)
            
            return renderer
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}


// MARK:- Set up the map
let US_CENTER = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
let US_SPAN = MKCoordinateSpan(latitudeDelta: 57, longitudeDelta: 30)
let MAP_SIZE = 800

let mapView = MKMapView(frame: CGRect(x: 0, y: 0,
                                      width: MAP_SIZE, height: MAP_SIZE))
let delegate = MapDelegate()
mapView.delegate = delegate

var mapRegion = MKCoordinateRegion()
mapRegion.center = US_CENTER
mapRegion.span = US_SPAN
mapView.setRegion(mapRegion, animated: true)

// MARK:- Read border data from disk
var states: [State] = []
if let filePath = Bundle.main.path(forResource: "borders", ofType: "json"),
    let borderData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
    
    let decoder = JSONDecoder()
    if let readStates = try? decoder.decode([State].self, from: borderData) {
        states = readStates
    }
}

// MARK:- Create overlays and show the map
for state in states {
    for border in state.borders {
        let coords = border.map { $0.toCL() }
        let poly = MKPolygon(coordinates: coords, count: coords.count)
        polyStates[poly] = state.state
        mapView.addOverlay(poly)
    }
}

// Add the created mapView to our Playground Live View
PlaygroundPage.current.liveView = mapView
