import SwiftUI
import CoreData

struct AddJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var company = ""
    @State private var location = ""
    @State private var salaryRange = ""
    @State private var status: JobStatus = .applied
    @State private var fitScore: Int16 = 75
    @State private var notes = ""
    @State private var customNotes: [CustomNoteDraft] = []
    @State private var dateApplied = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    basicInfoSection
                    statusSection
                    notesSection
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add New Job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Job Title")
            TextField("e.g. Frontend Developer", text: $title)
                .textFieldStyle(.roundedBorder)

            Text("Company")
            TextField("e.g. TechCorp", text: $company)
                .textFieldStyle(.roundedBorder)

            Text("Location")
            TextField("e.g. Remote or New York, NY", text: $location)
                .textFieldStyle(.roundedBorder)

            Text("Salary Range")
            TextField("e.g. $90,000 - $110,000", text: $salaryRange)
                .textFieldStyle(.roundedBorder)
            
            Text("Application Date")
            DatePicker("Application Date", selection: $dateApplied, displayedComponents: .date)
                .datePickerStyle(.compact)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
            Picker("Status", selection: $status) {
                ForEach(JobStatus.allCases) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(.menu)

            Text("Fit Score: \(fitScore)%")
            Slider(value: Binding(
                get: { Double(fitScore) },
                set: { fitScore = Int16($0) }),
                   in: 0...100, step: 5)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
            TextEditor(text: $notes)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Text("Custom Notes")
                .font(.headline)
            ForEach($customNotes) { $note in
                customNoteRow(note: $note)
            }
            Button(action: {
                customNotes.append(CustomNoteDraft())
            }) {
                Label("Add Custom Note", systemImage: "plus.circle")
            }
            .padding(.top, 4)

            Button(action: addJob) {
                Label("Save Job", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
    }
    
    private func customNoteRow(note: Binding<CustomNoteDraft>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Note Title", text: note.title)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    if let idx = customNotes.firstIndex(of: note.wrappedValue) {
                        customNotes.remove(at: idx)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
            TextEditor(text: note.content)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
        }
        .padding(.vertical, 4)
    }

    private func addJob() {
        let newJob = JobApplication(context: viewContext)
        newJob.id = UUID()
        newJob.title = title
        newJob.company = company
        newJob.location = location
        newJob.salaryRange = salaryRange
        newJob.status = status.rawValue
        newJob.fitScore = fitScore
        newJob.notes = notes
        newJob.dateApplied = dateApplied
        for draft in customNotes where !draft.title.isEmpty || !draft.content.isEmpty {
            let note = CustomNote(context: viewContext)
            note.id = UUID()
            note.title = draft.title
            note.content = draft.content
            note.job = newJob
        }
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save job: \(error.localizedDescription)")
        }
    }
}

struct CustomNoteDraft: Identifiable, Hashable {
    var id = UUID()
    var title: String = ""
    var content: String = ""
}
