import SwiftUI

// MARK: - Data Models

/// Represents a single registration entry.
struct RegistrationEntry: Identifiable, Hashable {
    let id = UUID()
    var controlNumber: Int
    var firstName: String
    var lastName: String
    var jerseyNumber: String
    var grade: String
    var school: String
    var sport: String
    var team: String
    var parentFirstName: String
    var parentLastName: String
    var parentPhone: String
    var parentEmail: String
    var eightByTen: String
    var teamPhoto: String
    var silverPackage: String
    var digitalCopy: String
    var banner: String
    var flex: String
    var frame: String
    var paymentType: String
    var paymentAmount: String
    var notes: String
    // Placeholder for the generated QR image
    // var qrImage: UIImage?
}

/// Manages all entries in the current session.
final class SessionData: ObservableObject {
    @Published var entries: [RegistrationEntry] = []
    @Published var nextControlNumber: Int = 1

    // Placeholder: load from disk
    func loadSession() {
        // TODO: JSONDecoder from file URL
    }

    // Placeholder: save to disk
    func saveSession() {
        // TODO: JSONEncoder to file URL
    }

    // Add a new entry
    func add(_ newEntry: RegistrationEntry) {
        entries.append(newEntry)
        nextControlNumber = (entries.map { $0.controlNumber }.max() ?? 0) + 1
        saveSession()
    }

    // Update an existing entry
    func update(_ updatedEntry: RegistrationEntry) {
        if let idx = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
            entries[idx] = updatedEntry
            saveSession()
        }
    }

    // Placeholder: export CSV / Excel
    func exportCSV() -> URL? {
        // TODO: serialize entries to CSV and return URL
        return nil
    }

    func printRosterByNumber() {
        // TODO: sort and print
    }

    func printRosterByGrade() {
        // TODO: sort and print
    }
}

// MARK: - Main App
@main
struct TitensorRegistrationApp: App {
    @StateObject private var sessionData = SessionData()

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
                    .environmentObject(sessionData)
            } detail: {
                RegistrationFormView()
                    .environmentObject(sessionData)
            }
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var sessionData: SessionData
    var body: some View {
        List {
            NavigationLink(value: SidebarSelection.register) {
                Label("New Registration", systemImage: "person.badge.plus")
            }
            NavigationLink(value: SidebarSelection.sessionData) {
                Label("Session Data", systemImage: "list.bullet.rectangle")
            }
            NavigationLink(value: SidebarSelection.exportData) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Titensor")
        .navigationDestination(for: SidebarSelection.self) { selection in
            switch selection {
            case .register:
                RegistrationFormView()
                    .environmentObject(sessionData)
            case .sessionData:
                SessionListView()
                    .environmentObject(sessionData)
            case .exportData:
                ExportView()
                    .environmentObject(sessionData)
            }
        }
    }
}

enum SidebarSelection: Hashable {
    case register, sessionData, exportData
}

// MARK: - Registration Form
struct RegistrationFormView: View {
    @EnvironmentObject var sessionData: SessionData

    // form fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jerseyNumber: String = ""
    @State private var gradeSelection: String = "9"
    @State private var schoolSelection: String = "Ridgeline"
    @State private var sportSelection: String = "Football"
    @State private var teamSelection: String = "Varsity"
    @State private var parentFirstName: String = ""
    @State private var parentLastName: String = ""
    @State private var parentPhone: String = ""
    @State private var parentEmail: String = ""
    @State private var eightByTen: String = "0"
    @State private var teamPhoto: String = "0"
    @State private var silverPackage: String = "0"
    @State private var digitalCopy: String = "0"
    @State private var banner: String = "0"
    @State private var flex: String = "0"
    @State private var frame: String = "0"
    @State private var paymentType: String = "Did not pay"
    @State private var paymentAmount: String = "0"
    @State private var notes: String = ""
    @State private var showQRCodePlaceholder = false

    let grades = ["9","10","11","12","Coach"]
    let schools = ["Ridgeline","Preston","Green Canyon","Skyview","Logan","N/A"]
    let sports = ["Football","Tennis","Soccer","Volleyball","Cross Country","Golf","Cheer"]
    let teams = ["Varsity","JV","Freshman","N/A"]
    let paymentTypes = ["Cash","Card","Check","Did not pay"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session controls
                HStack {
                    Button("Resume Session…") {
                        sessionData.loadSession()
                    }
                    Spacer()
                    Button("Upload Teams…") {
                        // TODO: open document picker
                    }
                }
                .padding(.horizontal)

                Divider()
                SectionHeaderView(title: "Athlete Info")

                // Example field
                HStack(spacing:16) {
                    VStack(alignment: .leading) {
                        Text("First Name").font(.headline)
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(height: 44)
                            .overlay(
                                Text(firstName.isEmpty ? "Enter first name…" : firstName)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 8),
                                alignment: .leading
                            )
                    }
                    VStack(alignment: .leading) {
                        Text("Last Name").font(.headline)
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(height: 44)
                            .overlay(
                                Text(lastName.isEmpty ? "Enter last name…" : lastName)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 8),
                                alignment: .leading
                            )
                    }
                }
                .padding(.horizontal)

                // ... [remaining fields omitted for brevity in this example]

                Divider()

                HStack(spacing:20) {
                    Button("Generate") {
                        let newEntry = RegistrationEntry(
                            controlNumber: sessionData.nextControlNumber,
                            firstName: firstName,
                            lastName: lastName,
                            jerseyNumber: jerseyNumber,
                            grade: gradeSelection,
                            school: schoolSelection,
                            sport: sportSelection,
                            team: teamSelection,
                            parentFirstName: parentFirstName,
                            parentLastName: parentLastName,
                            parentPhone: parentPhone,
                            parentEmail: parentEmail,
                            eightByTen: eightByTen,
                            teamPhoto: teamPhoto,
                            silverPackage: silverPackage,
                            digitalCopy: digitalCopy,
                            banner: banner,
                            flex: flex,
                            frame: frame,
                            paymentType: paymentType,
                            paymentAmount: paymentAmount,
                            notes: notes
                        )
                        sessionData.add(newEntry)
                        showQRCodePlaceholder = true
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)

                    Button("Totals") {
                        // placeholder totals
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)

                    Button("Export") {
                        // open export view
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                if showQRCodePlaceholder {
                    SectionHeaderView(title: "QR Code Preview")
                    RoundedRectangle(cornerRadius:12)
                        .stroke(style: StrokeStyle(lineWidth:2, dash:[10]))
                        .frame(width:200, height:200)
                        .overlay(Text("QR CODE").foregroundColor(.gray))
                        .padding(.top)
                }

                Spacer(minLength:50)
            }
            .padding(.vertical)
            .navigationTitle("New Registration")
        }
    }
}

// MARK: - Session List
struct SessionListView: View {
    @EnvironmentObject var sessionData: SessionData
    var body: some View {
        VStack {
            if sessionData.entries.isEmpty {
                Text("No entries yet.")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            } else {
                List {
                    ForEach(sessionData.entries) { entry in
                        NavigationLink(value: entry) {
                            HStack {
                                Text("#\(entry.controlNumber)")
                                VStack(alignment: .leading) {
                                    Text("\(entry.firstName) \(entry.lastName)")
                                        .font(.headline)
                                    Text("Jersey: \(entry.jerseyNumber) – \(entry.sport)")
                                        .font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationDestination(for: RegistrationEntry.self) { entry in
                    EditDetailView(entry: entry)
                        .environmentObject(sessionData)
                }
            }
        }
        .navigationTitle("Session Data")
    }
}

// MARK: - Edit Detail View
struct EditDetailView: View {
    @EnvironmentObject var sessionData: SessionData
    @State private var entry: RegistrationEntry

    @State private var firstName: String
    @State private var lastName: String
    @State private var jerseyNumber: String
    @State private var gradeSelection: String
    @State private var schoolSelection: String
    @State private var sportSelection: String
    @State private var teamSelection: String
    @State private var parentFirstName: String
    @State private var parentLastName: String
    @State private var parentPhone: String
    @State private var parentEmail: String
    @State private var eightByTen: String
    @State private var teamPhoto: String
    @State private var silverPackage: String
    @State private var digitalCopy: String
    @State private var banner: String
    @State private var flex: String
    @State private var frame: String
    @State private var paymentType: String
    @State private var paymentAmount: String
    @State private var notes: String
    @State private var showQRCodePlaceholder = true

    let grades = ["9","10","11","12","Coach"]
    let schools = ["Ridgeline","Preston","Green Canyon","Skyview","Logan","N/A"]
    let sports = ["Football","Tennis","Soccer","Volleyball","Cross Country","Golf","Cheer"]
    let teams = ["Varsity","JV","Freshman","N/A"]
    let paymentTypes = ["Cash","Card","Check","Did not pay"]

    init(entry: RegistrationEntry) {
        _entry = State(initialValue: entry)
        _firstName = State(initialValue: entry.firstName)
        _lastName = State(initialValue: entry.lastName)
        _jerseyNumber = State(initialValue: entry.jerseyNumber)
        _gradeSelection = State(initialValue: entry.grade)
        _schoolSelection = State(initialValue: entry.school)
        _sportSelection = State(initialValue: entry.sport)
        _teamSelection = State(initialValue: entry.team)
        _parentFirstName = State(initialValue: entry.parentFirstName)
        _parentLastName = State(initialValue: entry.parentLastName)
        _parentPhone = State(initialValue: entry.parentPhone)
        _parentEmail = State(initialValue: entry.parentEmail)
        _eightByTen = State(initialValue: entry.eightByTen)
        _teamPhoto = State(initialValue: entry.teamPhoto)
        _silverPackage = State(initialValue: entry.silverPackage)
        _digitalCopy = State(initialValue: entry.digitalCopy)
        _banner = State(initialValue: entry.banner)
        _flex = State(initialValue: entry.flex)
        _frame = State(initialValue: entry.frame)
        _paymentType = State(initialValue: entry.paymentType)
        _paymentAmount = State(initialValue: entry.paymentAmount)
        _notes = State(initialValue: entry.notes)
    }

    var body: some View {
        ScrollView {
            VStack(spacing:24) {
                SectionHeaderView(title: "Edit Registration #\(entry.controlNumber)")

                // For brevity these fields are the same as RegistrationFormView
                // ... (fields omitted)

                if showQRCodePlaceholder {
                    SectionHeaderView(title: "QR Code")
                    RoundedRectangle(cornerRadius:12)
                        .stroke(style: StrokeStyle(lineWidth:2, dash:[10]))
                        .frame(width:200, height:200)
                        .overlay(Text("QR CODE").foregroundColor(.gray))
                        .padding(.top)
                }

                Button("Save Changes") {
                    var updated = entry
                    updated.firstName = firstName
                    updated.lastName = lastName
                    updated.jerseyNumber = jerseyNumber
                    updated.grade = gradeSelection
                    updated.school = schoolSelection
                    updated.sport = sportSelection
                    updated.team = teamSelection
                    updated.parentFirstName = parentFirstName
                    updated.parentLastName = parentLastName
                    updated.parentPhone = parentPhone
                    updated.parentEmail = parentEmail
                    updated.eightByTen = eightByTen
                    updated.teamPhoto = teamPhoto
                    updated.silverPackage = silverPackage
                    updated.digitalCopy = digitalCopy
                    updated.banner = banner
                    updated.flex = flex
                    updated.frame = frame
                    updated.paymentType = paymentType
                    updated.paymentAmount = paymentAmount
                    updated.notes = notes
                    sessionData.update(updated)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

                Spacer(minLength:50)
            }
            .padding(.vertical)
            .navigationTitle("Edit Entry")
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    @EnvironmentObject var sessionData: SessionData

    var body: some View {
        VStack(spacing:24) {
            SectionHeaderView(title: "Export / Print")

            Button("Export to CSV/Excel") {
                if let csvURL = sessionData.exportCSV() {
                    // TODO: share csvURL
                }
            }
            .frame(maxWidth:.infinity, minHeight:50)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)

            Button("Print Roster by Number") {
                sessionData.printRosterByNumber()
            }
            .frame(maxWidth:.infinity, minHeight:50)
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)

            Button("Print Roster by Grade") {
                sessionData.printRosterByGrade()
            }
            .frame(maxWidth:.infinity, minHeight:50)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)
            Spacer()
        }
        .padding(.vertical)
        .navigationTitle("Export Data")
    }
}

// MARK: - Helper Views
fileprivate struct SectionHeaderView: View {
    let title: String
    var body: some View {
        HStack {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal)
    }
}

fileprivate struct PackageFieldView: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.headline)
            RoundedRectangle(cornerRadius: 6)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 44)
                .overlay(Text(value).foregroundColor(.gray).padding(.leading,8), alignment: .leading)
        }
    }
}

