import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    @Binding var mapType: MKMapType

    @ObservedObject var viewManager: ViewManager
    let mapView = MKMapView()
    let util = Util()
    
    func makeUIView(context: Context) -> MKMapView {
        // Map初期化
        self.mapView.delegate = context.coordinator
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.tapped(gesture:)))
        self.mapView.addGestureRecognizer(tapGesture)
        self.mapView.mapType = mapType

        if self.viewManager.storeManager.isTest {
            let tokyoStationLocation = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
            let region = MKCoordinateRegion(center: tokyoStationLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            self.mapView.setRegion(region, animated: false)
        }
        
        return self.mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.mapType = mapType

        // SwiftUIからの更新通知をUIKitに伝える

        // リスト選択
        if self.viewManager.selectedListIndex >= 0 {
            let selectedListIndex = self.viewManager.selectedListIndex
            print("selectedListIndex: \(selectedListIndex)")
            self.viewManager.selectAnnotation(index: selectedListIndex)
            if let annotation = self.viewManager.getSelectedAnnotation() {
                view.selectAnnotation(annotation, animated: true)
                self.adjustRegion(view: view, routeIndex: selectedListIndex)
            }
            Task { @MainActor in
                self.viewManager.selectedListIndex = -1
            }
        }

        // Map再描画
        if self.viewManager.mapRedrawFlag {
            self.util.startElapse()
            view.removeAnnotations(view.annotations)
            self.viewManager.initializeAnnotationColor()
            view.addAnnotations(self.viewManager.annotations)

            view.removeOverlays(view.overlays)
            self.util.finishElapse()
            self.util.startElapse()
            let travel = self.viewManager.travel
            if travel.hasRoute() {
                self.addOverlays(view: view, travel: travel)
                // 移動済ルート
                for route in travel.routes {
                    if let currentRouteSteps = route.currentRouteSteps {
                        self.addOverlays(view: view, routeSteps: currentRouteSteps)
                    }
                }
                // 今日のルート
                self.viewManager.createTodayRoute()
                if let todayPolyline = self.viewManager.todayPolyline {
                    view.addOverlay(todayPolyline, level: .aboveRoads)
                }
            }
            self.util.finishElapse()
            Task { @MainActor in
                self.viewManager.mapRedrawFlag = false
            }
        }
        
        if let annotation = self.viewManager.currentAnnotation {
            view.addAnnotation(annotation)
        }

        if let region = self.viewManager.mapRegion {
            view.setRegion(region, animated: true)
            Task { @MainActor in
                self.viewManager.mapRegion = nil
            }
        }
    }
    
    func adjustRegion(view: MKMapView, routeIndex: Int) {
        // rectRegion作成までをViewManagerに移行
        let travel = self.viewManager.travel
        if  travel.hasRoute() {
            var adjustRouteIndex = routeIndex
            if adjustRouteIndex < 0 {
                adjustRouteIndex = 0
            }
            if adjustRouteIndex >= travel.routes.count {
                adjustRouteIndex = travel.routes.count - 1
            }
            let rect = travel.routes[adjustRouteIndex].polyline.boundingMapRect
            var rectRegion = MKCoordinateRegion(rect)
            rectRegion.span.latitudeDelta = rectRegion.span.latitudeDelta * 1.2
            rectRegion.span.longitudeDelta = rectRegion.span.longitudeDelta * 1.2
            view.setRegion(rectRegion, animated: true)
        } else {
            if let annotation = self.viewManager.annotations.first {
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                view.setRegion(region, animated: true)
            }
        }
    }
    
    func addOverlays(view: MKMapView, routeSteps: [RouteStep]?) {
        if let steps = routeSteps {
            for step in steps {
                view.addOverlay(step.polyline, level: .aboveRoads)
            }
        }
    }
    
    func addOverlays(view: MKMapView, travel: Travel) {
        for route in travel.routes {
            self.addOverlays(view: view, routeSteps: route.routeSteps)
        }
    }

    func removeOverlays(view: MKMapView, routeSteps: [RouteStep]?) {
        if let steps = routeSteps {
            for step in steps {
                view.removeOverlay(step.polyline)
            }
        }
    }
    
    func updateRoute(view: MKMapView, routeUpdated: RouteUpdatedSet) {
        for route in routeUpdated.before {
            self.removeOverlays(view: view, routeSteps: route.route.routeSteps)
            self.removeOverlays(view: view, routeSteps: route.route.currentRouteSteps)
        }
        for route in routeUpdated.after {
            self.addOverlays(view: view, routeSteps: route.route.routeSteps)
            self.addOverlays(view: view, routeSteps: route.route.currentRouteSteps)
        }
    }
    
    func updateTodayRoute(view: MKMapView) {
        if let polyline = self.viewManager.todayPolyline {
            mapView.removeOverlay(polyline)
        }
        if let annotation = self.viewManager.currentAnnotation {
            mapView.removeAnnotation(annotation)
        }

        self.viewManager.createTodayRoute()

        if let polyline = self.viewManager.todayPolyline {
            mapView.addOverlay(polyline)
        }
        if let annotation = self.viewManager.currentAnnotation {
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, mapView: self.mapView, viewManager: self._viewManager)
    }
    
    // UIKitのイベントをSwiftUIに伝える
    final class Coordinator: NSObject, MKMapViewDelegate {
        
        @ObservedObject var viewManager: ViewManager
        var parent: MapView
        var mapView:MKMapView
        var overlayColor = UIColor.orange
        
        init(_ parent: MapView, mapView: MKMapView, viewManager: ObservedObject<ViewManager>) {
            self.parent = parent
            self.mapView = mapView
            _viewManager = viewManager
        }
        
        @objc func tapped(gesture: UITapGestureRecognizer) {
            if !self.viewManager.editMode.isEditing {
                return
            }

            let location = gesture.location(in: self.mapView)
            let coordinate: CLLocationCoordinate2D = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            
            print("tap: latitude: \(coordinate.latitude), longitude: \(coordinate.longitude)")
            
            let annotation = PointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            
            Task {
                do {
                    // 経路計算を省略した仮経路を生成
                    let tempRouteUpdated = try await self.viewManager.addAnnotation(annotation: annotation, isTemporary: true)
                    self.parent.updateRoute(view: self.mapView, routeUpdated: tempRouteUpdated)

                    let travel = self.viewManager.travel
                    if travel.hasRoute() {
                        // 仮経路でMap表示範囲を調整
                        self.parent.adjustRegion(view: self.mapView, routeIndex: travel.routes.count - 1)
                    }
                    // Annotationの座標を有効な位置に調整して再表示する
                    let coords = try await self.viewManager.checkValidLocation(annotation: annotation)
                    annotation.coordinate = coords
                    annotation.label = await self.viewManager.fetchAdministrativeAreaFromLocation(coordinate: annotation.coordinate) ?? "不明"

                    if travel.hasRoute() {
                        // 経路計算を行ったRouteに更新
                        let routeUpdated = try await self.viewManager.updateTemporaryAnnotation(annotation: annotation)
                        self.parent.updateRoute(view: self.mapView, routeUpdated: routeUpdated)
                        self.parent.updateTodayRoute(view: self.mapView)
                    }

                    // 座標を調整したAnnotationを再描画する
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.mapView.addAnnotations(self.viewManager.annotations)

                    self.viewManager.selectedListIndex = self.viewManager.annotations.count - 1
                    self.viewManager.updateMenuMessage()
                } catch {
                    let travel = self.viewManager.travel
                    if travel.hasRoute() {
                        self.parent.removeOverlays(view: self.mapView, routeSteps: travel.routes.last?.routeSteps)
                    }
                    let _ = try await self.viewManager.removeAnnotation(annotation: annotation)
                    self.mapView.removeAnnotation(annotation)
                    showErrorDialog(error: error)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? PointAnnotation {
                if let index = self.viewManager.annotations.firstIndex(where: {$0.routeIndex == annotation.routeIndex }) {
                    Task { @MainActor in
                        self.viewManager.selectedListIndex = index
                    }
                }
            }
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
            if newState == .ending {
                Task {
                    if let annotation = view.annotation as? PointAnnotation {
                        do {
                            let coords = try await self.viewManager.checkValidLocation(annotation: annotation)
                            annotation.coordinate = coords
                            // Route再構成
                            let routeUpdated = try await self.viewManager.updateAnnotation(annotation: annotation)
                            self.parent.updateRoute(view: mapView, routeUpdated: routeUpdated)
                            self.parent.updateTodayRoute(view: mapView)

                        } catch {
                            // Annotationの位置を元に戻す
                            if let coodinate = self.viewManager.getCoordinateFromTravel(annotation: annotation) {
                                annotation.coordinate = coodinate
                            } else {
                                do {
                                    let _ = try await self.viewManager.removeAnnotation(annotation: annotation)
                                } catch {
                                    showErrorDialog(error: error)
                                    return
                                }
                                Task { @MainActor in
                                    self.viewManager.selectedListIndex = 0
                                }
                            }
                            showErrorDialog(error: error)
                        }
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            if let colorPolyline = overlay as? ColoredPolyline {
                renderer.strokeColor = colorPolyline.color
            } else {
                renderer.strokeColor = overlayColor
            }
            renderer.lineWidth = 3.0
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "annotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if (annotationView != nil)  {
                annotationView!.annotation = annotation
            } else {
                annotationView = MKMarkerAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
            }
            self.setCallout(annotation: annotation, annotationView: annotationView!)
            return annotationView
        }
        
        public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let annotation = view.annotation, annotation.isKind(of: PointAnnotation.self) {
                let latitude = annotation.coordinate.latitude
                let longitude = annotation.coordinate.longitude
                guard let url = URL(string: "https://www.google.com/maps/@?api=1&map_action=pano&parameters&viewpoint=\(latitude),\(longitude)") else {
                    return
                }
                print(url.description)
                UIApplication.shared.open(url)
            }
        }
        
        private func setCallout(annotation: MKAnnotation, annotationView: MKAnnotationView) {
            if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
                if let pointAnnotation = annotation as? PointAnnotation {
                    markerAnnotationView.markerTintColor = pointAnnotation.color
                    if pointAnnotation.routeIndex < 0 {
                        markerAnnotationView.animatesWhenAdded = true
                        markerAnnotationView.canShowCallout = true

                        let button = UIButton(type: .detailDisclosure)
                        markerAnnotationView.rightCalloutAccessoryView = button
                    } else {
                        markerAnnotationView.isDraggable = true
                    }
                }
            }
        }
    }
    
}

