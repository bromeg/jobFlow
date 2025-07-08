import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct ResumeToolsView: View {
    @State private var resumeContent: String = ""
    @State private var jobDescription: String = ""
    @State private var jobLink: String = ""
    @State private var isProcessing = false
    @State private var showingFilePicker = false
    @State private var resumeGenerated = false
    @State private var matchScore: Int = 0
    @State private var suggestions: [String] = []
    @State private var justification: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 1. Upload Resume
                ResumeCard(
                    resumeContent: $resumeContent,
                    showingFilePicker: $showingFilePicker,
                    onFileSelected: loadResumeFromFile
                )
                
                // 2. Job Description & Link
                JobDescriptionAndLinkCard(
                    jobDescription: $jobDescription,
                    jobLink: $jobLink
                )
                
                // 3. Generate & Optimize
                GenerateOptimizeCard(
                    isProcessing: $isProcessing,
                    resumeGenerated: $resumeGenerated,
                    matchScore: $matchScore,
                    justification: $justification,
                    suggestions: $suggestions,
                    onGenerate: generateOptimizedResume
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }

    private func loadResumeFromFile(_ url: URL) {
        resumeContent = "Mock resume content loaded from \(url.lastPathComponent)"
    }

    private func generateOptimizedResume() {
        guard !resumeContent.isEmpty else { return }
        
        isProcessing = true
        analyzeResume(resumeText: resumeContent, jobDescription: jobDescription) { score, justification, suggestions in
            DispatchQueue.main.async {
                self.matchScore = score
                self.justification = justification
                self.suggestions = suggestions
                self.resumeGenerated = true
                self.isProcessing = false
            }
        }
    }
}

// Card 1: Resume Upload
struct ResumeCard: View {
    @Binding var resumeContent: String
    @Binding var showingFilePicker: Bool
    let onFileSelected: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upload Resume")
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
                    // TODO: Implement job fetching
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

// Card 3: Generate & Optimize
struct GenerateOptimizeCard: View {
    @Binding var isProcessing: Bool
    @Binding var resumeGenerated: Bool
    @Binding var matchScore: Int
    @Binding var justification: String
    @Binding var suggestions: [String]
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generate & Optimize")
                .font(.title2).bold()
            
            Button(action: onGenerate) {
                Text(resumeGenerated ? "Regenerate & Analyze Resume" : "Generate & Analyze Resume")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 4)
            .disabled(isProcessing)
            
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing your resume...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if resumeGenerated {
                // Match Score
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Match Score")
                            .font(.headline)
                        Spacer()
                        Text("\(matchScore)%")
                            .font(.title).bold()
                            .foregroundColor(scoreColor(matchScore))
                    }
                    
                    if !justification.isEmpty {
                        Text(justification)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 8)
                    }
                    
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggestions for Improvement")
                                .font(.headline)
                            
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
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.05)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// Backend API call function
func analyzeResume(resumeText: String, jobDescription: String, completion: @escaping (Int, String, [String]) -> Void) {
    guard let url = URL(string: "http://127.0.0.1:8000/analyze_resume") else {
        print("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Send both resume and job description to backend
    let body = [
        "resume": resumeText,
        "job_description": jobDescription
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    print("Sending request to backend...")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network error: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status: \(httpResponse.statusCode)")
        }
        
        guard let data = data else {
            print("No data received")
            return
        }
        
        print("Received data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let matchScore = json["match_score"] as? Int,
               let justification = json["justification"] as? String,
               let suggestions = json["suggestions"] as? [String] {
                completion(matchScore, justification, suggestions)
            } else {
                print("Failed to parse response: \(String(data: data, encoding: .utf8) ?? "nil")")
            }
        } catch {
            print("JSON decode error: \(error)")
        }
    }.resume()
} 