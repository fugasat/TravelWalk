import HealthKit

class HealthManager: ObservableObject, Identifiable {
    
    let util = Util()
    let quantityType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    let distanceUnit = HKUnit.meter()
    let healthStore = HKHealthStore()
    var currentDate: Date
    var storedWalkingDistance: WalkingDistance? // ここで指定した日付の前日の23:59:59までは取得済
    
    init() {
        self.currentDate = self.util.calendar.startOfDay(for: Date())
    }

    // for UnitTest
    init(currentDate: Date) {
        self.currentDate = self.util.calendar.startOfDay(for: currentDate)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        self.healthStore.requestAuthorization(toShare: [], read: Set([self.quantityType])) { (success, error) in
            if success {
                print("healthStore.requestAuthorization: success")
            }
            if error != nil {
                print("healthStore.requestAuthorization error. : \(String(describing: error))")
            }
            completion(success)
        }
    }
    
    private func getData(healthStore: HKHealthStore, quantityType: HKQuantityType, unit: HKUnit, fromDate: Date, toDate: Date) async -> [Date: Double] {
        return await withCheckedContinuation { continuation in
            var values: [Date: Double] = [:]
            
            // 検索条件を指定
            let predicate = HKQuery.predicateForSamples(withStart: fromDate,
                                                        end: toDate,
                                                        options: [])
            // クエリを作成
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                    quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum, // 合計を取得
                                                    anchorDate: fromDate,
                                                    intervalComponents: DateComponents(day: 1)) // １日単位で集計
            // クエリ結果を処理するハンドラを定義
            query.initialResultsHandler = { _, results, _ in
                /// `results (HKStatisticsCollection?)` からクエリ結果を取り出す。
                guard let statsCollection = results else { return }
                /// クエリ結果から期間（開始日・終了日）を指定して歩数の統計情報を取り出す。
                statsCollection.enumerateStatistics(from: fromDate, to: toDate) { statistics, _ in
                    /// `statistics` に最小単位（今回は１日分の歩数）のサンプルデータが返ってくる。
                    /// `statistics.sumQuantity()` でサンプルデータの合計（１日の合計歩数）を取得する。
                    let keyDate = statistics.startDate
                    if let quantity = statistics.sumQuantity() {
                        /// サンプルデータは`quantity.doubleValue`で取り出し、単位を指定して取得する。
                        /// 単位：歩数の場合`HKUnit.count()`と指定する。（歩行速度の場合：`HKUnit.meter()`、歩行距離の場合：`HKUnit(from: "m/s")`といった単位を指定する。）
                        let quantityValue = quantity.doubleValue(for: unit)
                        values[keyDate] = quantityValue
                        print("start:\(keyDate) - end:\(statistics.endDate) distance=\(String(describing: values[keyDate]))")
                    }
                }
                continuation.resume(returning: values)
            }
            // クエリ実行
            healthStore.execute(query)
        }
    }
    
    /// 歩行距離(単位:m)を1日単位で格納したdictを返す
    func getWalkingDistance(fromDate: Date, toDate: Date) async throws -> [Date: Double] {
        let values = await getData(
            healthStore: self.healthStore, quantityType: self.quantityType, unit: self.distanceUnit, fromDate: fromDate, toDate: toDate)
        return values
    }
    
    func getTotalWalkingDistance(fromDate: Date, toDate: Date) async throws -> Double {
        // storedWalkingDistanceの値を優先して利用する
        // storedWalkingDistanceが存在する場合はstoredWalkingDistance.toDate以降のデータをHealthKitから取得する
        var tempFromDate: Date? = nil
        var totalDistance: Double = 0.0
        
        if let storedWalkingDistance = self.storedWalkingDistance {
            totalDistance = storedWalkingDistance.distance
            let comparisonResult = toDate.compare(storedWalkingDistance.toDate)
            if comparisonResult == .orderedDescending {
                // toDate > storedWalkingDistance.toDate
                // 保存データよりも新しいデータが存在する
                tempFromDate = storedWalkingDistance.toDate
            } else {
                // toDate <= storedWalkingDistance.toDate
                // 保存データで全て賄えているので、保存データをそのまま返す
            }
        } else {
            // 保存データが存在しないので、HealthKitから全期間取得する
            tempFromDate = fromDate
        }

        if let tempRequestFromDate = tempFromDate {
            let requestFromDate = self.util.startOfDay(date: tempRequestFromDate)
            print("from: \(requestFromDate)")
            print("to  : \(toDate)")
            let values = try await self.getWalkingDistance(fromDate: requestFromDate, toDate: toDate)
            let previousDate = self.util.startOfDay(date: toDate)
            var storedDistance: Double = totalDistance
            print("pre : \(previousDate)")
            for (key, value) in values {
                print("date:\(key) - distance:\(value)")
                totalDistance += value
                if key < previousDate {
                    storedDistance += value
                }
            }
            print("total:\(totalDistance), store:\(storedDistance)")
            self.storedWalkingDistance = WalkingDistance(distance: storedDistance, toDate: previousDate)
        }
        return totalDistance
    }

}

class HealthManagerStub: HealthManager {
    
    let values: [Date: Double] = [
        Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!: 10000*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 1, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 3, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 4, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 5, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 7, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 8, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 9, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 10, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 11, day: 1))!: 20*1000,
        Calendar.current.date(from: DateComponents(year: 2023, month: 12, day: 1))!: 20*1000,
        ]

    override init() {
        super.init()
    }

    override func getWalkingDistance(fromDate: Date, toDate: Date) async throws -> [Date: Double] {
        let filteredValues = self.values.filter { (date, _) in
            return fromDate...toDate ~= date
        }
        return filteredValues
    }

}
