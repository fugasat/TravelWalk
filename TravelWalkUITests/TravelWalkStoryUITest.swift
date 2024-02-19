//


import XCTest

final class TravelWalkStoryUITest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSrory() throws {
        let fullTest = true
        
        let app = XCUIApplication()
        app.launchArguments = ["-uistorytest"]
        app.launch()
        sleep(1)

        // メニューの状態を確認
        XCTAssertTrue(app.staticTexts["開始日と開始地点を設定"].exists)
        XCTAssertEqual("2024/01/01", app.buttons["Date Picker"].value as! String)
        XCTAssertTrue(app.staticTexts["歩行済"].exists)
        XCTAssertTrue(app.staticTexts["目的地"].exists)
        XCTAssertTrue(app.staticTexts["0km"].exists)
        // 終了ボタンが表示されていないことを確認
        XCTAssertFalse(app.buttons["旅を中断"].exists)
        XCTAssertFalse(app.buttons["旅を終了"].exists)
        // 編集ボタンが表示されていないことを確認
        XCTAssertFalse(app.buttons["完了"].exists)
        XCTAssertFalse(app.buttons["編集"].exists)
        XCTAssertFalse(app.buttons["再開"].exists)

        //
        // 経路を作成する
        //

        // 開始位置を設定
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.1)).tap()
        sleep(1)
        app.otherElements["map"].pinch(withScale: 0.1, velocity: -0.5)
        Thread.sleep(forTimeInterval: 0.2)

        // メッセージを確認
        XCTAssertTrue(app.staticTexts["目的地を設定"].exists)
        // 経路地点の数を確認
        XCTAssertEqual(1, app.collectionViews.children(matching: .cell).count)
        // 終了ボタンが表示されていないことを確認
        XCTAssertFalse(app.buttons["旅を中断"].exists)
        XCTAssertFalse(app.buttons["旅を終了"].exists)
        // 編集ボタンが表示されていないことを確認
        XCTAssertFalse(app.buttons["完了"].exists)
        XCTAssertFalse(app.buttons["編集"].exists)
        XCTAssertFalse(app.buttons["再開"].exists)

        // 目的地を設定
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.4)).tap()
        sleep(1)
        app.otherElements["map"].pinch(withScale: 0.5, velocity: -0.8)
        Thread.sleep(forTimeInterval: 0.2)

        // メッセージを確認
        XCTAssertTrue(app.staticTexts["経路の編集"].exists)
        // 経路地点の数を確認
        XCTAssertEqual(2, app.collectionViews.children(matching: .cell).count)
        // 中断ボタンが表示されていることを確認
        XCTAssertTrue(app.buttons["旅を中断"].exists)
        // 編集完了ボタンが表示されていることを確認
        XCTAssertTrue(app.buttons["完了"].exists)

        // 目的地を追加する
        if fullTest {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.4)).tap()
            sleep(1)
            app.otherElements["map"].pinch(withScale: 0.4, velocity: -0.5)
            Thread.sleep(forTimeInterval: 0.2)

            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.4)).tap()
            sleep(1)

            // 経路地点の数を確認
            XCTAssertEqual(4, app.collectionViews.children(matching: .cell).count)
        }

        //
        // 各経路を確認する
        //
        
        // 編集モードを終了する
        app.buttons["完了"].tap()

        // メッセージを確認
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '目的地 0/'")).exists)
        // 中断ボタンが表示されていることを確認
        XCTAssertTrue(app.buttons["旅を中断"].exists)
        // 編集ボタンが表示されていることを確認
        XCTAssertTrue(app.buttons["編集"].exists)
        
        // 各経路を確認する
        if fullTest {
            app.collectionViews.children(matching: .cell).element(boundBy: 0).tap()
            app.collectionViews.children(matching: .cell).element(boundBy: 2).tap()
            app.collectionViews.children(matching: .cell).element(boundBy: 1).tap()
            app.collectionViews.children(matching: .cell).element(boundBy: 3).tap()
            app.collectionViews.children(matching: .cell).element(boundBy: 0).tap()
        }

        //
        // 歩行距離を増やす
        //

        // 編集モードに変更する
        app.buttons["編集"].tap()
        // 開始日を変更する
        self.setSelectionDate(app: app, yearLabel: "2023年", monthLabel: "12月")
        XCTAssertEqual("2023/12/01", app.buttons["Date Picker"].value as! String)
        sleep(1)
        // 歩行済距離が更新される
        XCTAssertTrue(app.staticTexts["20km"].exists)

        //
        // 新しいTravelを作成
        //
        
        // Travelを中断する
        app.buttons["旅を中断"].tap()
        app.buttons["はい、記録します"].tap()
        app.textFields["旅の名前"].typeText("1")
        app.buttons["記録する"].tap()

        // 開始日を2023/11に変更する
        self.setSelectionDate(app: app, yearLabel: "2023年", monthLabel: "11月")
        XCTAssertEqual("2023/11/01", app.buttons["Date Picker"].value as! String)

        // 歩行距離が40kmになる
        XCTAssertTrue(app.staticTexts["40km"].exists)

        // 新しいTravelの経路を登録
        app.otherElements["map"].pinch(withScale: 0.5, velocity: -0.8)
        Thread.sleep(forTimeInterval: 0.2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        sleep(1)
        app.otherElements["map"].pinch(withScale: 0.3, velocity: -0.5)
        Thread.sleep(forTimeInterval: 0.2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        sleep(1)
        app.buttons["完了"].tap()

        // 完了状態になっているか確認
        XCTAssertTrue(app.staticTexts["目的地に到着しました"].exists)
        app.buttons["旅を終了"].tap()
        app.buttons["はい、記録します"].tap()
        app.textFields["旅の名前"].typeText("2")
        app.buttons["記録する"].tap()

        //
        // 新しいTravelを作成
        //

        self.setSelectionDate(app: app, yearLabel: "2023年", monthLabel: "10月")
        XCTAssertEqual("2023/10/01", app.buttons["Date Picker"].value as! String)
        // 歩行距離が60kmになる
        XCTAssertTrue(app.staticTexts["60km"].exists)
        // 目的地を登録
        app.otherElements["map"].pinch(withScale: 0.1, velocity: -0.5)
        Thread.sleep(forTimeInterval: 0.2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.1)).tap()
        sleep(1)
        app.otherElements["map"].pinch(withScale: 0.1, velocity: -0.5)
        Thread.sleep(forTimeInterval: 0.2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.1)).tap()
        sleep(1)
        
        //
        // 中断しているTravelに切り替え
        //

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // ２つの項目が登録されていることを確認
        XCTAssertTrue(app.staticTexts["2023/11/01 新規2 (完了)"].exists)
        XCTAssertTrue(app.staticTexts["2023/12/01 新規1 (中断)"].exists)
        // 最初に作成した中断Travelを選択
        app.staticTexts["2023/12/01 新規1 (中断)"].tap()
        sleep(1)
        // メッセージを確認
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '中断 2023/12/01 20/'")).exists)
        // 再開する
        app.buttons["再開"].tap()
        app.buttons["はい、再開します"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '目的地 20/'")).exists)
        // 開始日を確認
        app.buttons["編集"].tap()
        XCTAssertEqual("2023/12/01", app.buttons["Date Picker"].value as! String)


        //
        // 完了しているTravelに切り替え
        //

        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // ２つの項目が登録されていることを確認
        XCTAssertTrue(app.staticTexts["2023/11/01 新規2 (完了)"].exists)
        // 実行中から完了に更新されている(距離が目的地を超えているため中断にはならない)
        XCTAssertTrue(app.staticTexts["2023/10/01 新規 (完了)"].exists)
        // 完了Travelを選択
        app.staticTexts["2023/11/01 新規2 (完了)"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '完了 2023/11/01'")).exists)
        // 再開する
        app.buttons["再開"].tap()
        app.buttons["はい、再開します"].tap()
        // 開始日を確認
        app.buttons["編集"].tap()
        XCTAssertEqual("2023/11/01", app.buttons["Date Picker"].value as! String)
        // 歩行距離を確認
        XCTAssertTrue(app.staticTexts["40km"].exists)

        //
        // 中断Travelの開始日を変更して完了にする
        //
        
        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // ２つの項目が登録されていることを確認
        XCTAssertTrue(app.staticTexts["2023/10/01 新規 (完了)"].exists)
        XCTAssertTrue(app.staticTexts["2023/12/01 新規1 (中断)"].exists)
        // 最初のTravelを選択
        app.staticTexts["2023/12/01 新規1 (中断)"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH '中断 2023/12/01 20/'")).exists)
        // 開始日を確認
        app.buttons["再開"].tap()
        app.buttons["はい、再開します"].tap()
        app.buttons["編集"].tap()
        XCTAssertEqual("2023/12/01", app.buttons["Date Picker"].value as! String)
        // 目的地を追加
        app.otherElements["map"].pinch(withScale: 0.5, velocity: -0.8)
        Thread.sleep(forTimeInterval: 0.2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        sleep(1)
        // 日付を変更
        self.setSelectionDate(app: app, yearLabel: "2023年", monthLabel: "1月")
        // 歩行距離が更新されることを確認
        XCTAssertTrue(app.staticTexts["240km"].exists)
        // 編集完了後のメッセージが目的地到着に変わっていることを確認
        app.buttons["完了"].tap()
        XCTAssertTrue(app.staticTexts["目的地に到着しました"].exists)

        //
        // 一番最後に作成したTravelに切り替えて、歩行距離も変わることを確認
        //
        
        // 終了済リストを表示
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        // 一番最後に作成したTravelを選択
        app.staticTexts["2023/10/01 新規 (完了)"].tap()
        // 再開して編集モードにする
        app.buttons["再開"].tap()
        app.buttons["はい、再開します"].tap()
        // 開始日を確認
        app.buttons["編集"].tap()
        XCTAssertEqual("2023/10/01", app.buttons["Date Picker"].value as! String)

        // 歩行距離を確認
        XCTAssertTrue(app.staticTexts["60km"].exists)
    }
    
    func setSelectionDate(app: XCUIApplication, yearLabel: String, monthLabel: String) {
        // 開始日を変更する
        app.buttons["Date Picker"].tap()
        sleep(1)
        // 日付を1に変更
        app.staticTexts["1"].tap()
        // 年月を変更するWeelsを表示
        app.buttons["Month"].tap()
        sleep(1)
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: yearLabel)
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: monthLabel)
        sleep(1)
        // カレンダー余白をタップしてDatePickerを閉じる
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
    }

}
