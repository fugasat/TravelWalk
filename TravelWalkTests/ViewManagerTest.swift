//


import XCTest
import CoreLocation
import SwiftUI


enum TestCoordinate {
    static let tokyo = CLLocationCoordinate2D(latitude:35.681464, longitude: 139.767052)
    static let tokyo2 = CLLocationCoordinate2D(latitude:35.67807493861317, longitude: 139.76232944760193)
    static let skytree = CLLocationCoordinate2D(latitude: 35.709152712026265, longitude: 139.80771829999996)
    static let koiwa = CLLocationCoordinate2D(latitude:35.71679877033119, longitude: 139.85786240753632)
    static let oomiya = CLLocationCoordinate2D(latitude:35.906320220143115, longitude: 139.6230897625388)
    static let imperial = CLLocationCoordinate2D(latitude:35.68407494838077, longitude: 139.74340112679587)
    static let invalid = CLLocationCoordinate2D(latitude:34.43578402782071, longitude: 143.06372666666672)
}

enum TestLabel {
    static let tokyo = "東京駅"
    static let tokyo2 = "東京駅前"
    static let skytree = "東京スカイツリー"
    static let koiwa = "新小岩駅"
    static let oomiya = "大宮駅"
    static let imperial = "皇居"
    static let invalid = "太平洋の海の底"
}

final class ViewManagerTest: XCTestCase {

    class StoreManagerMock: StoreManager {
        
        var savedTravel: Travel = Travel(startDate: Date())
        var savedFinishTravels: [Travel] = []
        var savedWalkingDistance: WalkingDistance? = nil
        
        override func save(travel: Travel) {
            self.savedTravel = travel
        }
        
        override func save(finishedTravels: [Travel]) {
            self.savedFinishTravels = finishedTravels
        }
        
        override func save(walkingDistance: WalkingDistance?) {
            self.savedWalkingDistance = walkingDistance
        }
        
    }
    
    class AnnotationSetMock: AnnotationSet {
        
        override init() {
            super.init()
        }
        
        override func calculateRoute(annotationStart: PointAnnotation, annotationFinish: PointAnnotation) async throws -> RouteUpdated {
            return try self.createSimpleRoute(annotationStart: annotationStart, annotationFinish: annotationFinish)
        }
    }
    
    class ViewManagerMock: ViewManager {
        
        var currentDate = Date()
        
        override init() {
            super.init()
            self.annotationSet = AnnotationSetMock()
            self.storeManager = StoreManagerMock()
            self.healthManager = HealthManagerStub()
            self.isTest = true
        }
        
        override func getCurrentDate() -> Date {
            return self.currentDate
        }
        
    }
    
    override func setUpWithError() throws {
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - View
    
    // MARK: editButtonPressed()
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // Travelが初期状態の時
    //
    func testEditButtonPressedWithDefaultTravel() {
        let viewManager = ViewManagerMock()
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.active, viewManager.editMode)
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
    }
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // Travelが１つだけAnnotationを持つ時
    //
    func testEditButtonPressedWithOneAnnotation() async throws {
        let viewManager = ViewManagerMock()
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertEqual(MenuMessage.requestFinish.rawValue, viewManager.message)
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.active, viewManager.editMode)
        XCTAssertEqual(MenuMessage.requestFinish.rawValue, viewManager.message)
    }
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // TravelがRouteを持つ時
    //
    func testEditButtonPressedWithRoute() async throws {
        let viewManager = ViewManagerMock()
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.infoRoute.rawValue))
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.active, viewManager.editMode)
        XCTAssertEqual(MenuMessage.edit.rawValue, viewManager.message)
    }
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // Travelが目的地に到着している時
    //
    func testEditButtonPressedWithFinish() async throws {
        let viewManager = ViewManagerMock()
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        viewManager.travel.currentDistance = 10000
        viewManager.travel.finishDistance = 10000
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.finish.rawValue))
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.active, viewManager.editMode)
        XCTAssertEqual(MenuMessage.edit.rawValue, viewManager.message)
    }
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // Travelが中断している時
    //
    func testEditButtonPressedWithStopped() async throws {
        let viewManager = ViewManagerMock()
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        viewManager.travel.isStop = true
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.infoInterrupted.rawValue))
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertTrue(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.infoInterrupted.rawValue))
    }
    
    //
    // 編集ボタンを押した時の編集モードの変化を確認
    // Travelが終了している時
    //
    func testEditButtonPressedWithStoppedFinish() async throws {
        let viewManager = ViewManagerMock()
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        viewManager.travel.isStop = true
        viewManager.travel.currentDistance = 10000
        viewManager.travel.finishDistance = 10000
        
        // 編集モードの時は通常モードになる
        viewManager.editMode = .active
        XCTAssertFalse(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.infoFinished.rawValue))
        
        // 通常モードの時は編集モードになる
        viewManager.editMode = .inactive
        XCTAssertTrue(viewManager.editButtonPressed())
        XCTAssertEqual(.inactive, viewManager.editMode)
        XCTAssertTrue(viewManager.message.starts(with: MenuMessage.infoFinished.rawValue))
    }
    
    func testUpdateSelectionDate() async throws {
        class ViewManagerMock: ViewManager {
            var isUpdateWalkDistance = false
            override func updateWalkDistance(forceUpdate: Bool = true, completion: @escaping () -> Void) async throws {
                self.isUpdateWalkDistance = true
                completion()
            }
        }
        
        let viewManager = ViewManagerMock()
        let calendar = Calendar.current
        let assertDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 2))!
        viewManager.healthManager.storedWalkingDistance = WalkingDistance(
            distance: 10000, toDate: calendar.date(from: DateComponents(year: 2022, month: 8, day: 1))!)
        
        viewManager.walkDistanceInitialized = true
        try await viewManager.updateSelectionDate(newSelectionDate: calendar.date(from: DateComponents(year: 2023, month: 1, day: 2))!) {}
        XCTAssertEqual(assertDate.timeIntervalSince1970, viewManager.travel.startDate.timeIntervalSince1970)
        // 歩行距離が更新される
        XCTAssertNil(viewManager.healthManager.storedWalkingDistance)
        XCTAssertTrue(viewManager.isUpdateWalkDistance)
    }
    
    //
    // 現在実行中のTravelを終了一覧に追加する
    //
    func testEntryCurrentTravelToFinishList() async throws {
        let viewManager = ViewManagerMock()
        let calendar = Calendar.current
        let storeManager = viewManager.storeManager as! StoreManagerMock

        //
        // 終了済Travelを設定
        //
        
        // 完了
        let finishedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 9, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo),
                annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        finishedTravel1.name = "finishedTravel1"
        finishedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!
        finishedTravel1.isStop = true
        finishedTravel1.finishDistance = 100000
        finishedTravel1.currentDistance = 100000
        
        // 実行中(経路あり) ※異常系（本来は発生しないはずのデータ）
        let runTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)).route])
        runTravel1.name = "runTravel1"
        runTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 11, day: 2))!
        runTravel1.isStop = false
        runTravel1.finishDistance = 200000
        runTravel1.currentDistance = 0
        
        // 実行中(経路なし) ※異常系（本来は発生しないはずのデータ）
        let runTravel2 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [])
        runTravel2.name = "runTravel2"
        runTravel2.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 4))!
        runTravel2.isStop = false
        runTravel2.finishDistance = 200000
        runTravel2.currentDistance = 0
        viewManager.finishedTravels.append(finishedTravel1)
        viewManager.finishedTravels.append(runTravel1)
        viewManager.finishedTravels.append(runTravel2)
        
        //
        // 現在実行中のTravelを設定
        //
        let travel = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2022, month: 12, day: 1, hour: 0, minute: 0, second: 0))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo),
                annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        travel.currentDistance = 1
        viewManager.setTravel(travel: travel)
        // 歩行データを更新する
        let expectationReplaceTravel = expectation(description: "entryCurrentTravelToFinishList")
        try viewManager.replaceTravel() {
            expectationReplaceTravel.fulfill()
        }
        await fulfillment(of: [expectationReplaceTravel])
        viewManager.updateMenuMessage()
        
        // 現在のTravelを終了済リストに追加する
        let expectationToFinishTravel1 = expectation(description: "entryCurrentTravelToFinishList")
        try viewManager.entryCurrentTravelToFinishList(
            entryName: "Travel1",
            finishedDate: calendar.date(from: DateComponents(year: 2023, month: 12, day: 1, hour: 0, minute: 0, second: 0))!)
        {
            expectationToFinishTravel1.fulfill()
        }
        await fulfillment(of: [expectationToFinishTravel1])

        // Travelが終了済リストに追加されている
        // 経路なしのTravelは削除されている
        XCTAssertEqual(3, viewManager.finishedTravels.count)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("Travel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[2].name)
        // 実行中のTravelは中断になっている
        XCTAssertTrue(viewManager.finishedTravels[1].isStop)
        // 新規Travelが設定されている
        XCTAssertFalse(viewManager.travel.hasRoute())
        // 日付は今日の日付に設定されている
        XCTAssertEqual(viewManager.travel.startDate.timeIntervalSince1970, viewManager.getCurrentDate().timeIntervalSince1970)
        XCTAssertEqual("新規", viewManager.travel.name)
        print("c-dis:\(viewManager.travel.currentDistance)")
        XCTAssertEqual(0, viewManager.travel.currentDistance)
        XCTAssertEqual(0, viewManager.annotations.count)
        XCTAssertEqual(EditMode.active, viewManager.editMode)
//        sleep(1)
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
        // 現在実行中のTravelを操作しても終了済には影響はない
        viewManager.travel.name = "test"
        XCTAssertEqual("Travel1", viewManager.finishedTravels[1].name)
        
        // 現在実行中のTravelを別のものに上書き
        let finishedTravel2 = try Travel(
            startDate: Date(),
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        finishedTravel2.currentDistance = 2
        viewManager.setTravel(travel: finishedTravel2)
        let expectationToFinishTravel2 = expectation(description: "entryCurrentTravelToFinishList")
        try viewManager.entryCurrentTravelToFinishList(
            entryName: "Travel2",
            finishedDate: calendar.date(from: DateComponents(year: 2023, month: 12, day: 2, hour: 0, minute: 0, second: 0))!)
        {
            expectationToFinishTravel2.fulfill()
        }
        await fulfillment(of: [expectationToFinishTravel2])

        // Travelが終了済リストに追加されている(日付が新しい順にソートされている)
        XCTAssertEqual(4, viewManager.finishedTravels.count)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("Travel2", viewManager.finishedTravels[1].name)
        XCTAssertEqual("Travel1", viewManager.finishedTravels[2].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[3].name)
        
        let finishedTravel3 = try Travel(
            startDate: Date(),
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)).route])
        finishedTravel3.currentDistance = 3
        viewManager.setTravel(travel: finishedTravel3)
        let expectationToFinishTravel3 = expectation(description: "entryCurrentTravelToFinishList")
        try viewManager.entryCurrentTravelToFinishList(
            entryName: "Travel3",
            finishedDate: calendar.date(from: DateComponents(year: 2023, month: 11, day: 30, hour: 0, minute: 0, second: 0))!)
        {
            expectationToFinishTravel3.fulfill()
        }
        await fulfillment(of: [expectationToFinishTravel3])

        // Travelが終了済リストに追加されている(日付が新しい順にソートされている)
        XCTAssertEqual(5, viewManager.finishedTravels.count)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("Travel2", viewManager.finishedTravels[1].name)
        XCTAssertEqual("Travel1", viewManager.finishedTravels[2].name)
        XCTAssertEqual("Travel3", viewManager.finishedTravels[3].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[4].name)
        
        // 保存処理が実行されている
        XCTAssertEqual("新規", storeManager.savedTravel.name)
        let storedFinishedTravels = storeManager.savedFinishTravels
        XCTAssertEqual(5, storedFinishedTravels.count)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("Travel2", storedFinishedTravels[1].name)
        XCTAssertEqual("Travel1", storedFinishedTravels[2].name)
        XCTAssertEqual("Travel3", storedFinishedTravels[3].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[4].name)
    }
    
    //
    // 現在実行中のTravelと終了したTravelを入れ替える
    //
    func testSwitchTravel() async throws {
        let viewManager = ViewManagerMock()
        
        let calendar = Calendar.current
        let storeManager = viewManager.storeManager as! StoreManagerMock
        viewManager.currentDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 1))!
        
        //
        // 終了済Travelを設定
        //
        
        // 完了
        let finishedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 9, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        finishedTravel1.name = "finishedTravel1"
        finishedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!
        finishedTravel1.isStop = true
        finishedTravel1.finishDistance = 100000
        finishedTravel1.currentDistance = 100000
        
        // 中断
        let interruptedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 10, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        interruptedTravel1.name = "interruptedTravel1"
        interruptedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 11, day: 2))!
        interruptedTravel1.isStop = true
        interruptedTravel1.finishDistance = 150000
        interruptedTravel1.currentDistance = 50000
        
        // 中断
        let interruptedTravel2 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)).route])
        interruptedTravel2.name = "interruptedTravel2"
        interruptedTravel2.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 11, day: 3))!
        interruptedTravel2.isStop = true
        interruptedTravel2.finishDistance = 200000
        interruptedTravel2.currentDistance = 0
        
        viewManager.finishedTravels.append(finishedTravel1)
        viewManager.finishedTravels.append(interruptedTravel1)
        viewManager.finishedTravels.append(interruptedTravel2)
        
        //
        // 現在実行中のTravelを設定(経路なし)
        //
        viewManager.createNewTravel(startDate: calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!)
        viewManager.travel.name = "current"
        viewManager.travel.currentDistance = 0
        viewManager.editMode = .active
        // 歩行データを更新する
        let expectationReplaceTravel = expectation(description: "expectationReplaceTravel")
        try viewManager.replaceTravel() {
            expectationReplaceTravel.fulfill()
        }
        await fulfillment(of: [expectationReplaceTravel])

        // 保存フラグをリセット
        storeManager.savedFinishTravels = []
        
        //
        // ここからテスト
        //
        
        // finishedTravel1に変更
        let expectationSwitchFinishedTravel1 = expectation(description: "expectationSwitchFinishedTravel1")
        try viewManager.switchTravel(switchedTravelIndex: 0) {
            expectationSwitchFinishedTravel1.fulfill()
        }
        await fulfillment(of: [expectationSwitchFinishedTravel1])

        XCTAssertEqual("finishedTravel1", viewManager.travel.name)
        XCTAssertTrue(viewManager.travel.isFinish())
        XCTAssertEqual(2, viewManager.annotations.count)
        // 歩行データの再取得は実施しない(currentDistanceは初期値そのまま)
        XCTAssertEqual(100000, viewManager.travel.currentDistance)
        // 元のTravelは終了日が現在の日付になるため、先頭に挿入される
        XCTAssertEqual("current", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel2", viewManager.finishedTravels[1].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[2].name)
        // 開始日が選択したTravelの日付に更新されていることを確認
        XCTAssertEqual(finishedTravel1.startDate.timeIntervalSince1970,
                       viewManager.travel.startDate.timeIntervalSince1970)
        // 編集モードはOFF
        XCTAssertEqual(EditMode.inactive, viewManager.editMode)
        // 最後のAnnotationが選択状態になっている（Travel1は完了しているため）
        XCTAssertEqual(1, viewManager.selectedListIndex)
        // 完了メッセージが表示される
        XCTAssertEqual("完了 2023/09/01 100km", viewManager.message)
        // 保存処理が実行されている
        XCTAssertEqual("finishedTravel1", storeManager.savedTravel.name)
        let storedFinishedTravels = storeManager.savedFinishTravels
        if storedFinishedTravels.count == 3 {
            XCTAssertEqual("current", storedFinishedTravels[0].name)
            XCTAssertEqual("interruptedTravel2", storedFinishedTravels[1].name)
            XCTAssertEqual("interruptedTravel1", storedFinishedTravels[2].name)
        } else {
            XCTFail("storedFinishedTravels.count <> 3")
        }
        
        // interruptedTravel1に変更
        let expectationSwitchInterruptedTravel1 = expectation(description: "expectationSwitchInterruptedTravel1")
        try viewManager.switchTravel(switchedTravelIndex: 2) {
            expectationSwitchInterruptedTravel1.fulfill()
        }
        await fulfillment(of: [expectationSwitchInterruptedTravel1])

        XCTAssertEqual("interruptedTravel1", viewManager.travel.name)
        XCTAssertEqual("current", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel2", viewManager.finishedTravels[1].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[2].name)
        // 中断メッセージが表示される
        XCTAssertEqual("中断 2023/10/01 50/150km", viewManager.message)
        
        // 元のTravelに変更
        let expectationSwitchCurrentTravel = expectation(description: "expectationSwitchCurrentTravel")
        try viewManager.switchTravel(switchedTravelIndex: 0) {
            expectationSwitchCurrentTravel.fulfill()
        }
        await fulfillment(of: [expectationSwitchCurrentTravel])

        XCTAssertEqual("current", viewManager.travel.name)
        XCTAssertEqual("interruptedTravel2", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[2].name)
        // 元のTravelの状態を確認(経路情報は登録されていない)
        XCTAssertEqual(calendar.date(from: DateComponents(year: 2023, month: 11, day: 1))!, viewManager.travel.startDate)
        XCTAssertFalse(viewManager.travel.isStop)
        XCTAssertFalse(viewManager.travel.hasRoute())
        // 開始日に応じた歩行処理が設定される(currentDistanceが更新される)
        XCTAssertEqual(40000, viewManager.travel.currentDistance)
        
        XCTAssertEqual(0, viewManager.annotations.count)
        // 編集モードはON(経路が存在しないため)
        XCTAssertEqual(EditMode.active, viewManager.editMode)
        // メッセージは「目的地の設定」
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
        
        // 無効なindexは無視される
        try viewManager.switchTravel(switchedTravelIndex: -1) {}
        XCTAssertEqual("current", viewManager.travel.name)
        XCTAssertEqual("interruptedTravel2", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[2].name)
        try viewManager.switchTravel(switchedTravelIndex: 3) {}
        XCTAssertEqual("current", viewManager.travel.name)
        XCTAssertEqual("interruptedTravel2", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[2].name)
    }
    
    //
    // 中断したTravelを再開する
    //
    func testRestartTravel() async throws {
        let calendar = Calendar.current
        let viewManager = ViewManagerMock()
        viewManager.currentDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 1))!
        viewManager.travel.startDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 1))!
        let storeManager = viewManager.storeManager as! StoreManagerMock
        
        //
        // 終了済Travelを設定
        //
        
        // 完了
        let finishedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        finishedTravel1.name = "finishedTravel1"
        finishedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 1))!
        finishedTravel1.isStop = true
        finishedTravel1.finishDistance = 100000
        finishedTravel1.currentDistance = 100000
        
        // 中断
        let interruptedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        interruptedTravel1.name = "interruptedTravel1"
        interruptedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 2))!
        interruptedTravel1.isStop = true
        interruptedTravel1.finishDistance = 150000
        interruptedTravel1.currentDistance = 50000
        
        // 実行中(経路あり)
        let runTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)).route])
        runTravel1.name = "runTravel1"
        runTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 3))!
        runTravel1.isStop = false
        runTravel1.finishDistance = 200000
        runTravel1.currentDistance = 0
        
        // 実行中(経路なし)
        let runTravel2 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [])
        runTravel2.name = "runTravel2"
        runTravel2.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 4))!
        runTravel2.isStop = false
        runTravel2.finishDistance = 200000
        runTravel2.currentDistance = 0
        
        viewManager.finishedTravels.append(finishedTravel1)
        viewManager.finishedTravels.append(interruptedTravel1)
        viewManager.finishedTravels.append(runTravel1)
        viewManager.finishedTravels.append(runTravel2)
        
        //
        // 現在実行中のTravelを設定(中断)
        //
        viewManager.createNewTravel(startDate: calendar.date(from: DateComponents(year: 2022, month: 12, day: 1))!)
        viewManager.travel.name = "current"
        viewManager.travel.isStop = true
        let expectationReplaceTravel = expectation(description: "expectationReplaceTravel")
        try viewManager.replaceTravel() {
            expectationReplaceTravel.fulfill()
        }
        await fulfillment(of: [expectationReplaceTravel])

        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        viewManager.travel.currentDistance = 0
        viewManager.travel.finishDistance = 200000
        viewManager.editMode = .inactive
        viewManager.updateMenuMessage()
        
        // 保存フラグをリセット
        storeManager.savedFinishTravels = []
        
        //
        // ここからテスト
        //
        
        // 現在表示中のTravelを再開
        let expectationRestartTravel = expectation(description: "expectationRestartTravel")
        try viewManager.restartTravel() {
            expectationRestartTravel.fulfill()
        }
        await fulfillment(of: [expectationRestartTravel])

        // 現在表示中のTravelが実行中であることを確認
        XCTAssertFalse(viewManager.travel.isStop)
        XCTAssertEqual(EditMode.inactive, viewManager.editMode)
        // 歩行データはTravelの日付範囲に従って再取得される
        XCTAssertEqual(240000, viewManager.travel.currentDistance)
        XCTAssertEqual("目的地に到着しました", viewManager.message)
        
        // 終了済Travelのうち元々実行中だったTravel(経路無し)が削除されていることを確認
        XCTAssertEqual(3, viewManager.finishedTravels.count)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[2].name)
        // 終了済Travelのうち元々実行中だったTravel(経路あり)が中断になっていることを確認
        XCTAssertTrue(viewManager.finishedTravels[2].isStop)
        XCTAssertEqual(viewManager.currentDate.timeIntervalSince1970, viewManager.finishedTravels[2].finishedDate.timeIntervalSince1970)
    }
    
    func testRestoreFinishedTravels() throws {
        let calendar = Calendar.current
        let viewManager = ViewManagerMock()
        
        //
        // 終了済Travelを設定
        //
        
        // 完了
        let finishedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        finishedTravel1.name = "finishedTravel1"
        finishedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 1))!
        finishedTravel1.isStop = true
        finishedTravel1.finishDistance = 100000
        finishedTravel1.currentDistance = 100000
        
        // 中断
        let interruptedTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa)).route])
        interruptedTravel1.name = "interruptedTravel1"
        interruptedTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 2))!
        interruptedTravel1.isStop = true
        interruptedTravel1.finishDistance = 150000
        interruptedTravel1.currentDistance = 50000
        
        // 実行中(経路あり)
        let runTravel1 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [try viewManager.createSimpleRoute(
                annotationStart: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), annotationFinish: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo)).route])
        runTravel1.name = "runTravel1"
        runTravel1.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 3))!
        runTravel1.isStop = false
        runTravel1.finishDistance = 200000
        runTravel1.currentDistance = 0
        
        // 実行中(経路なし)
        let runTravel2 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [])
        runTravel2.name = "runTravel2"
        runTravel2.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 4))!
        runTravel2.isStop = false
        runTravel2.finishDistance = 200000
        runTravel2.currentDistance = 0
        
        // 実行中(経路なし)
        let runTravel3 = try Travel(
            startDate: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!,
            routes: [])
        runTravel3.name = "runTravel3"
        runTravel3.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 6, day: 5))!
        runTravel3.isStop = false
        runTravel3.finishDistance = 200000
        runTravel3.currentDistance = 0
        
        viewManager.finishedTravels.append(finishedTravel1)
        viewManager.finishedTravels.append(interruptedTravel1)
        viewManager.finishedTravels.append(runTravel1)
        viewManager.finishedTravels.append(runTravel2)
        viewManager.finishedTravels.append(runTravel3)
        
        //
        // ここからテスト
        //
        viewManager.restoreFinishedTravels()
        // 経路なしTravelが削除されていることを確認
        XCTAssertEqual(3, viewManager.finishedTravels.count)
        XCTAssertEqual("finishedTravel1", viewManager.finishedTravels[0].name)
        XCTAssertEqual("interruptedTravel1", viewManager.finishedTravels[1].name)
        XCTAssertEqual("runTravel1", viewManager.finishedTravels[2].name)
    }

    // MARK: Annotation

    //
    // 歩行距離に合わせて各種状態を更新する
    //
    func testSetWalkDistance() async throws {
        let viewManager = ViewManagerMock()
        
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: true)
        
        // 0km
        viewManager.setWalkDistance(distance: 0)
        XCTAssertEqual(0, viewManager.travel.currentDistance)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps)
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        
        // 7km：route[1]の途中
        viewManager.setWalkDistance(distance: 7000)
        XCTAssertEqual(7000, viewManager.travel.currentDistance)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(viewManager.travel.routes[1].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        
        // 100km：全ステップ踏破
        viewManager.setWalkDistance(distance: 100000)
        XCTAssertEqual(100000, viewManager.travel.currentDistance)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps) // 全ステップ踏破
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[2].color)
    }
    
    //
    // 中断しているTravelは歩行距離が更新されないことを確認
    //
    func testSetWalkDistanceWithInterruptedTravel() async throws {
        let viewManager = ViewManagerMock()
        viewManager.travel.isStop = true
        
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: true)
        
        // 100km：全ステップ踏破
        viewManager.setWalkDistance(distance: 100000)
        
        // 何も状態は変化していない
        XCTAssertEqual(0, viewManager.travel.currentDistance)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps)
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
    }
    
    //
    // 経路なしTravelでも歩行距離が更新されることを確認
    //
    func testSetWalkDistanceWithNoRouteTravel() async throws {
        let viewManager = ViewManagerMock()
        
        // 100km：全ステップ踏破
        viewManager.setWalkDistance(distance: 100000)
        XCTAssertEqual(100000, viewManager.travel.currentDistance)
    }
    
    //
    // Annotationの座標を更新した後にRouteが更新されているか確認
    //
    func testUpdateAnnotationToFirstAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: false)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 開始地点を東京から大宮駅に変更(Route距離が約5kmから30kmに変化)
        let updateAnnotation = viewManager.annotations[0]
        updateAnnotation.coordinate = PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate
        updateAnnotation.label = TestLabel.oomiya
        let routeUpdated = try await viewManager.updateAnnotation(annotation: updateAnnotation)
        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(1, routeUpdated.after.count)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.after[0].route.finishLabel)
        
        var coords: CLLocationCoordinate2D
        let travel = viewManager.travel
        
        // 開始地点(大宮駅) 更新
        XCTAssertEqual(TestLabel.oomiya, travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.skytree, travel.routes[0].finishLabel)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 終了地点(新小岩駅)
        XCTAssertEqual(TestCoordinate.koiwa.latitude, travel.finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.koiwa.longitude, travel.finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 中間地点(東京スカイツリー)
        coords = travel.routes[0].finishLocation
        XCTAssertEqual(TestCoordinate.skytree.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.skytree.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        coords = travel.routes[1].startLocation
        XCTAssertEqual(TestCoordinate.skytree.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.skytree.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
    }
    
    //
    // Annotationの座標を更新した後にRouteが更新されているか確認
    //
    func testUpdateAnnotationToLastAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: false)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 終了地点を新小岩駅から大宮駅に変更(Route距離が約5kmから30kmに変化)
        let updateAnnotation = viewManager.annotations[2]
        updateAnnotation.coordinate = PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate
        updateAnnotation.label = TestLabel.oomiya
        let routeUpdated = try await viewManager.updateAnnotation(annotation: updateAnnotation)

        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(1, routeUpdated.after.count)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.after[0].route.finishLabel)
        
        var coords: CLLocationCoordinate2D
        let travel = viewManager.travel
        
        // 開始地点(東京駅) 更新
        XCTAssertEqual(TestCoordinate.tokyo.latitude, travel.startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, travel.startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 終了地点(大宮駅) 更新
        XCTAssertEqual(TestLabel.skytree, travel.routes[1].startLabel)
        XCTAssertEqual(TestLabel.oomiya, travel.routes[1].finishLabel)
        XCTAssertEqual(TestCoordinate.oomiya.latitude, travel.finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.oomiya.longitude, travel.finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 中間地点(東京スカイツリー)
        coords = travel.routes[0].finishLocation
        XCTAssertEqual(TestCoordinate.skytree.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.skytree.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        coords = travel.routes[1].startLocation
        XCTAssertEqual(TestCoordinate.skytree.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.skytree.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
    }
    
    //
    // Annotationの座標を更新した後にRouteが更新されているか確認
    //
    func testUpdateAnnotationToMiddleAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: false)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 中間地点を東京スカイツリーから大宮駅に変更
        let updateAnnotation = viewManager.annotations[1]
        updateAnnotation.coordinate = PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate
        updateAnnotation.label = TestLabel.oomiya
        let routeUpdated = try await viewManager.updateAnnotation(annotation: updateAnnotation)
        XCTAssertEqual(2, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.before[1].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.before[1].route.finishLabel)
        XCTAssertEqual(2, routeUpdated.after.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.after[0].route.finishLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.after[1].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.after[1].route.finishLabel)
        
        var coords: CLLocationCoordinate2D
        let travel = viewManager.travel
        
        // 開始地点(東京駅)
        XCTAssertEqual(TestCoordinate.tokyo.latitude, travel.startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, travel.startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 終了地点(新小岩駅)
        XCTAssertEqual(TestCoordinate.koiwa.latitude, travel.finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.koiwa.longitude, travel.finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        // 中間地点(大宮駅) 更新
        XCTAssertEqual(TestLabel.oomiya, travel.routes[0].finishLabel)
        XCTAssertEqual(TestLabel.oomiya, travel.routes[1].startLabel)
        coords = travel.routes[0].finishLocation
        XCTAssertEqual(TestCoordinate.oomiya.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.oomiya.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        coords = travel.routes[1].startLocation
        XCTAssertEqual(TestCoordinate.oomiya.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.oomiya.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
    }
    
    //
    // 仮で設定した経路を最新の経路で更新
    // 仮経路はリストの最後尾であることが前提
    //
    func testUpdateTemporaryAnnotation() async throws {
        let viewManager = ViewManagerMock()
        var routeUpdated: RouteUpdatedSet
        
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        routeUpdated = try await viewManager.updateTemporaryAnnotation(annotation: viewManager.annotations[0])
        XCTAssertEqual(0, routeUpdated.before.count)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        let routeSteps0 = viewManager.travel.routes[0].routeSteps
        XCTAssertEqual(1, routeSteps0.count)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        
        // 既に更新済みのAnnotationは対象外
        routeUpdated = try await viewManager.updateTemporaryAnnotation(annotation: viewManager.annotations[0])
        XCTAssertEqual(0, routeUpdated.before.count)
        XCTAssertEqual(0, routeUpdated.after.count)
        routeUpdated = try await viewManager.updateTemporaryAnnotation(annotation: viewManager.annotations[1])
        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(1, routeUpdated.after.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.skytree, routeUpdated.after[0].route.finishLabel)
        
        // 途中経過地点の確認
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
    }

    //
    // Annotationを削除
    //
    func testRemoveAnnotation() async throws {
        let viewManager = ViewManagerMock()
        var routeUpdated: RouteUpdatedSet

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 大宮駅 (30km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya), isTemporary: false)
        // 新小岩駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 途中経過地点を設定
        // 45km：route[1]の途中
        viewManager.travel.currentDistance = 45000
        let currentRouteSteps0 = viewManager.travel.routes[0].currentRouteSteps
        let currentRouteSteps1 = viewManager.travel.routes[1].currentRouteSteps
        XCTAssertNil(currentRouteSteps0) // 全ステップ踏破
        XCTAssertNotNil(currentRouteSteps1)
        
        // 中間地点(大宮駅)を削除、新しい経路が東京駅〜新小岩駅になる
        routeUpdated = try await viewManager.removeAnnotation(annotation: viewManager.annotations[1])
        XCTAssertEqual(2, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.before[1].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.before[1].route.finishLabel)
        XCTAssertEqual(1, routeUpdated.after.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.after[0].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.after[0].route.finishLabel)
        
        XCTAssertEqual(2, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[0].finishLabel)
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        
        // 終了地点までの距離が約10kmに変わるため終了フラグが立つ
        XCTAssertTrue(viewManager.travel.isFinish())
        // 途中経過地点の確認
        // Route[0]の終了地点
        XCTAssertEqual(1, viewManager.travel.routes.count)
        let currentRouteSteps0updated = viewManager.travel.routes[0].currentRouteSteps
        XCTAssertNil(currentRouteSteps0updated) // 全ステップ踏破
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        
        // 無関係な地点は削除できない
        routeUpdated = try await viewManager.removeAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree))
        XCTAssertEqual(0, routeUpdated.before.count)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        // 終了地点を削除
        routeUpdated = try await viewManager.removeAnnotation(annotation: viewManager.annotations[1])
        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        XCTAssertEqual(1, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        
        // Annotationが１つになるので、Routeが消える
        XCTAssertFalse(viewManager.travel.hasRoute())
        
        // 残った地点を削除
        routeUpdated = try await viewManager.removeAnnotation(annotation: viewManager.annotations[0])
        XCTAssertEqual(0, routeUpdated.before.count)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        XCTAssertEqual(0, viewManager.annotations.count)
    }

    //
    // 最初のAnnotationを削除
    //
    func testRemoveAnnotationToFirstAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 大宮駅 (30km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya), isTemporary: false)
        // 新小岩駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 開始地点を削除
        let routeUpdated = try await viewManager.removeAnnotation(annotation: viewManager.annotations[0])
        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.tokyo, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        XCTAssertEqual(2, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[0].finishLabel)
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
    }
    
    //
    // 最後のAnnotationを削除
    //
    func testRemoveAnnotationToLastAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 大宮駅 (30km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya), isTemporary: false)
        // 新小岩駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        
        // 最終地点を削除
        let routeUpdated = try await viewManager.removeAnnotation(annotation: viewManager.annotations[2])
        XCTAssertEqual(1, routeUpdated.before.count)
        XCTAssertEqual(TestLabel.oomiya, routeUpdated.before[0].route.startLabel)
        XCTAssertEqual(TestLabel.koiwa, routeUpdated.before[0].route.finishLabel)
        XCTAssertEqual(0, routeUpdated.after.count)
        
        XCTAssertEqual(2, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.oomiya, viewManager.travel.routes[0].finishLabel)
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
    }
    
    //
    // Annotation同士を入れ替え
    //
    func testMoveAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅1
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 大宮駅2 (30km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya), isTemporary: false)
        // 途中経過地点を設定
        // 15km：route[0]の途中
        viewManager.travel.currentDistance = 15000
        XCTAssertEqual(1, viewManager.travel.routes.count)
        XCTAssertNotNil(viewManager.travel.routes[0].currentRouteSteps)
        
        // ２点間の交換(1) 大宮2、東京1
        try await viewManager.moveAnnotation(fromIndex: 0, toIndex: 1)
        XCTAssertEqual(2, viewManager.annotations.count)
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        XCTAssertEqual(TestCoordinate.oomiya.latitude, viewManager.annotations[0].coordinate.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.oomiya.longitude, viewManager.annotations[0].coordinate.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[0].label)
        XCTAssertEqual(TestCoordinate.tokyo.latitude, viewManager.annotations[1].coordinate.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, viewManager.annotations[1].coordinate.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[1].label)
        
        // Route確認
        let travel = viewManager.travel
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[0]の途中
        XCTAssertEqual(1, travel.routes.count)
        XCTAssertNotNil(travel.routes[0].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        
        // ２点間の交換(2) 東京1、大宮2
        try await viewManager.moveAnnotation(fromIndex: 1, toIndex: 0)
        XCTAssertEqual(2, viewManager.annotations.count)
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[1].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[0]の途中
        XCTAssertEqual(1, travel.routes.count)
        XCTAssertNotNil(travel.routes[0].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        
        // 新小岩3&東京駅前4を追加 東京1、大宮2、新小岩3、東京駅前4
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: false)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2), isTemporary: false)
        
        // 途中経過地点の確認 route[0]の途中
        XCTAssertEqual(3, viewManager.travel.routes.count)
        XCTAssertNotNil(viewManager.travel.routes[0].currentRouteSteps)
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps)
        XCTAssertNil(viewManager.travel.routes[2].currentRouteSteps)
        
        // 大宮2から新小岩3に移動(中間同士) 東京1、新小岩3、大宮2、東京駅前4
        try await viewManager.moveAnnotation(fromIndex: 1, toIndex: 2)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[3].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[1].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[1].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[1].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[1].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[2].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[2].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.latitude, travel.routes[2].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.longitude, travel.routes[2].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[1]の途中
        XCTAssertEqual(3, travel.routes.count)
        XCTAssertNil(travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(travel.routes[1].currentRouteSteps)
        XCTAssertNil(travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 東京1から新小岩3に移動(先頭から中間) 新小岩3、東京1、大宮2、東京駅前4
        try await viewManager.moveAnnotation(fromIndex: 0, toIndex: 1)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[3].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[1].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[1].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[1].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[1].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[2].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[2].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.latitude, travel.routes[2].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.longitude, travel.routes[2].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[1]の途中
        XCTAssertEqual(3, travel.routes.count)
        XCTAssertNil(travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(travel.routes[1].currentRouteSteps)
        XCTAssertNil(travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 東京駅前4から大宮2に移動(末尾から中間) 新小岩3、東京1、東京駅前4、大宮2
        try await viewManager.moveAnnotation(fromIndex: 3, toIndex: 2)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[3].label)
        // 途中経過地点の確認 route[2]の途中
        XCTAssertEqual(3, viewManager.travel.routes.count)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(viewManager.travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 東京駅前4から新小岩3に移動(中間から先頭) 東京駅前4、新小岩3、東京1、大宮2
        try await viewManager.moveAnnotation(fromIndex: 2, toIndex: 0)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[3].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[1].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[1].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[1].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[1].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[2].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[2].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[2].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[2].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[1]の途中
        XCTAssertEqual(3, travel.routes.count)
        XCTAssertNil(travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(travel.routes[1].currentRouteSteps)
        XCTAssertNil(travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 新小岩3から大宮2に移動(中間から末尾) 東京駅前4、東京1、大宮2、新小岩3
        try await viewManager.moveAnnotation(fromIndex: 1, toIndex: 3)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[3].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[1].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[1].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[1].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[1].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[2].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[2].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[2].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[2].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[1]の途中
        XCTAssertEqual(3, travel.routes.count)
        XCTAssertNil(travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(travel.routes[1].currentRouteSteps)
        XCTAssertNil(travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 東京駅前4から新小岩3に移動(先頭から末尾) 東京1、大宮2、新小岩3、東京駅前4
        try await viewManager.moveAnnotation(fromIndex: 0, toIndex: 3)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[3].label)
        
        // Route確認
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.latitude, travel.routes[0].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo).coordinate.longitude, travel.routes[0].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[0].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[0].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.latitude, travel.routes[1].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya).coordinate.longitude, travel.routes[1].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[1].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[1].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.latitude, travel.routes[2].startLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa).coordinate.longitude, travel.routes[2].startLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.latitude, travel.routes[2].finishLocation.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2).coordinate.longitude, travel.routes[2].finishLocation.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 途中経過地点の確認 route[0]の途中
        XCTAssertEqual(3, travel.routes.count)
        XCTAssertNotNil(travel.routes[0].currentRouteSteps)
        XCTAssertNil(travel.routes[1].currentRouteSteps)
        XCTAssertNil(travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // Route Indexを確認
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        XCTAssertEqual(2, viewManager.annotations[2].routeIndex)
        XCTAssertEqual(3, viewManager.annotations[3].routeIndex)
        
        // from/toが同じ場合は何も起きない
        
        // 末尾から末尾の指定は何も起きない
        
        // 無効な位置指定の場合は何も起きない
        try await viewManager.moveAnnotation(fromIndex: -1, toIndex: 1)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[3].label)
        try await viewManager.moveAnnotation(fromIndex: 0, toIndex: 5)
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[3].label)
    }
    
    //
    // Annotationを挿入
    //
    func testInsertAnnotation() async throws {
        let viewManager = ViewManagerMock()

        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 大宮駅 (30km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.oomiya, label:TestLabel.oomiya), isTemporary: false)
        
        // 途中経過地点を設定
        // 15km：route[0]の途中
        viewManager.travel.currentDistance = 15000
        XCTAssertNotNil(viewManager.travel.routes[0].currentRouteSteps)
        
        // 東京と大宮の間に新小岩を挿入 => 東京、大宮、新小岩
        // 新小岩駅
        try await viewManager.insertAnnotation(index: 1, annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa))
        XCTAssertEqual(3, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[2].label)
        
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        XCTAssertEqual(2, viewManager.annotations[2].routeIndex)
        
        // 途中経過地点の確認
        // Route[1]の途中
        XCTAssertEqual(2, viewManager.travel.routes.count)
        XCTAssertEqual(TestLabel.tokyo, viewManager.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[0].finishLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[1].startLabel)
        XCTAssertEqual(TestLabel.oomiya, viewManager.travel.routes[1].finishLabel)
        
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(viewManager.travel.routes[1].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[2].color)
        
        // 先頭に東京駅近辺を挿入
        try await viewManager.insertAnnotation(index: 0, annotation: PointAnnotation(coordinate:TestCoordinate.tokyo2, label:TestLabel.tokyo2))
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.annotations[0].label)
        XCTAssertEqual(TestLabel.tokyo, viewManager.annotations[1].label)
        XCTAssertEqual(TestLabel.koiwa, viewManager.annotations[2].label)
        XCTAssertEqual(TestLabel.oomiya, viewManager.annotations[3].label)
        // RouteIndexが更新される
        XCTAssertEqual(0, viewManager.annotations[0].routeIndex)
        XCTAssertEqual(1, viewManager.annotations[1].routeIndex)
        XCTAssertEqual(2, viewManager.annotations[2].routeIndex)
        XCTAssertEqual(3, viewManager.annotations[3].routeIndex)
        
        // 途中経過地点の確認
        // Route[2]の途中
        XCTAssertEqual(3, viewManager.travel.routes.count)
        XCTAssertEqual(TestLabel.tokyo2, viewManager.travel.routes[0].startLabel)
        XCTAssertEqual(TestLabel.tokyo, viewManager.travel.routes[0].finishLabel)
        XCTAssertEqual(TestLabel.tokyo, viewManager.travel.routes[1].startLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[1].finishLabel)
        XCTAssertEqual(TestLabel.koiwa, viewManager.travel.routes[2].startLabel)
        XCTAssertEqual(TestLabel.oomiya, viewManager.travel.routes[2].finishLabel)
        XCTAssertNil(viewManager.travel.routes[0].currentRouteSteps) // 全ステップ踏破
        XCTAssertNil(viewManager.travel.routes[1].currentRouteSteps) // 全ステップ踏破
        XCTAssertNotNil(viewManager.travel.routes[2].currentRouteSteps)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[0].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[1].color)
        XCTAssertEqual(AnnotationColor.done, viewManager.annotations[2].color)
        XCTAssertEqual(AnnotationColor.yet, viewManager.annotations[3].color)
        
        // 無効なindex(最後尾の指定も含む)を指定した場合は何も起きない
        // 皇居前
        try await viewManager.insertAnnotation(index: -1, annotation: PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial))
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertFalse(viewManager.annotations.contains(PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial)))
        try await viewManager.insertAnnotation(index: 4, annotation: PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial))
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertFalse(viewManager.annotations.contains(PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial)))
        try await viewManager.insertAnnotation(index: 5, annotation: PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial))
        XCTAssertEqual(4, viewManager.annotations.count)
        XCTAssertFalse(viewManager.annotations.contains(PointAnnotation(coordinate:TestCoordinate.imperial, label:TestLabel.imperial)))
    }
    
    //
    // 指定位置が歩行先として有効かどうか確認
    // MapKitアクセスあり
    //
    func testCheckValidLocation() async throws {
        let viewManager = ViewManager()

        // 東京駅
        let coords = try await viewManager.checkValidLocation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo))
        XCTAssertEqual(TestCoordinate.tokyo.latitude, coords.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, coords.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        
        // 太平洋の海の底
        do {
            let _ = try await viewManager.checkValidLocation(annotation: PointAnnotation(coordinate:TestCoordinate.invalid, label:TestLabel.invalid))
            XCTFail()
        } catch {
        }
    }
    
    // MARK: - Util
    
    //
    // 状態に応じたメニューメッセージを生成できるか確認
    //
    func testMenuMessage() async throws {
        let viewManager = ViewManagerMock()
        let calendar = Calendar.current
        
        // 初期状態：開始地の指定を要求
        viewManager.createNewTravel(startDate: Date())
        viewManager.editMode = .inactive
        XCTAssertEqual(MenuMessage.requestStart, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
        
        // 歩行データは存在するが経路が設定されていない時：目的地の指定を要求
        viewManager.createNewTravel(startDate: Date())
        viewManager.editMode = .inactive
        viewManager.travel.currentDistance = 10
        XCTAssertEqual(MenuMessage.requestStart, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.requestStart.rawValue, viewManager.message)
        
        // 開始地点を追加した後：目的地の指定を要求
        viewManager.createNewTravel(startDate: calendar.date(from: DateComponents(year: 2023, month: 1, day: 2))!)
        viewManager.travel.finishedDate = calendar.date(from: DateComponents(year: 2023, month: 3, day: 4))!
        viewManager.editMode = .inactive
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        XCTAssertEqual(MenuMessage.requestFinish, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.requestFinish.rawValue, viewManager.message)
        
        // 目的地を追加した後：目的地までの距離を表示
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        viewManager.editMode = .inactive
        viewManager.travel.finishDistance = 10000
        viewManager.travel.currentDistance = 5000
        XCTAssertEqual(MenuMessage.infoRoute, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.infoRoute.rawValue + " 5/10km", viewManager.message)
        
        // 目的地を追加した後(経路編集)：編集操作の案内
        viewManager.editMode = .active
        XCTAssertEqual(MenuMessage.edit, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.edit.rawValue, viewManager.message)
        
        // 目的地に到着した後：目的地到着をお知らせ
        viewManager.editMode = .inactive
        viewManager.travel.finishDistance = 10000
        viewManager.travel.currentDistance = 10000
        XCTAssertEqual(MenuMessage.finish, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.finish.rawValue, viewManager.message)
        
        // 目的地に到着した後(経路編集)：編集操作の案内
        viewManager.editMode = .active
        XCTAssertEqual(MenuMessage.edit, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.edit.rawValue, viewManager.message)
        
        // 完了Travel
        viewManager.editMode = .inactive
        viewManager.travel.finishDistance = 10000
        viewManager.travel.currentDistance = 10000
        viewManager.travel.isStop = true
        XCTAssertEqual(MenuMessage.infoFinished, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.infoFinished.rawValue + " 2023/01/02 10km", viewManager.message)
        
        // 中断Travel
        viewManager.editMode = .inactive
        viewManager.travel.finishDistance = 10000
        viewManager.travel.currentDistance = 5000
        viewManager.travel.isStop = true
        XCTAssertEqual(MenuMessage.infoInterrupted, viewManager.menuMessage())
        viewManager.updateMenuMessage()
        XCTAssertEqual(MenuMessage.infoInterrupted.rawValue + " 2023/01/02 5/10km", viewManager.message)
    }
    
    //
    // 経路一覧に表示するラベルを取得
    //
    func testGetDisplayLabel() async throws {
        let viewManager = ViewManagerMock()
        XCTAssertEqual("Error", viewManager.getDisplayLabel(index: 0))
        
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: true)
        XCTAssertEqual("東京駅", viewManager.getDisplayLabel(index: 0))
        
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: true)
        
        let travel = viewManager.travel
        
        travel.currentDistance = 0
        XCTAssertEqual("東京駅", viewManager.getDisplayLabel(index: 0))
        XCTAssertEqual("東京スカイツリー", viewManager.getDisplayLabel(index: 1))
        XCTAssertEqual("新小岩駅", viewManager.getDisplayLabel(index: 2))
        travel.currentDistance = 1
        XCTAssertEqual("(済)東京駅", viewManager.getDisplayLabel(index: 0))
        XCTAssertEqual("東京スカイツリー", viewManager.getDisplayLabel(index: 1))
        XCTAssertEqual("新小岩駅", viewManager.getDisplayLabel(index: 2))
        travel.currentDistance = 7000
        XCTAssertEqual("(済)東京駅", viewManager.getDisplayLabel(index: 0))
        XCTAssertEqual("(済)東京スカイツリー", viewManager.getDisplayLabel(index: 1))
        XCTAssertEqual("新小岩駅", viewManager.getDisplayLabel(index: 2))
        travel.currentDistance = 70000
        XCTAssertEqual("(済)東京駅", viewManager.getDisplayLabel(index: 0))
        XCTAssertEqual("(済)東京スカイツリー", viewManager.getDisplayLabel(index: 1))
        XCTAssertEqual("(済)新小岩駅", viewManager.getDisplayLabel(index: 2))
        
        XCTAssertEqual("Error", viewManager.getDisplayLabel(index: -1))
        XCTAssertEqual("Error", viewManager.getDisplayLabel(index: 3))
    }
    
    //
    // 指定indexのAnnotationを選択状態にする
    //
    func testSelectAnnotation() async throws {
        let viewManager = ViewManagerMock()
        // 東京駅
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.tokyo, label:TestLabel.tokyo), isTemporary: false)
        // 東京スカイツリー (5.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.skytree, label:TestLabel.skytree), isTemporary: true)
        // 新小岩駅 (6.4km)
        let _ = try await viewManager.addAnnotation(annotation: PointAnnotation(coordinate:TestCoordinate.koiwa, label:TestLabel.koiwa), isTemporary: true)

        // 何も選択されていない状態
        var annotation: PointAnnotation?
        XCTAssertNil(viewManager.getSelectedAnnotation())
        
        // 最初のAnnotationを選択
        viewManager.selectAnnotation(index: 0)
        annotation = viewManager.getSelectedAnnotation()
        XCTAssertEqual(TestLabel.tokyo, annotation!.label)
        XCTAssertEqual(TestCoordinate.tokyo.latitude, annotation!.coordinate.latitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(TestCoordinate.tokyo.longitude, annotation!.coordinate.longitude, accuracy: COORD_STEP_ACCURACY_REAL)
        XCTAssertEqual(0, annotation!.routeIndex)
        
        // 最後のAnnotationを選択
        viewManager.selectAnnotation(index: 2)
        annotation = viewManager.getSelectedAnnotation()
        XCTAssertEqual(TestLabel.koiwa, annotation!.label)
        XCTAssertEqual(TestCoordinate.koiwa.latitude, annotation!.coordinate.latitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(TestCoordinate.koiwa.longitude, annotation!.coordinate.longitude, accuracy: COORD_ACCURACY)
        XCTAssertEqual(2, annotation!.routeIndex)
        
        // 無効なAnnotationを選択
        viewManager.selectAnnotation(index: 100)
        XCTAssertNil(viewManager.getSelectedAnnotation())
    }

    //
    // 表示用ラベル(歩行済み距離/目的地までの距離)を取得
    //
    func testGetCurrentDistancePerFinishLabel() throws {
        let viewManager = ViewManagerMock()

        let travel = viewManager.travel
        travel.currentDistance = 0
        travel.finishDistance = 0
        XCTAssertEqual("0/0km", viewManager.getCurrentDistancePerFinishLabel())

        travel.currentDistance = 0
        travel.finishDistance = 12345
        XCTAssertEqual("0/12km", viewManager.getCurrentDistancePerFinishLabel())

        //
        // 異常系
        //

        travel.currentDistance = 12345
        travel.finishDistance = 0
        XCTAssertEqual("12/0km", viewManager.getCurrentDistancePerFinishLabel())

        travel.currentDistance = -12345
        travel.finishDistance = -12345
        XCTAssertEqual("0/0km", viewManager.getCurrentDistancePerFinishLabel())
    }

    //
    // 表示用ラベル(歩行済み距離)を取得
    //
    func testGetCurrentDistanceLabel() throws {
        let viewManager = ViewManagerMock()
        
        let travel = viewManager.travel
        travel.currentDistance = 0
        XCTAssertEqual("0km", viewManager.getCurrentDistanceLabel())
        travel.currentDistance = 12345
        XCTAssertEqual("12km", viewManager.getCurrentDistanceLabel())
        travel.currentDistance = -12345
        XCTAssertEqual("0km", viewManager.getCurrentDistanceLabel())
    }

    //
    // 表示用ラベル(目的地までの距離)を取得
    //
    func testGetFinishDistanceLabel() throws {
        let viewManager = ViewManagerMock()
        
        let travel = viewManager.travel
        travel.finishDistance = 0
        XCTAssertEqual("0km", viewManager.getFinishDistanceLabel())
        travel.finishDistance = 12345
        XCTAssertEqual("12km", viewManager.getFinishDistanceLabel())
        travel.finishDistance = -12345
        XCTAssertEqual("0km", viewManager.getFinishDistanceLabel())
    }

    //
    // 表示用ラベル(本日の歩行距離)を取得
    //
    func testGetTodayDistanceMapLabel() throws {
        let viewManager = ViewManagerMock()
        
        let travel = viewManager.travel
        travel.todayDistance = 0
        XCTAssertEqual("0km", viewManager.getTodayDistanceMapLabel())
        travel.todayDistance = 12345
        XCTAssertEqual("12.3km", viewManager.getTodayDistanceMapLabel())
        travel.todayDistance = -12345
        XCTAssertEqual("0km", viewManager.getTodayDistanceMapLabel())
    }
    
    //
    // 現在位置を表すAnnotationを生成
    //
    func testCreateCurrentAnnotation() throws {
        let viewManager = ViewManagerMock()
        viewManager.travel.currentLocation = nil
        
        XCTAssertNil(viewManager.createCurrentAnnotation())

        var annotation: PointAnnotation?
        viewManager.travel.currentLocation = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        viewManager.travel.todayDistance = 12345
        annotation = viewManager.createCurrentAnnotation()
        if let annotation = annotation {
            XCTAssertEqual(10, annotation.coordinate.latitude, accuracy: COORD_ACCURACY)
            XCTAssertEqual(20, annotation.coordinate.longitude, accuracy: COORD_ACCURACY)
            XCTAssertEqual(AnnotationColor.today, annotation.color)
            XCTAssertEqual(-1, annotation.routeIndex)
            XCTAssertEqual(true, annotation.isCurrentLocation)
            XCTAssertEqual("12.3km", annotation.title)
        } else {
            XCTFail("createCurrentAnnotation is nil")
        }

        XCTAssertNotNil(annotation)
        
    }
    
    //
    // 現在位置を基準にしたMap表示範囲を生成(正常系)
    //
    func testSetMapRegionToCurrentLocation() throws {
        let viewManager = ViewManagerMock()

        let coords = [
            [
                CLLocationCoordinate2D(latitude: 10.0001, longitude: 11.0001), // 距離が近い
                CLLocationCoordinate2D(latitude: 10.0002, longitude: 11.0002),
            ],
            [
                CLLocationCoordinate2D(latitude: 10.1, longitude: 11.1), // 距離が遠い
                CLLocationCoordinate2D(latitude: 15.2, longitude: 15.2),
            ],
        ]
        // 2.55
        let polyline = [
            ColoredPolyline(coordinates: coords[0], count: coords[0].count),
            ColoredPolyline(coordinates: coords[1], count: coords[1].count),
        ]

        viewManager.mapRegion = nil
        viewManager.travel.currentLocation = coords[0][0]
        
        // 狭い範囲になるケースでは最小範囲で生成される
        viewManager.todayPolyline = polyline[0]
        viewManager.setMapRegionToCurrentLocation()
        if let region = viewManager.mapRegion {
            XCTAssertEqual(10.0001, region.center.latitude, accuracy: COORD_ACCURACY)
            XCTAssertEqual(11.0001, region.center.longitude, accuracy: COORD_ACCURACY)
            XCTAssertEqual(0.02, region.span.latitudeDelta, accuracy: COORD_ACCURACY)
            XCTAssertEqual(0.02, region.span.longitudeDelta, accuracy: COORD_ACCURACY)
        } else {
            XCTFail("viewManager.mapRegion is nil.")
        }
        
        // 広い範囲になるケース
        viewManager.todayPolyline = polyline[1]
        viewManager.setMapRegionToCurrentLocation()
        if let region = viewManager.mapRegion {
            XCTAssertEqual(10.0001, region.center.latitude, accuracy: COORD_ACCURACY)
            XCTAssertEqual(11.0001, region.center.longitude, accuracy: COORD_ACCURACY)
            XCTAssertTrue(region.span.latitudeDelta > 0.02)
            XCTAssertTrue(region.span.longitudeDelta > 0.02)
        } else {
            XCTFail("viewManager.mapRegion is nil.")
        }

    }
    
    //
    // 現在位置を基準にしたMap表示範囲を生成(異常系)
    //
    func testSetMapRegionToCurrentLocationByInvalidParam() throws {
        let viewManager = ViewManagerMock()

        let coords = [
            [
                CLLocationCoordinate2D(latitude: 10.0001, longitude: 11.0001), // 距離が近い
                CLLocationCoordinate2D(latitude: 10.0002, longitude: 11.0002),
            ],
            [
                CLLocationCoordinate2D(latitude: 10.1, longitude: 11.1), // 距離が遠い
                CLLocationCoordinate2D(latitude: 15.2, longitude: 15.2),
            ],
        ]
        let polyline = [
            ColoredPolyline(coordinates: coords[0], count: coords[0].count),
            ColoredPolyline(coordinates: coords[1], count: coords[1].count),
        ]

        // 初期状態では何も生成されない
        viewManager.mapRegion = nil
        viewManager.travel.currentLocation = nil
        viewManager.todayPolyline = nil
        viewManager.setMapRegionToCurrentLocation()
        XCTAssertNil(viewManager.mapRegion)

        // 今日の移動経路が存在しない場合は何も生成されない
        viewManager.travel.currentLocation = coords[0][0]
        viewManager.todayPolyline = nil
        viewManager.setMapRegionToCurrentLocation()
        XCTAssertNil(viewManager.mapRegion)

        // 現在位置が存在しない場合は何も生成されない
        viewManager.travel.currentLocation = nil
        viewManager.todayPolyline = polyline[0]
        viewManager.setMapRegionToCurrentLocation()
        XCTAssertNil(viewManager.mapRegion)


    }

}
