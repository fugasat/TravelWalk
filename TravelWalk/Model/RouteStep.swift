import MapKit


class ColoredPolyline: MKPolyline {

    var color: UIColor = AnnotationColor.yet

    override init() {
        super.init()
    }
    
    convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int, color: UIColor) {
        self.init(coordinates: coords, count: count)
        self.color = color
    }

    convenience init(polyline: MKPolyline, color: UIColor) {
        let coordinates = RouteStep.getCoordinates(polyline: polyline)
        self.init(coordinates: coordinates, count: coordinates.count, color: color)
    }
}

class RouteStep: Codable {

    var distance: CLLocationDistance
    var polyline: ColoredPolyline
    
    init(distance: CLLocationDistance, polyline: ColoredPolyline) {
        self.distance = distance
        self.polyline = polyline
    }
    
    func getCoordinates() -> [CLLocationCoordinate2D] {
        return RouteStep.getCoordinates(polyline: self.polyline)
    }

    static func getCoordinates(polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var polylineCoords = CLLocationCoordinate2D()
        for index in 0..<polyline.pointCount {
            polyline.getCoordinates(&polylineCoords, range: NSRange(location: index, length: 1))
            coordinates.append(polylineCoords)
        }
        return coordinates
    }
    
    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case distance
        case polyline
        case color
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.distance, forKey: .distance)
        
        let coordinates: [CLLocationCoordinate2D] = self.getCoordinates()
        let encodedCoordinates = coordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        try container.encode(encodedCoordinates, forKey: .polyline)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.distance = try container.decode(CLLocationDistance.self, forKey: .distance)

        let encodedCoordinates = try container.decode([[String: Double]].self, forKey: .polyline)
        let coordinates = encodedCoordinates.map { CLLocationCoordinate2D(latitude: $0["latitude"]!, longitude: $0["longitude"]!) }
        self.polyline = ColoredPolyline(coordinates: coordinates, count: coordinates.count, color: AnnotationColor.yet)
    }

}
