import Foundation
import MapKit

class PointAnnotation: MKPointAnnotation {

    var routeIndex = -1
    var label = ""
    var color = AnnotationColor.initial
    var isCurrentLocation = false
    
    init(routeIndex: Int = 1, label: String = "", color: UIColor = AnnotationColor.initial, isCurrentLocation: Bool = false) {
        self.routeIndex = routeIndex
        self.label = label
        self.color = color
        self.isCurrentLocation = isCurrentLocation
    }
    
    init(coordinate: CLLocationCoordinate2D, label: String = "") {
        super.init()
        self.coordinate = coordinate
        self.label = label
    }
    
}
