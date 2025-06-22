import Foundation

extension Calendar {
    func isToday(_ date: Date) -> Bool {
        return isDate(date, inSameDayAs: Date())
    }
    
    func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = self.date(byAdding: .day, value: -1, to: Date()) else {
            return false
        }
        return isDate(date, inSameDayAs: yesterday)
    }
}
