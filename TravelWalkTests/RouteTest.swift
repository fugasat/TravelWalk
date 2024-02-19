import XCTest
import MapKit

final class RouteTest: XCTestCase {

    var routeSteps: [RouteStep]!

    override func setUpWithError() throws {
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
        self.routeSteps = [
            RouteStep(distance: 100,
                      polyline: ColoredPolyline(coordinates: coords[0], count: coords[0].count)),
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: coords[1], count: coords[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: coords[2], count: coords[2].count)),
        ]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        let route = try Route(routeSteps: self.routeSteps, startLabel: "start", finishLabel: "finish")
            
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
    }
    
    func testInitByRouteStepsIsEmpty() throws {
        // Stepsが空の場合はTravel生成は無効
        do {
            _ = try Route(routeSteps: [], startLabel: "start", finishLabel: "finish")
            XCTFail()
        } catch {
            XCTAssertEqual(TravelError.invalidRoute, error as! TravelError)
        }
    }
    
    func testGetLocation() throws {
        // RouteStepsから開始&終了の位置情報を取得
        let startLocation = try Route.getLocation(steps: self.routeSteps, isFirst: true)
        XCTAssertEqual(10.1, startLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, startLocation.longitude, accuracy: COORD_ACCURACY)
        let finishLocation = try Route.getLocation(steps: self.routeSteps, isFirst: false)
        XCTAssertEqual(30.2, finishLocation.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, finishLocation.longitude, accuracy: COORD_ACCURACY)
    }

    func testGetStartLocation() throws {
        // RouteStepsから開始位置情報を取得
        let location = try Route.getStartLocation(steps: self.routeSteps)
        XCTAssertEqual(10.1, location.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, location.longitude, accuracy: COORD_ACCURACY)
    }
    
    func testGetFinishLocation() throws {
        // RouteStepsから終了位置情報を取得
        let result = try Route.getFinishLocation(steps: self.routeSteps)
        XCTAssertEqual(30.2, result.location.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, result.location.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual((100 + 200 + 300), result.distance, accuracy: COORD_ACCURACY)
    }

    func testCreatePolyline() throws {
        let polyline = Route.createPolyline(routeSteps: self.routeSteps)
        XCTAssertEqual(4, polyline.pointCount)
        var coords = CLLocationCoordinate2D()
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(10.1, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.1, coords.longitude, accuracy: COORD_ACCURACY)
        polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(11.2, coords.longitude, accuracy: COORD_ACCURACY)
        polyline.getCoordinates(&coords, range: NSRange(location: 3, length: 1))
        XCTAssertEqual(30.2, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31.2, coords.longitude, accuracy: COORD_ACCURACY)

    }
    
    func testUpdateCurrentRoute() throws {
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
        var coords = CLLocationCoordinate2D()

        var route = try Route(routeSteps: currentRouteStepsForTest1, startLabel: "start", finishLabel: "finish")

        try route.updateCurrentRouteSteps(currentDistance: -1)
        XCTAssertNil(route.currentRouteSteps)

        try route.updateCurrentRouteSteps(currentDistance: 0)
        XCTAssertNil(route.currentRouteSteps)

        try route.updateCurrentRouteSteps(currentDistance: 1000)
        XCTAssertNil(route.currentRouteSteps)

        // Route1 : Step0の中点を指定
        try route.updateCurrentRouteSteps(currentDistance: 50)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(50, route.currentRouteSteps![0].distance, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![0].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(10, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(10, coords.longitude, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(10.5, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(10, coords.longitude, accuracy: COORD_ACCURACY)

        // Route1 : Step0の終点を指定
        try route.updateCurrentRouteSteps(currentDistance: 100)
        XCTAssertNil(route.currentRouteSteps)

        // Route2 : Step0-0の中点を指定
        route = try Route(routeSteps: currentRouteStepsForTest2, startLabel: "start", finishLabel: "finish")
        try route.updateCurrentRouteSteps(currentDistance: 150 - 100)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(50, route.currentRouteSteps![0].distance, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![0].polyline.getCoordinates(&coords, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(20, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(20, coords.longitude, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(20.5, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(20, coords.longitude, accuracy: COORD_STEP_ACCURACY)

        // Route2 : Step0-0の終点を指定
        try route.updateCurrentRouteSteps(currentDistance: 200 - 100)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(100, route.currentRouteSteps![0].distance, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![0].polyline.getCoordinates(&coords, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(21, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(20, coords.longitude, accuracy: COORD_STEP_ACCURACY)

        // Route2 : Step1-3の中点を指定
        try route.updateCurrentRouteSteps(currentDistance: 550 - 100)
        XCTAssertEqual(2, route.currentRouteSteps!.count)
        XCTAssertEqual(200, route.currentRouteSteps![0].distance, accuracy: COORD_ACCURACY) // Step0
        XCTAssertEqual(250, route.currentRouteSteps![1].distance, accuracy: COORD_ACCURACY) // Step1
        route.currentRouteSteps![1].polyline.getCoordinates(&coords, range: NSRange(location: 2, length: 1))
        XCTAssertEqual(31, coords.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(31, coords.longitude, accuracy: COORD_ACCURACY)
        route.currentRouteSteps![1].polyline.getCoordinates(&coords, range: NSRange(location: 3, length: 1))
        XCTAssertEqual(31.5, coords.latitude, accuracy: COORD_STEP_ACCURACY)
        XCTAssertEqual(31, coords.longitude, accuracy: COORD_STEP_ACCURACY)

    }
    
    func testPolylineColorByUpdateCurrentRoute() throws {
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
        let currentRouteStepsForTest = [
            RouteStep(distance: 200,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[1], count: currentCoordsForTest[1].count)),
            RouteStep(distance: 300,
                      polyline: ColoredPolyline(coordinates: currentCoordsForTest[2], count: currentCoordsForTest[2].count)),
        ]

        let route = try Route(routeSteps: currentRouteStepsForTest, startLabel: "start", finishLabel: "finish")

        try route.updateCurrentRouteSteps(currentDistance: -1)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertNil(route.currentRouteSteps)

        try route.updateCurrentRouteSteps(currentDistance: 0)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertNil(route.currentRouteSteps)

        try route.updateCurrentRouteSteps(currentDistance: 1)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(AnnotationColor.done, route.currentRouteSteps![0].polyline.color)

        try route.updateCurrentRouteSteps(currentDistance: 200)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(AnnotationColor.done, route.currentRouteSteps![0].polyline.color)

        try route.updateCurrentRouteSteps(currentDistance: 201)
        XCTAssertEqual(AnnotationColor.done, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertEqual(2, route.currentRouteSteps!.count)
        XCTAssertEqual(AnnotationColor.done, route.currentRouteSteps![0].polyline.color)
        XCTAssertEqual(AnnotationColor.done, route.currentRouteSteps![1].polyline.color)

        try route.updateCurrentRouteSteps(currentDistance: 500)
        XCTAssertEqual(AnnotationColor.done, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.done, route.routeSteps[1].polyline.color)
        XCTAssertNil(route.currentRouteSteps) // 全て歩行済の場合はcurrentRouteStepsは表示しない

        // 歩行距離を戻しても正しく色が設定されることを確認する
        try route.updateCurrentRouteSteps(currentDistance: 1)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertEqual(1, route.currentRouteSteps!.count)
        XCTAssertEqual(AnnotationColor.done, route.currentRouteSteps![0].polyline.color)

        try route.updateCurrentRouteSteps(currentDistance: 0)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertNil(route.currentRouteSteps)

        try route.updateCurrentRouteSteps(currentDistance: -1)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[0].polyline.color)
        XCTAssertEqual(AnnotationColor.yet, route.routeSteps[1].polyline.color)
        XCTAssertNil(route.currentRouteSteps)

    }
}
