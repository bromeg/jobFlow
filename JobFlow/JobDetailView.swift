import SwiftUI

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let job: JobApplication
    @Environment(\.managedObjectContext) private var viewContext
    @State private var editableStatus: JobStatus
    @State private var editableDateApplied: Date
    @State private var customNotes: [CustomNote] = []
    @State private var isLoaded = false
    @State private var locationType: String = LocationType.remote.rawValue
    @State private var appliedVia: String = AppliedVia.other.rawValue
    @State private var isEditing = false
    @State private var editableTitle: String
    @State private var editableCompany: String
    @State private var editableJobDescription: String
    @State private var editableJobURL: String
    @State private var editableSalaryRange: String
    @State private var editableFitScore: Int
    @State private var editableNotes: String
    @State private var editableRecruiterName: String
    @State private var editableRecruiterEmail: String

    init(job: JobApplication) {
        self.job = job
        // Default to .applied if status is nil or not matching
        _editableStatus = State(initialValue: JobStatus(rawValue: job.status ?? "") ?? .applied)
        // Default to current date if dateApplied is nil
        _editableDateApplied = State(initialValue: job.dateApplied ?? Date())
        _editableTitle = State(initialValue: job.title ?? "")
        _editableCompany = State(initialValue: job.company ?? "")
        _editableJobDescription = State(initialValue: job.jobDescription ?? "")
        _editableJobURL = State(initialValue: job.url ?? "")
        _editableSalaryRange = State(initialValue: job.salaryRange ?? "")
        _editableFitScore = State(initialValue: Int(job.fitScore))
        _editableNotes = State(initialValue: job.notes ?? "")
        _editableRecruiterName = State(initialValue: job.recruiterName ?? "")
        _editableRecruiterEmail = State(initialValue: job.recruiterEmail ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomBackButton()
                .padding(.leading)
                .padding(.top, 8)
            HStack {
                Spacer()
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        // Save changes to Core Data
                        job.title = editableTitle
                        job.company = editableCompany
                        job.jobDescription = editableJobDescription
                        job.url = editableJobURL
                        job.salaryRange = editableSalaryRange
                        job.fitScore = Int16(editableFitScore)
                        job.notes = editableNotes
                        job.recruiterName = editableRecruiterName
                        job.recruiterEmail = editableRecruiterEmail
                        job.status = editableStatus.rawValue
                        job.dateApplied = editableDateApplied
                        job.locationType = locationType
                        job.appliedVia = appliedVia
                        try? viewContext.save()
                    }
                    isEditing.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        // Title
                        if isEditing {
                            Text("Title").bold()
                            TextField("Title", text: $editableTitle)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(job.title ?? "Untitled")
                                .font(.largeTitle)
                                .bold()
                        }

                        // Company
                        if isEditing {
                            Text("Company").bold()
                            TextField("Company", text: $editableCompany)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(job.company ?? "Unknown Company")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }

                        // Status
                        if isEditing {
                            Text("Status").bold()
                            Picker("Status", selection: $editableStatus) {
                                ForEach(JobStatus.allCases) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text(job.status ?? "N/A")
                                .padding(6)
                                .background(statusColor(for: job.status))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }

                        // Fit Score
                        if isEditing {
                            Text("Fit Score").bold()
                            HStack {
                                Slider(value: Binding(
                                    get: { Double(editableFitScore) },
                                    set: { editableFitScore = Int($0) }),
                                       in: 0...100, step: 5)
                                Text("\(editableFitScore)%")
                            }
                        } else {
                            Text("Fit Score: \(job.fitScore)%").bold()
                            ProgressView("Fit Score: \(job.fitScore)%", value: Double(job.fitScore), total: 100)
                                .progressViewStyle(.linear)
                                .tint(.blue)
                        }

                        // Application Date
                        if isEditing {
                            Text("Application Date").bold()
                            DatePicker("Application Date", selection: $editableDateApplied, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        } else {
                            HStack {
                                Text("Application Date:").bold()
                                Text(formattedDate(job.dateApplied ?? Date()))
                            }
                        }

                        // Salary Range
                        if isEditing {
                            Text("Salary Range").bold()
                            TextField("Salary Range", text: $editableSalaryRange)
                                .textFieldStyle(.roundedBorder)
                        } else if let salary = job.salaryRange {
                            Text("Salary: \(salary)").bold()
                        }

                        // Location Type
                        if isEditing {
                            Text("Location Type").bold()
                            Picker("", selection: $locationType) {
                                ForEach(LocationType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        } else if let locationType = job.locationType {
                            Text("Location Type: \(locationType)").bold()
                        }

                        // Applied Via
                        if isEditing {
                            Text("Applied Via").bold()
                            Picker("", selection: $appliedVia) {
                                ForEach(AppliedVia.allCases) { via in
                                    Text(via.rawValue).tag(via)
                                }
                            }
                            .pickerStyle(.menu)
                        } else if let appliedVia = job.appliedVia {
                            Text("Applied Via: \(appliedVia)").bold()
                        }

                        // Recruiter Name
                        if isEditing {
                            Text("Recruiter Name").bold()
                            TextField("Recruiter Name", text: $editableRecruiterName)
                                .textFieldStyle(.roundedBorder)
                        } else if let recruiterName = job.recruiterName {
                            Text("Recruiter: \(recruiterName)").bold()
                        }

                        // Recruiter Email
                        if isEditing {
                            Text("Recruiter Email").bold()
                            TextField("Recruiter Email", text: $editableRecruiterEmail)
                                .textFieldStyle(.roundedBorder)
                        } else if let recruiterEmail = job.recruiterEmail {
                            Text("Recruiter Email: \(recruiterEmail)").bold()
                        }

                        // Job Description
                        if isEditing {
                            Text("Job Description").bold()
                            TextEditor(text: $editableJobDescription)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        } else if let jobDescription = job.jobDescription, !jobDescription.isEmpty {
                            Text("Job Description").font(.headline)
                            Text(jobDescription)
                                .padding()
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(8)
                        }

                        // Job URL
                        if isEditing {
                            Text("Job URL").bold()
                            TextField("Job URL", text: $editableJobURL)
                                .textFieldStyle(.roundedBorder)
                        } else if let urlString = job.url, let url = URL(string: urlString), !urlString.isEmpty {
                            Text("Job URL").font(.headline)
                            Link(urlString, destination: url)
                                .foregroundColor(.blue)
                                .underline()
                                .padding(.bottom, 8)
                        }

                        // Notes
                        if isEditing {
                            Text("Notes").bold()
                            TextEditor(text: $editableNotes)
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        } else if let notes = job.notes, !notes.isEmpty {
                            Text("Notes").font(.headline)
                            Text(notes)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    Divider()

                    // Custom Notes Section
                    Text("Custom Notes")
                        .font(.headline)
                    ForEach($customNotes, id: \.objectID) { $note in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Note Title", text: Binding(
                                    get: { note.title ?? "" },
                                    set: { newValue in
                                        note.title = newValue
                                        saveContext()
                                    })
                                )
                                .textFieldStyle(.roundedBorder)
                                Button(action: {
                                    if let idx = customNotes.firstIndex(where: { $0.objectID == note.objectID }) {
                                        let noteToDelete = customNotes[idx]
                                        viewContext.delete(noteToDelete)
                                        customNotes.remove(at: idx)
                                        saveContext()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            TextEditor(text: Binding(
                                get: { note.content ?? "" },
                                set: { newValue in
                                    note.content = newValue
                                    saveContext()
                                })
                            )
                            .frame(height: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                        }
                        .padding(.vertical, 4)
                    }
                    Button(action: {
                        let newNote = CustomNote(context: viewContext)
                        newNote.id = UUID()
                        newNote.title = ""
                        newNote.content = ""
                        newNote.job = job
                        customNotes.append(newNote)
                        newNote.job = job
                        saveContext()
                    }) {
                        Label("Add Custom Note", systemImage: "plus.circle")
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
        }
        .navigationTitle("Job Details")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !isLoaded {
                if let notesSet = job.customNotes as? Set<CustomNote> {
                    customNotes = notesSet.sorted { ($0.title ?? "") < ($1.title ?? "") }
                }
                isLoaded = true
            }
        }
    }

    private func statusColor(for status: String?) -> Color {
        switch JobStatus(rawValue: status ?? "") ?? .applied {
        case .applied: return .blue
        case .interview: return .orange
        case .offer: return .green
        case .rejected: return .red
        default: return .gray
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save custom note: \(error.localizedDescription)")
        }
    }
}
