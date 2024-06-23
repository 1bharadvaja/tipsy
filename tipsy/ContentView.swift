import SwiftUI
import ChatGPT

struct ContentView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            TipsyPalView()
                .tabItem {
                    Label("TipsyPal", systemImage: "person.fill")
                }
        }
        .accentColor(.blue)
    }
}

struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var displayedMonth = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button(action: {
                        changeMonth(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(monthYearString(from: displayedMonth))
                        .font(.custom("Avenir-Heavy", size: 24))
                        .foregroundColor(.blue)
                    Spacer()
                    Button(action: {
                        changeMonth(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                CalendarGridView(currentDate: $currentDate, displayedMonth: $displayedMonth)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            .background(LinearGradient(gradient: Gradient(colors: [.white, .blue.opacity(0.1)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .navigationTitle("Calendar")
        }
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

struct CalendarGridView: View {
    @Binding var currentDate: Date
    @Binding var displayedMonth: Date
    
    var body: some View {
        let days = generateDays(for: displayedMonth)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(days, id: \.self) { date in
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isToday(date: date) ? Color.blue.opacity(0.7) : Color.gray.opacity(0.2))
                        .frame(height: 50)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Text(dayString(from: date))
                                .font(.caption)
                                .padding(5)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
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
        .padding()
    }
    
    private func generateDays(for date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 7 // Setting Saturday as the first day of the week
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthStartWeekday = calendar.component(.weekday, from: monthStart)
        
        var days: [Date] = []
        
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

struct TipsyPalView: View {
    @State private var userInput = ""
    @State private var messages: [String] = ["Hello! How can I help you today?"]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.self) { message in
                            Text(message)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Enter your message", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 10)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .navigationTitle("TipsyPal")
        }
    }
    
    private func sendMessage() {
        let userMessage = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        messages.append("You: \(userMessage)")
        userInput = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append("ChatGPT: I'm sorry, I can't actually respond right now. But imagine I gave you a great response!")
        }
    }
    
    private func askChatGPT() async throws{
        let chatGPT = ChatGPT(apiKey: "sk-proj-GmMF5ysPaGwN6FhHLI76T3BlbkFJ8elAnJASvNzRuFuHuJIj", defaultModel: .gpt4)
        let response = try await chatGPT.ask(
            messages: [
                ChatMessage(role: .system, content:  "I am a person who is a recreational drinker. I'd like to either become/stay sober or manage my drinking habits more responsibly. I'd like for you to play the role as my close friend who's trying to get me home safe and get through my circumstance. Do this by composing brief yet articulated responses to help me through what I am going through as outlined by my message. Speak as if you were my companion and close friend, not in a mundane, generic, or robotic manner with short, readable sentences. Again, generic/non-tailored responses are unacceptance and could have drastic effects. Provide USABLE, SPECIFIC, and NON-GENERIC feedback, and tailor it to me as you learn more about my situation. REMEMBER, the person you are talking to may be drunk, so keep your responses to the point. If needed, use emojis (max 2) or emoticons (max 2), but only use them when the response fits. Feel free to up to 5 sentences, easy to understand wording, etc. Of utmost importance is speaking with compassion to the user in order to make the user feel safe and at ease in order to track habits. Please respond to this message with this in mind: userMessage"),
                ChatMessage(role: .user, content: userInput)
            ]
        )
        print(response)

    }
    
    
}

extension Color {
    static let maroon = Color(red: 128/255, green: 0, blue: 0)
}

#Preview {
    ContentView()
}
