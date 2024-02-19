import Foundation
import SwiftUI
import MapKit

enum MenuMessage: String {
    case requestStart = "開始日と開始地点を設定"
    case requestFinish = "目的地を設定"
    case edit = "経路の編集"
    case infoRoute = "目的地"
    case finish = "目的地に到着しました"
    case infoFinished = "完了"
    case infoInterrupted = "中断"
}

enum AnnotationColor {
    static let done = UIColor(_colorLiteralRed: 0.8, green: 0, blue: 0, alpha: 1.0)
    static let yet = UIColor(_colorLiteralRed: 0, green: 0, blue: 1, alpha: 1.0)
    static let today = UIColor(_colorLiteralRed: 1, green: 0.7, blue: 0, alpha: 1.0)
    static let other = UIColor.black
    static let initial = UIColor(_colorLiteralRed: 1, green: 0.7, blue: 0, alpha: 1.0)
}

struct RouteUpdated {
    var route: Route
    var annotationStart: PointAnnotation? = nil
    var annotationFinish: PointAnnotation? = nil

    init(route: Route) {
        self.route = route
    }

    init(route: Route, annotationStart: PointAnnotation, annotationFinish: PointAnnotation) {
        self.init(route: route)
        self.annotationStart = annotationStart
        self.annotationFinish = annotationFinish
    }

}

struct RouteUpdatedSet {
    var before: [RouteUpdated] = []
    var after: [RouteUpdated] = []
    
    init() {
    }

    init(before: [RouteUpdated], after: [RouteUpdated]) {
        self.before = before
        self.after = after
    }
}

class ViewManager: ObservableObject {
    
    @Published var message = MenuMessage.requestStart.rawValue
    @Published var selectedListIndex = -1
    @Published var editMode: EditMode = .inactive
    @Published var finishedTravels: [Travel] = []
    @Published var mapRedrawFlag = false
    @Published var mapRegion: MKCoordinateRegion? = nil

    var healthManager: HealthManager = HealthManager()
    var storeManager: StoreManager = StoreManager()
    var annotationSet = AnnotationSet()

    var selectedAnnotationIndex = -1
    var walkDistanceInitialized = false
    var todayPolyline: ColoredPolyline? = nil
    var currentAnnotation: PointAnnotation? = nil

    var proxy: ScrollViewProxy?
    let util = Util()
        
    // MARK: for test

    var isTest = false
    let test_coordinates = [
        CLLocationCoordinate2D(latitude:35.68087149999998, longitude: 139.76724909999996),
        CLLocationCoordinate2D(latitude:34.970887999999995, longitude: 138.38653769999996),
        CLLocationCoordinate2D(latitude:35.169026999999986, longitude: 136.8818139),
        CLLocationCoordinate2D(latitude:34.98568120000001, longitude: 135.7589936),
        CLLocationCoordinate2D(latitude:34.687093000000004, longitude: 135.52575900000002),
    ]
    let labels = [
        "東京都千代田区丸の内1丁目",
        "静岡県静岡市葵区黒金町",
        "愛知県名古屋市中区",
        "京都府京都市中京区一之船入町",
        "大阪府大阪市中央区平野町3丁目",
    ]

    func initialize(completion: @escaping () -> Void) {
        let args = CommandLine.arguments
        print("args=\(args)")
        if args.contains("-uistorytest") {
            self.isTest = true
            self.healthManager = HealthManagerStub()
            self.storeManager.isTest = true
            self.storeManager.initializeTestData()
            let calendar = Calendar.current
            self.travel.startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
            do {
                try self.replaceTravel() {
                    let coordinate1 = self.test_coordinates[0]
                    let coordinate2 = CLLocationCoordinate2D(latitude:35.2401146, longitude: 139.14988)
                    let region = self.createRegionBetweenCoordinates(coordinate1: coordinate1, coordinate2: coordinate2)
                    self.mapRegion = region
                }
            } catch {
                print("initialize test updateWalkDistance error.\(error)")
            }
            completion()
        } else if args.contains("-uitest") {
            self.isTest = true
            self.healthManager = HealthManagerStub()
            self.storeManager.isTest = true
            self.storeManager.initializeTestData()

            let calendar = Calendar.current
            if CommandLine.arguments.contains("finish") {
                self.travel.startDate = calendar.date(from: DateComponents(year: 2016, month: 5, day: 17))!
            } else {
                self.travel.startDate = calendar.date(from: DateComponents(year: 2022, month: 12, day: 7))!
            }
            Task {
                do {
                    for index in 0..<self.test_coordinates.count {
                        let annotation = PointAnnotation()
                        annotation.coordinate = self.test_coordinates[index]
                        annotation.label = labels[index]
                        let _ = try await self.addAnnotation(annotation: annotation, isTemporary: false)
                    }
                    try await self.updateWalkDistance() {
                        Task { @MainActor in
                            do {
                                self.finishedTravels = try self.getDummyFinishedTravels()
                                let region = self.createRegionBetweenCoordinates(coordinate1: self.test_coordinates.first!, coordinate2: self.test_coordinates.last!)
                                self.mapRegion = region
                                completion()
                            } catch {
                                print("initialize test updateWalkDistance error.\(error)")
                            }
                        }
                    }
                } catch {
                    print("initialize test data error.\(error)")
                }
            }
        } else {
            self.healthManager.requestAuthorization() { success in
                if success {
                    print("viewManager healthManager.requestAuthorization success")
                    Task { @MainActor in
                        self.load()
                        do {
                            try self.replaceTravel() {
                                completion()
                            }
                        } catch {
                            print("load error.\(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func getDummyFinishedTravels() throws -> [Travel] {
        let calendar = Calendar.current
        // Travel0 中断 2023/9/1 - 2023/10/1 20/100km
        // Travel1 中断 2023/7/1 - 2023/11/1 80/100km ※今日の日付で歩行距離を更新すると完了になる
        // Travel2 完了 2023/5/1 - 2023/12/1 100/100km
        var dummyFinishedTravels: [Travel] = []
        for index in 0..<3 {
            let startMonth = (2 - index) * 2 + 5
            let finishMonth = index + 10
            let startDate = calendar.date(from: DateComponents(year: 2023, month: startMonth, day: 1, hour: 0, minute: 0, second: 0))!
            let finishedDate = calendar.date(from: DateComponents(year: 2023, month: finishMonth, day: 1, hour: 0, minute: 0, second: 0))!
            let annotationStart = PointAnnotation()
            annotationStart.coordinate = self.test_coordinates[index]
            annotationStart.label = "start\(index)"
            let annotationFinish = PointAnnotation()
            annotationFinish.coordinate = self.test_coordinates[index + 1]
            annotationFinish.label = "finish\(index)"
            let route = try self.annotationSet.createSimpleRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
            let travel = try Travel(startDate: startDate, routes: [route.route])
            travel.name = "Travel\(index)"
            travel.finishedDate = finishedDate
            travel.isStop = true
            travel.currentDistance = CLLocationDistance((finishMonth - startMonth) * 20000)
            travel.finishDistance = 100000
            dummyFinishedTravels.append(travel)
        }
        return dummyFinishedTravels
    }
    
    func getCurrentDate() -> Date {
        return Date()
    }
    
    // MARK: - View Control

    func editButtonPressed() -> Bool {
        var isPresentedConfirmFinishRestartMessage = false
        if self.editMode.isEditing {
            self.editMode = .inactive
        } else {
            if self.travel.isStop {
                isPresentedConfirmFinishRestartMessage = true
            } else {
                self.editMode = .active
            }
        }
        self.updateMenuMessage()

        return isPresentedConfirmFinishRestartMessage
    }
    
    func updateWalkDistance(forceUpdate: Bool = true, completion: @escaping () -> Void) async throws {
        let fromDate = self.util.startOfDay(date: self.travel.startDate)
        let distance = try await self.healthManager.getTotalWalkingDistance(fromDate: fromDate, toDate: self.getCurrentDate())
        if self.travel.currentDistance != distance || forceUpdate == true {
            print("finish distance:\(self.travel.finishDistance)")
            Task { @MainActor in
                self.setWalkDistance(distance: distance)
                self.save()
                self.updateMenuMessage()
                self.mapRedrawFlag = true // todo 要最適化
                self.walkDistanceInitialized = true
                completion()
            }
        }

    }
    

    func updateSelectionDate(newSelectionDate: Date, completion: @escaping () -> Void) async throws {
        print("** updateSelectionDate:\(newSelectionDate)")
        self.travel.startDate = newSelectionDate
        self.resetStoredWalkingDistance()
        try await self.updateWalkDistance() {
            completion()
        }
        
    }

    func entryCurrentTravelToFinishList(entryName: String, finishedDate: Date, completion: @escaping () -> Void) throws {
        print("** entry finish travel name: \(entryName)")
        self.travel.name = entryName
        self.travel.finishedDate = finishedDate
        self.travel.isStop = true
        self.restoreFinishedTravels()
        self.entryTravelToFinishList(travel: self.travel)
        
        self.resetStoredWalkingDistance()
        self.createNewTravel(startDate: self.getCurrentDate())
        try self.replaceTravel(completion: completion)
    }

    func switchTravel(switchedTravelIndex: Int, completion: @escaping () -> Void) throws {
        print("** switchTravel:\(switchedTravelIndex)")
        if switchedTravelIndex < 0 || switchedTravelIndex >= self.finishedTravels.count {
            return
        }

        let currentTravel = self.travel
        let removedTravel = self.finishedTravels.remove(at: switchedTravelIndex)
        self.annotationSet.setTravel(travel: removedTravel)
        self.entryTravelToFinishList(travel: currentTravel)
        self.resetStoredWalkingDistance()
        try self.replaceTravel(completion: completion)
    }

    func restartTravel(completion: @escaping () -> Void) throws {
        self.travel.isStop = false
        self.resetStoredWalkingDistance()
        self.restoreFinishedTravels()

        Task {
            try await self.updateWalkDistance() {
                Task { @MainActor in
                    self.editMode = .inactive
                    completion()
                }
            }
        }
    }
    
    private func entryTravelToFinishList(travel: Travel) {
        self.finishedTravels.append(travel)
        self.finishedTravels.sort { $0.finishedDate > $1.finishedDate }
    }

    func replaceTravel(completion: @escaping () -> Void) throws {
        if self.travel.hasRoute() {
            self.editMode = .inactive
            var index = self.travel.getCompletedAnnotationIndex()
            if index < 0 {
                index = 0
            }
            if index > self.annotationSet.annotations.count - 1 {
                index = self.annotationSet.annotations.count - 1
            }
            
            for annotation in self.annotationSet.annotations {
                print("latitude:\(annotation.coordinate.latitude), longitude: \(annotation.coordinate.longitude)")
                print("\"\(annotation.label)\"")
            }
            self.selectedListIndex = index
        } else {
            self.editMode = .active
        }
        Task {
            try await self.updateWalkDistance() {
                completion()
            }
        }
    }

    func restoreFinishedTravels() {
        var restoredTravels: [Travel] = []
        for travel in self.finishedTravels {
            if travel.isStop == false {
                travel.isStop = true
                travel.finishedDate = self.getCurrentDate()
            }
            if travel.hasRoute() {
                restoredTravels.append(travel)
            }
        }

        self.finishedTravels = restoredTravels
    }
    
    func setMapRegionToCurrentLocation() {
        if let centerCoordinate = self.travel.currentLocation, let todayPolyline = self.todayPolyline {
            let regionLimit = 0.02
            // 縦横のSpanを計算
            var latitudeDelta = abs(centerCoordinate.latitude - todayPolyline.coordinate.latitude) * 5
            var longitudeDelta = abs(centerCoordinate.longitude - todayPolyline.coordinate.longitude) * 5

            if latitudeDelta.isNaN || latitudeDelta <= regionLimit || longitudeDelta.isNaN || longitudeDelta <= regionLimit {
                latitudeDelta = regionLimit
                longitudeDelta = regionLimit
            }
            
            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
            self.mapRegion = region
        }
    }
    
    // MARK: wrap AnnotationSet

    var travel: Travel {
        get {
            return self.annotationSet.travel
        }
    }

    var annotations: [PointAnnotation] {
        get {
            return self.annotationSet.annotations
        }
    }

    func addAnnotation(annotation: PointAnnotation, isTemporary: Bool) async throws -> RouteUpdatedSet {
        let routeUpdated = try await self.annotationSet.addAnnotation(annotation: annotation, isTemporary: isTemporary)
        if isTemporary == false {
            try self.updateTravelInformation(travel: self.travel)
        }
        return routeUpdated
    }
    
    func updateTemporaryAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        let routeUpdated = try await self.annotationSet.updateTemporaryAnnotation(annotation: annotation)
        try self.updateTravelInformation(travel: self.travel)
        return routeUpdated
    }

    func updateAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        let routeUpdated = try await self.annotationSet.updateAnnotation(annotation: annotation)
        print(travel.startLocation.latitude)
        try self.updateTravelInformation(travel: self.travel)
        return routeUpdated
    }
    
    func removeAnnotation(annotation: PointAnnotation) async throws -> RouteUpdatedSet {
        let routeUpdated = try await self.annotationSet.removeAnnotation(annotation: annotation)
        try self.updateTravelInformation(travel: self.travel)
        return routeUpdated
    }
    
    func moveAnnotation(fromIndex: Int, toIndex: Int) async throws {
        try await self.annotationSet.moveAnnotation(fromIndex: fromIndex, toIndex: toIndex)
        try self.updateTravelInformation(travel: self.travel)
    }
    
    func insertAnnotation(index: Int, annotation: PointAnnotation) async throws {
        try await self.annotationSet.insertAnnotation(index: index, annotation: annotation)
        try self.updateTravelInformation(travel: self.travel)
    }
    
    private func updateTravelInformation(travel: Travel) throws {
        try travel.updateInformation()
        self.annotationSet.resetAnnotationColor()
        self.save()
    }

    func createTodayRoute() {
        if self.travel.hasRoute() {
            self.todayPolyline = self.travel.createTodayRoute()
        }
        self.currentAnnotation = self.createCurrentAnnotation()
    }
    
    func createCurrentAnnotation() -> PointAnnotation? {
        var currentAnnotation: PointAnnotation? = nil
        if let currentCoords = self.travel.currentLocation {
            let annotation = PointAnnotation()
            annotation.isCurrentLocation = true
            annotation.routeIndex = -1
            annotation.coordinate = currentCoords
            annotation.color = AnnotationColor.today
            annotation.title = self.getTodayDistanceMapLabel()
            currentAnnotation = annotation
        }
        return currentAnnotation
    }

    // ViewManagerに移行
    func checkValidLocation(annotation: PointAnnotation) async throws -> CLLocationCoordinate2D {
        // 経路案内に有効な座標かどうかチェック
        let route = try await self.annotationSet.calculateRoute(annotationStart: annotation, annotationFinish: annotation)
        let coordinate = try Travel.getStartLocation(routes: [route.route])
        return coordinate
    }
    
    func getCoordinateFromTravel(annotation: PointAnnotation) -> CLLocationCoordinate2D? {
        return self.annotationSet.getCoordinateFromTravel(annotation: annotation)
    }
    
    func createSimpleRoute(annotationStart: PointAnnotation, annotationFinish: PointAnnotation) throws -> RouteUpdated {
        return try self.annotationSet.createSimpleRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
    }

    func createNewTravel(startDate: Date) {
        self.selectedAnnotationIndex = -1
        self.annotationSet.createNewTravel(startDate: startDate)
    }
    
    func setTravel(travel: Travel) {
        self.annotationSet.setTravel(travel: travel)
    }

    // MARK: - Util

    func createRegionBetweenCoordinates(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> MKCoordinateRegion {
        // 中心座標を計算
        let centerCoordinate = CLLocationCoordinate2D(
            latitude: (coordinate1.latitude + coordinate2.latitude) / 2,
            longitude: (coordinate1.longitude + coordinate2.longitude) / 2
        )

        // 縦横のSpanを計算
        let latitudeDelta = abs(coordinate1.latitude - coordinate2.latitude) * 1.5
        let longitudeDelta = abs(coordinate1.longitude - coordinate2.longitude) * 1.5

        let region = MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
        return region
    }
    
    func isAnnotationCompleted(index: Int) throws -> Bool {
        if index < 0 || index >= self.annotationSet.annotations.count {
            throw AnnotationSetError.annotationNotFound
        }
        let currentStep = self.travel.getCompletedAnnotationIndex()
        if index <= currentStep {
            return true
        } else {
            return false
        }

    }
    
    func getDisplayLabel(index: Int) -> String {
        do {
            let prefix: String
            if try self.isAnnotationCompleted(index: index) {
                prefix = "(済)"
            } else {
                prefix = ""
            }
            return "\(prefix)\(self.annotationSet.annotations[index].label)"
        } catch {
            return "Error"
        }
    }

    func updateMenuMessage() {
        let message = self.menuMessage()
        let travel = self.travel

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateLabel = " \(dateFormatter.string(from: travel.startDate))"
        let currentDistanceLabel = " " + self.getCurrentDistancePerFinishLabel()
        let finishDistanceLabel = " " + self.getFinishDistanceLabel()

        if message == .infoRoute {
            self.message = message.rawValue + currentDistanceLabel
        } else if message == .infoFinished {
            self.message = message.rawValue + dateLabel + finishDistanceLabel
        } else if message == .infoInterrupted {
            self.message = message.rawValue + dateLabel + currentDistanceLabel
        } else {
            self.message = message.rawValue
        }
    }
    
    func getCurrentDistancePerFinishLabel() -> String {
        return "\(self.convertDistanceToKM(distance: self.travel.currentDistance))/\(self.convertDistanceToKM(distance: self.travel.finishDistance))km"
    }
    
    func getCurrentDistanceLabel() -> String {
        return "\(self.convertDistanceToKM(distance: self.travel.currentDistance))km"
    }
    
    func getFinishDistanceLabel() -> String {
        return "\(self.convertDistanceToKM(distance: self.travel.finishDistance))km"
    }
    
    func getTodayDistanceMapLabel() -> String {
        if self.travel.todayDistance <= 0 {
            return "0km"
        }
        return String(format: "%.1fkm", (self.travel.todayDistance / 1000))
    }
    
    private func convertDistanceToKM(distance: CLLocationDistance) -> Int {
        if distance < 0 {
            return 0
        }
        return Int(distance / 1000)
    }

    func menuMessage() -> MenuMessage {
        let travel = self.travel
        if travel.hasRoute() {
            if self.editMode.isEditing {
                return .edit
            }
            if travel.isStop {
                if travel.isFinish() {
                    return .infoFinished
                } else {
                    return .infoInterrupted
                }
            } else {
                if travel.isFinish() {
                    return .finish
                } else {
                    return .infoRoute
                }
            }
        } else {
            if self.annotationSet.annotations.count == 0 {
                return .requestStart
            } else {
                return .requestFinish
            }
        }
    }

    func setWalkDistance(distance: Double) {
        let travel = self.travel
        if travel.isStop {
            travel.todayDistance = 0
        } else {
            travel.currentDistance = distance
            travel.todayDistance = distance - (self.healthManager.storedWalkingDistance?.distance ?? 0)
        }
        self.createTodayRoute()
        self.annotationSet.resetAnnotationColor()
    }
    
    func resetStoredWalkingDistance() {
        self.healthManager.storedWalkingDistance = nil
    }
    
    func fetchAdministrativeAreaFromLocation(coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        return await reverseGeocodeLocationWithGeocoder(geocoder, location)
    }

    private func reverseGeocodeLocationWithGeocoder(_ geocoder: CLGeocoder, _ location: CLLocation) async -> String {
        await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let place = placemarks?.first {
                    var address = (place.administrativeArea ?? "") + (place.locality ?? "") + (place.thoroughfare ?? "")
                    if address.count == 0 {
                        address = "不明"
                    }
                    continuation.resume(returning: address)
                } else {
                    continuation.resume(returning: "不明")
                }
            }
        }
    }

    func selectAnnotation(index: Int) {
        self.selectedAnnotationIndex = index
    }
    
    func getSelectedAnnotation() -> PointAnnotation? {
        if self.selectedAnnotationIndex >= 0 && self.selectedAnnotationIndex < self.annotations.count {
            return self.annotations[self.selectedAnnotationIndex]
        } else {
            return nil
        }
    }

    func initializeAnnotationColor() {
        for annotation in self.annotations {
            annotation.color = self.annotationSet.getAnnotationColor(annotation: annotation)
        }
    }
    
    // MARK: - Store

    func save() {
        self.storeManager.save(travel: self.travel)
        if let walkingDistance = self.healthManager.storedWalkingDistance {
            self.storeManager.save(walkingDistance: walkingDistance)
        }
        self.storeManager.save(finishedTravels: self.finishedTravels)
        print("save travel:\(self.travel.name)")
    }
    
    func load() {
        self.loadTravel()
        self.finishedTravels = self.storeManager.loadFinishedTravels()
    }

    private func loadTravel() {
        if let travel = self.storeManager.loadTravel() {
            self.annotationSet.setTravel(travel: travel)
            self.healthManager.storedWalkingDistance = self.storeManager.loadWalkingDistance()
            print("load travel")
        } else {
            print("load travel error")
        }
    }

    func rollback() {
        self.loadTravel()
    }

}

