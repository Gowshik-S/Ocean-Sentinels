import SwiftUI

// MARK: - AlertsScreen

struct AlertsScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel

    @State private var selectedCategory = "All"
    @State private var liveUpdatedTime = ""

    private let categories = ["All", "Pollution", "Marine Life", "Weather", "Navigation"]

    var body: some View {
        let incidents = viewModel.incidents
        let totalReports = incidents.count
        let inProgressCount = incidents.filter { $0.status == .inProgress }.count
        let criticalCount = incidents.filter { $0.urgency == .critical }.count
        let lastHourReports = incidents.filter { $0.createdAt.timeIntervalSinceNow > -3600 }.count

        List {
            // 2×2 Stat Cards
            Section {
                HStack(spacing: 10) {
                    AlertStatCard(label: "Active Hazards", value: "\(inProgressCount)", icon: "exclamationmark.triangle.fill", color: .oceanDanger, fraction: totalReports > 0 ? Double(inProgressCount) / Double(totalReports) : 0)
                    AlertStatCard(label: "Critical Alerts", value: "\(criticalCount)", icon: "bell.badge.fill", color: .oceanWarning, fraction: totalReports > 0 ? Double(criticalCount) / Double(totalReports) : 0)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                HStack(spacing: 10) {
                    AlertStatCard(label: "Total Reports", value: "\(totalReports)", icon: "eye.fill", color: .oceanInfo, fraction: 1)
                    AlertStatCard(label: "Last Hour", value: "\(lastHourReports)", icon: "alarm.fill", color: .oceanSuccess, fraction: totalReports > 0 ? Double(lastHourReports) / Double(totalReports) : 0)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Filter
            Section {
                HStack {
                    Label("Filters", systemImage: "line.3.horizontal.decrease")
                    Spacer()
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Refresh row
            Section {
                HStack {
                    Button { viewModel.loadIncidents(filters: nil) } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("Live Updated: \(liveUpdatedTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Recent Alerts
            if !incidents.isEmpty {
                Section("Recent Alerts") {
                    ForEach(incidents.prefix(10), id: \.id) { incident in
                        NavigationLink(value: AppRoute.incidentDetail(incidentId: incident.id)) {
                            AlertListRow(incident: incident)
                        }
                    }
                }
            }

            if viewModel.isLoading {
                Section { ProgressView().frame(maxWidth: .infinity) }
            }
        }
        .compatInsetGroupedListStyle()
        .navigationTitle("Alerts")
        .toolbar {
            ToolbarItem(placement: .compatTopBarTrailing) {
                Button { viewModel.loadIncidents(filters: nil) } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            viewModel.loadIncidents(filters: nil)
            updateLiveTime()
        }
    }

    private func updateLiveTime() {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        liveUpdatedTime = fmt.string(from: Date())
    }
}

// MARK: - AlertStatCard

private struct AlertStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(color, in: RoundedRectangle(cornerRadius: 7))
                Text(label).font(.caption2.weight(.medium))
            }
            Text(value).font(.title3.bold())
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.compatSystemBackground).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * min(max(fraction, 0), 1), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AlertListRow

private struct AlertListRow: View {
    let incident: Incident

    private var urgencyColor: Color {
        switch incident.urgency {
        case .critical: return .oceanDanger
        case .high: return .orange
        case .medium: return .oceanPrimary
        case .low: return .oceanSuccess
        }
    }

    private var statusColor: Color {
        switch incident.status {
        case .resolved: return .green
        case .inProgress: return .orange
        case .pending: return .purple
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(urgencyColor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(incident.hazardType.displayName).font(.subheadline.weight(.medium))
                Text(incident.location).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(incident.status.value.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption2)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2), in: Capsule())
        }
    }
}
