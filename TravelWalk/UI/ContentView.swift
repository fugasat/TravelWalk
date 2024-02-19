import SwiftUI
import MapKit

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewManager = ViewManager()
    @State private var selectionDate = Date()
    @State private var selectedListIndex: Int? = nil
    @State private var isProcessing = false
    @State private var mapType: MKMapType = .standard
    @State private var storedTravelName = ""
    @State private var isPresentedFinishMessage = false
    @State private var isPresentedConfirmFinishEntryMessage = false
    @State private var isPresentedInputFinishNameMessage = false
    @State private var isPresentedConfirmFinishRestartMessage = false
    @State private var isPresentedFinihedTravelListView = false
    @State private var switchedTravelIndex: Int = -1
    @State private var isDatePickerVisible = false
    
    // MARK: Contents view
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if self.viewManager.walkDistanceInitialized {
                    VStack {
                        //
                        // Contents view
                        //
                        VStack {
                            //
                            // Map
                            //
                            ZStack {
                                MapView(mapType: $mapType, viewManager: self.viewManager)
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height * 0.5)
                                    .accessibility(identifier: "map")
                                //
                                // Map overlay menu
                                //
                                VStack {
                                    HStack {
                                        if self.viewManager.finishedTravels.count > 0 {
                                            self.mapOverlayButton(
                                                systemName: "book.closed.circle.fill",
                                                action: {
                                                    self.isPresentedFinihedTravelListView = true
                                                }
                                            )
                                        }
                                        Spacer()
                                        self.mapOverlayButton(
                                            systemName: "map.circle.fill",
                                            action: {
                                                self.mapType = (self.mapType == .standard) ? .satellite : .standard
                                            }
                                        )
                                    }
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        if self.viewManager.finishedTravels.count > 0 {
                                            self.mapOverlayButton(
                                                systemName: "location.circle.fill",
                                                action: {
                                                    self.viewManager.setMapRegionToCurrentLocation()
                                                }
                                            )
                                        }
                                    }
                                }
                                .alignmentGuide(.top) { _ in
                                    -((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top)!
                                }
                                .onChange(of: self.switchedTravelIndex) { newSwitchedTravelIndex in
                                    self.switchTravel()
                                }
                            }
                            
                            //
                            // Menu
                            //
                            menuView()
                        }
                        .sheet(isPresented: $isPresentedFinihedTravelListView) {
                            FinishedTravelListView(
                                isPresentedFinihedTravelListView: $isPresentedFinihedTravelListView,
                                finishdTravels: self.$viewManager.finishedTravels,
                                switchedTravelIndex: $switchedTravelIndex,
                                viewManager: viewManager
                            )
                        }
                        .alert(
                            "目的地に到着しました",
                            isPresented: self.$isPresentedFinishMessage
                        ) {
                            Button(action: {}) {
                                Text("OK")
                            }
                        } message: {
                            Text("ここまでの目的地を記録することができます。")
                        }
                    }
                }
                if self.isProcessing {
                    self.mapProgressView()
                }
            }.onChange(of: scenePhase) { phase in
                if phase == .active && self.viewManager.walkDistanceInitialized {
                    self.updateWalkDistance()
                }
            }.onAppear() {
                self.initialize()
            }
        }
    }
    
    // MARK: Map
    
    private func mapOverlayButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: 40, height: 40)
        }
        .padding(4)
    }
    
    private func mapProgressView() -> some View {
        VStack {
            Text("地図を再構成しています...")
                .foregroundColor(.white)
                .padding()
                .background(Color.gray)
                .cornerRadius(10)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2) // サイズを調整
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
        
    }
    
    // MARK: Menu
    
    private func menuView() -> some View {
        ScrollViewReader { proxy in
            VStack {

                //
                // Menu
                //
                HStack {
                    Text(self.viewManager.message)
                        .padding(.horizontal, 16)
                        .font(.body)
                    Spacer()
                    if self.viewManager.travel.hasRoute() {
                        if self.viewManager.travel.isStop == false {
                            finishButton()
                        }
                        editButton()
                            .padding(.horizontal, 16)
                    }
                }
                if self.viewManager.editMode.isEditing {
                    HStack {
                        DatePicker("", selection: self.$selectionDate,
                                   displayedComponents: .date)
                            .accessibility(identifier: "datePicker")
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.description))
                            .onChange(of: self.selectionDate) { newValue in
                                self.updateSelectionDate(newSelectionDate: newValue)
                            }
                        Spacer()
                        VStack {
                            Text("歩行済")
                            Text("目的地")
                        }
                        VStack(alignment: .trailing) {
                            Text(self.viewManager.getCurrentDistanceLabel())
                            Text(self.viewManager.getFinishDistanceLabel())
                        }
                    }.padding(.horizontal, 8)
                }
                
                //
                // Finished travel list
                //
                VStack {
                    List(selection: self.$selectedListIndex) {
                        ForEach(self.viewManager.annotations.indices, id: \.self) {index in
                            let label = self.viewManager.getDisplayLabel(index: index)
                            HStack{
                                Text("\(label)")
                                    .accessibility(identifier: "cell_\(label)")
                            }
                            .id(index)
                            .contentShape(Rectangle())
                        }
                        .onDelete(perform: deleteItem)
                        .onMove(perform: moveItem)
                    }
                    .accessibility(identifier: "annotationList")
                    .listStyle(InsetListStyle())
                    .environment(\.editMode, self.$viewManager.editMode)
                }
            }
            .onChange(of: self.selectedListIndex) { newSelectedListIndex in
                self.viewManager.selectedListIndex = newSelectedListIndex ?? -1
            }
            .onChange(of: self.viewManager.selectedListIndex) { newSelectedListIndex in
                if newSelectedListIndex >= 0 {
                    self.selectedListIndex = newSelectedListIndex
                    proxy.scrollTo(newSelectedListIndex)
                }
            }
        }
    }
    
    private func editButton() -> some View {
        Button(action: {
            self.isPresentedConfirmFinishRestartMessage = self.viewManager.editButtonPressed()
        }) {
            if self.viewManager.editMode.isEditing {
                Text("完了")
            } else {
                if self.viewManager.travel.isStop {
                    Text("再開")
                } else {
                    Text("編集")
                }
            }
        }
        .accessibility(identifier: "editButton")
        .alert(
            "この旅を再開しますか？",
            isPresented: $isPresentedConfirmFinishRestartMessage
        ) {
            Button(role: .destructive, action: {
                self.restartTravel()
            }) {
                Text("はい、再開します")
            }
            Button(role: .cancel, action: {}) {
                Text("いいえ、再開しません")
            }
        } message: {
            Text("現在実行中の旅は一旦中断されます")
        }
    }
    
    private func finishButton() -> some View {
        HStack {
            Button(action: {
                self.isPresentedConfirmFinishEntryMessage = true
            }) {
                if self.viewManager.travel.isFinish() {
                    Text("旅を終了")
                } else {
                    Text("旅を中断")
                }
            }
            .accessibility(identifier: "finishButton")
            .alert(
                "目的地までの経路を記録しますか？",
                isPresented: $isPresentedConfirmFinishEntryMessage
            ) {
                Button(role: .destructive, action: {
                    self.isPresentedInputFinishNameMessage = true
                    var travelName = self.viewManager.travel.name
                    // storedTravelNameを""に設定すると最後の確定ボタンが機能しないので注意
                    if travelName == "" {
                        travelName = "新規"
                    }
                    self.storedTravelName = travelName
                }) {
                    Text("はい、記録します")
                }
                Button(role: .cancel, action: {}) {
                    Text("いいえ、記録しません")
                }
            } message: {
                Text("経路を記録した後は全ての経路が初期化され、新しい目的地を再び登録することができます")
            }
        }
        .alert(
            "保存する旅の名前を入力してください",
            isPresented: $isPresentedInputFinishNameMessage
        ) {
            TextField("旅の名前", text: $storedTravelName)
            Button(role: .destructive, action: {
                self.entryTravelToFinishList(entryName: self.storedTravelName)
            }) {
                Text("記録する")
            }
            .disabled(self.storedTravelName.count == 0)
            Button(role: .cancel, action: {}) {
                Text("まだ記録しない")
            }
        } message: {
            Text("記録した旅の内容はいつでも振り返ることができます")
        }
    }
    
    // MARK: Travel
    
    private func initialize() {
        self.isProcessing = true
        Task {
            self.viewManager.initialize {
                self.selectionDate = self.viewManager.travel.startDate
                if self.viewManager.travel.isFinish() {
                    self.isPresentedFinishMessage = true
                }
                Task { @MainActor in
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func updateSelectionDate(newSelectionDate: Date) {
        Task {
            do {
                try await self.viewManager.updateSelectionDate(newSelectionDate: newSelectionDate) {}
            } catch {
                showErrorDialog(error: error)
            }
        }
    }

    private func updateWalkDistance() {
        Task {
            do {
                try await self.viewManager.updateWalkDistance() {}
            } catch {
                showErrorDialog(error: error)
            }
        }
    }
    
    private func entryTravelToFinishList(entryName: String) {
        do {
            try self.viewManager.entryCurrentTravelToFinishList(
                entryName: entryName, finishedDate: self.viewManager.getCurrentDate())
            {
                self.selectionDate = self.viewManager.travel.startDate
            }
        } catch {
            print(error)
        }
    }
    
    private func switchTravel() {
        self.isProcessing = true
        Task {
            do {
                try self.viewManager.switchTravel(
                    switchedTravelIndex: self.switchedTravelIndex) {
                        print("travel switched \(self.switchedTravelIndex)")
                        self.selectionDate = self.viewManager.travel.startDate
                        self.switchedTravelIndex = -1
                        Task { @MainActor in
                            self.isProcessing = false
                        }
                    }
            } catch {
                print(error)
            }
        }
    }

    private func restartTravel() {
        do {
            try self.viewManager.restartTravel() {
            }
        } catch {
            print(error)
        }
    }
    
    private func deleteItem(from source: IndexSet) {
        self.isProcessing = true
        let selectIndex = Array(source)[0]
        Task {
            do {
                let annotation = self.viewManager.annotations[selectIndex]
                let _ = try await self.viewManager.removeAnnotation(annotation: annotation)
                self.viewManager.createTodayRoute()
                self.viewManager.selectedListIndex = selectIndex
                self.viewManager.mapRedrawFlag = true
            } catch {
                print("Failed to remove annotation: \(error)")
                showErrorDialog(error: error)
            }
            self.isProcessing = false
        }
    }
    
    private func moveItem(from sourceIndexSet: IndexSet, to destination: Int) {
        self.isProcessing = true
        let fromIndex = Array(sourceIndexSet)[0]
        var toIndex = destination
        if toIndex > 0 && fromIndex < destination {
            toIndex -= 1
        }
        Task {
            var annotationError: Error? = nil
            do {
                try await self.viewManager.moveAnnotation(fromIndex: fromIndex, toIndex: toIndex)
            } catch {
                annotationError = error
            }
            Task { @MainActor in
                if let error = annotationError {
                    showErrorDialog(error: error)
                    self.selectedListIndex = fromIndex
                    self.viewManager.rollback()
                    self.viewManager.updateMenuMessage()
                } else {
                    self.selectedListIndex = toIndex
                }
                self.viewManager.mapRedrawFlag = true
                self.isProcessing = false
            }
        }
    }
}

func showErrorDialog(error: Error) {
    print(error)
    let message = "人が立ち入ることができない場所か、経路が遠すぎる可能性があります"
    let alertController = UIAlertController(title: error.localizedDescription, message: message, preferredStyle: .actionSheet)
    let actionCancel = UIAlertAction(title: "OK", style: .cancel){
        (action) -> Void in
        print("cancel")
    }
    alertController.addAction(actionCancel)
    
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    window?.rootViewController?.present(alertController, animated: true, completion: nil)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
