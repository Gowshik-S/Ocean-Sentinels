import SwiftUI

// MARK: - AnalyticsScreen

struct AnalyticsScreen: View {
    @Environment(AnalyticsViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Stats Grid (2×2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatsCard(title: "Total Incidents", value: "\(viewModel.dashboardAnalytics?.totalIncidents ?? 0)", icon: "doc.text.fill", iconColor: .oceanPrimary)
                    StatsCard(title: "Active Incidents", value: "\(viewModel.dashboardAnalytics?.activeIncidents ?? 0)", icon: "exclamationmark.triangle.fill", iconColor: .oceanWarning)
                    StatsCard(title: "Pending Review", value: "\(viewModel.dashboardAnalytics?.pendingCount ?? 0)", icon: "clock.fill", iconColor: .orange)
                    StatsCard(title: "Resolved", value: "\(viewModel.dashboardAnalytics?.resolvedIncidents ?? 0)", icon: "checkmark.circle.fill", iconColor: .oceanSuccess)
                }
                .padding(.horizontal)

                // Resolution Rate
                if let analytics = viewModel.dashboardAnalytics, analytics.totalIncidents > 0 {
                    let rate = Double(analytics.resolvedIncidents) / Double(analytics.totalIncidents) * 100
                    SectionCard(title: "Resolution Rate") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill").foregroundStyle(Color.oceanPrimary)
                                Text("Resolution Rate").font(.headline)
                                Spacer()
                                Text(String(format: "%.1f%%", rate))
                                    .font(.title3.bold())
                                    .foregroundStyle(rate >= 70 ? Color.oceanSuccess : rate >= 40 ? Color.oceanWarning : Color.oceanDanger)
                            }
                            ProgressView(value: rate / 100)
                                .tint(rate >= 70 ? Color.oceanSuccess : rate >= 40 ? Color.oceanWarning : Color.oceanDanger)
                                .scaleEffect(y: 2, anchor: .center)
                                .clipShape(Capsule())
                            Text("\(analytics.resolvedIncidents) of \(analytics.totalIncidents) incidents resolved")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                // Distribution by Hazard Type
                if let distribution = viewModel.distribution?.byHazardType, !distribution.isEmpty {
                    SectionCard(title: "Distribution by Type") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "chart.pie.fill").foregroundStyle(Color.oceanPrimary)
                                Text("Distribution by Type").font(.headline)
                            }
                            ForEach(distribution) { item in
                                HStack {
                                    Circle()
                                        .fill(hazardColor(item.label))
                                        .frame(width: 10, height: 10)
                                    Text(HazardType.fromValue(item.label)?.displayName ?? item.label)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(item.value)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Distribution by Urgency
                if let distribution = viewModel.distribution?.byUrgency, !distribution.isEmpty {
                    SectionCard(title: "Distribution by Urgency") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.oceanWarning)
                                Text("Distribution by Urgency").font(.headline)
                            }
                            ForEach(distribution) { item in
                                HStack {
                                    Circle()
                                        .fill(urgencyColor(item.label))
                                        .frame(width: 10, height: 10)
                                    Text(item.label.capitalized)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(item.value)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .refreshable { viewModel.loadAllAnalytics() }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading analytics...")
            }
        }
        .task { viewModel.loadAllAnalytics() }
    }

    private func hazardColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "oil_spill": return .black
        case "illegal_fishing": return .oceanDanger
        case "vessel_distress": return .orange
        case "water_pollution": return .brown
        case "coral_damage": return .pink
        case "coastal_erosion": return .yellow
        case "wildlife_threat": return .green
        case "weather_hazard": return .oceanInfo
        default: return .gray
        }
    }

    private func urgencyColor(_ urgency: String) -> Color {
        switch urgency.lowercased() {
        case "critical": return .oceanDanger
        case "high": return .orange
        case "medium": return .oceanWarning
        case "low": return .oceanSuccess
        default: return .gray
        }
    }
}
