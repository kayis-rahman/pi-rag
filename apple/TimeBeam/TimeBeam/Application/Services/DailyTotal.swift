import Foundation

struct DailyTotal: Identifiable, Equatable {

    let date: Date

    let totalMinutes: Int

    var id: Date { date }

}
