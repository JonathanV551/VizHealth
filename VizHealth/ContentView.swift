//
//  ContentView.swift
//  VizHealth
//
//  Created by Jonathan Vadala on 12/13/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HealthDataViewModel()
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                // Title section with gradient background
                VStack(spacing: 4) {
                    Text("VizHealth")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("Visualize. Understand. Thrive.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    Text("by Jonathan Vadala")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.3, blue: 0.5),
                            Color(red: 0.4, green: 0.3, blue: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Search and Filter section
                VStack(spacing: 12) {
                    SearchBar(text: $viewModel.searchText)
                    
                    Menu {
                        Button("All States", action: { viewModel.selectedState = nil })
                        ForEach(viewModel.availableStates, id: \.self) { state in
                            Button(state) { viewModel.selectedState = state }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedState ?? "Select State")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Content area
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredCounties) { countyId in
                                NavigationLink(destination: CountyDetailView(county: countyId.county, state: countyId.state, viewModel: viewModel)) {
                                    CountyRowView(county: countyId.county, state: countyId.state)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadData()
            }
        }
        .environment(\.navigationPath, path)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
            
            TextField("Search counties...", text: $text)
                .font(.body)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CountyRowView: View {
    let county: String
    let state: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(county), \(state)")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
}

// Add this environment key for navigation
private struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: NavigationPath = NavigationPath()
}

extension EnvironmentValues {
    var navigationPath: NavigationPath {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}
