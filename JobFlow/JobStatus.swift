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

    var locationTypeEnum: LocationType {
        get { LocationType(rawValue: self.locationType ?? "") ?? .remote }
        set { self.locationType = newValue.rawValue }
    }

    var appliedViaEnum: AppliedVia {
        get { AppliedVia(rawValue: self.appliedVia ?? "") ?? .other }
        set { self.appliedVia = newValue.rawValue }
    }
}

enum LocationType: String, CaseIterable, Identifiable {
    case remote = "Remote"
    case hybrid = "Hybrid"
    case inOffice = "In Office"

    var id: String { self.rawValue }
}

enum AppliedVia: String, CaseIterable, Identifiable {
    case linkedIn = "LinkedIn"
    case indeed = "Indeed"
    case companySite = "Company Site"
    case referral = "Referral"
    case glassdoor = "Glassdoor"
    case builtIn = "BuiltIn"
    case other = "Other"

    var id: String { self.rawValue }
}


