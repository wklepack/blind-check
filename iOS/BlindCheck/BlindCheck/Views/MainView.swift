//
//  MainView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = BlindCheckViewModel()
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Grid Overview Tab
            NavigationView {
                GridView(viewModel: viewModel)
                    .navigationTitle("Marker Grid")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: {
                                    showingExportSheet = true
                                }) {
                                    Label("Export Report", systemImage: "square.and.arrow.up")
                                }
                                
                                Button(action: {
                                    viewModel.loadSampleData()
                                }) {
                                    Label("Reset Data", systemImage: "arrow.clockwise")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Grid", systemImage: "square.grid.3x3")
            }
            .tag(0)
            
            // Validation Status Tab
            NavigationView {
                ValidationListView(viewModel: viewModel)
                    .navigationTitle("Validation Status")
            }
            .tabItem {
                Label("Status", systemImage: "checkmark.seal")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportReportView(report: viewModel.exportValidationReport())
        }
    }
}

struct ValidationListView: View {
    @ObservedObject var viewModel: BlindCheckViewModel
    
    var body: some View {
        List {
            Section {
                StatCard(
                    title: "Total Markers",
                    value: "\(viewModel.allMarkers.count)",
                    icon: "square.grid.3x3",
                    color: .blue
                )
                
                StatCard(
                    title: "Validated",
                    value: "\(validatedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Pending",
                    value: "\(viewModel.allMarkers.count - validatedCount)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            Section("All Markers") {
                ForEach(sortedMarkers) { marker in
                    MarkerRow(marker: marker, result: viewModel.validationResults[marker.id])
                        .onTapGesture {
                            viewModel.selectMarkerAt(marker.gridPosition)
                        }
                }
            }
        }
    }
    
    private var validatedCount: Int {
        viewModel.allMarkers.values.filter { $0.isValidated }.count
    }
    
    private var sortedMarkers: [MarkerData] {
        viewModel.allMarkers.values.sorted { m1, m2 in
            if m1.gridPosition.row == m2.gridPosition.row {
                return m1.gridPosition.column < m2.gridPosition.column
            }
            return m1.gridPosition.row < m2.gridPosition.row
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MarkerRow: View {
    let marker: MarkerData
    let result: ValidationResult?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(marker.name)
                    .font(.headline)
                
                Text("Position: (\(marker.gridPosition.row), \(marker.gridPosition.column))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let date = marker.validationDate {
                    Text("Validated: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let result = result {
                ValidationBadge(status: result.status)
            } else if marker.isValidated {
                ValidationBadge(status: .valid)
            } else {
                ValidationBadge(status: .notScanned)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ValidationBadge: View {
    let status: ValidationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var color: Color {
        switch status {
        case .valid: return .green
        case .partialMatch: return .orange
        case .invalid: return .red
        case .notScanned: return .gray
        }
    }
    
    private var text: String {
        switch status {
        case .valid: return "Valid"
        case .partialMatch: return "Partial"
        case .invalid: return "Invalid"
        case .notScanned: return "Pending"
        }
    }
}

struct ExportReportView: View {
    let report: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Validation Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        UIPasteboard.general.string = report
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
}
