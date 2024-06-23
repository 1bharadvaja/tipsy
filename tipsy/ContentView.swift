import SwiftUI

struct ContentView: View {
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                        .background(Color.maroon)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                Spacer()
                Text(monthYearString(from: displayedMonth))
                    .font(.custom("MarkerFelt-Wide", size: 32))
                    .foregroundColor(.maroon)
                Spacer()
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .padding()
                        .background(Color.maroon)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            
            CalendarView(currentDate: $currentDate, displayedMonth: $displayedMonth)
                .padding()
        }
        .padding()
        .background(Color.brown.opacity(0.1))
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

struct CalendarView: View {
    @Binding var currentDate: Date
    @Binding var displayedMonth: Date
    
    var body: some View {
        let days = generateDays(for: displayedMonth)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { date in
                ZStack {
                    Rectangle()
                        .fill(Color.maroon.opacity(isToday(date: date) ? 1 : 0.3))
                        .cornerRadius(10)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Text(dayString(from: date))
                                .font(.caption)
                                .padding(5)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(5)
                                .padding(5)
                                .foregroundColor(isCurrentMonth(date: date) ? .primary : .gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        Spacer()
                    }
                }
                .frame(height: 50)
            }
        }
    }
    
    private func generateDays(for date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 7 // Setting Saturday as the first day of the week
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthStartWeekday = calendar.component(.weekday, from: monthStart)
        
        var days: [Date] = []
        
        // Fill in the days of the previous month to align the first weekday
        let previousMonthPadding = (monthStartWeekday + 5) % 7 // +5 to adjust for Saturday start
        if previousMonthPadding > 0 {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart)!
            let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth)!
            let previousMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!
            
            for day in (previousMonthRange.count - previousMonthPadding + 1)...previousMonthRange.count {
                let date = calendar.date(byAdding: .day, value: day - 1, to: previousMonthStart)!
                days.append(date)
            }
        }
        
        days.append(contentsOf: range.map { calendar.date(byAdding: .day, value: $0 - 1, to: monthStart)! })
        
        // Fill in the days of the next month to complete the last week
        let totalDays = days.count
        if totalDays % 7 != 0 {
            let nextMonthPadding = 7 - (totalDays % 7)
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let nextMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
            
            for day in 1...nextMonthPadding {
                let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonthStart)!
                days.append(date)
            }
        }
        
        return days
    }
    
    private func dayString(from date: Date) -> String {
        if date == Date.distantPast {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter.string(from: date)
    }
    
    private func isToday(date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    private func isCurrentMonth(date: Date) -> Bool {
        let displayedMonthComponents = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
        let dateComponents = Calendar.current.dateComponents([.year, .month], from: date)
        return displayedMonthComponents.year == dateComponents.year && displayedMonthComponents.month == dateComponents.month
    }
}

extension Color {
    static let maroon = Color(red: 128/255, green: 0, blue: 0)
}

#Preview {
    ContentView()
}
