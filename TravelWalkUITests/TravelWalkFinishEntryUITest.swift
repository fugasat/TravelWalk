import XCTest

final class TravelWalkFinishEntryUITest: XCTestCase {

    override func setUpWithError() throws {
        // UI tests must launch the application that they test.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFinishTravel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "finish"]
        app.launch()
        TravelWalkUITests.waitAllAnnotationAppear(app: app, isFinish: true)

        // ゴールメッセージが表示されていることを確認
        XCTAssertTrue(app.staticTexts["目的地に到着しました"].exists)
        app.buttons["OK"].tap()
        print(app.debugDescription)

        // 到着メッセージの表示と編集モードになっていることを確認
        XCTAssertTrue(app.staticTexts["目的地に到着しました"].exists)
        XCTAssertTrue(app.buttons["編集"].exists)
        XCTAssertTrue(app.buttons["旅を終了"].exists)

        // 記録確認ダイアログを確認
        app.buttons["旅を終了"].tap()
        app.buttons["いいえ、記録しません"].tap()
        // キャンセルした時に名前入力ダイアログが出ていないことを確認
        XCTAssertFalse(app.buttons["旅の名前"].exists)

        // 名前入力ダイアログを確認
        app.buttons["旅を終了"].tap()
        app.buttons["はい、記録します"].tap()
        XCTAssertTrue(app.staticTexts["保存する旅の名前を入力してください"].exists)
        app.buttons["まだ記録しない"].tap()
        app.buttons["旅を終了"].tap()
        app.buttons["はい、記録します"].tap()
        app.textFields["旅の名前"].typeText("旅行")
        app.buttons["記録する"].tap()

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // 終了状態で登録されていることを確認
        XCTAssertTrue(app.staticTexts["2016/05/17 新規旅行 (完了)"].exists)

    }
    
    func testSwitchTravels() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest", "finish"]
        app.launch()
        TravelWalkUITests.waitAllAnnotationAppear(app: app, isFinish: true)

        app.buttons["OK"].tap()

        // 初期状態のTravelの開始日を変更する
        app.buttons["編集"].tap()
        app.buttons["Date Picker"].tap()
        app.staticTexts["1"].tap()
        // カレンダー余白をタップしてDatePickerを閉じる
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // Travelを選択
        app.staticTexts["2023/09/01 Travel0 (中断)"].tap()
        sleep(1)
        print(app.debugDescription)
        XCTAssertTrue(app.staticTexts["中断 2023/09/01 20/100km"].exists)
        XCTAssertFalse(app.buttons["旅を中断"].exists)
        XCTAssertTrue(app.buttons["再開"].exists)

        app.staticTexts["(済)start0"].tap()
        app.staticTexts["finish0"].tap()

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // Travelを選択
        app.staticTexts["2023/07/01 Travel1 (中断)"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["中断 2023/07/01 80/100km"].exists)
        XCTAssertFalse(app.buttons["旅を中断"].exists)
        XCTAssertTrue(app.buttons["再開"].exists)
        app.staticTexts["(済)start1"].tap()
        app.staticTexts["finish1"].tap()

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // Travelを選択
        app.staticTexts["2023/05/01 Travel2 (完了)"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["完了 2023/05/01 100km"].exists)
        XCTAssertFalse(app.buttons["旅を終了"].exists)
        XCTAssertTrue(app.buttons["再開"].exists)
        app.staticTexts["(済)start2"].tap()
        app.staticTexts["(済)finish2"].tap()

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // 元のTravelを選択
        app.staticTexts["2016/05/01 新規 (実行中)"].tap()
        app.buttons["編集"].tap()
        XCTAssertEqual("2016/05/01", app.buttons["Date Picker"].value as! String)
        XCTAssertTrue(app.buttons["旅を終了"].exists)
    }
    
    func testRestartTravel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
        TravelWalkUITests.waitAllAnnotationAppear(app: app, isFinish: false)

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // Travelを選択
        app.staticTexts["2023/07/01 Travel1 (中断)"].tap()
        // 再開ボタンが表示される
        app.buttons["再開"].tap()
        app.buttons["いいえ、再開しません"].tap()
        app.buttons["再開"].tap()
        app.buttons["はい、再開します"].tap()
        // 通常画面になる
        // 歩行距離が更新されてゴールになる
        sleep(1)
        XCTAssertTrue(app.staticTexts["目的地に到着しました"].exists)
        XCTAssertTrue(app.buttons["編集"].exists)
        
        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()

        // 今まで実行中だったTravelは中断になっている
        XCTAssertTrue(app.staticTexts["2022/12/07 新規 (中断)"].exists)
    }
    
    func testEditFinishedTravel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
        TravelWalkUITests.waitAllAnnotationAppear(app: app, isFinish: false)

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        print(app.debugDescription)

        // 編集モードにする
        app.buttons["finishedTravelListEditButton"].tap()

        // Travelを選択
        app.staticTexts["2023/07/01 Travel1 (中断)"].tap()
        app.textFields["旅の名前"].typeText("あああ")
        app.buttons["キャンセル"].tap()

        app.staticTexts["2023/07/01 Travel1 (中断)"].tap()
        app.textFields["旅の名前"].typeText("旅行")
        app.buttons["名前を変更する"].tap()

        XCTAssertTrue(app.staticTexts["2023/07/01 Travel1旅行 (中断)"].exists)

        // 編集モードを解除
        app.buttons["finishedTravelListEditButton"].tap()

        // ダイアログを閉じる
        app.buttons["finishedTravelListClose"].tap()

        // 再度終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()

        // 編集モードにする
        app.buttons["finishedTravelListEditButton"].tap()

        // 全てのTravelを削除する
        app.images["removeButton1"].firstMatch.tap()
        app.buttons["いいえ、削除しません"].tap()
        app.images["removeButton1"].firstMatch.tap()
        app.buttons["はい、削除します"].tap()
        app.images["removeButton0"].firstMatch.tap()
        app.buttons["はい、削除します"].tap()
        app.images["removeButton0"].firstMatch.tap()
        app.buttons["はい、削除します"].tap()
        
        // 元の画面に戻っていることを確認
        sleep(1)
        XCTAssertFalse(app.staticTexts["旅の記録"].exists)
    }
}
