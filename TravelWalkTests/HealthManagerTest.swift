//


import XCTest

final class HealthManagerTest: XCTestCase {
    
    var fromDate: Date?
    var toDate: Date?
    var lastRetrieveDate: Date?
    var value: Double?
    var answer: Int = 0
    let formatter = DateFormatter()
    let formatterWithTime = DateFormatter()
    let healthManager = Manager()

    override func setUpWithError() throws {
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyyMMdd"
        formatterWithTime.timeZone = TimeZone.current
        formatterWithTime.locale = Locale.current
        formatterWithTime.dateFormat = "yyyyMMddHHmmss"
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    class Manager: HealthManager {
        
        var usedFromDate: Date?
        var usedToDate: Date?

        override func getTotalWalkingDistance(fromDate: Date, toDate: Date) async throws -> Double {
            self.usedFromDate = nil
            self.usedToDate = nil
            return try await super.getTotalWalkingDistance(fromDate: fromDate, toDate: toDate)
        }

        override func getWalkingDistance(fromDate: Date, toDate: Date) async throws -> [Date: Double] {
            // ウォーキング＋ランニングの距離
            // 2023/8/1 : 800m
            // 2023/9/1 : 900m
            // 2023/10/1 : 1000m
            // 2023/11/1 : 1100m
            self.usedFromDate = fromDate
            self.usedToDate = toDate
            let values = [
                self.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1))!: Double(800),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 9, day: 1))!: Double(900),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 10, day: 1))!: Double(1000),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!: Double(1100),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 2, hour: 0, minute: 0, second: 0))!: Double(200),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 2, hour: 23, minute: 59, second: 59))!: Double(201),
                self.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))!: Double(300),
            ]
            var values_result:[Date: Double] = [:]
            for value in values {
                if value.key >= fromDate && value.key < toDate {
                    values_result[value.key] = value.value
                }
            }
            return values_result
        }
    }
    
    ///
    /// 保存データが無い状態で総歩行距離を取得
    ///  歩行距離は保存されていないため、HealthKitのデータがそのまま反映される
    ///
    func testGetTotalWalkingDistanceNoStoreValueFrom0801To1101() async throws {
        // 取得対象範囲 8/1-11/1(10/31 23:59:59)まで
        fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))!
        toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 1, hour: 0, minute: 0, second: 0))!
        
        // toDateのデータ(11/1 1100m)は取得対象にならない
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        // 8/1(800m) + 9/1(900m) + 10/1(1000m)
        answer = 800 + 900 + 1000
        XCTAssertEqual(answer, Int(value!))
        
        // 保存対象データ
        //  11/1(10/31 23:59:59)まで
        //  8/1(800m) + 9/1(900m) + 10/1(1000m)
        XCTAssertEqual("20231101", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 800 + 900 + 1000
        XCTAssertEqual(answer, Int(value!))
    }

    ///
    /// 保存データが無い状態で総歩行距離を取得
    ///  歩行距離は保存されていないため、HealthKitのデータがそのまま反映される
    ///
    func testGetTotalWalkingDistanceNoStoreValueFrom0801To1102100000() async throws {
        // 取得対象範囲 8/1-11/2(11/1 23:59:59)まで
        fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))!
        toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 2, hour: 10, minute: 0, second: 0))!
        
        // toDateのデータ(11/2 23:59:59 (201)m)は取得対象にならない
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        // 8/1(800m) + 9/1(900m) + 10/1(1000m) + 11/1(1100m) + 11/2 10:00:00(200m)
        answer = 800 + 900 + 1000 + 1100 + 200
        XCTAssertEqual(answer, Int(value!))
        
        // 保存対象データ
        //  11/2(11/1 23:59:59)まで
        //  8/1(800m) + 9/1(900m) + 10/1(1000m) + 11/1(1100m)
        XCTAssertEqual("20231102", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 800 + 900 + 1000 + 1100
        XCTAssertEqual(answer, Int(value!))
    }

    ///
    /// 保存データが無い状態で総歩行距離を取得
    ///  歩行距離は保存されていないため、HealthKitのデータがそのまま反映される
    ///
    func testGetTotalWalkingDistanceNoStoreValueFrom0801To1103() async throws {
        // 取得対象範囲 8/1-11/3(11/2 23:59:59)まで
        fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))!
        toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))!

        // toDateのデータ(11/3 300m)は取得対象にならない
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        // 8/1(800m) + 9/1(900m) + 10/1(1000m) + 11/1(1100m) + 11/2 0:00(200m) + 11/2 23:59:59(201m)
        answer = 800 + 900 + 1000 + 1100 + 200 + 201
        XCTAssertEqual(answer, Int(value!))
        
        // 保存対象データ
        //  11/2(11/1 23:59:59)まで
        // 8/1(800m) + 9/1(900m) + 10/1(1000m) + 11/1(1100m) + 11/2 0:00(200m) + 11/2 23:59:59(201m)
        XCTAssertEqual("20231103", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 800 + 900 + 1000 + 1100 + 200 + 201
        XCTAssertEqual(answer, Int(value!))
    }

    ///
    /// 保存データが存在する状態で総歩行距離を取得（保存データの更新は無し）
    ///  HealthKitよりも保存データの値が優先される
    ///
    func testGetTotalWalkingDistanceWithStoreValueByNoUpdate() async throws {
        // 取得対象範囲 8/1-11/4 (11/3 23:59:59)まで
        fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))
        toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 4, hour: 0, minute: 0, second: 0))

        // 保存データ：11/3(11/2 23:59:59)まで10000m歩行
        lastRetrieveDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))
        healthManager.storedWalkingDistance = WalkingDistance(distance: 10000, toDate: lastRetrieveDate!)

        // 歩行データ取得
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)

        // 関数の引数は8/1-11/4の範囲だが、HealthKitへのリクエストは11/3-11/4になる
        XCTAssertEqual("20231103", formatter.string(from: healthManager.usedFromDate!))
        XCTAssertEqual("20231104", formatter.string(from: healthManager.usedToDate!))

        // 保存データ(10000m) + HealthKitデータ(300m) = 10300mになる
        answer = 10000 + 300
        XCTAssertEqual(answer, Int(value!))

        // 保存対象データ
        //  11/3(11/2 23:59:59)まで
        //  10000m
        XCTAssertEqual("20231104", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000 + 300
        XCTAssertEqual(answer, Int(value!))
    }
    
    ///
    /// 保存データが存在する状態で総歩行距離を取得（保存データの更新あり）
    ///  HealthKitよりも保存データの値が優先される
    ///
    func testGetTotalWalkingDistanceWithStoreValueByUpdate() async throws {
        // 取得対象範囲 8/1-11/4 (11/3 23:59:59)まで
        let fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))
        let toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 4, hour: 0, minute: 0, second: 0))

        // 保存データ：10/1(9/30 23:59:59)まで10000m歩行
        lastRetrieveDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 10, day: 1, hour: 0, minute: 0, second: 0))
        healthManager.storedWalkingDistance = WalkingDistance(distance: 10000, toDate: lastRetrieveDate!)

        // 歩行データ取得
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        
        // 関数の引数は8/1-11/4の範囲だが、HealthKitへのリクエストは10/1-11/4になる
        XCTAssertEqual("20231001", formatter.string(from: healthManager.usedFromDate!))
        XCTAssertEqual("20231104", formatter.string(from: healthManager.usedToDate!))

        // 保存データ(10000m) + HealthKitデータ(1000 + 1100 + 200 + 201 + 300)mになる
        answer = 10000 + 1000 + 1100 + 200 + 201 + 300
        XCTAssertEqual(answer, Int(value!))

        // 最新の取得内容に応じて保存対象データも変化する
        //  11/3(11/2 23:59:59)まで
        //  10000m + (1000 + 1100 + 200 + 201 + 300)m
        XCTAssertEqual("20231104", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000 + 1000 + 1100 + 200 + 201 + 300
        XCTAssertEqual(answer, Int(value!))
    }
    
    ///
    /// 保存データが存在する状態で総歩行距離を取得（異常系: toDateの範囲まで保存データが存在する）
    ///  HealthKitよりも保存データの値が優先される
    ///
    func testGetTotalWalkingDistanceWithStoreValueByInvalidFrom0801To1103() async throws {
        // 取得対象範囲 8/1-11/3 (11/2 23:59:59)まで　※異常系
        let fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))
        let toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))

        // 保存データ：11/3(11/2 23:59:59)まで10000m歩行
        lastRetrieveDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))
        healthManager.storedWalkingDistance = WalkingDistance(distance: 10000, toDate: lastRetrieveDate!)

        // 歩行データ取得
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)

        // 保存データでカバーできるため、HealthKitへのリクエストは行われない(nilになる)
        XCTAssertNil(healthManager.usedFromDate)
        XCTAssertNil(healthManager.usedToDate)

        // 保存データ(10000m)がそのまま利用される
        answer = 10000
        XCTAssertEqual(answer, Int(value!))

        // 保存対象データは変化しない
        //  11/3(11/2 23:59:59)まで
        //  10000m
        XCTAssertEqual("20231103", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000
        XCTAssertEqual(answer, Int(value!))
    }

    ///
    /// 保存データが存在する状態で総歩行距離を取得（異常系: toDateの範囲まで保存データが存在する）
    ///  HealthKitよりも保存データの値が優先される
    ///
    func testGetTotalWalkingDistanceWithStoreValueByInvalidFrom0801To1001() async throws {
        // 取得対象範囲 8/1-10/1 (9/30 23:59:59)まで　※異常系
        let fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 8, day: 1, hour: 0, minute: 0, second: 0))
        let toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 10, day: 1, hour: 0, minute: 0, second: 0))

        // 保存データ：11/3(11/2 23:59:59)まで10000m歩行
        lastRetrieveDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))
        healthManager.storedWalkingDistance = WalkingDistance(distance: 10000, toDate: lastRetrieveDate!)

        // 歩行データ取得
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        
        // 保存データでカバーできるため、HealthKitへのリクエストは行われない(nilになる)
        XCTAssertNil(healthManager.usedFromDate)
        XCTAssertNil(healthManager.usedToDate)

        // 保存データ(10000m) = 10000mになるはず
        answer = 10000
        XCTAssertEqual(answer, Int(value!))

        // 保存対象データは変化しない
        //  11/3(11/2 23:59:59)まで
        //  10000m
        XCTAssertEqual("20231103", formatter.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000
        XCTAssertEqual(answer, Int(value!))
    }

    func testGetTotalWalkingDistanceWithStoreValueByRepeat() async throws {
        // 取得対象範囲 11/2 9:00 -11/3 14:00 (11/3 13:59:59)まで
        let fromDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 2, hour: 9, minute: 0, second: 0))
        let toDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 14, minute: 0, second: 0))

        // 保存データ：11/3 (11/2 23:59:59)まで10000m歩行
        lastRetrieveDate = healthManager.util.calendar.date(from: DateComponents(year: 2023, month: 11, day: 3, hour: 0, minute: 0, second: 0))
        healthManager.storedWalkingDistance = WalkingDistance(distance: 10000, toDate: lastRetrieveDate!)

        // 歩行データ取得
        // 11/3 0:00 - 14:00
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        XCTAssertEqual("20231103000000", formatterWithTime.string(from: healthManager.usedFromDate!))
        XCTAssertEqual("20231103140000", formatterWithTime.string(from: healthManager.usedToDate!))

        // 保存データ(10000m) + HealthKitデータ(300)mになる
        answer = 10000 + 300
        XCTAssertEqual(answer, Int(value!))

        // 最新の取得内容に応じて保存対象データも変化する
        XCTAssertEqual("20231103000000", formatterWithTime.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000
        XCTAssertEqual(answer, Int(value!))
        
        // 再度取得しても同じ結果になることを確認
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        answer = 10000 + 300
        XCTAssertEqual(answer, Int(value!))
        XCTAssertEqual("20231103000000", formatterWithTime.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000
        XCTAssertEqual(answer, Int(value!))

        // 再度取得しても同じ結果になることを確認
        value = try await healthManager.getTotalWalkingDistance(fromDate: fromDate!, toDate: toDate!)
        answer = 10000 + 300
        XCTAssertEqual(answer, Int(value!))
        XCTAssertEqual("20231103000000", formatterWithTime.string(from: healthManager.storedWalkingDistance!.toDate))
        value = healthManager.storedWalkingDistance?.distance
        answer = 10000
        XCTAssertEqual(answer, Int(value!))
    }
    
    func testHealthManagerStub() async throws {
        let healthManager = HealthManagerStub()
        var values = try await healthManager.getWalkingDistance(
            fromDate: Calendar.current.date(from: DateComponents(year: 2023, month: 1, day: 1))!,
            toDate: Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 1))!)
        XCTAssertEqual(12, values.count)
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 1, day: 1))!))
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 1))!))

        values = try await healthManager.getWalkingDistance(
            fromDate: Calendar.current.date(from: DateComponents(year: 2022, month: 1, day: 1))!,
            toDate: Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!)
        XCTAssertEqual(6, values.count)
        XCTAssertFalse(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2022, month: 1, day: 1))!))
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 1, day: 1))!))
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!))

        values = try await healthManager.getWalkingDistance(
            fromDate: Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 1))!,
            toDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!)
        XCTAssertEqual(6, values.count)
        XCTAssertFalse(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!))
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 1))!))
        XCTAssertTrue(values.keys.contains(Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 1))!))
    }
}
