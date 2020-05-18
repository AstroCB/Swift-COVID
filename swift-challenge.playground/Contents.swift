//: Swift Student Challenge submission for Cameron Bernhardt

import MapKit
import AppKit
import PlaygroundSupport

// MARK:- Constants

// Map data
let US_CENTER = CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129)
let US_SPAN = MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 0)
let MAP_SIZE = (w: CGFloat(700), h: CGFloat(600))

// UI elements
let BTN_SZ: CGFloat = 30
let Y_BASELINE: CGFloat = 35
let BUFFER: CGFloat = 10

// Earliest data: Jan 22, 2020
let START = Date(timeIntervalSince1970: 1579712400)
// Most recent data: May 17, 2020
let END = Date(timeIntervalSince1970: 1589731200)

// Tuning parameters for opacity
let OFFSET: CGFloat = 0.05
let MULTIPLIER: CGFloat = 450

// MARK:- Deserialized representations of JSON data for states, COVID data, pop
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

struct DataPoint: Codable {
    var positive: Int?
    var negative: Int?
    var pending: Int?
    var hospitalizedCurrently: Int?
    var hospitalizedCumulative: Int?
    var inIcuCurrently: Int?
    var inIcuCumulative: Int?
    var onVentilatorCurrently: Int?
    var onVentilatorCumulative: Int?
    var recovered: Int?
    var hash: String?
    var lastModified: String?
    var death: Int?
    var hospitalized: Int?
    var total: Int?
    var totalTestResults: Int?
    var posNeg: Int?
    var notes: String?
    var date: Int
    var deathIncrease: Int?
    var hospitalizedIncrease: Int?
    var negativeIncrease: Int?
    var positiveIncrease: Int?
    var totalTestResultsIncrease: Int?
    var lastUpdateEt: String?
    var dataQualityGrade: String?
    var state: String
    var dateChecked: String?
    var fips: String?
    
    func matches(date other: Date) -> Bool {
        let otherStr = dataDateFormatter.string(from: other)
        
        return "\(date)" == otherStr
    }
}

typealias CovidData = [String : [DataPoint]]
typealias PopulationData = [String : Int]

// MARK:- Date-related globals for parsing
let dataDateFormatter: DateFormatter = ({
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    // Dates look like 20200517 (in EST)
    formatter.dateFormat = "yyyyMMdd"
    formatter.timeZone = TimeZone(abbreviation: "EST")
    return formatter
})()
let cal: Calendar = .current

func getString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    
    return formatter.string(from: date)
}


// MARK:- MapView delegate and auxiliary funcs
var polyStates: [MKPolygon : (String, Date)] = [:]

func getAlphaComponent(for state: String, on date: Date) -> CGFloat? {
    if let stateData = covidData[state],
        let pt = stateData.first(where: { $0.matches(date: date) }) {
        
        let positive = pt.positive ?? 0
        let recovered = pt.recovered ?? 0
        let pop = popData[state] ?? 1
        let ratio = CGFloat(positive - recovered) / CGFloat(pop)
        
        return OFFSET + (ratio * MULTIPLIER)
    }
    return nil
}

class MapDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolygon,
            let (state, date) = polyStates[poly] {
            
            let alpha = getAlphaComponent(for: state, on: date) ?? 0
            
            let renderer = MKPolygonRenderer(overlay: poly)
            renderer.lineWidth = 1
            renderer.strokeColor = .red
            renderer.fillColor = NSColor.red.withAlphaComponent(alpha)
            return renderer
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK:- Parse and store COVID and population data
var covidData: CovidData = [:]
if let filePath = Bundle.main.path(forResource: "covid", ofType: "json"),
    let parsedData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
    
    let decoder = JSONDecoder()
    if let data = try? decoder.decode(CovidData.self,
                                      from: parsedData) {
        covidData = data
    }
}

var popData: PopulationData = [:]
if let filePath = Bundle.main.path(forResource: "population", ofType: "json"),
    let parsedData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
    
    let decoder = JSONDecoder()
    if let data = try? decoder.decode(PopulationData.self,
                                      from: parsedData) {
        popData = data
    }
}

// MARK:- Parse and store border data
var states: [State] = []
if let filePath = Bundle.main.path(forResource: "borders", ofType: "json"),
    let borderData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
    
    let decoder = JSONDecoder()
    if let readStates = try? decoder.decode([State].self, from: borderData) {
        states = readStates
    }
}

// MARK:- Set up the map
let mapView = MKMapView(frame: CGRect(x: 0, y: 0,
                                      width: MAP_SIZE.w, height: MAP_SIZE.h))
let delegate = MapDelegate()
mapView.delegate = delegate

var mapRegion = MKCoordinateRegion()
mapRegion.center = US_CENTER
mapRegion.span = US_SPAN
mapView.setRegion(mapRegion, animated: true)

// MARK:- Create overlays and add to the map
for state in states {
    for border in state.borders {
        let coords = border.map { $0.toCL() }
        let poly = MKPolygon(coordinates: coords, count: coords.count)
        polyStates[poly] = (state.state, START)
        mapView.addOverlay(poly)
    }
}

// MARK:- Set up UI element handlers
let numDays = cal.dateComponents([.day], from: START, to: END).day ?? 0

// Some "delegate"-y classes for handling actions in Playgroun
class SliderHandler: NSObject {
    @objc func slid(sender: NSSlider) {
        let days = Int(sender.intValue)
        self.setAlpha(for: days)
        
        if let date = cal.date(byAdding: .day, value: days, to: START) {
            dateLabel.stringValue = getString(from: date)
        }
        
        
        
        if buttonHandler.playing {
            buttonHandler.pause()
        }
    }
    
    func setAlpha(for days: Int) {
        if let date = cal.date(byAdding: .day, value: days, to: START) {
            for overlay in mapView.overlays {
                if let poly = overlay as? MKPolygon,
                    let renderer = mapView.renderer(for: poly) as?
                    MKPolygonRenderer, let (state, _) = polyStates[poly] {
                    
                    let alpha = getAlphaComponent(for: state, on: date) ?? 0
                    renderer.fillColor = NSColor.red.withAlphaComponent(alpha)
                }
            }
        }
    }
}

class ButtonHandler: NSObject {
    var start = NSImage()
    var stop = NSImage()
    var playing: Bool = false
    
    override init() {
        if let arrowUrl = Bundle.main.urlForImageResource("arrow.png"),
            let arrow = NSImage(contentsOf: arrowUrl),
            let boxUrl = Bundle.main.urlForImageResource("box.png"),
            let box = NSImage(contentsOf: boxUrl) {
            start = arrow
            stop = box
        }
        super.init()
    }
    
    @objc func clicked(sender: NSButton) {
        sender.image = playing ? start : stop
        playing = !playing
        
        let day = Int(slider.intValue)
        self.play(from: day, completion: self.pause, first: true)
    }
    
    func pause() {
        self.playing = false
        button.image = self.start
    }
    
    func play(from start: Int, completion: (() -> Void)?, first: Bool = false) {
        var day = start
        
        // Auto-restart if playing from end
        if first && day == numDays {
            day = 0
        }
        
        if day <= numDays && self.playing {
            slider.intValue = Int32(day)
            let date = Calendar.current.date(byAdding: .day,
                                             value: day, to: START) ?? END
            dateLabel.stringValue = getString(from: date)
            slideHandler.setAlpha(for: day)
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                self.play(from: day+1, completion: completion)
            }
        } else {
            completion?()
        }
    }
}


// MARK:- Create and place UI elements
let rightEdge = mapView.frame.maxX

// Date label
let dateLabel = NSTextField(labelWithString: getString(from: START))
let dateX = rightEdge - dateLabel.frame.width - BUFFER
let dateY = Y_BASELINE+BUFFER/2
dateLabel.frame = CGRect(x: dateX, y: dateY, width: BTN_SZ, height: BTN_SZ)
dateLabel.sizeToFit()
mapView.addSubview(dateLabel)

// Play button for automatic slider movement
let buttonHandler = ButtonHandler()
let button = NSButton(image: buttonHandler.start, target: buttonHandler,
                      action: #selector(buttonHandler.clicked(sender:)))

let btnX = dateLabel.frame.minX - BTN_SZ - BUFFER/2
button.frame = CGRect(x: btnX, y: Y_BASELINE, width: BTN_SZ, height: BTN_SZ)
mapView.addSubview(button)

// Date slider
let slideHandler = SliderHandler()
let slider = NSSlider(value: 0, minValue: 0, maxValue: Double(numDays),
                      target: slideHandler,
                      action: #selector(slideHandler.slid(sender:)))
slider.isContinuous = false
let slideW: CGFloat = button.frame.minX - (2 * BUFFER)
slider.frame = CGRect(x: BUFFER, y: Y_BASELINE, width: slideW, height: BTN_SZ)
mapView.addSubview(slider)

// Display the map!
PlaygroundPage.current.liveView = mapView
