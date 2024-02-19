import Foundation
import MapKit
import CoreLocation

enum TravelError: Error {
    case invalidRoute
}

class Travel: Codable {

    var startDate: Date
    var name: String = "新規"
    var finishedDate = Date()
    var isStop = false
    var routes: [Route] = []
    var currentDistance: CLLocationDistance { // meter
        didSet {
            self.updateCurrentRoute()
            self.updateRemainingDistance()
        }
    }
    var finishDistance: CLLocationDistance = 0 { // meter
        didSet {
            updateRemainingDistance()
        }
    }

    var startLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var finishLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var currentLocation: CLLocationCoordinate2D? = nil
    var remainingDistance: CLLocationDistance = 0 // meter
    var todayDistance: CLLocationDistance = 0 // meter

    static func getLocation(routes: [Route]?, isFirst: Bool) throws -> CLLocationCoordinate2D {
        if let route = isFirst ? routes?.first : routes?.last {
            let coordinate = try Route.getLocation(steps: route.routeSteps, isFirst: isFirst)
            return coordinate
        } else {
            throw TravelError.invalidRoute
        }
    }

    static func getStartLocation(routes: [Route]?) throws -> CLLocationCoordinate2D {
        return try Travel.getLocation(routes: routes, isFirst: true)
    }

    static func getFinishLocation(routes: [Route]?) throws -> (location: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let location = try Travel.getLocation(routes: routes, isFirst: false)
        var distance: CLLocationDistance = 0
        for route in routes! {
            for step in route.routeSteps {
                distance += step.distance
            }
        }
        return (location: location, distance: distance)
    }

    init(startDate: Date) {
        self.startDate = startDate
        self.currentDistance = 0
    }
    
    init(startDate: Date, routes: [Route], currentDistance: CLLocationDistance) throws {
        self.routes = routes
        self.startDate = startDate
        self.currentDistance = currentDistance

        try self.initialize(routes: self.routes)
    }
    
    func initialize(routes: [Route]) throws {
        if self.hasRoute() {
            self.startLocation = try Travel.getStartLocation(routes: routes)
            let result = try Travel.getFinishLocation(routes: routes)
            self.finishLocation = result.location
            self.finishDistance = result.distance
            self.updateCurrentRoute()
        }
    }
    
    convenience init(startDate: Date, routes: [Route]) throws {
        try self.init(startDate: startDate, routes: routes, currentDistance: 0)
    }
   
    func hasRoute() -> Bool {
        if self.routes.count > 0 {
            return true
        }
        return false
    }
    
    func addRoute(route: Route) throws {
        self.routes.append(route)
        let result = try Travel.getFinishLocation(routes: self.routes)
        self.finishLocation = result.location
        self.finishDistance = result.distance
    }
    
    func isFinish() -> Bool {
        if self.hasRoute() {
            if self.currentDistance >= self.finishDistance {
                return true
            }
        }
        return false
    }

    func updateCurrentRoute() {
        var previousRouteDistance: CLLocationDistance = 0
        for route in self.routes {
            do {
                let divCurrentDistance = currentDistance - previousRouteDistance
                try route.updateCurrentRouteSteps(currentDistance: divCurrentDistance)
            } catch {
                print("error : Travel.updateCurrentRoute()")
            }
            previousRouteDistance += route.distance
        }
    }
    
    func createTodayRoute() -> ColoredPolyline? {
        self.currentLocation = nil
        if self.currentDistance <= 0 {
            return nil
        }
        var currentLocation: CLLocationCoordinate2D? = nil

        var startDistance: CLLocationDistance = self.currentDistance - self.todayDistance
        if startDistance < 0 {
            startDistance = 0
        }

        var newRouteStepCoords: [CLLocationCoordinate2D] = []
        var checkedDistance: CLLocationDistance = 0
        for route in self.routes {
            let checkRouteSteps: [RouteStep]
            var currentRouteStepsChecked = false
            if let currentRouteSteps = route.currentRouteSteps {
                checkRouteSteps = currentRouteSteps
                currentLocation = currentRouteSteps.last?.getCoordinates().last
                currentRouteStepsChecked = true
            } else {
                checkRouteSteps = route.routeSteps
            }

            for step in checkRouteSteps {
                checkedDistance += step.distance
                if startDistance < checkedDistance {
                    let checkedDivDistance = checkedDistance - startDistance
                    let stepUnitDistance = 1 - (checkedDivDistance / step.distance)
                    var previousPolylineCoords: CLLocationCoordinate2D? = nil
                    var previousPolylineUnitDistance: CLLocationDistance = 0

                    for index in 0..<step.polyline.pointCount {
                        var polylineCoords = CLLocationCoordinate2D()
                        step.polyline.getCoordinates(&polylineCoords, range: NSRange(location: index, length: 1))
                        let polylineUnitDistance = step.polyline.location(atPointIndex: index)

                        if index > 0 {
                            if newRouteStepCoords.count == 0 {
                                if stepUnitDistance <= polylineUnitDistance {
                                    let unitDistanceRate = (stepUnitDistance - previousPolylineUnitDistance) / (polylineUnitDistance - previousPolylineUnitDistance)

                                    let latitude = previousPolylineCoords!.latitude + (polylineCoords.latitude - previousPolylineCoords!.latitude) * unitDistanceRate
                                    let longitude = previousPolylineCoords!.longitude + (polylineCoords.longitude - previousPolylineCoords!.longitude) * unitDistanceRate
                                    let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    newRouteStepCoords.append(coord)
                                    newRouteStepCoords.append(polylineCoords)
                                }
                            } else {
                                newRouteStepCoords.append(polylineCoords)
                            }
                        }
                        previousPolylineCoords = polylineCoords
                        previousPolylineUnitDistance += polylineUnitDistance
                    }
                }
            }
            if currentRouteStepsChecked {
                break
            }
        }
        let polyline = ColoredPolyline(
            coordinates: newRouteStepCoords, count: newRouteStepCoords.count, color: AnnotationColor.today)
        if let newCoords = newRouteStepCoords.last {
            self.currentLocation = newCoords
        } else {
            self.currentLocation = currentLocation
        }
        return polyline
    }
    
    func updateRemainingDistance() {
        self.remainingDistance = self.finishDistance - self.currentDistance
        if self.remainingDistance < 0 {
            self.remainingDistance = 0
        }
    }
    
    func getCompletedAnnotationIndex() -> Int {
        if self.hasRoute() {
            if self.currentDistance <= 0 {
                return -1
            }
            var distance: CLLocationDistance = 0
            var currentIndex = 0
            for route in self.routes {
                distance += route.distance
                if self.currentDistance < distance {
                    return currentIndex
                }
                currentIndex += 1
            }
            return currentIndex
        } else {
            return -1
        }
    }
    
    func updateInformation() throws {
        if self.hasRoute() {
            self.startLocation = try Travel.getStartLocation(routes: self.routes)
            let finishLocationAndDistance = try Travel.getFinishLocation(routes: self.routes)
            self.finishLocation = finishLocationAndDistance.location
            self.finishDistance = finishLocationAndDistance.distance
            self.updateCurrentRoute()
        }
    }
    
    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case name
        case routes
        case startDate
        case finishedDate
        case currentDistance
        case isStop
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.routes, forKey: .routes)
        try container.encode(self.startDate, forKey: .startDate)
        try container.encode(self.finishedDate, forKey: .finishedDate)
        try container.encode(self.currentDistance, forKey: .currentDistance)
        try container.encode(self.isStop, forKey: .isStop)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(CodingKeys.name) {
            self.name = try container.decode(String.self, forKey: .name)
        } else {
            self.name = ""
        }
        if container.contains(CodingKeys.routes) {
            self.routes = try container.decode([Route].self, forKey: .routes)
        } else {
            self.routes = []
        }
        if container.contains(CodingKeys.startDate) {
            self.startDate = try container.decode(Date.self, forKey: .startDate)
        } else {
            self.startDate = Date()
        }
        if container.contains(CodingKeys.finishedDate) {
            self.finishedDate = try container.decode(Date.self, forKey: .finishedDate)
        } else {
            self.finishedDate = Date()
        }
        if container.contains(CodingKeys.currentDistance) {
            self.currentDistance = try container.decode(CLLocationDistance.self, forKey: .currentDistance)
        } else {
            self.currentDistance = 0
        }
        if container.contains(CodingKeys.isStop) {
            self.isStop = try container.decode(Bool.self, forKey: .isStop)
        } else {
            self.isStop = false
        }

        try self.initialize(routes: self.routes)
    }

    func getFinishedTravelDisplayLabel() -> String {
        var status: String
        if self.hasRoute() == false {
            status = "(準備中)"
        } else if self.isStop == false {
            status = "(実行中)"
        } else if self.isFinish() {
            status = "(完了)"
        } else {
            status = "(中断)"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let label = "\(dateFormatter.string(from: self.startDate)) \(self.name) \(status)"
        return label
    }
}

