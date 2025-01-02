import Foundation
import TabularData

class HealthTransformer {
    static func transform(csvData: Data) throws -> [HealthRecord] {
        guard let csvString = String(data: csvData, encoding: .utf8) else {
            throw ParsingError.invalidEncoding
        }
        
        let rows = csvString.components(separatedBy: .newlines)
        guard rows.count > 1 else {
            throw ParsingError.invalidFormat
        }
        
        let headers = rows[0].components(separatedBy: ",")
        return rows.dropFirst().compactMap { row in
            let values = row.components(separatedBy: ",")
            guard values.count == headers.count else { return nil }
            
            return HealthRecord(
                id: UUID(),
                state: values[0].trimmingCharacters(in: .whitespacesAndNewlines),
                county: values[1].trimmingCharacters(in: .whitespacesAndNewlines),
                stateCode: values[2].trimmingCharacters(in: .whitespacesAndNewlines),
                countyCode: values[3].trimmingCharacters(in: .whitespacesAndNewlines),
                yearSpan: values[4].trimmingCharacters(in: .whitespacesAndNewlines),
                measureName: values[5].trimmingCharacters(in: .whitespacesAndNewlines),
                rawValue: Double(values[9].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0,
                releaseYear: values[7].trimmingCharacters(in: .whitespacesAndNewlines),
                fipsCode: values[3].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
    
    enum ParsingError: Error {
        case invalidEncoding
        case invalidFormat
    }
    
    static func groupByCounty(_ records: [HealthRecord]) -> [String: [HealthRecord]] {
        Dictionary(grouping: records) { $0.displayTitle }
    }
    
    static func filterRecords(_ records: [HealthRecord], 
                            yearSpan: String? = nil,
                            measureName: String? = nil,
                            sortOrder: SortOrder = .forward) -> [HealthRecord] {
        var filtered = records
        
        if let yearSpan = yearSpan {
            filtered = filtered.filter { $0.yearSpan == yearSpan }
        }
        
        if let measureName = measureName {
            filtered = filtered.filter { $0.measureName == measureName }
        }
        
        return filtered.sorted { 
            sortOrder == .forward ? $0.rawValue < $1.rawValue : $0.rawValue > $1.rawValue 
        }
    }
}

enum SortOrder {
    case forward
    case reverse
} 