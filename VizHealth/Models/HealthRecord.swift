import Foundation

struct HealthRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let state: String
    let county: String
    let stateCode: String
    let countyCode: String
    let yearSpan: String
    let measureName: String
    let rawValue: Double
    let releaseYear: String
    let fipsCode: String
    
    var displayTitle: String {
        return "\(county), \(state)"
    }
} 