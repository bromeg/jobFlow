import SwiftUI
import CoreData

struct DashboardView: View {
    let applications: FetchedResults<JobApplication>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Stats Cards Row
                HStack(spacing: 16) {
                    StatCard(title: "Total Applications", value: "24", icon: "tray.full")
                    StatCard(title: "Active Interviews", value: "3", icon: "person.2.fill")
                    StatCard(title: "Response Rate", value: "58%", icon: "envelope.open")
                    StatCard(title: "Avg Fit Score", value: "72", icon: "chart.bar.fill")
                }

                // Recent Applications Section
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Applications")
                            .font(.title2).bold()
                        Text("Your latest job applications and their status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(Array(applications.prefix(3))) { job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                RecentApplicationRow(job: job)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 90)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Recent Applications Row

struct RecentApplicationRow: View {
    let job: JobApplication
    
    private var statusIcon: String {
        switch job.status?.lowercased() {
        case "applied": return "info.circle"
        case "interview": return "clock.fill"
        case "offer": return "checkmark.circle.fill"
        case "rejected": return "xmark.octagon"
        default: return "questionmark.circle"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(job.title ?? "Untitled")
                    .font(.headline)
                Text(job.company ?? "Unknown Company")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Fit: \(job.fitScore)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let dateApplied = job.dateApplied {
                    Text(formattedDate(dateApplied))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(job.status ?? "N/A")
                    .font(.caption2).bold()
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Preview
// Note: Preview removed as it requires Core Data context 