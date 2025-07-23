import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("defaultDeposit") private var defaultDeposit: Double = 0
    @AppStorage("businessName") private var businessName = ""
    @AppStorage("businessEmail") private var businessEmail = ""
    @AppStorage("businessPhone") private var businessPhone = ""
    @AppStorage("businessICO") private var businessICO = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationHours") private var notificationHours = 24
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("showTotalEarnings") private var showTotalEarnings = true
    
    @State private var showingExportAlert = false
    @State private var showingNotificationPermissionAlert = false
    @State private var hasUnsavedChanges = false
    @State private var originalBusinessName = ""
    @State private var originalBusinessEmail = ""
    @State private var originalBusinessPhone = ""
    @State private var originalBusinessICO = ""
    @State private var originalDefaultDeposit: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private let notificationOptions = [
        (1, "1 hodina"),
        (6, "6 hodin"),
        (24, "1 den"),
        (48, "2 dny"),
        (168, "1 týden")
    ]
    
    private let appearanceOptions = [
        ("light", "Světlý", "sun.max"),
        ("dark", "Tmavý", "moon"),
        ("system", "Systémový", "circle.lefthalf.filled")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Firemní údaje") {
                    TextField("Název firmy", text: $businessName)
                        .focused($isTextFieldFocused)
                        .onChange(of: businessName) { _ in checkForChanges() }
                    TextField("E-mail", text: $businessEmail)
                        .keyboardType(.emailAddress)
                        .focused($isTextFieldFocused)
                        .onChange(of: businessEmail) { _ in checkForChanges() }
                    TextField("Telefon", text: $businessPhone)
                        .keyboardType(.phonePad)
                        .focused($isTextFieldFocused)
                        .onChange(of: businessPhone) { _ in checkForChanges() }
                    TextField("IČO", text: $businessICO)
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                        .onChange(of: businessICO) { _ in checkForChanges() }
                }
                
                Section("Výchozí nastavení") {
                    HStack {
                        Text("Výchozí záloha")
                        Spacer()
                        TextField("0", value: $defaultDeposit, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isTextFieldFocused)
                            .onChange(of: defaultDeposit) { _ in checkForChanges() }
                        Text("Kč")
                    }
                    
                    Toggle("Zobrazit celkové tržby", isOn: $showTotalEarnings)
                }
                
                Section("Upozornění") {
                    Toggle("Povolit upozornění", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    
                    if notificationsEnabled {
                        Picker("Upozornit před událostí", selection: $notificationHours) {
                            ForEach(notificationOptions, id: \.0) { hours, title in
                                Text(title).tag(hours)
                            }
                        }
                        .onChange(of: notificationHours) { _ in
                            scheduleNotifications()
                        }
                    }
                }
                
                Section("Vzhled") {
                    ForEach(appearanceOptions, id: \.0) { value, title, icon in
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(appearanceMode == value ? .blue : .secondary)
                            Text(title)
                            Spacer()
                            if appearanceMode == value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appearanceMode = value
                            applyAppearanceMode()
                        }
                    }
                }
                
                Section("Data") {
                    Button("Exportovat data") {
                        showingExportAlert = true
                    }
                    
                    Button("Smazat všechna data", role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "SavedOrders")
                    }
                }
                
                Section("O aplikaci") {
                    HStack {
                        Text("Verze")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Vývojář")
                        Spacer()
                        Text("Radim Ručil")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Nastavení")
            .onAppear {
                saveOriginalValues()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if hasUnsavedChanges {
                        Button("Uložit") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        isTextFieldFocused = false
                    }
                }
            }
            .alert("Export dat", isPresented: $showingExportAlert) {
                Button("OK") { }
            } message: {
                Text("Export umožní zálohovat všechny zakázky do souboru (CSV/JSON) pro přenos na jiné zařízení nebo pro účetní účely. Funkce bude implementována v budoucí verzi.")
            }
            .alert("Povolení upozornění", isPresented: $showingNotificationPermissionAlert) {
                Button("Nastavení") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Zrušit", role: .cancel) {
                    notificationsEnabled = false
                }
            } message: {
                Text("Pro zasílání upozornění je nutné povolit notifikace v nastavení zařízení.")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotifications()
                } else {
                    showingNotificationPermissionAlert = true
                    notificationsEnabled = false
                }
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus != .authorized && notificationsEnabled {
                    notificationsEnabled = false
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard notificationsEnabled else { return }
        
        let viewModel = OrdersViewModel()
        let upcomingOrders = viewModel.orders.filter { order in
            order.status == .planned || order.status == .inProgress
        }
        
        for order in upcomingOrders {
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -notificationHours, to: order.date)
            
            guard let notificationDate = notificationDate, notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Blížící se zakázka"
            content.body = "\(order.name) - \(order.location)"
            content.sound = .default
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: order.id.uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func applyAppearanceMode() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch appearanceMode {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func checkForChanges() {
        hasUnsavedChanges = businessName != originalBusinessName ||
                           businessEmail != originalBusinessEmail ||
                           businessPhone != originalBusinessPhone ||
                           businessICO != originalBusinessICO ||
                           defaultDeposit != originalDefaultDeposit
    }
    
    private func saveOriginalValues() {
        originalBusinessName = businessName
        originalBusinessEmail = businessEmail
        originalBusinessPhone = businessPhone
        originalBusinessICO = businessICO
        originalDefaultDeposit = defaultDeposit
    }
    
    private func saveChanges() {
        // Hodnoty se ukládají automaticky díky @AppStorage
        saveOriginalValues()
        hasUnsavedChanges = false
    }
}
