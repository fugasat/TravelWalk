import XCTest
import MapKit

final class AnnotationSetTest: XCTestCase {
    
    var travel1: Travel!
    var travel2: Travel!
    
    var tokyo = PointAnnotation()
    var tokyo2 = PointAnnotation()
    var skytree = PointAnnotation()
    var koiwa = PointAnnotation()
    var oomiya = PointAnnotation()
    var imperial = PointAnnotation()
    var invalid = PointAnnotation()
    
    class AnnotationSetMock: AnnotationSet {
        override func calculateRoute(annotationStart: PointAnnotation, annotationFinish: PointAnnotation) async throws -> RouteUpdated {
            return try self.createSimpleRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
        }
    }
    
    override func setUpWithError() throws {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        
        self.tokyo = PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)
        self.tokyo2 = PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2)
        self.skytree = PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree)
        self.koiwa = PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)
        self.oomiya = PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya)
        self.imperial = PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial)
        self.invalid = PointAnnotation(coordinate:TestCoordinate.invalid, label:TestLabel.invalid)
        
        let coords = [
            [
                CLLocationCoordinate2D(latitude: 10.1, longitude: 11.1),
                CLLocationCoordinate2D(latitude: 10.2, longitude: 11.2),
            ],
            [
                CLLocationCoordinate2D(latitude: 20.1, longitude: 21.1),
                CLLocationCoordinate2D(latitude: 20.2, longitude: 21.2),
                CLLocationCoordinate2D(latitude: 20.3, longitude: 21.3),
            ],
            [
                CLLocationCoordinate2D(latitude: 30.1, longitude: 31.1),
                CLLocationCoordinate2D(latitude: 30.2, longitude: 31.2),
            ],
            [
                CLLocationCoordinate2D(latitude: 40.1, longitude: 41.1),
                CLLocationCoordinate2D(latitude: 40.2, longitude: 41.2),
            ],
        ]
        let routeSteps1 = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: coords[0], count: coords[0].count)),
        ]
        let routeSteps2 = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: coords[1], count: coords[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: coords[2], count: coords[2].count)),
        ]
        let routeSteps3 = [
            RouteStep(distance: 400,
                      polyline: ColoredPolyline(coordinates: coords[3], count: coords[3].count)),
        ]
        
        let routes = [
            try Route(routeSteps: routeSteps1, startLabel: "start11", finishLabel: "finish11"),
            try Route(routeSteps: routeSteps2, startLabel: "start12", finishLabel: "finish12"),
            try Route(routeSteps: routeSteps3, startLabel: "start13", finishLabel: "finish13"),
        ]
        self.travel1 = try Travel(startDate: testDate, routes: routes)
        self.travel2 = try Travel(startDate: testDate, routes: [try Route(routeSteps: routeSteps2, startLabel: "start21", finishLabel: "finish21")])
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Annotation操作

    //
    // 東京駅から東京スカイツリーまでの経路を生成できるか確認
    // MapKitアクセスあり
    //
    func testCalculateRoute() async throws {
        let annotationSet = AnnotationSet()
        let annotationStart = self.tokyo
        let annotationFinish = self.skytree
        
        let route = try await annotationSet.calculateRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
        XCTAssertGreaterThan(route.route.routeSteps.count, 0)
        XCTAssertEqual(TestLabel.tokyo, route.route.startLabel)
        XCTAssertEqual(TestLabel.skytree, route.route.finishLabel)
        
        // 開始地点(東京駅)
        XCTAssertEqual(TestCoordinate.tokyo.latitude, route.route.startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, route.route.startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 終了地点(東京スカイツリー)
        XCTAssertEqual(TestCoordinate.skytree.latitude, route.route.finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.skytree.longitude, route.route.finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
    }

    //
    // 指定したAnnotationに対応する座標をTravelから取得
    // 異常系：存在しないAnnotationを指定した場合はエラーになる
    //
    func testGetCoordinateFromTravelWithTravelIsNil() async throws {
        let annotationSet = AnnotationSetMock()
        if let _ = annotationSet.getCoordinateFromTravel(annotation: PointAnnotation()) {
            XCTFail()
        }
    }
    
    // MARK: Annotation,Travel操作

    //
    // 新規にTravelを生成できるか確認
    //
    func testCreateNewTravel() throws {
        let calendar = Calendar.current
        let annotationSet = AnnotationSetMock()
        annotationSet.createNewTravel(startDate: calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!)
        XCTAssertFalse(annotationSet.travel.hasRoute())
        XCTAssertEqual("新規", annotationSet.travel.name)
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!.timeIntervalSince1970,
                       annotationSet.travel.startDate.timeIntervalSince1970)
    }
    
    //
    // TravelからAnnotationが生成されるか確認
    //
    func testSetTravel() throws {
        let annotationSet = AnnotationSetMock()
        XCTAssertFalse(annotationSet.travel.hasRoute())
        XCTAssertEqual(0, annotationSet.annotations.count)
        
        // Travel1を設定できるか確認
        annotationSet.setTravel(travel: self.travel1)
        
        // 開始地点と各Routeの終了地点を示すAnnotationを取得できているか確認
        let annotations = annotationSet.annotations
        XCTAssertEqual(4, annotations.count)
        
        // 開始地点
        XCTAssertEqual("start11", annotations[0].label)
        XCTAssertEqual(10.1, annotations[0].coordinate.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, annotations[0].coordinate.longitude, accuracy: COORD_ACCURACY)
        
        // 各Routeの終了地点
        XCTAssertEqual("finish11", annotations[1].label)
        XCTAssertEqual(10.2, annotations[1].coordinate.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, annotations[1].coordinate.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual("finish12", annotations[2].label)
        XCTAssertEqual(30.2, annotations[2].coordinate.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, annotations[2].coordinate.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual("finish13", annotations[3].label)
        XCTAssertEqual(40.2, annotations[3].coordinate.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(41.2, annotations[3].coordinate.longitude, accuracy: COORD_ACCURACY)
        
        // Travel2を設定できるか確認
        annotationSet.setTravel(travel: self.travel2)
        XCTAssertNotNil(annotationSet.travel)
        XCTAssertEqual(1, annotationSet.travel.routes.count)
        XCTAssertEqual(2, annotationSet.annotations.count)
    }
    

    //
    // Annotationを追加できるか確認
    //
    func testAddAnnotation() async throws {
        let annotationSet = AnnotationSetMock()
        var routeUpdatedSet: RouteUpdatedSet
        
        // 東京駅
        routeUpdatedSet = try await annotationSet.addAnnotation(annotation: self.tokyo, isTemporary: false)
        XCTAssertEqual(0, routeUpdatedSet.before.count)
        XCTAssertEqual(0, routeUpdatedSet.after.count)
        XCTAssertEqual(1, annotationSet.annotations.count)
        XCTAssertEqual(0, annotationSet.annotations[0].routeIndex)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.annotations[0].label)
        XCTAssertEqual(AnnotationColor.yet, annotationSet.annotations[0].color)
        
        // 東京スカイツリー
        routeUpdatedSet = try await annotationSet.addAnnotation(annotation: self.skytree, isTemporary: false)
        XCTAssertEqual(0, routeUpdatedSet.before.count)
        XCTAssertEqual(1, routeUpdatedSet.after.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdatedSet.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdatedSet.after[0].route.finishLabel)
        XCTAssertEqual(2, annotationSet.annotations.count)
        XCTAssertEqual(0, annotationSet.annotations[0].routeIndex)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.annotations[0].label)
        XCTAssertEqual(AnnotationColor.yet, annotationSet.annotations[0].color)
        XCTAssertEqual(1, annotationSet.annotations[1].routeIndex)
        XCTAssertEqual(TestLabel.skytree, annotationSet.annotations[1].label)
        XCTAssertEqual(AnnotationColor.yet, annotationSet.annotations[1].color)
        
        // ２つ追加した時にTravelが生成されるか確認
        XCTAssertEqual(1, annotationSet.travel.routes.count)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.skytree, annotationSet.travel.routes[0].finishLabel)
        
        // 新小岩駅
        routeUpdatedSet = try await annotationSet.addAnnotation(annotation: self.koiwa, isTemporary: false)
        XCTAssertEqual(0, routeUpdatedSet.before.count)
        XCTAssertEqual(1, routeUpdatedSet.after.count)
        XCTAssertEqual(TestLabel.skytree, routeUpdatedSet.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdatedSet.after[0].route.finishLabel)
        XCTAssertEqual(3, annotationSet.annotations.count)
        XCTAssertEqual(2, annotationSet.travel.routes.count)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.skytree, annotationSet.travel.routes[0].finishLabel)
        XCTAssertEqual(TestLabel.skytree, annotationSet.travel.routes[1].startLabel)
        XCTAssertEqual(TestLabel.koiwa, annotationSet.travel.routes[1].finishLabel)
        XCTAssertEqual(2, annotationSet.annotations[2].routeIndex)
        XCTAssertEqual(TestLabel.koiwa, annotationSet.annotations[2].label)
        XCTAssertEqual(AnnotationColor.yet, annotationSet.annotations[2].color)
    }
    
    //
    // Annotationを仮経路で追加できるか確認
    //
    func testAddTemporaryAnnotation() async throws {
        let annotationSet = AnnotationSetMock()
        
        // 東京駅
        let routeUpdatedSet1 = try await annotationSet.addAnnotation(annotation: self.tokyo, isTemporary: true)
        XCTAssertEqual(0, routeUpdatedSet1.before.count)
        XCTAssertEqual(0, routeUpdatedSet1.after.count)
        XCTAssertEqual(1, annotationSet.annotations.count)
        XCTAssertEqual(0, annotationSet.annotations[0].routeIndex)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.annotations[0].label)
        
        // 東京スカイツリー
        let routeUpdatedSet2 = try await annotationSet.addAnnotation(annotation: self.skytree, isTemporary: true)
        XCTAssertEqual(0, routeUpdatedSet2.before.count)
        XCTAssertEqual(1, routeUpdatedSet2.after.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdatedSet2.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdatedSet2.after[0].route.finishLabel)
        
        XCTAssertEqual(2, annotationSet.annotations.count)
        XCTAssertEqual(0, annotationSet.annotations[0].routeIndex)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.annotations[0].label)
        XCTAssertEqual(1, annotationSet.annotations[1].routeIndex)
        XCTAssertEqual(TestLabel.skytree, annotationSet.annotations[1].label)
        
        // ２つ追加した時にTravelが生成されるか確認
        XCTAssertEqual(1, annotationSet.travel.routes.count)
        XCTAssertEqual(TestLabel.tokyo, annotationSet.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.skytree, annotationSet.travel.routes[0].finishLabel)
        
        // 仮で作成した経路なのでRouteStepが1個だけ存在することを確認
        XCTAssertEqual(1, annotationSet.travel.routes[0].routeSteps.count)
    }
    
    //
    // 無効なAnnotationで更新しようとした時に例外が発生するか確認
    //
    func testUpdateAnnotationWithError() async throws {
        let annotationSet = AnnotationSet()
        do {
            let _ = try await annotationSet.updateAnnotation(annotation: PointAnnotation())
            XCTFail()
        } catch {
            XCTAssertEqual(AnnotationSetError.annotationNotFound, error as! AnnotationSetError)
        }
    }
    
    //
    // Annotationを削除
    // 異常系：不適切なAnnotationを指定した場合は何も起きない
    //
    func testRemoveAnnotationWithInvalidAnnotation() async throws {
        let annotationSet = AnnotationSetMock()
        let routeUpdated = try await annotationSet.removeAnnotation(annotation: PointAnnotation())
        XCTAssertEqual(0, routeUpdated.before.count)
        XCTAssertEqual(0, routeUpdated.after.count)
    }
    
    // MARK: - Util

    //
    // 指定したAnnotationに対応する座標をTravelから取得
    //
    func testGetCoordinateFromTravel() async throws {
        // 指定したAnnotationに対応する座標をTravelから取得
        let annotationSet = AnnotationSetMock()
        
        // 東京駅
        let _ = try await annotationSet.addAnnotation(annotation: self.tokyo, isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await annotationSet.addAnnotation(annotation: self.skytree, isTemporary: false)
        // 新小岩駅 (6.4km)
        let _ = try await annotationSet.addAnnotation(annotation: self.koiwa, isTemporary: false)
        
        // 指定Annotationに相当するRouteの座標と同じになることを確認
        var coords: CLLocationCoordinate2D
        coords = annotationSet.getCoordinateFromTravel(annotation: self.tokyo)!
        XCTAssertEqual(annotationSet.travel.routes[0].startLocation.latitude, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(annotationSet.travel.routes[0].startLocation.longitude, coords.longitude, accuracy: COORD_ACCURACY)
        coords = annotationSet.getCoordinateFromTravel(annotation: self.skytree)!
        XCTAssertEqual(annotationSet.travel.routes[1].startLocation.latitude, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(annotationSet.travel.routes[1].startLocation.longitude, coords.longitude, accuracy: COORD_ACCURACY)
        coords = annotationSet.getCoordinateFromTravel(annotation: self.koiwa)!
        XCTAssertEqual(annotationSet.travel.routes[1].finishLocation.latitude, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(annotationSet.travel.routes[1].finishLocation.longitude, coords.longitude, accuracy: COORD_ACCURACY)
    }
    
    //
    // 歩行距離に応じたAnnotationの色を取得
    //
    func testGetAnnotationColor() async throws {
        let annotation = PointAnnotation()
        let annotationSet = AnnotationSetMock()
        
        // 経路が存在しないとき
        annotation.routeIndex = 0
        XCTAssertEqual(AnnotationColor.yet, annotationSet.getAnnotationColor(annotation: annotation))
        
        // 東京駅
        let _ = try await annotationSet.addAnnotation(annotation: self.tokyo, isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await annotationSet.addAnnotation(annotation: self.skytree, isTemporary: false)
        // 新小岩駅 (6.4km)
        let _ = try await annotationSet.addAnnotation(annotation: self.koiwa, isTemporary: false)
        
        annotationSet.travel.currentDistance = 0
        annotation.routeIndex = 0
        XCTAssertEqual(AnnotationColor.yet, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 1
        XCTAssertEqual(AnnotationColor.yet, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 2
        XCTAssertEqual(AnnotationColor.yet, annotationSet.getAnnotationColor(annotation: annotation))
        
        annotationSet.travel.currentDistance = 7000
        annotation.routeIndex = 0
        XCTAssertEqual(AnnotationColor.done, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 1
        XCTAssertEqual(AnnotationColor.done, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 2
        XCTAssertEqual(AnnotationColor.yet, annotationSet.getAnnotationColor(annotation: annotation))
        
        annotationSet.travel.currentDistance = 100000
        annotation.routeIndex = 0
        XCTAssertEqual(AnnotationColor.done, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 1
        XCTAssertEqual(AnnotationColor.done, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 2
        XCTAssertEqual(AnnotationColor.done, annotationSet.getAnnotationColor(annotation: annotation))
        
        annotation.routeIndex = -1
        XCTAssertEqual(AnnotationColor.other, annotationSet.getAnnotationColor(annotation: annotation))
        annotation.routeIndex = 100
        XCTAssertEqual(AnnotationColor.other, annotationSet.getAnnotationColor(annotation: annotation))
    }

}
