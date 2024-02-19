import Foundation
import MapKit.MKAnnotation

enum AnnotationSetError: Error {
    case annotationNotFound
    case mismatchAnnotationSetAndTravel
}

class AnnotationSet {

    var travel = Travel(startDate: Date())
    var annotations: [PointAnnotation] = []
    var util = Util()

    init() {
    }
    
    // MARK: Annotation操作

    func createSimpleRoute(annotationStart: PointAnnotation, annotationFinish: PointAnnotation) throws -> RouteUpdated {
        let locationStart = CLLocation(latitude: annotationStart.coordinate.latitude,
                                       longitude: annotationStart.coordinate.longitude)
        let locationFinish = CLLocation(latitude: annotationFinish.coordinate.latitude,
                                        longitude: annotationFinish.coordinate.longitude)
        let distance = locationStart.distance(from: locationFinish)
        
        let polylineCoords = [annotationStart.coordinate, annotationFinish.coordinate]
        let polyline = ColoredPolyline(coordinates: polylineCoords, count: polylineCoords.count, color: AnnotationColor.initial)
        
        let route = try Route(routeSteps: [RouteStep(distance: distance, polyline: polyline)],
                              startLabel: annotationStart.label, finishLabel: annotationFinish.label)
        let routeUpdated = RouteUpdated(route: route, annotationStart: annotationStart, annotationFinish: annotationFinish)
        return routeUpdated
    }

    private func createRoute(mkRoute: MKRoute, startLabel: String, finishLabel: String) throws -> Route {
        // 経路探索結果からRouteを生成
        var routeSteps: [RouteStep] = []
        for step in mkRoute.steps {
            let polyline = ColoredPolyline(polyline: step.polyline, color: AnnotationColor.yet)
            let routeStep = RouteStep(distance: step.distance, polyline: polyline)
            routeSteps.append(routeStep)
        }
        let route = try Route(routeSteps: routeSteps, startLabel: startLabel, finishLabel: finishLabel)
        return route
    }

    func calculateRoute(annotationStart: PointAnnotation, annotationFinish: PointAnnotation) async throws -> RouteUpdated {
        // 経路探索
        let startPlaceMark = MKPlacemark(coordinate: annotationStart.coordinate)
        let finishPlaceMark = MKPlacemark(coordinate: annotationFinish.coordinate)
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: startPlaceMark)
        directionRequest.destination = MKMapItem(placemark: finishPlaceMark)
        directionRequest.transportType = MKDirectionsTransportType.walking
        let directions = MKDirections(request: directionRequest)
        let response = try await directions.calculate()
        let route = try self.createRoute(
            mkRoute: response.routes[0], startLabel: annotationStart.label, finishLabel: annotationFinish.label)
        return RouteUpdated(route: route, annotationStart: annotationStart, annotationFinish: annotationFinish)
    }
    
    private func updatePreviousRoute(travel: Travel, annotation: PointAnnotation, index: Int) async throws -> RouteUpdatedSet {
        let routeIndex = index - 1
        let previousAnnotation = self.annotations[index - 1]
        let routeUpdatedBefore = RouteUpdated(
            route: travel.routes[routeIndex], annotationStart: previousAnnotation, annotationFinish: annotation)

        let routeUpdatedAfter = try await self.calculateRoute(annotationStart: previousAnnotation, annotationFinish: annotation)
        travel.routes[routeIndex] = routeUpdatedAfter.route

        return RouteUpdatedSet(before: [routeUpdatedBefore], after: [routeUpdatedAfter])
    }
    
    private func updateNextRoute(travel: Travel, annotation: PointAnnotation, index: Int) async throws -> RouteUpdatedSet {
        let routeIndex = index
        let nextAnnotation = self.annotations[index + 1]
        let routeUpdatedBefore = RouteUpdated(
            route: travel.routes[routeIndex], annotationStart: annotation, annotationFinish: nextAnnotation)

        let routeUpdatedAfter = try await self.calculateRoute(annotationStart: annotation, annotationFinish: nextAnnotation)
        travel.routes[routeIndex] = routeUpdatedAfter.route

        return RouteUpdatedSet(before: [routeUpdatedBefore], after: [routeUpdatedAfter])
    }
    
    func getCoordinateRegion() -> MKCoordinateRegion {
        let region = MKCoordinateRegion()
        return region
    }
 
    func resetAnnotationColor() {
        for annotation in self.annotations {
            annotation.color = self.getAnnotationColor(annotation: annotation)
        }
    }
    
    // MARK: Annotation,Travel操作

    func createNewTravel(startDate: Date) {
        self.annotations = []
        let travel = Travel(startDate: startDate)
        self.setTravel(travel: travel)
    }

    func setTravel(travel: Travel) {
        self.travel = travel
        self.annotations = []

        if travel.hasRoute() {
            let annotationStart = PointAnnotation()
            annotationStart.routeIndex = 0
            annotationStart.coordinate = travel.startLocation
            if travel.routes.count > 0 {
                annotationStart.label = travel.routes[0].startLabel
            }
            self.annotations.append(annotationStart)

            // 各Routeの終了地点のみAnnotationに設定する
            for (index, route) in travel.routes.enumerated() {
                let annotationRouteFinish = PointAnnotation()
                annotationRouteFinish.routeIndex = 1 + index
                annotationRouteFinish.coordinate = route.finishLocation
                annotationRouteFinish.label = route.finishLabel
                self.annotations.append(annotationRouteFinish)
            }
        }
    }

    func addAnnotation(annotation: PointAnnotation, isTemporary: Bool) async throws -> RouteUpdatedSet {
        var updatedRoute = RouteUpdatedSet()
        var newRoute: RouteUpdated? = nil
        var annotationStart: PointAnnotation? = nil
        var annotationFinish: PointAnnotation? = nil
        if self.annotations.count > 0 {
            annotationStart = self.annotations.last!
            annotationFinish = annotation
            if isTemporary {
                newRoute = try self.createSimpleRoute(annotationStart: annotationStart!, annotationFinish: annotationFinish!)
            } else {
                newRoute = try await self.calculateRoute(annotationStart: annotationStart!, annotationFinish: annotationFinish!)
            }
            updatedRoute.after.append(newRoute!)
            try self.travel.addRoute(route: newRoute!.route)
            annotation.coordinate = self.travel.finishLocation
        }
        annotation.routeIndex = self.annotations.count
        self.annotations.append(annotation)
        annotation.color = self.getAnnotationColor(annotation: annotation)
        return updatedRoute
    }

    func updateTemporaryAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        var updatedRoute = RouteUpdatedSet()
        if self.travel.hasRoute() {
            if let index = self.annotations.firstIndex(of: annotation) {
                if index == self.annotations.count - 1 {
                    // 最新のAnnotationのみサポート
                    updatedRoute = try await self.updatePreviousRoute(travel: travel, annotation: annotation, index: index)
                }
            }
        }
        return updatedRoute
    }
    
    func updateAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        var updatedRoute = RouteUpdatedSet()
        if !self.annotations.contains(annotation) {
            throw AnnotationSetError.annotationNotFound
        }
        if (self.annotations.count - 1) != self.travel.routes.count {
            throw AnnotationSetError.mismatchAnnotationSetAndTravel
        }
        if let index = self.annotations.firstIndex(of: annotation), self.travel.hasRoute() {
            if index > 0 {
                let routeUpdatedPrevious = try await self.updatePreviousRoute(travel: travel, annotation: annotation, index: index)
                updatedRoute.before += routeUpdatedPrevious.before
                updatedRoute.after += routeUpdatedPrevious.after
            }
            if index < (self.annotations.count - 1) {
                let routeUpdatedNext = try await self.updateNextRoute(travel: travel, annotation: annotation, index: index)
                updatedRoute.before += routeUpdatedNext.before
                updatedRoute.after += routeUpdatedNext.after
            }
        }
        return updatedRoute
    }

    func removeAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        var routeUpdated = RouteUpdatedSet()
        if let removeIndex = self.annotations.firstIndex(of: annotation) {
            if self.travel.hasRoute() {
                if self.annotations.count >= 2 {
                    // 経路を再作成
                    if removeIndex == 0 {
                        // 最初の経路を削除する
                        let routeIndex = 0
                        routeUpdated.before.append(RouteUpdated(route: travel.routes[routeIndex]))
                        travel.routes.remove(at: routeIndex)
                    } else if removeIndex == self.annotations.count - 1 {
                        // 最後の経路を削除する
                        let routeIndex = removeIndex - 1
                        routeUpdated.before.append(RouteUpdated(route: travel.routes[routeIndex]))
                        travel.routes.remove(at: routeIndex)
                    } else {
                        // 削除した地点の前後を結ぶ経路を再作成する
                        let previousAnnotation = self.annotations[removeIndex - 1]
                        let nextAnnotation = self.annotations[removeIndex + 1]
                        let route = try await self.calculateRoute(annotationStart: previousAnnotation, annotationFinish: nextAnnotation)
                        let routeIndex = removeIndex - 1
                        routeUpdated.before.append(RouteUpdated(route: travel.routes[routeIndex]))
                        routeUpdated.before.append(RouteUpdated(route: travel.routes[routeIndex + 1]))
                        routeUpdated.after.append(route)
                        travel.routes.remove(at: routeIndex)
                        travel.routes[routeIndex] = route.route
                    }
                }
            }
            self.annotations.remove(at: removeIndex)
            for (index, annotation) in annotations.enumerated() {
                annotation.routeIndex = index
            }
            if self.annotations.count < 2 {
                self.travel.routes = []
            }
        }
        return routeUpdated
    }
    
    func moveAnnotation(fromIndex: Int, toIndex: Int) async throws {
        if fromIndex == toIndex {
            return
        }
        if fromIndex < 0 || fromIndex >= self.annotations.count {
            return
        }
        if toIndex < 0 || toIndex >= (self.annotations.count + 1) {
            return
        }
        if self.travel.hasRoute() {
            let moveAnnotation = self.annotations[fromIndex]
            self.annotations.remove(at: fromIndex)
            
            if toIndex >= self.annotations.count {
                self.annotations.append(moveAnnotation)
            } else {
                self.annotations.insert(moveAnnotation, at: toIndex)
            }
            for (index, annotation) in annotations.enumerated() {
                annotation.routeIndex = index
            }

            let routeIndexStart = min(fromIndex, toIndex) - 1
            let routeIndexFinish = max(fromIndex, toIndex)
            for index in routeIndexStart ... routeIndexFinish {
                if index < 0 || index >= travel.routes.count {
                    continue
                }
                let annotationStart = self.annotations[index]
                let annotationFinish = self.annotations[index + 1]
                let route = try await self.calculateRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
                travel.routes.insert(route.route, at: index)
                travel.routes.remove(at: index + 1)
            }
        }
    }
    
    func insertAnnotation(index: Int, annotation: PointAnnotation) async throws {
        if index < 0 || index >= self.annotations.count {
            return
        }
        if self.travel.hasRoute() {
            self.annotations.insert(annotation, at: index)
            for (index, annotation) in annotations.enumerated() {
                annotation.routeIndex = index
            }
            if index > 0 {
                // 挿入した地点とその前を結ぶ経路を再作成する
                let previousAnnotation = self.annotations[index - 1]
                let previousRoute = try await self.calculateRoute(annotationStart: previousAnnotation, annotationFinish: annotation)
                travel.routes.insert(previousRoute.route, at: index - 1)
                travel.routes.remove(at: index)
            }
            // 挿入した地点とその後ろを結ぶ経路を再作成する
            let nextAnnotation = self.annotations[index + 1]
            let nextRoute = try await self.calculateRoute(annotationStart: annotation, annotationFinish: nextAnnotation)
            travel.routes.insert(nextRoute.route, at: index)
        }
    }

    // MARK: - Util

    func getAnnotationColor(annotation: PointAnnotation) -> UIColor {
        if self.annotations.count <= 0 {
            return AnnotationColor.yet
        }
        if annotation.routeIndex < 0 || annotation.routeIndex >= self.annotations.count {
            return AnnotationColor.other
        }

        let color: UIColor
        let completedAnnotationIndex = self.travel.getCompletedAnnotationIndex()
        if annotation.routeIndex <= completedAnnotationIndex {
            color = AnnotationColor.done
        } else {
            color = AnnotationColor.yet
        }
        return color
    }
    
    func getCoordinateFromTravel(annotation: PointAnnotation) -> CLLocationCoordinate2D? {
        if let index = self.annotations.firstIndex(of: annotation), self.travel.hasRoute() {
            var coordinate: CLLocationCoordinate2D
            if index < (self.annotations.count - 1) {
                coordinate = self.travel.routes[index].startLocation
            } else {
                coordinate = self.travel.routes[index - 1].finishLocation
            }
            return coordinate
        } else {
            return nil
        }
    }

}

