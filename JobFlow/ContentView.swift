import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JobApplication.dateApplied, ascending: false)],
        animation: .default)
    private var applications: FetchedResults<JobApplication>

    @State private var showingAddJob = false
    @State private var selectedTab = "Dashboard"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("JobFlow")
                        .font(.system(size: 32, weight: .bold))
                    Text("Your intelligent job application tracking and career management tool")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Tab Bar
                HStack(spacing: 0) {
                    tabBarButton(title: "Dashboard", isSelected: selectedTab == "Dashboard")
                    tabBarButton(title: "Applications", isSelected: selectedTab == "Applications")
                    tabBarButton(title: "Resume Tools", isSelected: selectedTab == "Resume Tools")
                    tabBarButton(title: "Budget", isSelected: selectedTab == "Budget")
                    tabBarButton(title: "Integrations", isSelected: selectedTab == "Integrations")
                }
                .padding(.horizontal)
                .padding(.bottom, 24)

                // Main Content
                if selectedTab == "Dashboard" {
                    DashboardView(applications: applications)
                } else if selectedTab == "Applications" {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(applications) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    .navigationTitle("")
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
                } else {
                    // Placeholder for other tabs
                    VStack(spacing: 16) {
                        Text("Coming Soon")
                            .font(.title)
                        Text("This feature is under development")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private func jobRowView(job: JobApplication) -> some View {
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

    // Tab Bar Button Helper
    @ViewBuilder
    private func tabBarButton(title: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedTab = title
        }) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.pink.opacity(0.4), lineWidth: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
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

// JobCardView for displaying each job application as a card
struct JobCardView: View {
    let job: JobApplication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(job.title ?? "Untitled")
                            .font(.title3).bold()
                        if let status = job.status {
                            StatusBadge(status: status)
                        }
                    }
                    HStack(spacing: 16) {
                        if let company = job.company {
                            Label(company, systemImage: "building.2")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let location = job.location {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let salary = job.salaryRange {
                            Label(salary, systemImage: "dollarsign.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Fit Score:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: Double(job.fitScore), total: 100)
                            .frame(width: 60)
                        Text("\(job.fitScore)%")
                            .font(.caption)
                    }
                }
            }
            Divider()
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Stage")
                        .font(.caption).bold()
                    Text(job.status ?? "N/A")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Next Step:")
                        .font(.caption).bold()
                    Text("(Add logic for next step)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Applied Date")
                        .font(.caption).bold()
                    if let dateApplied = job.dateApplied {
                        Text(formattedDate(dateApplied))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Not specified")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption).bold()
                    Text(job.notes ?? "")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// Status badge view
struct StatusBadge: View {
    let status: String
    var color: Color {
        switch status.lowercased() {
        case "applied": return .blue
        case "interview": return .yellow
        case "offer": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
    var body: some View {
        Text(status.capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// Star rating view (static for now)
struct StarRatingView: View {
    let rating: Int // 0...5
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.yellow)
            }
        }
    }
}

