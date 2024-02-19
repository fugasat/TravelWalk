import Foundation


class StoreManager {
    
    enum StoreKey: String {
        case travel = "travel"
        case route = "route"
        case routeStep = "routestep"
        case walkingDistance = "walkingdistance"
        case finishedTravels = "finishedTravels"
    }

    var isTest = false
    var isLoadError = false
    
    let userDefaults = UserDefaults.standard

    private func getKeyName(key: StoreKey) -> String {
        if self.isTest {
            return "test_" + key.rawValue
        }
        return key.rawValue
    }

    func initializeTestData() {
        if self.isTest == false {
            return
        }
        self.userDefaults.removeObject(forKey: "test_routeStep")
        self.userDefaults.removeObject(forKey: "test_route")
        self.userDefaults.removeObject(forKey: "test_travel")
        self.userDefaults.removeObject(forKey: "test_walkingdistance")
    }
    
    func loadObject(key: String) -> Data? {
        return self.userDefaults.data(forKey: key)
    }
    
    private func saveToUserDefaults(codable: Codable?, key: String) {
        if self.isLoadError {
            print("save canceled by isLoadError (saveToUserDefaults)")
            return
        }
        if let storeValue = codable {
            do {
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(storeValue)
                self.userDefaults.set(encodedData, forKey: key)
                print("save finished:\(key)")
            } catch {
                print("Failed to save object to UserDefaults: \(error)")
            }
        } else {
            self.userDefaults.removeObject(forKey: key)
        }
    }

    func save(travel: Travel, walkingDistance: WalkingDistance) {
        self.save(travel: travel)
        self.save(walkingDistance: walkingDistance)
    }
    
    func save(travel: Travel) {
        self.saveToUserDefaults(codable: travel, key: self.getKeyName(key: .travel))
    }

    func loadTravel() -> Travel? {
        if let savedData = self.loadObject(key: self.getKeyName(key: .travel)) {
            do {
                return try JSONDecoder().decode(Travel.self, from: savedData)
            } catch {
                print("Failed to load Travel from UserDefaults: \(error)")
                self.isLoadError = true
            }
        }
        return nil
    }
    
    func save(finishedTravels: [Travel]) {
        if self.isLoadError {
            print("save canceled by isLoadError (save(finishedTravels: [Travel]))")
            return
        }
        if let encodedData = try? JSONEncoder().encode(finishedTravels) {
            let key = self.getKeyName(key: .finishedTravels)
            UserDefaults.standard.set(encodedData, forKey: key)
            print("save finished:\(key)")
        }
    }
    
    func loadFinishedTravels() -> [Travel] {
        if let decodedData = UserDefaults.standard.data(forKey: self.getKeyName(key: .finishedTravels)) {
            if let finishedTravels = try? JSONDecoder().decode([Travel].self, from: decodedData) {
                return finishedTravels
            }
        }
        print("Objects not found in UserDefaults.")
        return []
    }
    
    func save(walkingDistance: WalkingDistance?) {
        self.saveToUserDefaults(codable: walkingDistance, key: self.getKeyName(key: .walkingDistance))
    }

    func loadWalkingDistance() -> WalkingDistance? {
        if let savedData = self.loadObject(key: self.getKeyName(key: .walkingDistance)) {
            do {
                return try JSONDecoder().decode(WalkingDistance.self, from: savedData)
            } catch {
                print("Failed to load WalkingDistance from UserDefaults: \(error)")
                self.isLoadError = true
            }
        }
        return nil
    }    

    // MARK: for UnitTest

    func save(route: Route?) {
        self.saveToUserDefaults(codable: route, key: self.getKeyName(key: .route))
    }
    
    func loadRoute() -> Route? {
        if let savedData = self.loadObject(key: self.getKeyName(key: .route)) {
            do {
                return try JSONDecoder().decode(Route.self, from: savedData)
            } catch {
                print("Failed to load Route from UserDefaults: \(error)")
                self.isLoadError = true
            }
        }
        return nil
    }

    func save(routeStep: RouteStep?) {
        self.saveToUserDefaults(codable: routeStep, key: self.getKeyName(key: .routeStep))
    }
    
    func loadRouteStep() -> RouteStep? {
        if let savedData = self.loadObject(key: self.getKeyName(key: .routeStep)) {
            do {
                return try JSONDecoder().decode(RouteStep.self, from: savedData)
            } catch {
                print("Failed to load RouteStep from UserDefaults: \(error)")
                self.isLoadError = true
            }
        }
        return nil
    }

}
