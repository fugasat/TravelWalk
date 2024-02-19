import XCTest
import MapKit

let COORD_ACCURACY: Double = 0.00000001
let COORD_STEP_ACCURACY: Double = 0.7
let COORD_STEP_ACCURACY_REAL: Double = 0.001 // 実在の位置情報を利用する場合はこちらを使う

final class RouteStepTests: XCTestCase {
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitFromPolyline() throws {
        let coords:[CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 35.69425040000001, longitude: 139.78981050000004),
            CLLocationCoordinate2D(latitude: 35.694305199999995, longitude: 139.7898603),
            CLLocationCoordinate2D(latitude: 35.694333199999996, longitude: 139.7898685),
            CLLocationCoordinate2D(latitude: 35.6943487, longitude: 139.789781),
        ]
        let polyline = ColoredPolyline(coordinates: coords, count: coords.count)
        XCTAssertEqual(4, polyline.pointCount)

        let step = RouteStep(distance: 15.24, polyline: polyline)
        XCTAssertEqual(15.24, step.distance, accuracy: COORD_ACCURACY)
        
        var coords_point = CLLocationCoordinate2D()
        polyline.getCoordinates(&coords_point, range: NSRange(location: 0, length: 1))
        XCTAssertEqual(35.69425040000001, coords_point.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(139.78981050000004, coords_point.longitude, accuracy: COORD_ACCURACY)
        polyline.getCoordinates(&coords_point, range: NSRange(location: 1, length: 1))
        XCTAssertEqual(35.694305199999995, coords_point.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(139.7898603, coords_point.longitude, accuracy: COORD_ACCURACY)
        polyline.getCoordinates(&coords_point, range: NSRange(location: 3, length: 1))
        XCTAssertEqual(35.6943487, coords_point.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(139.789781, coords_point.longitude, accuracy: COORD_ACCURACY)
    }
    
}
