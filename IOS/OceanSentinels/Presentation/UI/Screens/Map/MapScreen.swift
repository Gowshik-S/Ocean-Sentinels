import SwiftUI
import CoreLocation
import MapboxMaps

// MARK: - MapScreen

/// Live incident map powered by Mapbox Maps SDK.
/// Converted from: Android MapScreen.kt (AndroidView + CircleAnnotationManager)
struct MapScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel

    var initialLat: Double?
    var initialLng: Double?

    private var defaultLat: Double { initialLat ?? 19.0760 }
    private var defaultLng: Double { initialLng ?? 72.8777 }
    private var defaultZoom: Double { initialLat != nil ? 12.0 : 5.0 }

    @State private var selectedIncident: Incident?
    @State private var showSheet = false
    @State private var viewport: Viewport = .idle

    var body: some View {
        ZStack {
            // Mapbox Map with incident annotations
            mapView

            // Overlays
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
        .compatInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        viewModel.loadIncidents(filters: nil)
                    } label: {
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
        .onAppear {
            viewport = .camera(center: CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng), zoom: defaultZoom)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        MapReader { proxy in
            Map(viewport: $viewport) {
                // Incident annotation markers
                ForEvery(locatedIncidents) { incident in
                    MapViewAnnotation(
                        coordinate: CLLocationCoordinate2D(
                            latitude: incident.latitude ?? 0,
                            longitude: incident.longitude ?? 0
                        )
                    ) {
                        incidentMarker(incident)
                    }
                    .allowOverlap(false)
                    .allowOverlapWithPuck(false)
                }
            }
            .mapStyle(.streets)
            .ornamentOptions(OrnamentOptions(
                scaleBar: ScaleBarViewOptions(visibility: .hidden),
                compass: CompassViewOptions(visibility: .visible),
                logo: LogoViewOptions(margins: CGPoint(x: 8, y: 52)),
                attributionButton: AttributionButtonOptions(margins: CGPoint(x: 8, y: 52))
            ))
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Incident Marker

    private func incidentMarker(_ incident: Incident) -> some View {
        Button {
            selectedIncident = incident
            showSheet = true
        } label: {
            Circle()
                .fill(statusColor(incident.status))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                )
                .shadow(color: statusColor(incident.status).opacity(0.4), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var locatedIncidents: [Incident] {
        viewModel.incidents.filter { $0.latitude != nil && $0.longitude != nil }
    }

    private func statusColor(_ status: IncidentStatus) -> Color {
        switch status {
        case .pending: return .oceanWarning
        case .verified: return .oceanInfo
        case .inProgress: return .oceanPrimary
        case .resolved: return .oceanSuccess
        case .closed, .falseAlarm: return .gray
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
