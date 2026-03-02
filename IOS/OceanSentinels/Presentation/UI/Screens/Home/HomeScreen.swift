import SwiftUI
import CoreLocation

// MARK: - HomeScreen

struct HomeScreen: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AnalyticsViewModel.self) private var analyticsViewModel
    @Environment(WeatherViewModel.self) private var weatherViewModel
    @Environment(IncidentViewModel.self) private var incidentViewModel
    @Environment(NavigationRouter.self) private var router

    @State private var currentTime = ""
    @State private var displayLocation = "Chennai, India"
    @State private var timer: Timer?

    private var currentUser: User? {
        if case .authenticated(let user, _) = authViewModel.userSession { return user }
        return nil
    }
    private var userRole: UserRole { currentUser?.role ?? .`public` }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                marqueeSection
                    .padding(.top, 16)
                liveDashboardCard
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                alertsBannerCard
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                weatherBannerCard
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                quickActionsSection
                    .padding(.top, 24)
                howItWorksSection
                    .padding(.top, 24)
                Spacer(minLength: 24)
            }
        }
        .task {
            updateTime()
            analyticsViewModel.loadDashboardAnalytics()
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            // Logo
            Circle()
                .fill(Color.oceanSecondary)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "water.waves")
                        .foregroundStyle(Color.oceanPrimary)
                )
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentTime).font(.caption)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.caption)
                    Text(displayLocation).font(.caption)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Marquee

    private var marqueeSection: some View {
        let text = weatherViewModel.weatherAlerts.isEmpty
            ? "No active weather alerts for your region   •   Ocean Sentinels — Monitoring coastal safety"
            : weatherViewModel.weatherAlerts.map(\.description).joined(separator: "   •   ")

        return Text(text)
            .font(.caption)
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color.oceanPrimary, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Live Dashboard

    private var liveDashboardCard: some View {
        VStack(spacing: 16) {
            HStack {
                livePulseBadge
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "scope").font(.caption2).foregroundStyle(Color.oceanInfo)
                    Text("\(analyticsViewModel.dashboardAnalytics?.activeIncidents ?? 0) Active Zones")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.oceanSecondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }

            roleSpecificDashboardContent

            // Status indicators
            HStack(spacing: 24) {
                statusIndicator(icon: "bell.badge.fill", label: "Alerts", isActive: (analyticsViewModel.dashboardAnalytics?.activeIncidents ?? 0) > 0)
                statusIndicator(icon: "wifi", label: "Network", isActive: true)
                statusIndicator(icon: "icloud.fill", label: "Sync", isActive: true)
            }
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    @ViewBuilder
    private var roleSpecificDashboardContent: some View {
        if let analytics = analyticsViewModel.dashboardAnalytics {
            switch userRole {
            case .`public`:
                if let weather = weatherViewModel.currentWeather {
                    VStack(spacing: 8) {
                        Text("Local Weather — \(weather.location.name)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.oceanInfo)
                        HStack(spacing: 24) {
                            dashboardStat(value: "\(Int(weather.current.tempC))°C", label: "Temp", color: .oceanInfo)
                            dashboardStat(value: "\(weather.current.humidity)%", label: "Humidity", color: .oceanInfo)
                            dashboardStat(value: String(weather.current.condition.text.prefix(12)), label: "Condition", color: .oceanSuccess)
                        }
                    }
                } else if analyticsViewModel.isLoading {
                    ProgressView()
                }
            case .rescueTeam:
                VStack(spacing: 8) {
                    Text("Assigned Jobs").font(.subheadline.weight(.semibold)).foregroundStyle(Color.oceanInfo)
                    HStack(spacing: 24) {
                        dashboardStat(value: "\(incidentViewModel.assignedIncidents.filter { $0.status == .inProgress || $0.status == .verified }.count)", label: "Active", color: .oceanDanger)
                        dashboardStat(value: "\(incidentViewModel.assignedIncidents.filter { $0.status == .verified }.count)", label: "Pending", color: .oceanWarning)
                        dashboardStat(value: "\(incidentViewModel.assignedIncidents.filter { $0.status == .resolved }.count)", label: "Completed", color: .oceanSuccess)
                    }
                }
            default:
                HStack(spacing: 16) {
                    dashboardStat(value: "\(analytics.totalIncidents)", label: "Total", color: .oceanInfo)
                    dashboardStat(value: "\(analytics.activeIncidents)", label: "Active", color: .oceanDanger)
                    dashboardStat(value: "\(analytics.pendingCount)", label: "Pending", color: .oceanWarning)
                    dashboardStat(value: "\(analytics.resolvedCount)", label: "Resolved", color: .oceanSuccess)
                }
            }
        } else if analyticsViewModel.isLoading {
            ProgressView()
        } else {
            Text("LIVE DASHBOARD").font(.headline).foregroundStyle(Color.oceanInfo)
        }
    }

    // MARK: - Banner Cards

    private var alertsBannerCard: some View {
        Button { router.mainPath.append(AppRoute.incidentsDashboard) } label: {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill").font(.title3).foregroundStyle(Color.oceanPrimary)
                Text("Alerts").font(.headline).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .frame(height: 77)
            .background(Color.oceanInfo.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var weatherBannerCard: some View {
        Button { router.mainPath.append(AppRoute.weather) } label: {
            HStack {
                Image(systemName: "cloud.fill").font(.title3).foregroundStyle(Color.oceanPrimary)
                VStack(alignment: .leading) {
                    Text("Weather Forecast").font(.headline).foregroundStyle(.white)
                    if let w = weatherViewModel.currentWeather {
                        Text("\(Int(w.current.tempC))°C • \(w.current.condition.text)")
                            .font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                if let w = weatherViewModel.currentWeather {
                    Text("\(Int(w.current.tempC))°").font(.title3.bold()).foregroundStyle(Color.oceanPrimary)
                }
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.oceanInfo.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions").font(.title3.bold()).padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickActionCard(title: "Live Map", icon: "map.fill", color: .oceanSecondary) {
                        router.mainPath.append(AppRoute.map)
                    }
                    quickActionCard(title: "Report Hazard", icon: "exclamationmark.triangle.fill", color: .oceanDanger) {
                        router.mainPath.append(AppRoute.reportIncident)
                    }
                    quickActionCard(title: "My Reports", icon: "clock.arrow.circlepath", color: .purple) {
                        router.mainPath.append(AppRoute.myReports)
                    }
                    if userRole == .admin || userRole == .rescueTeam || userRole == .authority {
                        quickActionCard(title: "All Incidents", icon: "list.bullet.rectangle", color: .orange) {
                            router.mainPath.append(AppRoute.incidentsDashboard)
                        }
                        quickActionCard(title: "Analytics", icon: "chart.bar.fill", color: .green) {
                            router.mainPath.append(AppRoute.analytics)
                        }
                    }
                    if userRole == .admin {
                        quickActionCard(title: "Admin Panel", icon: "gearshape.2.fill", color: .oceanDanger) {
                            router.mainPath.append(AppRoute.adminDashboard)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works").font(.title3.bold()).padding(.horizontal, 16)

            VStack(spacing: 12) {
                howItWorksCard(number: "1", title: "Spot a Hazard", desc: "See pollution, debris, or marine life in distress?", icon: "eye.fill", color: .purple)
                howItWorksCard(number: "2", title: "Report It", desc: "Take a photo and share the location details", icon: "camera.fill", color: .orange)
                howItWorksCard(number: "3", title: "Track Response", desc: "Watch as authorities respond and resolve the issue", icon: "arrow.triangle.2.circlepath", color: .green)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func dashboardStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func quickActionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(title).font(.caption2.weight(.medium)).foregroundStyle(color)
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func howItWorksCard(number: String, title: String, desc: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.title.bold())
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon).font(.title3).foregroundStyle(color)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var livePulseBadge: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 10, height: 10)
            Text("LIVE").font(.caption.bold()).foregroundStyle(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func statusIndicator(icon: String, label: String, isActive: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color(.systemGray))
            Circle()
                .fill(isActive ? Color.oceanSuccess : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 1))
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTime()
        }
    }

    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss 'Hrs,' EEEE"
        currentTime = formatter.string(from: Date())
    }
}
