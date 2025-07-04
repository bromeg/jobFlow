import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JobApplication.dateApplied, ascending: false)],
        animation: .default)
    private var applications: FetchedResults<JobApplication>

    @State private var showingAddJob = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("My Applications").font(.title2)) {
                    ForEach(applications) { job in
                        NavigationLink(destination: JobDetailView(job: job)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(job.title ?? "Untitled")
                                            .font(.headline)

                                        Text(job.company ?? "Unknown Company")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(job.status ?? "N/A")
                                        .font(.caption)
                                        .padding(6)
                                        .background(statusColor(for: job.status))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                ProgressView("Fit: \(job.fitScore)%", value: Double(job.fitScore), total: 100)
                                    .progressViewStyle(.linear)
                                    .tint(.blue)

                                if let date = job.dateApplied {
                                    Text("Applied on \(formattedDate(date))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                }
            }
            .navigationTitle("Applications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddJob = true
                    }) {
                        Label("Add Job", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddJob) {
                AddJobView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

private func statusColor(for status: String?) -> Color {
    switch status {
    case "Applied":
        return .blue
    case "Interview":
        return .orange
    case "Offer":
        return .green
    case "Rejected":
        return .red
    default:
        return .gray
    }
}

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

