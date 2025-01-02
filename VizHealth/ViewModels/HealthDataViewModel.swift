import Foundation
import SwiftUI

@MainActor
class HealthDataViewModel: ObservableObject {
    static let dataURL = URL(string: "https://public.tableau.com/app/sample-data/County_Health_Rankings.csv")!
    
    @Published private(set) var records: [HealthRecord] = []
    @Published private(set) var filteredCounties: [CountyIdentifier] = []
    @Published private(set) var isLoading = false
    @Published var searchText = "" {
        didSet {
            updateFilteredCounties()
        }
    }
    @Published var selectedState: String? {
        didSet {
            updateFilteredCounties()
        }
    }
    
    // Improve caching with memory cache only (more reliable than UserDefaults for large datasets)
    private static var memoryCache: [HealthRecord]?
    private var countyRecordsCache: [String: [HealthRecord]] = [:]
    
    // Add CountyIdentifier struct
    struct CountyIdentifier: Hashable, Identifiable {
        let county: String
        let state: String
        
        var id: String { "\(county)-\(state)" }
    }
    
    var availableStates: [String] {
        Array(Set(records.map { $0.state })).sorted()
    }
    
    // Get unique counties with validation
    private var uniqueCounties: [CountyIdentifier] {
        let counties = records
            .filter { !$0.county.isEmpty && !$0.state.isEmpty }
            .map { CountyIdentifier(county: $0.county, state: $0.state) }
        return Array(Set(counties))
            .sorted { $0.county < $1.county }
    }
    
    // Add index for faster searching
    private var searchIndex: [String: Set<CountyIdentifier>] = [:]
    private var stateIndex: [String: Set<CountyIdentifier>] = [:]
    
    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Try memory cache first
        if let cached = Self.memoryCache {
            records = cached
            buildIndexes() // Build indexes once
            updateFilteredCounties()
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.dataURL)
            records = try HealthTransformer.transform(csvData: data)
            Self.memoryCache = records
            buildIndexes() // Build indexes once
            updateFilteredCounties()
        } catch {
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    private func buildIndexes() {
        // Build search index
        searchIndex.removeAll()
        stateIndex.removeAll()
        
        for county in uniqueCounties {
            // Index each word in county and state names
            let words = "\(county.county) \(county.state)".lowercased().split(separator: " ")
            for word in words {
                searchIndex[String(word), default: []].insert(county)
            }
            // Index by state
            stateIndex[county.state, default: []].insert(county)
        }
    }
    
    func updateFilteredCounties() {
        var filtered = uniqueCounties
        
        // Apply state filter first
        if let state = selectedState {
            filtered = filtered.filter { $0.state == state }
        }
        
        // Apply fuzzy search if there's search text
        if !searchText.isEmpty {
            let searchTerms = searchText.lowercased().split(separator: " ")
            filtered = filtered.filter { county in
                let searchableText = "\(county.county) \(county.state)".lowercased()
                // More flexible search that matches partial words
                return searchTerms.allSatisfy { term in
                    searchableText.contains(term)
                }
            }
        }
        
        filteredCounties = filtered
    }
    
    // Optimize county records retrieval
    func getCountyRecords(county: String, state: String) -> [HealthRecord] {
        let cacheKey = "\(county)-\(state)"
        
        if let cached = countyRecordsCache[cacheKey] {
            return cached
        }
        
        let filtered = records.filter { $0.county == county && $0.state == state }
        countyRecordsCache[cacheKey] = filtered
        return filtered
    }
    
    func resetToHome() {
        searchText = ""
        selectedState = nil
        updateFilteredCounties()
    }
} 