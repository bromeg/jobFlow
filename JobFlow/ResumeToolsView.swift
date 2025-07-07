import SwiftUI
import UniformTypeIdentifiers

struct ResumeToolsView: View {
    @State private var resumeContent: String = ""
    @State private var jobDescription: String = ""
    @State private var jobLink: String = ""
    @State private var companyInfo: CompanyInfo? = nil
    @State private var glassdoorInfo: GlassdoorInfo? = nil
    @State private var chatMessages: [ChatMessage] = []
    @State private var newChatMessage: String = ""
    @State private var matchScore: MatchScore? = nil
    @State private var suggestions: [String] = []
    @State private var changeSummary: [ChangeItem] = []
    @State private var isProcessing = false
    @State private var showingFilePicker = false
    @State private var resumeGenerated = false
    @State private var showPreview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ResumeCard(
                    resumeContent: $resumeContent,
                    showingFilePicker: $showingFilePicker,
                    onFileSelected: loadResumeFromFile
                )
                JobDescriptionAndLinkCard(
                    jobDescription: $jobDescription,
                    jobLink: $jobLink,
                    onFetch: fetchJobInfo
                )
                CompanyResearchView(
                    companyInfo: $companyInfo,
                    glassdoorInfo: $glassdoorInfo
                )
                AIAnalysisView(
                    chatMessages: $chatMessages,
                    newChatMessage: $newChatMessage,
                    isProcessing: $isProcessing
                )
                MatchCard(
                    matchScore: $matchScore,
                    suggestions: $suggestions
                )
                GeneratePreviewCard(
                    resumeGenerated: $resumeGenerated,
                    onGenerate: generateOptimizedResume,
                    changeSummary: $changeSummary,
                    showPreview: $showPreview
                )
                .sheet(isPresented: $showPreview) {
                    ResumePreviewView(resumeContent: resumeContent)
                }
                DownloadCard(
                    resumeGenerated: resumeGenerated
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }

    private func loadResumeFromFile(_ url: URL) {
        resumeContent = "Mock resume content loaded from \(url.lastPathComponent)"
    }

    private func fetchJobInfo() {
        // Mock implementation - in real app, scrape job posting
        companyInfo = CompanyInfo(
            name: "StartupXYZ",
            industry: "Technology",
            size: "500-1000 employees",
            description: "Mid-size technology company founded in 2015. Leading provider of innovative software solutions.",
            mission: "To empower businesses through cutting-edge technology"
        )
        glassdoorInfo = GlassdoorInfo(
            rating: 4.2,
            pros: ["Great work-life balance", "Innovative projects", "Supportive management"],
            cons: ["Fast-paced environment", "Limited remote work options"],
            culture: "Collaborative and results-driven with emphasis on continuous learning"
        )
    }

    private func generateOptimizedResume() {
        // Mock: pretend to generate resume, update change summary
        resumeGenerated = true
        changeSummary = [
            ChangeItem(type: .added, section: "Skills", description: "Added cloud computing and Agile methodology"),
            ChangeItem(type: .modified, section: "Experience", description: "Enhanced bullet points with metrics"),
            ChangeItem(type: .reordered, section: "Education", description: "Moved to bottom for better flow")
        ]
    }
}

// Card 1: Resume
struct ResumeCard: View {
    @Binding var resumeContent: String
    @Binding var showingFilePicker: Bool
    let onFileSelected: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resume")
                .font(.title2).bold()
            Text("Upload or paste your resume to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upload PDF or DOCX")
                            .font(.headline)
                        Text("Select a file from your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.pdf, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        onFileSelected(url)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Or paste your resume content")
                    .font(.headline)
                TextEditor(text: $resumeContent)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// Card 2: Job Description & Link
struct JobDescriptionAndLinkCard: View {
    @Binding var jobDescription: String
    @Binding var jobLink: String
    let onFetch: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job Description & Link")
                .font(.title2).bold()
            Text("Paste the job description and/or a link to the job post.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextEditor(text: $jobDescription)
                .frame(minHeight: 80)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            HStack {
                TextField("https://example.com/job-posting", text: $jobLink)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Fetch") {
                    onFetch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(jobLink.isEmpty)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// Card 3: Company Research
struct CompanyResearchView: View {
    @Binding var companyInfo: CompanyInfo?
    @Binding var glassdoorInfo: GlassdoorInfo?
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 24) {
                // Company Overview
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.title2)
                        Text("Company Research")
                            .font(.title2).bold()
                    }
                    Text("AI-powered company insights and employee reviews")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Company Overview")
                        .font(.headline)
                        .padding(.top, 12)
                    VStack(alignment: .leading, spacing: 8) {
                        if let company = companyInfo {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(company.name)")
                                    .font(.headline).bold()
                                    .foregroundColor(.blue)
                                Text("is a mid-size technology company founded in 2015.")
                                Text("Leading provider of innovative software solutions")
                                    .foregroundColor(.blue)
                                HStack(alignment: .top) {
                                    Text("Mission:")
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text(company.mission)
                                }
                            }
                        } else {
                            Text("No company info available.")
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                // Employee Reviews
                VStack(alignment: .leading, spacing: 12) {
                    Text("Employee Reviews (Glassdoor)")
                        .font(.headline)
                        .padding(.top, 36)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < 4 ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            Text("4.2/5.0")
                                .font(.headline)
                            Text("(847 reviews)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Pros: Great work-life balance, innovative projects, supportive management")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .bold()
                        Text("Cons: Fast-paced environment, limited remote work options")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .bold()
                        Text("Culture: Collaborative and results-driven with emphasis on continuous learning")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .bold()
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.yellow.opacity(0.08)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.vertical, 16)
    }
}

// Card 4: AI Clarification Chat
struct AIAnalysisView: View {
    @Binding var chatMessages: [ChatMessage]
    @Binding var newChatMessage: String
    @Binding var isProcessing: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Clarification Chat")
                .font(.title2).bold()
            Text("AI will ask follow-up questions to better understand your experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatMessages) { message in
                        ChatMessageView(message: message)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.05)))
            HStack {
                TextField("Type your response...", text: $newChatMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newChatMessage.isEmpty || isProcessing)
            }
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("AI is analyzing your response...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if chatMessages.isEmpty {
                startAIChat()
            }
        }
    }
    private func startAIChat() {
        chatMessages = [
            ChatMessage(
                id: UUID(),
                content: "Hi! I'm here to help optimize your resume. I can see you have experience in software development. Do you have experience with Agile methodology?",
                isFromAI: true,
                timestamp: Date()
            )
        ]
    }
    private func sendMessage() {
        let userMessage = ChatMessage(
            id: UUID(),
            content: newChatMessage,
            isFromAI: false,
            timestamp: Date()
        )
        chatMessages.append(userMessage)
        let messageContent = newChatMessage
        newChatMessage = ""
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let aiResponse = ChatMessage(
                id: UUID(),
                content: "Great! I can see you have \(messageContent.count) characters of experience. Can you tell me more about your experience with cloud platforms like AWS or Azure?",
                isFromAI: true,
                timestamp: Date()
            )
            chatMessages.append(aiResponse)
            isProcessing = false
        }
    }
}

// Card 5: Match (score & suggestions)
struct MatchCard: View {
    @Binding var matchScore: MatchScore?
    @Binding var suggestions: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Match Score & Suggestions")
                .font(.title2).bold()
            if let matchScore = matchScore {
                MatchScoreCard(matchScore: matchScore)
            }
            if !suggestions.isEmpty {
                SuggestionsCard(suggestions: suggestions)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// Card 6: Generate & Preview
struct GeneratePreviewCard: View {
    @Binding var resumeGenerated: Bool
    let onGenerate: () -> Void
    @Binding var changeSummary: [ChangeItem]
    @Binding var showPreview: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generate & Preview")
                .font(.title2).bold()
            Button(action: onGenerate) {
                Text(resumeGenerated ? "Regenerate Optimized Resume" : "Generate Optimized Resume")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 4)
            .disabled(resumeGenerated)
            if resumeGenerated {
                Button(action: { showPreview = true }) {
                    Text("Preview Optimized Resume")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 4)
            }
            if !changeSummary.isEmpty {
                ChangeSummaryCard(changeSummary: changeSummary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// Card 7: Download
struct DownloadCard: View {
    var resumeGenerated: Bool
    @State private var isGenerating = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Download Optimized Resume")
                .font(.title2).bold()
            Text("Your ATS-optimized resume is ready for download")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                Button(action: { downloadResume(format: .docx) }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                        Text("Download as DOCX")
                            .font(.headline)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!resumeGenerated || isGenerating)
                Button(action: { downloadResume(format: .pdf) }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                            .font(.title2)
                        Text("Download as PDF")
                            .font(.headline)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!resumeGenerated || isGenerating)
            }
            if isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating optimized resume...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    private func downloadResume(format: ResumeFormat) {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
        }
    }
}

// Preview Card (Sheet)
struct ResumePreviewView: View {
    let resumeContent: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resume Preview")
                .font(.title2).bold()
            ScrollView {
                Text(resumeContent)
                    .padding()
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}

// MARK: - Supporting Views and Models

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromAI: Bool
    let timestamp: Date
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromAI {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    Text("AI Assistant")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CompanyInfo: Identifiable {
    let id = UUID()
    let name: String
    let industry: String
    let size: String
    let description: String
    let mission: String
}

struct GlassdoorInfo: Identifiable {
    let id = UUID()
    let rating: Double
    let pros: [String]
    let cons: [String]
    let culture: String
}

struct MatchScore: Identifiable {
    let id = UUID()
    let overall: Int
    let technicalSkills: Int
    let experienceLevel: Int
    let keywords: Int
}

struct ChangeItem: Identifiable {
    let id = UUID()
    let type: ChangeType
    let section: String
    let description: String
    
    enum ChangeType {
        case added, modified, removed, reordered
    }
}

enum ResumeFormat {
    case docx, pdf
}

struct CompanyInfoCard: View {
    let companyInfo: CompanyInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Company Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Company", value: companyInfo.name)
                InfoRow(label: "Industry", value: companyInfo.industry)
                InfoRow(label: "Size", value: companyInfo.size)
                InfoRow(label: "Description", value: companyInfo.description)
                InfoRow(label: "Mission", value: companyInfo.mission)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct GlassdoorInfoCard: View {
    let glassdoorInfo: GlassdoorInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Employee Reviews")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < Int(glassdoorInfo.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    Text(String(format: "%.1f", glassdoorInfo.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoSection(title: "Pros", items: glassdoorInfo.pros, color: .green)
                InfoSection(title: "Cons", items: glassdoorInfo.cons, color: .red)
                InfoRow(label: "Culture", value: glassdoorInfo.culture)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InfoSection: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline).bold()
                .foregroundColor(color)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(color)
                    Text(item)
                        .font(.caption)
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption).bold()
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
            Spacer()
        }
    }
}

struct MatchScoreCard: View {
    let matchScore: MatchScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Match Score")
                    .font(.headline)
                Spacer()
                Text("\(matchScore.overall)%")
                    .font(.title).bold()
                    .foregroundColor(scoreColor(matchScore.overall))
            }
            
            VStack(spacing: 12) {
                ScoreRow(label: "Technical Skills", score: matchScore.technicalSkills)
                ScoreRow(label: "Experience Level", score: matchScore.experienceLevel)
                ScoreRow(label: "Keywords Match", score: matchScore.keywords)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

struct ScoreRow: View {
    let label: String
    let score: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            ProgressView(value: Double(score), total: 100)
                .frame(width: 100)
            Text("\(score)%")
                .font(.caption)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct SuggestionsCard: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions for Improvement")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .font(.caption).bold()
                            .foregroundColor(.blue)
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ChangeSummaryCard: View {
    let changeSummary: [ChangeItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Changes Made")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(changeSummary) { change in
                    HStack(alignment: .top) {
                        Image(systemName: changeIcon(for: change.type))
                            .foregroundColor(changeColor(for: change.type))
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(change.section)
                                .font(.caption).bold()
                            Text(change.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func changeIcon(for type: ChangeItem.ChangeType) -> String {
        switch type {
        case .added: return "plus.circle"
        case .modified: return "pencil.circle"
        case .removed: return "minus.circle"
        case .reordered: return "arrow.up.arrow.down.circle"
        }
    }
    
    private func changeColor(for type: ChangeItem.ChangeType) -> Color {
        switch type {
        case .added: return .green
        case .modified: return .blue
        case .removed: return .red
        case .reordered: return .orange
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: View {
    let types: [UTType]
    let onPick: (URL) -> Void
    @State private var showingFilePicker = false
    
    var body: some View {
        Button("Select File") {
            showingFilePicker = true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: types,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onPick(url)
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
} 