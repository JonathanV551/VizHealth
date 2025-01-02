import SwiftUI
import Charts

struct CountyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let county: String
    let state: String
    @ObservedObject var viewModel: HealthDataViewModel
    @State private var selectedMeasure: String?
    @State private var selectedYearSpan: String?
    @State private var valueFilter: ValueFilter = .all
    @State private var showChart = false
    
    enum ValueFilter: Hashable {
        case all
        case above(Double)
        case below(Double)
        
        var description: String {
            switch self {
            case .all: return "All Values"
            case .above(let value): return "Above \(value)/100k"
            case .below(let value): return "Below \(value)/100k"
            }
        }
        
        static let options: [ValueFilter] = [
            .all,
            .above(50),
            .below(50)
        ]
    }
    
    var countyRecords: [HealthRecord] {
        var filtered = viewModel.getCountyRecords(county: county, state: state)
        
        if let measure = selectedMeasure {
            filtered = filtered.filter { $0.measureName == measure }
        }
        
        if let yearSpan = selectedYearSpan {
            filtered = filtered.filter { $0.yearSpan == yearSpan }
        }
        
        switch valueFilter {
        case .all: break
        case .above(let value):
            filtered = filtered.filter { $0.rawValue > value }
        case .below(let value):
            filtered = filtered.filter { $0.rawValue < value }
        }
        
        return filtered.sorted { $0.yearSpan < $1.yearSpan }
    }
    
    var availableMeasures: [String] {
        Array(Set(countyRecords.map(\.measureName))).sorted()
    }
    
    var availableYears: [String] {
        Array(Set(countyRecords.map(\.yearSpan))).sorted()
    }
    
    // Define the custom accent color
    private let accentColor = Color(red: 0.2, green: 0.3, blue: 0.5)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with better visual hierarchy
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(county), \(state)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.primary)
                    
                    if let selectedMeasure = selectedMeasure {
                        Text(selectedMeasure)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Filters with better styling
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filters")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        filterPicker("Measure", selection: $selectedMeasure, options: availableMeasures)
                        filterPicker("Year", selection: $selectedYearSpan, options: availableYears)
                        
                        Picker("Value Range", selection: $valueFilter) {
                            ForEach(ValueFilter.options, id: \.self) { filter in
                                Text(filter.description).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                
                // Chart Section with better styling
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show Trend Chart", isOn: $showChart)
                        .padding(.horizontal)
                        .tint(.blue)
                    
                    if showChart {
                        trendChart
                    }
                }
                
                // Data List with better styling
                LazyVStack(spacing: 12) {
                    ForEach(countyRecords) { record in
                        HealthDataRow(record: record)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.resetToHome()
                    dismiss()
                } label: {
                    Image(systemName: "house.fill")
                        .foregroundColor(Theme.primaryColor)
                }
            }
        }
        .tint(Theme.primaryColor)
        .background(Color(.systemGroupedBackground))
    }
    
    private func filterPicker<T: Hashable>(_ title: String, selection: Binding<T?>, options: [T]) -> some View where T: CustomStringConvertible {
        Menu {
            Button("All \(title)s", action: { selection.wrappedValue = nil })
            ForEach(options, id: \.self) { option in
                Button(option.description) { selection.wrappedValue = option }
            }
        } label: {
            HStack {
                Text(selection.wrappedValue?.description ?? "All \(title)s")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .frame(minHeight: 44)
        }
    }
    
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(countyRecords) { record in
                LineMark(
                    x: .value("Year", record.yearSpan),
                    y: .value("Value", selectedMeasure != nil ? record.rawValue : normalizedValue(for: record))
                )
                .foregroundStyle(measureColor(for: record.measureName))
                .foregroundStyle(by: .value("Measure", record.measureName))
            }
            .chartForegroundStyleScale(
                domain: availableMeasures,
                range: availableMeasures.map { measureColor(for: $0) }
            )
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom, spacing: 20)
            .frame(height: 300)
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var dataList: some View {
        LazyVStack(spacing: 12) {
            ForEach(countyRecords) { record in
                HealthDataRow(record: record)
            }
        }
        .padding(.horizontal)
    }
    
    private func measureColor(for measureName: String) -> Color {
        if let measure = HealthMeasure(rawValue: measureName) {
            return measure.color
        }
        // Generate a consistent color for unknown measures
        let hash = abs(measureName.hashValue)
        return Color(
            hue: Double(hash % 256) / 256,
            saturation: 0.7,
            brightness: 0.9
        )
    }
    
    // Add helper function to normalize values
    private func normalizedValue(for record: HealthRecord) -> Double {
        let measureRecords = countyRecords.filter { $0.measureName == record.measureName }
        let maxValue = measureRecords.map(\.rawValue).max() ?? 1.0
        return (record.rawValue / maxValue) * 100 // Convert to percentage
    }
}

struct HealthDataRow: View {
    let record: HealthRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.measureName)
                .font(.headline)
            
            HStack {
                Text("Year: \(record.yearSpan)")
                Spacer()
                Text("Value: \(String(format: "%.1f", record.rawValue))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        CountyDetailView(
            county: "Albany",
            state: "New York",
            viewModel: HealthDataViewModel()
        )
    }
} 