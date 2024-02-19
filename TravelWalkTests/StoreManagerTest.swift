import XCTest
import MapKit

final class StoreManagerTest: XCTestCase {
    
    var testDate: Date!
    var assertDate: Date!
    var testFinishedDate: Date!
    var assertFinishedDate: Date!
    var testCoords: [[CLLocationCoordinate2D]]!
    let storeManager = StoreManager()
    
    // load時に不正なObjectを返すMockクラス
    class StoreManagerErrorStub: StoreManager {
        override func loadObject(key: String) -> Data? {
            if let data = super.loadObject(key: key) {
                return data
            } else {
                return Data()
            }
        }
    }
    
    override func setUpWithError() throws {
        self.storeManager.isTest = true
        self.storeManager.userDefaults.removeObject(forKey: "test_routeStep")
        self.storeManager.userDefaults.removeObject(forKey: "test_route")
        self.storeManager.userDefaults.removeObject(forKey: "test_travel")
        self.storeManager.userDefaults.removeObject(forKey: "test_walkingdistance")
        
        let calendar = Calendar.current
        self.testDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.assertDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.testFinishedDate = calendar.date(from: DateComponents(year: 2022, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.assertFinishedDate = calendar.date(from: DateComponents(year: 2022, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.testCoords = [
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
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// テストデータを削除できるか確認
    func testInitializeTestData() throws {
        let routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routes = try [
            Route(routeSteps: routeSteps, startLabel: "start", finishLabel: "finish"),
        ]
        let testTravel = try Travel(startDate: self.testDate, routes: routes, currentDistance: 123)
        let testWalkingDistance = WalkingDistance(distance: 0, toDate: Date())
        self.storeManager.save(travel: testTravel, walkingDistance: testWalkingDistance)
        self.storeManager.initializeTestData()
        let travel = self.storeManager.loadTravel()
        let walkingDistance = self.storeManager.loadWalkingDistance()
        XCTAssertNil(travel)
        XCTAssertNil(walkingDistance)
    }
    
    func testRouteStep() throws {
        let testRouteStep = RouteStep(distance: 100,
                                      polyline: ColoredPolyline(coordinates: self.testCoords[0], count: self.testCoords[0].count))
        
        self.storeManager.save(routeStep: testRouteStep)
        let routeStep: RouteStep! = self.storeManager.loadRouteStep()
        
        XCTAssertEqual(100, routeStep.distance)
        var storedCoords = CLLocationCoordinate2D()
        routeStep.polyline.getCoordinates(&storedCoords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(10.1, storedCoords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, storedCoords.longitude, accuracy: COORD_ACCURACY)
        routeStep.polyline.getCoordinates(&storedCoords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, storedCoords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, storedCoords.longitude, accuracy: COORD_ACCURACY)
        
        // nilを渡すと削除される
        self.storeManager.save(routeStep: nil)
        let removed: RouteStep? = self.storeManager.loadRouteStep()
        XCTAssertNil(removed)
    }
    
    func testLoad() throws {
        // 何も保存されていない初期状態でloadしても問題いないことを確認
        var travel = self.storeManager.loadTravel()
        var walkingDistance = self.storeManager.loadWalkingDistance()
        XCTAssertNil(travel)
        XCTAssertNil(walkingDistance)
        
        // 保存した後にloadできることを確認
        let routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routes = try [
            Route(routeSteps: routeSteps, startLabel: "start", finishLabel: "finish"),
        ]
        let testTravel = try Travel(startDate: self.testDate, routes: routes, currentDistance: 123)
        let testWalkingDistance = WalkingDistance(distance: 0, toDate: Date())
        self.storeManager.save(travel: testTravel, walkingDistance: testWalkingDistance)
        travel = self.storeManager.loadTravel()
        walkingDistance = self.storeManager.loadWalkingDistance()
        XCTAssertNotNil(travel)
        XCTAssertNotNil(walkingDistance)
    }
    
    func testRoute() throws {
        let routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: self.testCoords[0], count: self.testCoords[0].count)),
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: self.testCoords[1], count: self.testCoords[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: self.testCoords[2], count: self.testCoords[2].count)),
        ]
        let testRoute = try Route(routeSteps: routeSteps, startLabel: "start", finishLabel: "finish")
        
        self.storeManager.save(route: testRoute)
        let route: Route! = self.storeManager.loadRoute()
        
        // 基本情報を確認
        XCTAssertEqual("start", route.startLabel)
        XCTAssertEqual("finish", route.finishLabel)
        
        XCTAssertNil(route.currentRouteSteps)
        XCTAssertEqual(10.1, route.startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, route.startLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(30.2, route.finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, route.finishLocation.longitude, accuracy: COORD_ACCURACY)
        
        XCTAssertEqual(3, route.routeSteps.count)
        XCTAssertEqual(100, route.routeSteps[0].distance)
        XCTAssertEqual(200, route.routeSteps[1].distance)
        XCTAssertEqual(300, route.routeSteps[2].distance)
        
        // 各Stepの座標情報を確認
        var coords = CLLocationCoordinate2D()
        route.routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(10.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, coords.longitude, accuracy: COORD_ACCURACY)
        route.routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, coords.longitude, accuracy: COORD_ACCURACY)
        
        route.routeSteps[1].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(20.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(21.1, coords.longitude, accuracy: COORD_ACCURACY)
        route.routeSteps[1].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(20.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(21.2, coords.longitude, accuracy: COORD_ACCURACY)
        
        route.routeSteps[2].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(30.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.1, coords.longitude, accuracy: COORD_ACCURACY)
        route.routeSteps[2].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(30.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, coords.longitude, accuracy: COORD_ACCURACY)
        
        // nilを渡すと削除される
        self.storeManager.save(route: nil)
        let removed: Route? = self.storeManager.loadRoute()
        XCTAssertNil(removed)
    }
    
    func testTravel() throws {
        let routeSteps1 = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routeSteps2 = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: testCoords[1], count: testCoords[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: testCoords[2], count: testCoords[2].count)),
        ]
        let routes = try [
            Route(routeSteps: routeSteps1, startLabel: "start1", finishLabel: "finish1"),
            Route(routeSteps: routeSteps2, startLabel: "start2", finishLabel: "finish2")
        ]
        let testTravel = try Travel(startDate: self.testDate, routes: routes, currentDistance: 123)
        testTravel.name = "test"
        testTravel.isStop = true
        testTravel.finishedDate = self.testFinishedDate
        
        self.storeManager.save(travel: testTravel)
        let travel: Travel! = self.storeManager.loadTravel()
        
        // 基本情報を確認
        XCTAssertEqual("test", travel.name)
        XCTAssertEqual(self.assertDate.timeIntervalSince1970, travel.startDate.timeIntervalSince1970)
        XCTAssertEqual(self.assertFinishedDate.timeIntervalSince1970, travel.finishedDate.timeIntervalSince1970)
        XCTAssertTrue(travel.isStop)

        XCTAssertEqual(10.1, travel.startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, travel.startLocation.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(30.2, travel.finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, travel.finishLocation.longitude, accuracy: COORD_ACCURACY)
        
        XCTAssertEqual((100 + 200 + 300), travel.finishDistance, accuracy: COORD_ACCURACY)
        XCTAssertEqual(123, travel.currentDistance, accuracy: COORD_ACCURACY)
        
        XCTAssertEqual(2, travel.routes.count)
        XCTAssertEqual(100, travel.routes[0].distance)
        XCTAssertEqual(500, travel.routes[1].distance)
        XCTAssertEqual("start1", travel.routes[0].startLabel)
        XCTAssertEqual("finish1", travel.routes[0].finishLabel)
        XCTAssertEqual("start2", travel.routes[1].startLabel)
        XCTAssertEqual("finish2", travel.routes[1].finishLabel)
        
        // 各Stepの座標情報を確認(一部のみ)
        var coords = CLLocationCoordinate2D()
        travel.routes[0].routeSteps[0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, coords.longitude, accuracy: COORD_ACCURACY)
        travel.routes[1].routeSteps[1].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(30.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.1, coords.longitude, accuracy: COORD_ACCURACY)
    }
    
    func testWalkingDistance() throws {
        let calendar = Calendar.current
        self.testDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        self.assertDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 19, hour: 18, minute: 0, second: 0))!
        
        let testWalkingDistance = WalkingDistance(distance: 1234, toDate: self.testDate)
        self.storeManager.save(walkingDistance: testWalkingDistance)
        let walkingDistance: WalkingDistance! = self.storeManager.loadWalkingDistance()
        
        // 基本情報を確認
        XCTAssertEqual(1234, walkingDistance.distance)
        XCTAssertEqual(self.assertDate.timeIntervalSince1970, walkingDistance.toDate.timeIntervalSince1970)
        
        // nilを渡すと削除される
        self.storeManager.save(walkingDistance: nil)
        let removed: WalkingDistance? = self.storeManager.loadWalkingDistance()
        XCTAssertNil(removed)
    }
    
    //
    // loadに失敗した際はsave操作を無効にする
    //
    func testLoadErrorOnTravel() throws {
        let storeManager = StoreManagerErrorStub()
        storeManager.isTest = true
        var travel: Travel?
        var walkingDistance: WalkingDistance?
        
        travel = storeManager.loadTravel()
        XCTAssertNil(travel)
        XCTAssertTrue(storeManager.isLoadError)
        
        // エラーが発生した時はsaveできないことを確認
        let routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routes = try [
            Route(routeSteps: routeSteps, startLabel: "start", finishLabel: "finish"),
        ]
        let testTravel = try Travel(startDate: self.testDate, routes: routes, currentDistance: 123)
        let testWalkingDistance = WalkingDistance(distance: 0, toDate: Date())
        storeManager.save(travel: testTravel, walkingDistance: testWalkingDistance)
        
        travel = storeManager.loadTravel()
        XCTAssertNil(travel)
        XCTAssertTrue(storeManager.isLoadError)
        
        walkingDistance = storeManager.loadWalkingDistance()
        XCTAssertNil(walkingDistance)
        XCTAssertTrue(storeManager.isLoadError)
    }
    
    //
    // loadに失敗した際はsave操作を無効にする
    //
    func testLoadErrorOnWalkingDistance() throws {
        let storeManager = StoreManagerErrorStub()
        storeManager.isTest = true
        var travel: Travel?
        var walkingDistance: WalkingDistance?
        
        walkingDistance = storeManager.loadWalkingDistance()
        XCTAssertNil(walkingDistance)
        XCTAssertTrue(storeManager.isLoadError)
        
        // エラーが発生した時はsaveできないことを確認
        let routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routes = try [
            Route(routeSteps: routeSteps, startLabel: "start", finishLabel: "finish"),
        ]
        let testTravel = try Travel(startDate: self.testDate, routes: routes, currentDistance: 123)
        let testWalkingDistance = WalkingDistance(distance: 0, toDate: Date())
        storeManager.save(travel: testTravel, walkingDistance: testWalkingDistance)

        travel = storeManager.loadTravel()
        XCTAssertNil(travel)
        XCTAssertTrue(storeManager.isLoadError)
        
        walkingDistance = storeManager.loadWalkingDistance()
        XCTAssertNil(walkingDistance)
        XCTAssertTrue(storeManager.isLoadError)
    }
    
    func testFinishedTravel() throws {
        let routeSteps1 = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: testCoords[0], count: testCoords[0].count)),
        ]
        let routeSteps2 = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: testCoords[1], count: testCoords[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: testCoords[2], count: testCoords[2].count)),
        ]
        let routes1 = try [
            Route(routeSteps: routeSteps1, startLabel: "start1", finishLabel: "finish1"),
        ]
        let routes12 = try [
            Route(routeSteps: routeSteps1, startLabel: "start1", finishLabel: "finish1"),
            Route(routeSteps: routeSteps2, startLabel: "start2", finishLabel: "finish2")
        ]
        let testTravel1 = try Travel(startDate: self.testDate, routes: routes1, currentDistance: 100)
        let testTravel2 = try Travel(startDate: self.testDate, routes: routes12, currentDistance: 100)
        let testTravel3 = try Travel(startDate: self.testDate, routes: [], currentDistance: 200)

        let testFinishedTravels = [testTravel1, testTravel2, testTravel3]
        
        // 保存されることを確認
        // RouteなしのTravelも保存される
        self.storeManager.save(finishedTravels: testFinishedTravels)
        let finishedTravels = self.storeManager.loadFinishedTravels()
        XCTAssertEqual(3, finishedTravels.count)
        XCTAssertEqual("finish1", finishedTravels[0].routes.last?.finishLabel)
        XCTAssertEqual("finish2", finishedTravels[1].routes.last?.finishLabel)
        XCTAssertEqual(0, finishedTravels[2].routes.count)

        self.storeManager.save(finishedTravels: [])
        let removed = self.storeManager.loadFinishedTravels()
        XCTAssertEqual(0, removed.count)
    }
}
