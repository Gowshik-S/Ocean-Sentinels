import SwiftUI

// MARK: - MyReportsScreen

struct MyReportsScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.incidents.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.incidents.isEmpty {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: { Text(error) } actions: {
                    Button("Try Again") { viewModel.loadMyReports() }
                }
            } else if viewModel.incidents.isEmpty {
                ContentUnavailableView {
                    Label("No Reports Yet", systemImage: "doc.text")
                } description: {
                    Text("You haven't submitted any hazard reports. Help protect our oceans by reporting incidents.")
                } actions: {
                    NavigationLink(value: AppRoute.reportIncident) {
                        Label("Report Hazard", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.oceanPrimary)
                }
            } else {
                List {
                    ForEach(viewModel.incidents, id: \.id) { incident in
                        NavigationLink(value: AppRoute.incidentDetail(incidentId: incident.id)) {
                            IncidentCardView(incident: incident)
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Reports")
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
                Button { viewModel.loadMyReports() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { viewModel.loadMyReports() }
    }
}
