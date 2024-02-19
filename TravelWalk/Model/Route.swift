import Foundation
import MapKit
import CoreLocation

class Route: Codable {

    var routeSteps: [RouteStep]
    var startLabel = ""
    var finishLabel = ""
    var currentRouteSteps: [RouteStep]?
    var startLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var finishLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var distance: CLLocationDistance = CLLocationDistance()
    var polyline: ColoredPolyline = ColoredPolyline()
    var util = Util()

    static func getLocation(steps: [RouteStep]?, isFirst: Bool) throws -> CLLocationCoordinate2D {
        var coordinate = CLLocationCoordinate2D()
        if let step = isFirst ? steps?.first : steps?.last {
            if step.polyline.pointCount < 1 {
                throw TravelError.invalidRoute
            }
            let index = isFirst ? 0 : step.polyline.pointCount - 1
            step.polyline.getCoordinates(&coordinate, range: NSRange(location: index, length: 1))
        } else {
            throw TravelError.invalidRoute
        }
        return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    static func getStartLocation(steps: [RouteStep]?) throws -> CLLocationCoordinate2D {
        return try Route.getLocation(steps: steps, isFirst: true)
    }

    static func getFinishLocation(steps: [RouteStep]?) throws -> (location: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let location = try Route.getLocation(steps: steps, isFirst: false)
        var distance: CLLocationDistance = 0
        for step in steps! {
            distance += step.distance
        }
        return (location: location, distance: distance)
    }

    static func createPolyline(routeSteps: [RouteStep]) -> ColoredPolyline {
        if routeSteps.isEmpty {
            return ColoredPolyline()
        }
        var polylineCoords: [CLLocationCoordinate2D] = []
        let firstStep = routeSteps.first
        var coords = CLLocationCoordinate2D()
        firstStep?.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        polylineCoords.append(coords)

        for step in routeSteps {
            step.polyline.getCoordinates(&coords, range: NSRange(location: step.polyline.pointCount - 1, length: 1))
            polylineCoords.append(coords)
        }
        let polyline = ColoredPolyline(coordinates: polylineCoords, count: polylineCoords.count, color: UIColor.green)

        return polyline
    }
    
    init(routeSteps: [RouteStep], startLabel: String, finishLabel: String) throws {
        if routeSteps.isEmpty {
            throw TravelError.invalidRoute
        }
        self.routeSteps = routeSteps
        self.startLabel = startLabel
        self.finishLabel = finishLabel

        try self.initialize(initialRouteSteps: self.routeSteps)
    }
    
    func initialize(initialRouteSteps: [RouteStep]) throws {
        self.currentRouteSteps = nil
        self.startLocation = try Route.getStartLocation(steps: initialRouteSteps)
        let result = try Route.getFinishLocation(steps: initialRouteSteps)
        self.finishLocation = result.location
        self.distance = result.distance
        self.polyline = Route.createPolyline(routeSteps: initialRouteSteps)
    }

    func updateCurrentRouteSteps(currentDistance: CLLocationDistance) throws {
        for step in self.routeSteps {
            step.polyline.color = AnnotationColor.yet
        }
        self.currentRouteSteps = nil

        if currentDistance <= 0 {
            return
        }
        if currentDistance >= self.distance {
            for step in self.routeSteps {
                step.polyline.color = AnnotationColor.done
            }
            return
        }

        var newCurrentRouteSteps: [RouteStep] = []
        var previousStepDistance: CLLocationDistance = 0

        for step in self.routeSteps {
            if currentDistance <= (previousStepDistance + step.distance) {
                let newStepDistance = currentDistance - previousStepDistance
                let unitDistance = newStepDistance / step.distance
                var previousPolylineUnitDistance: CGFloat = 0
                var startCoords = CLLocationCoordinate2D()
                step.polyline.getCoordinates(&startCoords, range: NSRange(location: 0, length: 1))
                var newRouteStepCoords = [startCoords]

                for index in 1...step.polyline.pointCount {
                    let polylineUnitDistance = step.polyline.location(atPointIndex: index)
                    var polylineCoords = CLLocationCoordinate2D()
                    step.polyline.getCoordinates(&polylineCoords, range: NSRange(location: index, length: 1))
                    if unitDistance <= polylineUnitDistance {
                        let currentPolylineUnitDistance = (unitDistance - previousPolylineUnitDistance) / (polylineUnitDistance - previousPolylineUnitDistance)
                        let previousNewRouteStepCoords = newRouteStepCoords[index - 1]
                        let latitude = previousNewRouteStepCoords.latitude + (polylineCoords.latitude - previousNewRouteStepCoords.latitude) * currentPolylineUnitDistance
                        let longitude = previousNewRouteStepCoords.longitude + (polylineCoords.longitude - previousNewRouteStepCoords.longitude) * currentPolylineUnitDistance
                        newRouteStepCoords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        break
                    } else {
                        newRouteStepCoords.append(polylineCoords)
                        previousPolylineUnitDistance = polylineUnitDistance
                    }
                }

                let polyline = ColoredPolyline(
                    coordinates: newRouteStepCoords, count: newRouteStepCoords.count, color: AnnotationColor.done)
                let newRouteStep = RouteStep(distance: newStepDistance, polyline: polyline)
                newCurrentRouteSteps.append(newRouteStep)

                break
                
            } else {
                step.polyline.color = AnnotationColor.done
                newCurrentRouteSteps.append(step)
                previousStepDistance += step.distance
            }
        }
        if newCurrentRouteSteps.count > 0 {
            self.currentRouteSteps = newCurrentRouteSteps
        }
    }
    
    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case routeSteps
        case startLabel
        case finishLabel
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.routeSteps, forKey: .routeSteps)
        try container.encode(self.startLabel, forKey: .startLabel)
        try container.encode(self.finishLabel, forKey: .finishLabel)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.routeSteps = try container.decode([RouteStep].self, forKey: .routeSteps)
        self.startLabel = try container.decode(String.self, forKey: .startLabel)
        self.finishLabel = try container.decode(String.self, forKey: .finishLabel)
        try self.initialize(initialRouteSteps: self.routeSteps)
    }

}

