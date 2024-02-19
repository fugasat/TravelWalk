import XCTest

final class TravelWalkUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    static func waitAllAnnotationAppear(app: XCUIApplication, isFinish: Bool) {
        // Annotationが全て登録されるまで待機
        for _ in 0..<100 {
            if isFinish {
                if
                    app.staticTexts["(済)東京都千代田区丸の内1丁目"].exists &&
                    app.staticTexts["(済)静岡県静岡市葵区黒金町"].exists &&
                    app.staticTexts["(済)愛知県名古屋市中区"].exists &&
                    app.staticTexts["(済)京都府京都市中京区一之船入町"].exists &&
                    app.staticTexts["(済)大阪府大阪市中央区平野町3丁目"].exists
                {
                    break
                }
            } else {
                if
                    app.staticTexts["(済)東京都千代田区丸の内1丁目"].exists &&
                    app.staticTexts["(済)静岡県静岡市葵区黒金町"].exists &&
                    app.staticTexts["愛知県名古屋市中区"].exists &&
                    app.staticTexts["京都府京都市中京区一之船入町"].exists &&
                    app.staticTexts["大阪府大阪市中央区平野町3丁目"].exists
                {
                    break
                }
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
    @MainActor func test() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()

        // Fastlane初期化
        // ScreenShot生成はコマンドラインで実施：fastlane snapshot
        setupSnapshot(app)
        
        // Test Modeを指定する（テスト用Annotationが追加される）
        app.launchArguments = ["-uitest"]
        app.launch()
        TravelWalkUITests.waitAllAnnotationAppear(app: app, isFinish: false)
        print(app.debugDescription)

        // 編集ボタンを確認
        app.buttons["編集"].tap()
        sleep(1)

        // 開始ボタンを確認
        let datePickers = app.datePickers.matching(identifier: "datePicker").firstMatch
        datePickers.tap()
        sleep(1)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
        sleep(1)

        // 編集を完了
        app.buttons["完了"].tap()
        sleep(1)
        
        snapshot("overall_view")

        // 登録されたAnnotationを確認
        XCTAssertTrue(app.staticTexts["(済)東京都千代田区丸の内1丁目"].exists)
        XCTAssertTrue(app.staticTexts["(済)静岡県静岡市葵区黒金町"].exists)
        XCTAssertTrue(app.staticTexts["愛知県名古屋市中区"].exists)
        XCTAssertTrue(app.staticTexts["京都府京都市中京区一之船入町"].exists)
        XCTAssertTrue(app.staticTexts["大阪府大阪市中央区平野町3丁目"].exists)

        // 通常モードで経路を確認
        app.staticTexts["(済)東京都千代田区丸の内1丁目"].tap()
        app.staticTexts["(済)静岡県静岡市葵区黒金町"].tap()
        app.staticTexts["京都府京都市中京区一之船入町"].tap()
        app.staticTexts["愛知県名古屋市中区"].tap()
        app.staticTexts["大阪府大阪市中央区平野町3丁目"].tap()
        app.staticTexts["(済)東京都千代田区丸の内1丁目"].tap()
        app.staticTexts["大阪府大阪市中央区平野町3丁目"].tap()

        // 編集モードに変更
        app.buttons["編集"].tap()
        sleep(1)

        // 編集モードで経路を確認
        app.staticTexts["(済)東京都千代田区丸の内1丁目"].tap()
        app.staticTexts["愛知県名古屋市中区"].tap()
        app.staticTexts["(済)東京都千代田区丸の内1丁目"].tap()
        app.staticTexts["大阪府大阪市中央区平野町3丁目"].tap()
        sleep(2)

        snapshot("current_edit_view")

        // Annotationを連続で追加
        // MapRegionアニメーション中に操作を開始する
        app.staticTexts["(済)東京都千代田区丸の内1丁目"].tap()
        app.staticTexts["愛知県名古屋市中区"].tap()
        for _ in 0..<20 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.12)).tap()
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.12)).tap()
        }

        sleep(1)
    }

}
