import SwiftUI
import UniformTypeIdentifiers
import Foundation

// Main view for the Resume Tools page
struct ResumeToolsView: View {
    // --- State Variables ---
    @State private var resumeContent: String = "" // Stores the user's resume text
    @State private var jobDescription: String = "" // Stores the job description text
    @State private var jobLink: String = "" // Stores the job link (not used yet)
    @State private var isProcessing = false // Indicates if analysis is in progress
    @State private var showingFilePicker = false // Controls file picker visibility
    @State private var resumeGenerated = false // Indicates if analysis is complete
    @State private var matchScore: Int = 0 // Stores the AI match score
    @State private var suggestions: [String] = [] // Stores AI suggestions
    @State private var justification: String = "" // Stores AI justification/explanation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // --- 1. Upload Resume Card ---
                ResumeCard(
                    resumeContent: $resumeContent,
                    showingFilePicker: $showingFilePicker,
                    onFileSelected: loadResumeFromFile
                )
                // --- 2. Job Description & Link Card ---
                JobDescriptionAndLinkCard(
                    jobDescription: $jobDescription,
                    jobLink: $jobLink
                )
                // --- 3. Generate & Optimize Card ---
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

    // Handles loading resume content from a selected file (now uploads to backend for extraction)
    private func loadResumeFromFile(_ url: URL) {
        // Determine file type
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" || ext == "docx" {
            // Upload file to backend for analysis
            self.isProcessing = true
            analyzeResumeFile(fileURL: url, jobDescription: jobDescription) { score, justification, suggestions in
                DispatchQueue.main.async {
                    self.matchScore = score
                    self.justification = justification
                    self.suggestions = suggestions
                    self.resumeGenerated = true
                    self.isProcessing = false
                }
            }
        } else {
            // Fallback: just show mock content
            resumeContent = "Mock resume content loaded from \(url.lastPathComponent)"
        }
    }

    // Triggers the backend analysis and updates state with results
    private func generateOptimizedResume() {
        guard !resumeContent.isEmpty else { return }
        isProcessing = true
        // If resumeContent is not a file upload, use the plain text endpoint
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

// --- Card 1: Resume Upload ---
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
            // File upload button
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
                allowedContentTypes: [UTType.pdf, UTType.plainText] + (UTType(filenameExtension: "docx") != nil ? [UTType(filenameExtension: "docx")!] : []),
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
            // Text area for pasting resume content
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

// --- Card 2: Job Description & Link ---
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
            // Text area for job description
            TextEditor(text: $jobDescription)
                .frame(minHeight: 80)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            // Job link field (fetch not implemented yet)
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

// --- Card 3: Generate & Optimize ---
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
            // Button to trigger backend analysis
            Button(action: onGenerate) {
                Text(resumeGenerated ? "Regenerate & Analyze Resume" : "Generate & Analyze Resume")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.vertical, 4)
            .disabled(isProcessing)
            // Show progress indicator while processing
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing your resume...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            // Show results after analysis
            if resumeGenerated {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Match Score")
                            .font(.headline)
                        Spacer()
                        Text("\(matchScore)%")
                            .font(.title).bold()
                            .foregroundColor(scoreColor(matchScore))
                    }
                    // Show AI justification/explanation
                    if !justification.isEmpty {
                        Text(justification)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 8)
                    }
                    // Show AI suggestions as a numbered list
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
    // Helper to color the score based on value
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// --- Backend API Call Function ---
// Calls the Python backend to analyze the resume and job description
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

// Calls the backend to analyze a resume file (PDF/DOCX) and job description
func analyzeResumeFile(fileURL: URL, jobDescription: String, completion: @escaping (Int, String, [String]) -> Void) {
    guard let url = URL(string: "http://127.0.0.1:8000/analyze_resume_file") else {
        print("Invalid URL")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    var data = Data()
    // Add file data
    if let fileData = try? Data(contentsOf: fileURL) {
        let filename = fileURL.lastPathComponent
        let mimetype = fileURL.pathExtension.lowercased() == "pdf" ? "application/pdf" : "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
    }
    // Add job description
    data.append("--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"job_description\"\r\n\r\n".data(using: .utf8)!)
    data.append(jobDescription.data(using: .utf8)!)
    data.append("\r\n".data(using: .utf8)!)
    data.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = data
    print("Uploading file to backend for analysis...")
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