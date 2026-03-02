import SwiftUI
// ⚠️ ANDROID ONLY — Mapbox Maps iOS SDK needed: https://docs.mapbox.com/ios/maps/guides/install/
// TODO: Add MapboxMaps via SPM and replace placeholder

// MARK: - MapScreen

struct MapScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel

    var initialLat: Double?
    var initialLng: Double?

    private var defaultLat: Double { initialLat ?? 19.0760 }
    private var defaultLng: Double { initialLng ?? 72.8777 }

    @State private var selectedIncident: Incident?
    @State private var showSheet = false

    var body: some View {
        ZStack {
            // Placeholder map — replace with MapboxMaps MapView integration
            mapPlaceholder

            // Legend
            VStack {
                HStack {
                    Spacer()
                    legendView
                }
                Spacer()
                HStack {
                    incidentCountBadge
                    Spacer()
                }
            }
            .padding(8)

            // Loading
            if viewModel.isLoading {
                VStack {
                    ProgressView().tint(Color.oceanPrimary)
                    Spacer()
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Live Incident Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button { viewModel.loadIncidents(filters: nil) } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    NavigationLink(value: AppRoute.reportIncident) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            if let incident = selectedIncident {
                incidentSheet(incident)
            }
        }
        .task {
            viewModel.loadIncidents(filters: IncidentFilters(size: 100))
        }
    }

    // MARK: - Placeholder Map

    private var mapPlaceholder: some View {
        ZStack {
            Color.oceanInfo.opacity(0.1).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "map.fill").font(.system(size: 48)).foregroundStyle(Color.oceanInfo.opacity(0.4))
                Text("Map View").font(.headline).foregroundStyle(Color.oceanInfo)
                Text("Integrate MapboxMaps SDK").font(.caption).foregroundStyle(.secondary)

                if !viewModel.incidents.isEmpty {
                    Divider().padding(.vertical, 8)
                    mapIncidentList
                }
            }
        }
    }

    private var mapIncidentList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.incidents.filter { $0.latitude != nil && $0.longitude != nil }, id: \.id) { incident in
                    Button {
                        selectedIncident = incident
                        showSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor(incident.status))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading) {
                                Text(incident.hazardType.displayName).font(.caption.weight(.medium))
                                Text(incident.location).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func statusColor(_ status: IncidentStatus) -> Color {
        switch status {
        case .pending: return .oceanWarning
        case .verified: return .oceanInfo
        case .inProgress: return .oceanPrimary
        case .resolved: return .oceanSuccess
        default: return .gray
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legend").font(.caption2.weight(.medium)).foregroundStyle(Color.oceanPrimary)
            legendItem(color: .oceanWarning, label: "Pending")
            legendItem(color: .oceanInfo, label: "Verified")
            legendItem(color: .oceanPrimary, label: "In Progress")
            legendItem(color: .oceanSuccess, label: "Resolved")
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption2)
        }
    }

    private var incidentCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse").font(.caption).foregroundStyle(Color.oceanPrimary)
            Text("\(viewModel.incidents.count) incidents").font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Bottom Sheet

    private func incidentSheet(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.hazardType.displayName).font(.title3).foregroundStyle(Color.oceanPrimary)
                    Text(incident.referenceId).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: incident.status)
            }

            HStack(spacing: 8) {
                HazardTypeBadge(hazardType: incident.hazardType)
                UrgencyBadge(urgency: incident.urgency)
            }

            Text(incident.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)

            HStack(spacing: 8) {
                Image(systemName: "location.fill").font(.caption).foregroundStyle(Color.oceanPrimary)
                Text(incident.location.isEmpty ? "\(String(format: "%.4f", incident.latitude ?? 0)), \(String(format: "%.4f", incident.longitude ?? 0))" : incident.location)
                    .font(.caption).foregroundStyle(.secondary)
            }

            NavigationLink(value: AppRoute.incidentDetail(incidentId: incident.id)) {
                Text("View Full Details")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.oceanPrimary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
