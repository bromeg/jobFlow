import SwiftUI

struct JobDetailView: View {
    let job: JobApplication
    @Environment(\.managedObjectContext) private var viewContext
    @State private var editableStatus: JobStatus
    @State private var editableDateApplied: Date
    @State private var customNotes: [CustomNote] = []
    @State private var isLoaded = false

    init(job: JobApplication) {
        self.job = job
        // Default to .applied if status is nil or not matching
        _editableStatus = State(initialValue: JobStatus(rawValue: job.status ?? "") ?? .applied)
        // Default to current date if dateApplied is nil
        _editableDateApplied = State(initialValue: job.dateApplied ?? Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text(job.title ?? "Untitled")
                        .font(.largeTitle)
                        .bold()

                    Text(job.company ?? "Unknown Company")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Status:")
                            .bold()
                        Picker("Status", selection: $editableStatus) {
                            ForEach(JobStatus.allCases) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: editableStatus) { newStatus in
                            job.status = newStatus.rawValue
                            do {
                                try viewContext.save()
                            } catch {
                                print("Failed to update status: \(error.localizedDescription)")
                            }
                        }
                        Text(job.status ?? "N/A")
                            .padding(6)
                            .background(statusColor(for: job.status))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    
                    ProgressView("Fit Score: \(job.fitScore)%", value: Double(job.fitScore), total: 100)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                    

                    if let salary = job.salaryRange {
                        Text("Salary: \(salary)")
                    }

                    HStack {
                        Text("Application Date:")
                            .bold()
                        DatePicker("Application Date", selection: $editableDateApplied, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .onChange(of: editableDateApplied) { newDate in
                                job.dateApplied = newDate
                                do {
                                    try viewContext.save()
                                } catch {
                                    print("Failed to update date: \(error.localizedDescription)")
                                }
                            }
                    }
                }

                Divider()

                if let notes = job.notes, !notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

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
                    job.addToCustomNotes(newNote)
                    saveContext()
                }) {
                    Label("Add Custom Note", systemImage: "plus.circle")
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding()
            .onAppear {
                if !isLoaded {
                    if let notesSet = job.customNotes as? Set<CustomNote> {
                        customNotes = notesSet.sorted { ($0.title ?? "") < ($1.title ?? "") }
                    }
                    isLoaded = true
                }
            }
        }
        .navigationTitle("Job Details")
    }

    private func statusColor(for status: String?) -> Color {
        switch status {
        case "Applied": return .blue
        case "Interview": return .orange
        case "Offer": return .green
        case "Rejected": return .red
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
