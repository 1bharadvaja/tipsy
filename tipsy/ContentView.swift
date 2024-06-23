import SwiftUI
import ChatGPT
import CoreLocation
import UserNotifications

 var variableUserInput = ""

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    var barsAndNightclubs: [CLLocation] = [
        CLLocation(latitude: 37.867993, longitude: -122.259592),
        CLLocation(latitude: 37.867802, longitude: -122.268119),
        CLLocation(latitude: 37.87173, longitude: -122.268678),
        CLLocation(latitude: 37.87265, longitude: -122.268756),
        CLLocation(latitude: 37.867638, longitude: -122.262708),
        CLLocation(latitude: 37.868144, longitude: -122.267558),
        CLLocation(latitude: 37.870567, longitude: -122.266864),
        CLLocation(latitude: 37.867686, longitude: -122.291469),
        CLLocation(latitude: 37.867006, longitude: -122.266146),
        CLLocation(latitude: 37.867097, longitude: -122.267355),
        CLLocation(latitude: 37.866252, longitude: -122.258862),
        CLLocation(latitude: 37.867672, longitude: -122.258142),
        CLLocation(latitude: 37.869796, longitude: -122.267582)
    ]
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            checkIfAtBarOrNightclub(location: location)
        }
    }
    
    private func checkIfAtBarOrNightclub(location: CLLocation) {
        for barOrNightclub in barsAndNightclubs {
            if location.distance(from: barOrNightclub) < 20 {
                sendTestNotification()
                break
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "TipsyPal Alert"
        content.body = "It seems like you're at or near a bar or nightclub! Remember to drink responsibly John."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    func simulateLocation(latitude: Double, longitude: Double) {
        let simulatedLocation = CLLocation(latitude: latitude, longitude: longitude)
        self.locationManager(self.locationManager, didUpdateLocations: [simulatedLocation])
    }
}

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
            //.background(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .white]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
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
                        .fill(isToday(date: date) ? Color.blue.opacity(0.7) : Color.blue.opacity(0.2))
                        .frame(height: 50)
                    CalendarCell(date:date)
                    
                    VStack {
                        HStack {
                            Text(dayString(from: date))
                                .font(.caption)
                                //.padding(5)

                                .cornerRadius(8)
                                .padding(5)
                                .foregroundColor(isCurrentMonth(date: date) ? .primary : .gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
                .frame(height: 60)
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


struct CalendarCell: View {
    let date: Date
    
    var status: String {
        getStatus(for: date)
    }
    
    var body: some View {
        
        VStack {
            Spacer()
            Text(emoji(for: status))
                .font(.system(size: 10))
    
        }
        .padding(10)
    }
    
    func stripTime(from originalDate: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: originalDate)
        let date = Calendar.current.date(from: components)
        return date!
    }


    
    func getStatus(for date: Date) -> String {
        // Replace this logic with your actual status determination logic
        let day = Calendar.current.component(.day, from: date)
        
        if stripTime(from: date) > stripTime(from: Date()) {
            return ""
        }
        switch day % 7 {
            case 0:
                return "warning"
            case 1:
                return "cross"
            case 2: 
                return "cross"
            default:
                return "check"
        }
        }
    
    func emoji(for status: String) -> String {
        switch status {
        case "check":
            return "🎉"
        case "cross":
            return "❌"
        case "warning":
            return "⚠️"
        default:
            return ""
        }
    }
}

struct TipsyPalView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var userInput = ""
    @State private var messages: [String] = ["Hey John! What can I help you with?"]
    
    var body: some View {
            NavigationView {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(messages, id: \.self) { message in
                                HStack {
                                    if message.starts(with: "You:") {
                                        Spacer()
                                        Text(message)
                                            .padding()
                                            .background(Color.blue.opacity(0.15))
                                            .cornerRadius(10)
                                            .padding(.vertical, 2)
                                            .foregroundColor(.black)
                                    } else {
                                        Text(message)
                                            .padding()
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(10)
                                            .padding(.vertical, 2)
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding()
                }
                
                HStack {
                    TextField("Enter your message", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 10)
                        .onSubmit {
                            Task { await sendMessage() }
                        }
                    
                    Button(action: { Task { await sendMessage() } }) {
                        Image(systemName: "paperplane.fill")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Button(action: {
                    locationManager.simulateLocation(latitude: 37.867991, longitude: -122.259591) // Simulate location for testing
                               }) {
                                   Text("")
                                       .padding()
                                       .background(Color.white)
                                       .foregroundColor(.white)
                                       .cornerRadius(10)
                               }
                               .padding(.top, 20)
                           }
                           .navigationTitle("TipsyPal")
                       }
            .onAppear {
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.delegate = NotificationDelegate()
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Error requesting notifications permission: \(error.localizedDescription)")
                    } else if granted {
                        print("Notifications permission granted")
                    } else {
                        print("Notifications permission denied")
                    }
                }
            }
        }
    
    private func sendMessage() async {
        let userMessage = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        messages.append("You: \(userMessage)")
        variableUserInput = userMessage
        userInput = ""
        
        do {
            let response = try await askChatGPT()
            let cleanResponse = response.replacingOccurrences(of: "\"", with: "")
            DispatchQueue.main.async {
                messages.append("TipsyPal: " + cleanResponse)
            }
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                messages.append("TipsyPal: I'm sorry, I can't actually respond right now. But imagine I gave you a great response!")
            }
        }
    }
    
    private func askChatGPT() async throws -> String {
        let chatGPT = ChatGPT(apiKey: "sk-proj-GmMF5ysPaGwN6FhHLI76T3BlbkFJ8elAnJASvNzRuFuHuJIj", defaultModel: .gpt4)
        let response = try await chatGPT.ask(
            messages: [
                ChatMessage(role: .system, content: "You are helping a person who is a recreational drinker. This person (me, name: John) would like to either become/stay sober or manage my drinking habits more responsibly. This should be among the first questions you ask me, so you can better understand your role as a companion. I'd like for you to play the role as my close friend who's trying to help me through my SPECIFIC circumstance. Do this by composing brief yet articulated responses to help me through what I am going through as outlined by my message. Speak as if you were my companion and close friend, not in a mundane, generic, or robotic manner with short, readable sentences. Generic/non-tailored responses are unacceptance and could have drastic effects. Provide USABLE, SPECIFIC, and NON-GENERIC feedback, and tailor it to me as you learn more about my situation. REMEMBER, the person you are talking to may be drunk, so keep your responses to the point. Write up to 5 sentences if and ONLY if needed with easy to understand wording, etc. Of utmost importance is taking it step by step by asking one question at a time as to not overwhelm or disengage the user, and speaking with compassion to the user in order to make the user feel safe and at ease in order to track habits or stay sober and not give in to temptations. Please respond to this message with this in mind: userMessage"),
                ChatMessage(role: .user, content: userInput)
            ]
        )
        return response
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

extension Color {
    static let maroon = Color(red: 128/255, green: 0, blue: 0)
}

#Preview {
    ContentView()
}
