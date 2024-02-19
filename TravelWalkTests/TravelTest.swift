import XCTest
import MapKit

final class TravelTest: XCTestCase {

    var testDate: Date!
    var assertDate: Date!
    var routes: [Route]!

    override func setUpWithError() throws {
        let calendar = Calendar.current
        self.testDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.assertDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!

        let coords = [
            [
                CLLocationCoordinate2D(latitude: 10.1, longitude: 11.1),
                CLLocationCoordinate2D(latitude: 10.2, longitude: 11.2),
            ],
            [
                CLLocationCoordinate2D(latitude: 20.1, longitude: 21.1),
                CLLocationCoordinate2D(latitude: 20.2, longitude: 21.2),
            ],
            [
                CLLocationCoordinate2D(latitude: 30.1, longitude: 31.1),
                CLLocationCoordinate2D(latitude: 30.2, longitude: 31.2),
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
        try self.routes = [
            Route(routeSteps: routeSteps1, startLabel: "start1", finishLabel: "finish1"),
            Route(routeSteps: routeSteps2, startLabel: "start2", finishLabel: "finish2")
        ]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitEmpty() throws {
        let travel = Travel(startDate: self.testDate)
        
        // 基本情報を確認
        XCTAssertEqual(self.assertDate.timeIntervalSince1970, travel.startDate.timeIntervalSince1970)
        XCTAssertEqual(0, travel.currentDistance, accuracy: COORD_ACCURACY)
        XCTAssertEqual(0, travel.routes.count)

    }
    
    func testInit() throws {
        let travel = try Travel(startDate: self.testDate, routes: self.routes, currentDistance: 123)
            
        // 基本情報を確認
        XCTAssertEqual(self.assertDate.timeIntervalSince1970, travel.startDate.timeIntervalSince1970)

        XCTAssertEqual(10.1, travel.startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, travel.startLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(30.2, travel.finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, travel.finishLocation.longitude, accuracy: COORD_ACCURACY)

        XCTAssertEqual((100 + 200 + 300), travel.finishDistance, accuracy: COORD_ACCURACY)
        XCTAssertEqual(123, travel.currentDistance, accuracy: COORD_ACCURACY)

        XCTAssertEqual(2, travel.routes.count)
        XCTAssertEqual(100, travel.routes[0].distance)
        XCTAssertEqual(500, travel.routes[1].distance)

        // 各Stepの座標情報を確認(一部のみ)
        var coords = CLLocationCoordinate2D()
        travel.routes[0].routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, coords.longitude, accuracy: COORD_ACCURACY)
        travel.routes[1].routeSteps[1].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(30.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.1, coords.longitude, accuracy: COORD_ACCURACY)
    }

    func testGetLocation() throws {
        // RouteStepsから開始または終了の位置情報を取得
        let startLocation = try Travel.getLocation(routes: self.routes, isFirst: true)
        XCTAssertEqual(10.1, startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, startLocation.longitude, accuracy: COORD_ACCURACY)
        let finishLocation = try Travel.getLocation(routes: self.routes, isFirst: false)
        XCTAssertEqual(30.2, finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, finishLocation.longitude, accuracy: COORD_ACCURACY)
    }
    
    func testGetStartLocation() throws {
        // RouteStepsから開始位置情報を取得
        let location = try Travel.getStartLocation(routes: self.routes)
        XCTAssertEqual(10.1, location.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, location.longitude, accuracy: COORD_ACCURACY)
    }
    
    func testGetFinishLocation() throws {
        // RouteStepsから終了位置情報を取得
        let result = try Travel.getFinishLocation(routes: self.routes)
        XCTAssertEqual(30.2, result.location.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, result.location.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual((100 + 200 + 300), result.distance, accuracy: COORD_ACCURACY)
    }
    
    func testAddRoute() throws {
        // RouteStepsを追加して各種情報が更新されるか確認
        let newCoords = [
            [
                CLLocationCoordinate2D(latitude: 40.1, longitude: 41.1),
                CLLocationCoordinate2D(latitude: 40.2, longitude: 41.2),
            ],
            [
                CLLocationCoordinate2D(latitude: 50.1, longitude: 51.1),
                CLLocationCoordinate2D(latitude: 50.2, longitude: 51.2),
            ],
        ]
        let newRouteSteps = [
            RouteStep(distance: 400,
                      polyline: ColoredPolyline(coordinates: newCoords[0], count: newCoords[0].count)),
            RouteStep(distance: 500,
                      polyline: ColoredPolyline(coordinates: newCoords[1], count: newCoords[1].count)),
        ]
        let route = try Route(routeSteps: newRouteSteps, startLabel: "start_add", finishLabel: "finish_add")
        let travel = try Travel(startDate: self.testDate, routes: self.routes, currentDistance: 123)
        try travel.addRoute(route: route)
        
        // 基本情報を確認
        XCTAssertEqual(10.1, travel.startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, travel.startLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(50.2, travel.finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(51.2, travel.finishLocation.longitude, accuracy: COORD_ACCURACY)

        XCTAssertEqual((100 + 200 + 300 + 400 + 500), travel.finishDistance, accuracy: COORD_ACCURACY)
        XCTAssertEqual(123, travel.currentDistance, accuracy: COORD_ACCURACY)

        XCTAssertEqual(3, travel.routes.count)
        XCTAssertEqual(100, travel.routes[0].distance)
        XCTAssertEqual(500, travel.routes[1].distance)
        XCTAssertEqual(900, travel.routes[2].distance)

        XCTAssertEqual("start1", travel.routes[0].startLabel)
        XCTAssertEqual("finish1", travel.routes[0].finishLabel)
        XCTAssertEqual("start2", travel.routes[1].startLabel)
        XCTAssertEqual("finish2", travel.routes[1].finishLabel)
        XCTAssertEqual("start_add", travel.routes[2].startLabel)
        XCTAssertEqual("finish_add", travel.routes[2].finishLabel)

        
        // 各Stepの座標情報を確認(一部のみ)
        var coords = CLLocationCoordinate2D()
        travel.routes[0].routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, coords.longitude, accuracy: COORD_ACCURACY)
        travel.routes[1].routeSteps[1].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(30.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.1, coords.longitude, accuracy: COORD_ACCURACY)
        travel.routes[2].routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(40.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(41.1, coords.longitude, accuracy: COORD_ACCURACY)

    }

    func testIsFinish() throws {
        // currentDistanceからTravelがゴールに達しているかどうか判定する
        let travel = try Travel(startDate: self.testDate, routes: self.routes, currentDistance: 0)
        XCTAssertFalse(travel.isFinish())
        travel.currentDistance = 100
        XCTAssertFalse(travel.isFinish())
        travel.currentDistance = 599.999
        XCTAssertFalse(travel.isFinish())

        // 距離が600以上ならゴール
        travel.currentDistance = 600
        XCTAssertTrue(travel.isFinish())
        travel.currentDistance = 10000
        XCTAssertTrue(travel.isFinish())
    }

    func testIsFinishWithNoRoute() throws {
        let travel = Travel(startDate: Date())
        XCTAssertFalse(travel.isFinish())
        travel.currentDistance = 0
        XCTAssertFalse(travel.isFinish())
        travel.currentDistance = 100
        XCTAssertFalse(travel.isFinish())
    }
    
    func testUpdateCurrentRoute() throws {
        // currentDistanceに応じたCurrentRouteStepsが生成されるか確認
        let currentCoordsForTest = [
            [
                CLLocationCoordinate2D(latitude: 10, longitude: 10),
                CLLocationCoordinate2D(latitude: 11, longitude: 10),
            ],
            [
                CLLocationCoordinate2D(latitude: 20, longitude: 20),
                CLLocationCoordinate2D(latitude: 21, longitude: 20),
                CLLocationCoordinate2D(latitude: 21, longitude: 21),
            ],
            [
                CLLocationCoordinate2D(latitude: 30, longitude: 30),
                CLLocationCoordinate2D(latitude: 31, longitude: 30),
                CLLocationCoordinate2D(latitude: 31, longitude: 31),
                CLLocationCoordinate2D(latitude: 32, longitude: 31),
            ],
        ]
        let currentRouteStepsForTest1 = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[0], count: currentCoordsForTest[0].count)),
        ]
        let currentRouteStepsForTest2 = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[1], count: currentCoordsForTest[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[2], count: currentCoordsForTest[2].count)),
        ]
        let routesForTest = try [
            Route(routeSteps: currentRouteStepsForTest1, startLabel: "start1", finishLabel: "finish1"),
            Route(routeSteps: currentRouteStepsForTest2, startLabel: "start2", finishLabel: "finish2")
        ]

        let travel = try Travel(startDate: self.testDate, routes: routesForTest, currentDistance: 0)
        XCTAssertNil(travel.routes[0].currentRouteSteps)
        XCTAssertNil(travel.routes[1].currentRouteSteps)

        // Route0 : Step0の中点を指定
        travel.currentDistance = 50
        XCTAssertEqual(1, travel.routes[0].currentRouteSteps!.count)
        XCTAssertEqual(50, travel.routes[0].currentRouteSteps![0].distance, accuracy: COORD_ACCURACY)
        XCTAssertNil(travel.routes[1].currentRouteSteps)

        // Route1 : Step1-3の中点を指定
        travel.currentDistance = 550
        XCTAssertNil(travel.routes[0].currentRouteSteps)
        XCTAssertEqual(2, travel.routes[1].currentRouteSteps!.count)
        XCTAssertEqual(200, travel.routes[1].currentRouteSteps![0].distance, accuracy: COORD_ACCURACY) // Step0
        XCTAssertEqual(250, travel.routes[1].currentRouteSteps![1].distance, accuracy: COORD_ACCURACY) // Step1
        
        // Route1 : 終点よりも先の地点を指定
        travel.currentDistance = 1000
        XCTAssertNil(travel.routes[0].currentRouteSteps)
        XCTAssertNil(travel.routes[1].currentRouteSteps)
    }
    
    //
    // 本日の歩行経路からPolylineを作成できているか確認
    // 現在位置がPolylineの最後の位置で設定されることを確認
    //
    func testCreateTodayRoute() throws {
        let currentCoordsForTest = [
            [
                CLLocationCoordinate2D(latitude: 10, longitude: 10),
                CLLocationCoordinate2D(latitude: 20, longitude: 10),
            ],
            [
                CLLocationCoordinate2D(latitude: 20, longitude: 10),
                CLLocationCoordinate2D(latitude: 30, longitude: 20),
                CLLocationCoordinate2D(latitude: 40, longitude: 20),
            ],
            [
                CLLocationCoordinate2D(latitude: 40, longitude: 20),
                CLLocationCoordinate2D(latitude: 50, longitude: 30),
                CLLocationCoordinate2D(latitude: 60, longitude: 30),
                CLLocationCoordinate2D(latitude: 70, longitude: 30),
            ],
        ]
        let currentRouteStepsForTest1 = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[0], count: currentCoordsForTest[0].count)),
        ]
        let currentRouteStepsForTest2 = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[1], count: currentCoordsForTest[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[2], count: currentCoordsForTest[2].count)),
        ]
        let routesForTest = try [
            Route(routeSteps: currentRouteStepsForTest1, startLabel: "start1", finishLabel: "finish1"),
            Route(routeSteps: currentRouteStepsForTest2, startLabel: "start2", finishLabel: "finish2")
        ]
        let travel = try Travel(startDate: self.testDate, routes: routesForTest, currentDistance: 0)
        var polyline: ColoredPolyline? = nil
        var coords = CLLocationCoordinate2D()

        travel.currentDistance = 350
        travel.todayDistance = 100
        polyline = travel.createTodayRoute()
        
        // Polylineが想定通りに作成されているか確認
        XCTAssertEqual(3, polyline?.pointCount)
        
        polyline?.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(35, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(20, coords.longitude, accuracy: COORD_STEP_ACCURACY)
        polyline?.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(40, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(20, coords.longitude, accuracy: COORD_STEP_ACCURACY)
        polyline?.getCoordinates(&coords, range: NSRange(location: 2, length: 1))
        XCTAssertEqual(45, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(25, coords.longitude, accuracy: COORD_STEP_ACCURACY)
        
        // 現在位置を確認
        // Polylineの最後の位置が現在位置になる
        XCTAssertEqual(45, travel.currentLocation!.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(25, travel.currentLocation!.longitude, accuracy: COORD_STEP_ACCURACY)


    }

    func testHasRoute() throws {
        let travel = Travel(startDate: Date())
        XCTAssertFalse(travel.hasRoute())
        
        let currentCoordsForTest = [
            CLLocationCoordinate2D(latitude: 10, longitude: 10),
            CLLocationCoordinate2D(latitude: 20, longitude: 10),
        ]
        let currentRouteStepsForTest = RouteStep(
            distance: 100,
            polyline: ColoredPolyline(coordinates: currentCoordsForTest, count: currentCoordsForTest.count))
        let routesForTest = try Route(routeSteps: [currentRouteStepsForTest], startLabel: "start1", finishLabel: "finish1")
        try travel.addRoute(route: routesForTest)
        XCTAssertTrue(travel.hasRoute())
    }
    
    //
    // 最新の通過済Annotationのindexを取得
    //
    func testGetCompletedAnnotationIndex() async throws {
        let travel = Travel(startDate: Date())
        travel.currentDistance = 0

        XCTAssertEqual(-1, travel.getCompletedAnnotationIndex())

        let currentCoords1 = [TestCoordinate.tokyo, TestCoordinate.skytree]
        let routeStep1 = RouteStep(distance: 5000, polyline: ColoredPolyline(coordinates: currentCoords1, count: currentCoords1.count))
        let route1 = try Route(routeSteps: [routeStep1], startLabel: "start1", finishLabel: "finish1")
        let currentCoords2 = [TestCoordinate.skytree, TestCoordinate.koiwa]
        let routeStep2 = RouteStep(distance: 5000, polyline: ColoredPolyline(coordinates: currentCoords2, count: currentCoords2.count))
        let route2 = try Route(routeSteps: [routeStep2], startLabel: "start2", finishLabel: "finish2")
        try travel.addRoute(route: route1)
        try travel.addRoute(route: route2)

        XCTAssertEqual(-1, travel.getCompletedAnnotationIndex())
        travel.currentDistance = 1
        XCTAssertEqual(0, travel.getCompletedAnnotationIndex())
        travel.currentDistance = 7000
        XCTAssertEqual(1, travel.getCompletedAnnotationIndex())
        travel.currentDistance = 70000
        XCTAssertEqual(2, travel.getCompletedAnnotationIndex())
    }
    
    func testUpdateInformation() throws {
        class TravelMock: Travel {
            var isUpdateCurrentRoute = false
            override func updateCurrentRoute() {
                self.isUpdateCurrentRoute = true
            }
        }
        let travel = TravelMock(startDate: Date())
        
        // 経路を持たない状態では何も起きない
        try travel.updateInformation()
        XCTAssertFalse(travel.isUpdateCurrentRoute)
        
        // Travelに経路を設定
        let currentCoords1 = [TestCoordinate.tokyo, TestCoordinate.skytree]
        let routeStep1 = RouteStep(distance: 5000, polyline: ColoredPolyline(coordinates: currentCoords1, count: currentCoords1.count))
        let route1 = try Route(routeSteps: [routeStep1], startLabel: "start1", finishLabel: "finish1")
        travel.routes.append(route1)

        // 経路に応じた情報が設定される
        try travel.updateInformation()
        XCTAssertEqual(TestCoordinate.tokyo.latitude, travel.startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, travel.startLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(TestCoordinate.skytree.latitude, travel.finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(TestCoordinate.skytree.longitude, travel.finishLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertTrue(travel.finishDistance > 0)
        XCTAssertTrue(travel.isUpdateCurrentRoute)
    }

    //
    // 終了済Travel一覧に表示するラベルを取得
    //
    func testGetFinishedTravelDisplayLabel() async throws {
        let calendar = Calendar.current
        
        // 経路が存在しない場合は「準備中」と表記する
        let startDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 1))!
        var travel = Travel(startDate: startDate)
        travel.finishedDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        
        XCTAssertEqual("2023/12/01 新規 (準備中)", travel.getFinishedTravelDisplayLabel())
        
        travel.isStop = true
        XCTAssertEqual("2023/12/01 新規 (準備中)", travel.getFinishedTravelDisplayLabel())
        
        // 経路が存在する場合は「実行中」と表記する
        let viewManagwr = ViewManager()
        travel = try Travel(
            startDate: startDate,
            routes: [try viewManagwr.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        travel.finishedDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        XCTAssertEqual("2023/12/01 新規 (実行中)", travel.getFinishedTravelDisplayLabel())
        
        // 停止中＆目的地未到達の場合は旅の名前と一緒に「中断」の表記を行う
        travel.name = "test"
        travel.isStop = true
        XCTAssertEqual("2023/12/01 test (中断)", travel.getFinishedTravelDisplayLabel())
        
        // 停止中＆目的地到達の場合は旅の名前と一緒に「完了」の表記を行う
        travel.currentDistance = 10000
        XCTAssertEqual("2023/12/01 test (完了)", travel.getFinishedTravelDisplayLabel())
    }
}
