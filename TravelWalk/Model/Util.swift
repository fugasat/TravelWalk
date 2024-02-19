import Foundation

class Util {

    let calendar = Calendar.current
    var startTime = Date()
    var endTime = Date()

    func startOfDay(date: Date) -> Date {
        let dateComponents = self.calendar.dateComponents([.year, .month, .day], from: date)
        var newDateComponents = DateComponents()
        newDateComponents.year = dateComponents.year
        newDateComponents.month = dateComponents.month
        newDateComponents.day = dateComponents.day
        return calendar.date(from: newDateComponents)!
    }
    
    func startElapse() {
        self.startTime = Date()
    }

    func finishElapse() {
        self.endTime = Date()
        let elapsedTime = endTime.timeIntervalSince(startTime)
        let formattedTime = String(format: "%.2f", elapsedTime)

        print("********** Elapsed Time: \(formattedTime) seconds **********")
        
    }
}
