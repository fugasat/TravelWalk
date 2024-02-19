//


import XCTest

final class UtilTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStartOfDay() throws {
        let util = Util()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        var srcDate: Date
        var firstDate: Date
        var formattedTime: String

        srcDate = util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 2, hour: 12, minute: 34, second: 56))!
        firstDate = util.startOfDay(date: srcDate)
        formattedTime = dateFormatter.string(from: firstDate)
        XCTAssertEqual("20231102000000", formattedTime)

        srcDate = util.calendar.date(from: DateComponents(year: 2023, month: 12, day: 1, hour: 0, minute: 0, second: 0))!
        firstDate = util.startOfDay(date: srcDate)
        formattedTime = dateFormatter.string(from: firstDate)
        XCTAssertEqual("20231201000000", formattedTime)
    }

}
