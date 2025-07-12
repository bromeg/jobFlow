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
    @State private var selectedResumeFile: URL? = nil // Stores the selected file URL
    @State private var resumeUploadStatus: String? = nil // Stores upload status message
    @State private var extractedResumeText: String? = nil // Stores extracted text from file
    @State private var isExtractingResume = false
    @State private var isFetchingJob = false // Indicates if job fetching is in progress
    @State private var jobFetchStatus: String? = nil // Stores job fetch status message

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // --- 1. Upload Resume Card ---
                ResumeCard(
                    resumeContent: $resumeContent,
                    selectedResumeFile: $selectedResumeFile,
                    resumeUploadStatus: $resumeUploadStatus,
                    showingFilePicker: $showingFilePicker,
                    onFileSelected: handleResumeFileSelected,
                    onRemoveFile: removeSelectedResumeFile
                )
                // --- 2. Job Description & Link Card ---
                JobDescriptionAndLinkCard(
                    jobDescription: $jobDescription,
                    jobLink: $jobLink,
                    isFetchingJob: $isFetchingJob,
                    jobFetchStatus: $jobFetchStatus,
                    onFetchJob: fetchJobDescription
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
    

    // Handles when a resume file is selected
    private func handleResumeFileSelected(_ url: URL) {
        selectedResumeFile = url
        resumeUploadStatus = "Uploading..."
        extractedResumeText = nil
        print("handleResumeFileSelected")
        let ext = url.pathExtension.lowercased()
        print(ext)
        if ext == "pdf" || ext == "docx" {
            isExtractingResume = true
            // Start accessing security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            extractResumeTextFromFile(fileURL: url) { extractedText, error in
                DispatchQueue.main.async {
                    isExtractingResume = false
                    if let extractedText = extractedText {
                        self.extractedResumeText = extractedText
                        print(extractedText)
                        self.resumeUploadStatus = "Upload success!"
                    } else {
                        self.resumeUploadStatus = "Upload failed: \(error ?? "Unknown error")"
                    }
                    // Stop accessing after done
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            }
        } else {
            resumeUploadStatus = "Upload failed: Unsupported file type."
        }
    }

    // Handles removing the selected resume file
    private func removeSelectedResumeFile() {
        selectedResumeFile = nil
        resumeUploadStatus = nil
        extractedResumeText = nil
    }
    
    // Handles fetching job description from URL
    private func fetchJobDescription() {
        guard !jobLink.isEmpty else { return }
        
        isFetchingJob = true
        jobFetchStatus = "Fetching job description..."
        
        scrapeJobPosting(url: jobLink) { jobDescription, error in
            DispatchQueue.main.async {
                isFetchingJob = false
                if let jobDescription = jobDescription {
                    self.jobDescription = jobDescription
                    self.jobFetchStatus = "Job description fetched successfully!"
                } else {
                    self.jobFetchStatus = "Failed to fetch job description: \(error ?? "Unknown error")"
                }
            }
        }
    }

    // Triggers the backend analysis and updates state with results
    private func generateOptimizedResume() {
        print("generateOptimizedResume")
        let resumeTextToAnalyze: String
        if let fileText = extractedResumeText, selectedResumeFile != nil {
            resumeTextToAnalyze = fileText
        } else {
            resumeTextToAnalyze = resumeContent
        }
        guard !resumeTextToAnalyze.isEmpty else { return }
        isProcessing = true
        analyzeResume(resumeText: resumeTextToAnalyze, jobDescription: jobDescription) { score, justification, suggestions in
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
    @Binding var selectedResumeFile: URL?
    @Binding var resumeUploadStatus: String?
    @Binding var showingFilePicker: Bool
    let onFileSelected: (URL) -> Void
    let onRemoveFile: () -> Void

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
            // Show selected file with icon, name, X to remove, and upload status
            if let fileURL = selectedResumeFile {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.teal)
                    Text(fileURL.lastPathComponent)
                        .font(.body)
                    if let status = resumeUploadStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("success") ? .green : (status.contains("Uploading") ? .orange : .red))
                    }
                    Button(action: onRemoveFile) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            // Text area for pasting resume content
            if selectedResumeFile == nil {
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
    @Binding var isFetchingJob: Bool
    @Binding var jobFetchStatus: String?
    let onFetchJob: () -> Void
    
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
            // Job link field with fetch functionality
            HStack {
                TextField("https://example.com/job-posting", text: $jobLink)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: onFetchJob) {
                    if isFetchingJob {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Fetch")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(jobLink.isEmpty || isFetchingJob)
            }
            // Show fetch status
            if let status = jobFetchStatus {
                Text(status)
                    .font(.caption)
                    .foregroundColor(status.contains("successfully") ? .green : (status.contains("Fetching") ? .orange : .red))
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
    print("analyzeResumeFile")
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

// Calls the backend to extract resume text from a file (PDF/DOCX)
func extractResumeTextFromFile(fileURL: URL, completion: @escaping (String?, String?) -> Void) {
    print("extractResumeTextFromFile")
    guard let url = URL(string: "http://127.0.0.1:8000/extract_resume_text_file") else {
        completion(nil, "Invalid backend URL")
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    var data = Data()
    // Add file data
    if let fileData = try? Data(contentsOf: fileURL) {
        print("fileData")
        let filename = fileURL.lastPathComponent
        let mimetype = fileURL.pathExtension.lowercased() == "pdf" ? "application/pdf" : "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        print("Upload body size: \(data.count) bytes")
        request.httpBody = data
    } else {
        completion(nil, "Could not read file data")
        print("Could not read file data")
        
        return
    }
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(nil, error.localizedDescription)
            return
        }
        guard let data = data else {
            completion(nil, "No data received")
            return
        }
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resumeText = json["resume_text"] as? String {
                completion(resumeText, nil)
            } else {
                completion(nil, "Failed to parse response")
            }
        } catch {
            completion(nil, error.localizedDescription)
        }
    }.resume()
}

// Calls the backend to scrape job description from a URL
func scrapeJobPosting(url: String, completion: @escaping (String?, String?) -> Void) {
    guard let backendURL = URL(string: "http://127.0.0.1:8000/scrape_job_posting") else {
        completion(nil, "Invalid backend URL")
        return
    }
    
    var request = URLRequest(url: backendURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["url": url]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    print("Scraping job posting from URL: \(url)")
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network error: \(error)")
            completion(nil, error.localizedDescription)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status: \(httpResponse.statusCode)")
        }
        
        guard let data = data else {
            print("No data received")
            completion(nil, "No data received")
            return
        }
        
        print("Received scraping response: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let jobDescription = json["job_description"] as? String {
                completion(jobDescription, nil)
            } else {
                completion(nil, "Failed to parse response")
            }
        } catch {
            print("JSON decode error: \(error)")
            completion(nil, error.localizedDescription)
        }
    }.resume()
}
