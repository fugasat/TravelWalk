import SwiftUI

struct FinishedTravelListView: View {

    @Binding var isPresentedFinihedTravelListView: Bool
    @Binding var finishdTravels: [Travel]
    @Binding var switchedTravelIndex: Int
    @ObservedObject var viewManager: ViewManager

    @State private var selectedListIndex: Int?
    @State var editMode: EditMode = .inactive
    @State var isPresentedFinihedTravelEditView = false
    @State var isPresentedConfirmFinishRemoveMessage = false
    @State private var storedTravelName = ""
    @State private var removeListIndex: Int?

    var body: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                Text("旅の記録")
                Spacer()
                editButton
            }
            List(selection: self.$selectedListIndex) {
                let values = self.createList()
                ForEach(values.indices, id: \.self) {index in
                    HStack {
                        if self.editMode.isEditing {
                            Image(systemName: "minus.circle.fill")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(Color.red)
                                .accessibility(identifier: "removeButton\(index)")
                                .onTapGesture {
                                    self.selectedListIndex = index
                                    self.removeListIndex = index
                                    self.isPresentedConfirmFinishRemoveMessage = true
                                }
                        }

                        HStack {
                            Text("\(values[index])")
                            Spacer()
                            if self.editMode.isEditing {
                                Image(systemName: "pencil.circle")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.selectItem(selectedIndex: index)
                        }
                    }
                }
                .alert(
                    "この旅の経路を削除しますか？",
                    isPresented: $isPresentedConfirmFinishRemoveMessage
                ) {
                    Button(role: .destructive, action: {
                        self.deleteItem(removeIndex: self.removeListIndex)
                    }) {
                        Text("はい、削除します")
                    }
                    Button(role: .cancel, action: {}) {
                        Text("いいえ、削除しません")
                    }
                } message: {
                }

            }
            .environment(\.editMode, self.$editMode)
            .alert(
                "旅の名前を入力してください",
                isPresented: $isPresentedFinihedTravelEditView
            ) {
                TextField("旅の名前", text: $storedTravelName)
                Button(role: .destructive, action: {
                    self.renameTravel(name: self.storedTravelName)
                }) {
                    Text("名前を変更する")
                }
                .disabled(self.storedTravelName.count == 0)
                Button(role: .cancel, action: {}) {
                    Text("キャンセル")
                }
            } message: {
            }
        }
    }
    
    var editButton: some View {
        Button(action: {
            if self.editMode.isEditing {
                self.editMode = .inactive
            } else {
                self.editMode = .active
            }
        }) {
            if self.editMode.isEditing {
                Text("完了")
            } else {
                Text("編集")
            }
        }
        .accessibility(identifier: "finishedTravelListEditButton")
        .padding(16)
    }
    
    var closeButton: some View {
        Button(action: {
            self.isPresentedFinihedTravelListView = false
        }) {
            Image(systemName: "xmark")
        }
        .accessibility(identifier: "finishedTravelListClose")
        .padding(16)
    }

    private func createList() -> [String] {
        var values: [String] = []
        for travel in self.finishdTravels {
            values.append(travel.getFinishedTravelDisplayLabel())
        }
        return values
    }

    private func createLabel(travel: Travel) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return "\(dateFormatter.string(from: travel.finishedDate)) \(travel.name)"
    }

    private func selectItem(selectedIndex: Int) {
        self.selectedListIndex = selectedIndex
        if self.editMode.isEditing {
            print("edit:\(selectedIndex)")
            self.storedTravelName = self.finishdTravels[selectedIndex].name
            self.isPresentedFinihedTravelEditView = true
        } else {
            self.switchedTravelIndex = selectedIndex
            self.isPresentedFinihedTravelListView = false
        }
    }
    
    private func renameTravel(name: String) {
        if let index = self.selectedListIndex {
            self.finishdTravels[index].name = name
        }
    }

    private func deleteItem(removeIndex: Int?) {
        if let index = removeIndex {
            self.finishdTravels.remove(at: index)
            self.viewManager.save()
            if self.finishdTravels.count == 0 {
                self.isPresentedFinihedTravelListView = false
            }
        }
    }

}
