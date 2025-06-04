import SwiftUI
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

#if os(iOS)
import UIKit
public typealias UXImage = UIImage
#elseif os(macOS)
import AppKit
public typealias UXImage = NSImage
#endif

// MARK: - Data Models

struct RegistrationEntry: Identifiable, Codable, Hashable {
    let id: UUID
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
    var qrImageData: Data?

    init(controlNumber: Int,
         firstName: String = "",
         lastName: String = "",
         jerseyNumber: String = "",
         grade: String = "9",
         school: String = "Ridgeline",
         sport: String = "Football",
         team: String = "Varsity",
         parentFirstName: String = "",
         parentLastName: String = "",
         parentPhone: String = "",
         parentEmail: String = "",
         eightByTen: String = "0",
         teamPhoto: String = "0",
         silverPackage: String = "0",
         digitalCopy: String = "0",
         banner: String = "0",
         flex: String = "0",
         frame: String = "0",
         paymentType: String = "Did not pay",
         paymentAmount: String = "0",
         notes: String = "",
         qrImageData: Data? = nil) {
        self.id = UUID()
        self.controlNumber = controlNumber
        self.firstName = firstName
        self.lastName = lastName
        self.jerseyNumber = jerseyNumber
        self.grade = grade
        self.school = school
        self.sport = sport
        self.team = team
        self.parentFirstName = parentFirstName
        self.parentLastName = parentLastName
        self.parentPhone = parentPhone
        self.parentEmail = parentEmail
        self.eightByTen = eightByTen
        self.teamPhoto = teamPhoto
        self.silverPackage = silverPackage
        self.digitalCopy = digitalCopy
        self.banner = banner
        self.flex = flex
        self.frame = frame
        self.paymentType = paymentType
        self.paymentAmount = paymentAmount
        self.notes = notes
        self.qrImageData = qrImageData
    }
}

// MARK: - Session Data

final class SessionData: ObservableObject {
    @Published var entries: [RegistrationEntry] = []
    @Published var nextControlNumber: Int = 1

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("session.json")
    }

    func loadSession() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([RegistrationEntry].self, from: data) {
            entries = decoded
            nextControlNumber = (entries.map { $0.controlNumber }.max() ?? 0) + 1
        }
    }

    func saveSession() {
        if let data = try? JSONEncoder().encode(entries) {
            do {
                try data.write(to: fileURL)
                print("Session saved to: \(fileURL)")
            } catch {
                print("Failed to write session: \(error)")
            }
        } else {
            print("Failed to encode session data")
        }
    }

    func add(_ newEntry: RegistrationEntry) {
        entries.append(newEntry)
        nextControlNumber = (entries.map { $0.controlNumber }.max() ?? 0) + 1
        saveSession()
    }

    func update(_ updatedEntry: RegistrationEntry) {
        if let idx = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
            print("Updating entry at index \(idx): \(updatedEntry.firstName) \(updatedEntry.lastName)")
            entries[idx] = updatedEntry
            saveSession()
        } else {
            print("No match found for entry ID: \(updatedEntry.id)")
        }
    }

    func exportCSV() -> URL? {
        var csv = "Control #,First Name,Last Name,Jersey #,Grade,School,Sport,Team,Parent First,Parent Last,Parent Phone,Parent Email,8x10,Team Photo,Silver,Digital,Banner,Flex,Frame,Payment Type,Payment Amount,Notes\n"
        for e in entries {
            let row = [
                "\(e.controlNumber)", e.firstName, e.lastName, e.jerseyNumber,
                e.grade, e.school, e.sport, e.team,
                e.parentFirstName, e.parentLastName, e.parentPhone, e.parentEmail,
                e.eightByTen, e.teamPhoto, e.silverPackage, e.digitalCopy,
                e.banner, e.flex, e.frame, e.paymentType, e.paymentAmount,
                e.notes.replacingOccurrences(of: "\n", with: " ")
            ].joined(separator: ",")
            csv.append(row + "\n")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("entries.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    func printRosterByNumber() {
        share(entries.sorted { $0.jerseyNumber < $1.jerseyNumber }, name: "roster_by_number.csv")
    }

    func printRosterByGrade() {
        share(entries.sorted { $0.grade < $1.grade }, name: "roster_by_grade.csv")
    }

    private func share(_ sorted: [RegistrationEntry], name: String) {
        var csv = "Control #,First Name,Last Name,Jersey #,Grade,School,Sport,Team\n"
        for e in sorted {
            csv.append("\(e.controlNumber),\(e.firstName),\(e.lastName),\(e.jerseyNumber),\(e.grade),\(e.school),\(e.sport),\(e.team)\n")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareURL(url)
    }

    func shareURL(_ url: URL) {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let avc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(avc, animated: true)
        #elseif os(macOS)
        let picker = NSSharingServicePicker(items: [url])
        if let view = NSApplication.shared.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        #endif
    }
}

// MARK: - QR Generation Helper

func generateQRCodeImage(from string: String) -> UXImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)
    if let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)) {
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #else
        return NSImage(cgImage: cgImage, size: output.extent.size)
        #endif
    }
    return nil
}

func dataFromImage(_ image: UXImage?) -> Data? {
#if os(iOS)
    return image?.pngData()
#else
    return image?.tiffRepresentation
#endif
}

extension Image {
    init?(uxImage: UXImage?) {
        guard let img = uxImage else { return nil }
        #if os(iOS)
        self.init(uiImage: img)
        #else
        self.init(nsImage: img)
        #endif
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

enum SidebarSelection: Hashable { case register, sessionData, exportData }

struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink(value: SidebarSelection.register) { Label("New Registration", systemImage: "person.badge.plus") }
            NavigationLink(value: SidebarSelection.sessionData) { Label("Session Data", systemImage: "list.bullet.rectangle") }
            NavigationLink(value: SidebarSelection.exportData) { Label("Export Data", systemImage: "square.and.arrow.up") }
        }
        .listStyle(.sidebar)
        .navigationTitle("Titensor")
        .navigationDestination(for: SidebarSelection.self) { selection in
            switch selection {
            case .register:
                RegistrationFormView()
            case .sessionData:
                SessionListView()
            case .exportData:
                ExportView()
            }
        }
    }
}

// MARK: - Registration Form

struct RegistrationFormView: View {
    @EnvironmentObject var sessionData: SessionData

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var jerseyNumber = ""
    @State private var gradeSelection = "9"
    @State private var schoolSelection = "Ridgeline"
    @State private var sportSelection = "Football"
    @State private var teamSelection = "Varsity"
    @State private var parentFirstName = ""
    @State private var parentLastName = ""
    @State private var parentPhone = ""
    @State private var parentEmail = ""
    @State private var eightByTen = "0"
    @State private var teamPhoto = "0"
    @State private var silverPackage = "0"
    @State private var digitalCopy = "0"
    @State private var banner = "0"
    @State private var flex = "0"
    @State private var frame = "0"
    @State private var paymentType = "Did not pay"
    @State private var paymentAmount = "0"
    @State private var notes = ""
    @State private var qrImage: UXImage?

    let grades = ["9","10","11","12","Coach"]
    let schools = ["Ridgeline","Preston","Green Canyon","Skyview","Logan","N/A"]
    let sports = ["Football","Tennis","Soccer","Volleyball","Cross Country","Golf","Cheer"]
    let teams = ["Varsity","JV","Freshman","N/A"]
    let paymentTypes = ["Cash","Card","Check","Did not pay"]

    var body: some View {
        Form {
            Section("Session") {
                HStack {
                    Button("Resume Session…") { sessionData.loadSession() }
                    Spacer()
                    Button("Upload Teams…") { }
                }
            }

            Section("Athlete Info") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Jersey #", text: $jerseyNumber)
                Picker("Grade", selection: $gradeSelection) { ForEach(grades, id: \.self) { Text($0) } }
                Picker("School", selection: $schoolSelection) { ForEach(schools, id: \.self) { Text($0) } }
                Picker("Sport", selection: $sportSelection) { ForEach(sports, id: \.self) { Text($0) } }
                Picker("Team", selection: $teamSelection) { ForEach(teams, id: \.self) { Text($0) } }
            }

            Section("Parent / Guardian") {
                TextField("Parent First", text: $parentFirstName)
                TextField("Parent Last", text: $parentLastName)
                TextField("Phone", text: $parentPhone)
                TextField("Email", text: $parentEmail)
            }

            Section("Package Quantities") {
                TextField("8×10", text: $eightByTen)
                TextField("Team Photo", text: $teamPhoto)
                TextField("Silver", text: $silverPackage)
                TextField("Digital", text: $digitalCopy)
                TextField("Banner", text: $banner)
                TextField("Flex", text: $flex)
                TextField("Frame", text: $frame)
            }

            Section("Payment") {
                Picker("Type", selection: $paymentType) { ForEach(paymentTypes, id: \.self) { Text($0) } }
                TextField("Amount", text: $paymentAmount)
            }

            Section("Notes") {
                TextField("Enter notes", text: $notes, axis: .vertical)
            }

            if let img = qrImage, let image = Image(uxImage: img) {
                Section("QR Code") {
                    image
                        .resizable()
                        .frame(width: 200, height: 200)
                        .scaledToFit()
                }
            }

            Section {
                Button("Submit") { submitEntry() }
            }
        }
        .navigationTitle("New Registration")
    }

    func submitEntry() {
        qrImage = generateQRCodeImage(from: "\(firstName) \(lastName) \(sessionData.nextControlNumber)")
        let entry = RegistrationEntry(controlNumber: sessionData.nextControlNumber,
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
                                      notes: notes,
                                      qrImageData: dataFromImage(qrImage))
        sessionData.add(entry)
    }
}

// MARK: - Session List

struct SessionListView: View {
    @EnvironmentObject var sessionData: SessionData
    var body: some View {
        List(sessionData.entries) { entry in
            NavigationLink(value: entry) {
                VStack(alignment: .leading) {
                    Text("#\(entry.controlNumber) - \(entry.firstName) \(entry.lastName)")
                    Text("Jersey: \(entry.jerseyNumber) - \(entry.sport)")
                        .font(.caption)
                }
            }
        }
        .id(UUID())
        .navigationDestination(for: RegistrationEntry.self) { entry in
            EditDetailView(entry: entry)
        }
        .navigationTitle("Session Data")
    }
}

// MARK: - Edit Detail

struct EditDetailView: View {
    @EnvironmentObject var sessionData: SessionData
    @State private var entry: RegistrationEntry

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
#if os(iOS)
        if let data = entry.qrImageData { _qrImage = State(initialValue: UIImage(data: data)) }
#else
        if let data = entry.qrImageData { _qrImage = State(initialValue: NSImage(data: data)) }
#endif
    }

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jerseyNumber: String = ""
    @State private var gradeSelection: String = ""
    @State private var schoolSelection: String = ""
    @State private var sportSelection: String = ""
    @State private var teamSelection: String = ""
    @State private var parentFirstName: String = ""
    @State private var parentLastName: String = ""
    @State private var parentPhone: String = ""
    @State private var parentEmail: String = ""
    @State private var eightByTen: String = ""
    @State private var teamPhoto: String = ""
    @State private var silverPackage: String = ""
    @State private var digitalCopy: String = ""
    @State private var banner: String = ""
    @State private var flex: String = ""
    @State private var frame: String = ""
    @State private var paymentType: String = ""
    @State private var paymentAmount: String = ""
    @State private var notes: String = ""
    @State private var qrImage: UXImage?

    var body: some View {
        Form {
            Section("Athlete Info") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Jersey #", text: $jerseyNumber)
                TextField("Grade", text: $gradeSelection)
                TextField("School", text: $schoolSelection)
                TextField("Sport", text: $sportSelection)
                TextField("Team", text: $teamSelection)
            }
            Section("Parent") {
                TextField("Parent First", text: $parentFirstName)
                TextField("Parent Last", text: $parentLastName)
                TextField("Phone", text: $parentPhone)
                TextField("Email", text: $parentEmail)
            }
            Section("Packages") {
                TextField("8×10", text: $eightByTen)
                TextField("Team Photo", text: $teamPhoto)
                TextField("Silver", text: $silverPackage)
                TextField("Digital", text: $digitalCopy)
                TextField("Banner", text: $banner)
                TextField("Flex", text: $flex)
                TextField("Frame", text: $frame)
            }
            Section("Payment") {
                TextField("Type", text: $paymentType)
                TextField("Amount", text: $paymentAmount)
            }
            Section("Notes") { TextField("Notes", text: $notes, axis: .vertical) }
            if let img = qrImage, let image = Image(uxImage: img) {
                Section("QR Code") {
                    image.resizable().frame(width:200,height:200).scaledToFit()
                }
            }
            Section {
                Button("Save Changes") {
                    print("Save button tapped")
                    saveChanges()
                }
            }
        }
        .navigationTitle("Edit Entry")
    }

    func saveChanges() {
        print("Saving entry with ID: \(entry.id)")
        qrImage = generateQRCodeImage(from: "\(firstName) \(lastName) \(entry.controlNumber)")
        entry.firstName = firstName
        entry.lastName = lastName
        entry.jerseyNumber = jerseyNumber
        entry.grade = gradeSelection
        entry.school = schoolSelection
        entry.sport = sportSelection
        entry.team = teamSelection
        entry.parentFirstName = parentFirstName
        entry.parentLastName = parentLastName
        entry.parentPhone = parentPhone
        entry.parentEmail = parentEmail
        entry.eightByTen = eightByTen
        entry.teamPhoto = teamPhoto
        entry.silverPackage = silverPackage
        entry.digitalCopy = digitalCopy
        entry.banner = banner
        entry.flex = flex
        entry.frame = frame
        entry.paymentType = paymentType
        entry.paymentAmount = paymentAmount
        entry.notes = notes
        entry.qrImageData = dataFromImage(qrImage)
        sessionData.update(entry)
    }
}

// MARK: - Export View

struct ExportView: View {
    @EnvironmentObject var sessionData: SessionData
    var body: some View {
        Form {
            Section {
                Button("Export to CSV") {
                    if let url = sessionData.exportCSV() { sessionData.shareURL(url) }
                }
                Button("Print Roster by Number") { sessionData.printRosterByNumber() }
                Button("Print Roster by Grade") { sessionData.printRosterByGrade() }
            }
        }
        .navigationTitle("Export Data")
    }
}
