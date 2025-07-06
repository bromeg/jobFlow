import Foundation

enum JobStatus: String, CaseIterable, Identifiable {
    case applied = "Applied"
    case initialScreen = "Initial Screen"
    case interview = "Interview"
    case waiting = "Waiting"
    case offer = "Offer"
    case rejected = "Rejected"
    case scheduling = "Scheduling"

    var id: String { self.rawValue }
}

extension JobApplication {
    var jobStatusEnum: JobStatus {
        get {
            JobStatus(rawValue: self.status ?? "") ?? .applied
        }
        set {
            self.status = newValue.rawValue
            if newValue == .initialScreen || newValue == .interview {
                self.hasReachedInterview = true
            }
        }
    }
}

