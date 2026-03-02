import SwiftUI

// MARK: - MeshNetworkScreen

struct MeshNetworkScreen: View {
    @Environment(MeshViewModel.self) private var viewModel

    @State private var showReportForm = false
    @State private var description = ""
    @State private var selectedHazardType: HazardType?
    @State private var selectedUrgency: UrgencyLevel = .medium
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var isGettingLocation = false
    @State private var locationError: String?

    @StateObject private var locationManager = SimpleLocationManager()

    var body: some View {
        List {
            // Status Banner
            Section {
                meshStatusBanner
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Send State Feedback
            if viewModel.sendState != .idle {
                Section {
                    sendStateBanner
                }
            }

            // Quick Report Form
            if showReportForm {
                Section("Quick Mesh Report") {
                    quickReportForm
                }
            }

            // Tab Selector
            Section {
                Picker("Tab", selection: Binding(
                    get: { viewModel.selectedTab },
                    set: { viewModel.selectTab($0) }
                )) {
                    ForEach(MeshTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            // Message List / Peers
            if viewModel.selectedTab == .peers {
                Section { peersSection }
            } else {
                let messages = currentMessages
                if messages.isEmpty {
                    Section { emptyStateView }
                } else {
                    Section {
                        ForEach(messages, id: \.messageId) { message in
                            meshMessageCard(message)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Mesh Network")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle("", isOn: Binding(
                    get: { viewModel.meshStatus.isRunning },
                    set: { _ in viewModel.toggleMeshService() }
                ))
                .toggleStyle(.switch)
                .tint(Color.oceanSuccess)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button { showReportForm.toggle() } label: {
                Image(systemName: showReportForm ? "xmark" : "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.oceanPrimary, in: Circle())
                    .shadow(radius: 4)
            }
            .padding(20)
        }
        .onChange(of: viewModel.sendState) { _, newState in
            if case .success = newState {
                showReportForm = false
                description = ""
                selectedHazardType = nil
                latitude = ""
                longitude = ""
                locationError = nil
            }
        }
    }

    private var currentMessages: [MeshMessage] {
        switch viewModel.selectedTab {
        case .all: return viewModel.allMessages
        case .queue: return viewModel.pendingMessages
        case .delivered: return viewModel.deliveredMessages
        case .relayed: return viewModel.relayedMessages
        case .peers: return []
        }
    }

    // MARK: - Status Banner

    private var meshStatusBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(viewModel.meshStatus.isRunning ? Color.oceanSuccess : Color.gray)
                    .frame(width: 12, height: 12)
                Text(viewModel.meshStatus.isRunning ? "Mesh Active" : "Mesh Inactive")
                    .font(.headline)
                Spacer()
                Text(viewModel.meshStatus.isCodedPhySupported ? "PHY Coded" : "Standard BLE")
                    .font(.caption2.bold())
                    .foregroundStyle(viewModel.meshStatus.isCodedPhySupported ? Color.oceanInfo : Color.oceanWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        (viewModel.meshStatus.isCodedPhySupported ? Color.oceanInfo : Color.oceanWarning).opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 4)
                    )
            }

            if !viewModel.meshStatus.isBleAvailable {
                Text("Bluetooth is disabled or unavailable")
                    .font(.caption).foregroundStyle(Color.oceanDanger)
            }

            HStack(spacing: 12) {
                statItem(icon: "antenna.radiowaves.left.and.right", value: "\(viewModel.meshStatus.discoveredPeerCount)", label: "Nearby", color: .oceanPrimary)
                statItem(icon: "person.2.fill", value: "\(viewModel.meshStatus.connectedPeerCount)", label: "Connected", color: .oceanInfo)
                statItem(icon: "clock.fill", value: "\(viewModel.pendingMessages.count)", label: "Pending", color: .oceanWarning)
                statItem(icon: "checkmark.circle.fill", value: "\(viewModel.deliveredMessages.count)", label: "Delivered", color: .oceanSuccess)
                statItem(icon: "arrowshape.turn.up.right.fill", value: "\(viewModel.relayedMessages.count)", label: "Relayed", color: .oceanPrimary)
            }
        }
        .padding(16)
        .background(
            (viewModel.meshStatus.isRunning ? Color.oceanPrimary.opacity(0.1) : Color(.secondarySystemBackground)),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Send State Banner

    private var sendStateBanner: some View {
        let (color, icon, text): (Color, String, String) = {
            switch viewModel.sendState {
            case .sending:
                return (.oceanInfo, "icloud.and.arrow.up", "Sending report...")
            case .success(_, let transport, _):
                let t: String
                switch transport {
                case .internet: t = "Sent via Internet"
                case .bleCoded: t = "Sent via BLE Mesh (Long Range)"
                case .bleStandard: t = "Sent via BLE (Standard)"
                case .localQueue: t = "Queued locally — will relay when peers available"
                }
                return (.oceanSuccess, "checkmark.circle.fill", t)
            case .error(let message):
                return (.oceanDanger, "exclamationmark.circle.fill", "Error: \(message)")
            default:
                return (.clear, "", "")
            }
        }()

        return HStack(spacing: 8) {
            if case .sending = viewModel.sendState {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: icon).foregroundStyle(color)
            }
            Text(text).font(.caption).foregroundStyle(color)
            Spacer()
            if viewModel.sendState != .sending {
                Button { viewModel.resetSendState() } label: {
                    Image(systemName: "xmark").font(.caption2)
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Quick Report Form

    private var quickReportForm: some View {
        VStack(spacing: 12) {
            Text("Auto-routes via Internet → Mesh → Local Queue")
                .font(.caption).foregroundStyle(.secondary)

            OceanTextArea(label: "Description", text: $description, placeholder: "Describe the hazard...")

            Picker("Hazard Type", selection: $selectedHazardType) {
                Text("Select type").tag(HazardType?.none)
                ForEach(HazardType.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
            }
            .pickerStyle(.menu)

            Picker("Urgency", selection: $selectedUrgency) {
                ForEach(UrgencyLevel.allCases, id: \.self) { Text($0.value.capitalized).tag($0) }
            }
            .pickerStyle(.segmented)

            // Location
            HStack {
                if isGettingLocation {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: !latitude.isEmpty ? "location.fill" : "location.slash.fill")
                        .foregroundStyle(!latitude.isEmpty ? Color.oceanSuccess : Color.oceanWarning)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isGettingLocation ? "Detecting..." : !latitude.isEmpty ? "Location detected" : "Location unavailable")
                        .font(.caption.weight(.semibold))
                    if !latitude.isEmpty {
                        Text("\(latitude), \(longitude)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { fetchLocation() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(!latitude.isEmpty ? Color.oceanSuccess.opacity(0.08) : Color(.secondarySystemBackground))
            )

            if let locationError {
                Text(locationError).font(.caption2).foregroundStyle(Color.oceanDanger)
            }

            OceanPrimaryButton(
                text: "Send via Mesh",
                action: {
                    guard let hazard = selectedHazardType else { return }
                    viewModel.reportHazard(
                        hazardType: hazard,
                        location: "\(latitude), \(longitude)",
                        latitude: Double(latitude),
                        longitude: Double(longitude),
                        description: description,
                        urgency: selectedUrgency
                    )
                },
                isEnabled: !description.isEmpty && selectedHazardType != nil && !latitude.isEmpty && viewModel.sendState != .sending,
                isLoading: viewModel.sendState == .sending,
                icon: "paperplane.fill"
            )
        }
    }

    private func fetchLocation() {
        isGettingLocation = true
        locationError = nil
        locationManager.requestLocation { result in
            isGettingLocation = false
            switch result {
            case .success(let loc):
                latitude = String(format: "%.6f", loc.coordinate.latitude)
                longitude = String(format: "%.6f", loc.coordinate.longitude)
            case .failure(let error):
                locationError = error.localizedDescription
            }
        }
    }

    // MARK: - Message Card

    private func meshMessageCard(_ message: MeshMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(statusColor(message.status))
                    .frame(width: 10, height: 10)
                Text(HazardType.fromValue(message.hazardType).displayName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                // Urgency badge
                Text(message.urgency.capitalized)
                    .font(.caption2.bold())
                    .foregroundStyle(urgencyColor(message.urgency))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(urgencyColor(message.urgency).opacity(0.2), in: RoundedRectangle(cornerRadius: 4))

                if message.hopCount > 0 && message.status == .delivered {
                    HStack(spacing: 3) {
                        Image(systemName: "antenna.radiowaves.left.and.right").font(.caption2)
                        Text("Relayed").font(.caption2.bold())
                    }
                    .foregroundStyle(Color.oceanPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.oceanPrimary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "person.fill").font(.caption2).foregroundStyle(.secondary)
                Text("From: \(String(message.originDeviceFingerprint.prefix(8)))").font(.caption2).foregroundStyle(.secondary)
            }

            Text(message.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)

            // Relay path
            if !message.relayPath.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill").font(.caption2).foregroundStyle(Color.oceanPrimary)
                    let chain = ([String(message.originDeviceMac.prefix(6))] + message.relayPath.map { String($0.prefix(6)) }).joined(separator: " → ")
                    Text(chain).font(.caption2).foregroundStyle(Color.oceanPrimary).lineLimit(1)
                }
                .padding(6)
                .background(Color.oceanPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }

            // Bottom row
            HStack(spacing: 12) {
                Label(Date(timeIntervalSince1970: Double(message.createdAtMillis) / 1000).formatted(.dateTime.month(.abbreviated).day().hour().minute()), systemImage: "clock")
                Label(message.hopCount == 0 ? "Origin" : "\(message.hopCount) hop\(message.hopCount > 1 ? "s" : "")", systemImage: "arrow.triangle.branch")
                    .foregroundStyle(message.hopCount > 0 ? Color.oceanPrimary : .secondary)
                    .fontWeight(message.hopCount > 0 ? .bold : .regular)
                let remainingMs = MeshMessage.messageLifetimeMs - Int64((Date().timeIntervalSince1970 * 1000)) + message.createdAtMillis
                let remainingHours = max(0, Int(remainingMs / 3_600_000))
                Text(remainingHours > 0 ? "\(remainingHours)h left" : "Expiring")
                    .foregroundStyle(remainingHours <= 6 ? Color.oceanDanger : .secondary)
                Spacer()
                Text(message.status.rawValue.capitalized)
                    .font(.caption2.bold())
                    .foregroundStyle(statusColor(message.status))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Text("ID: \(String(message.messageId.prefix(12)))...")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: MeshMessageStatus) -> Color {
        switch status {
        case .pending: return .oceanWarning
        case .sending: return .oceanInfo
        case .relayed: return .oceanPrimary
        case .delivered: return .oceanSuccess
        case .failed: return .oceanDanger
        }
    }

    private func urgencyColor(_ urgency: String) -> Color {
        switch urgency.lowercased() {
        case "critical": return .oceanDanger
        case "high": return .orange
        case "medium": return .oceanWarning
        default: return .oceanSuccess
        }
    }

    // MARK: - Peers Section

    private var peersSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(viewModel.meshStatus.isRunning ? Color.oceanPrimary : .gray)
            Text(viewModel.meshStatus.isRunning
                 ? "\(viewModel.meshStatus.discoveredPeerCount) nearby mesh devices"
                 : "Mesh service is not running")
                .font(.subheadline.weight(.semibold))
            if viewModel.meshStatus.isRunning {
                Text("\(viewModel.meshStatus.connectedPeerCount) connected  •  \(viewModel.meshStatus.discoveredPeerCount) discovered")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Peers with Ocean Sentinels installed will auto-relay your hazard reports when you have no internet connection.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            } else {
                Text("Toggle the mesh switch to start scanning for nearby Ocean Sentinels devices.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        let (icon, title, subtitle): (String, String, String) = {
            switch viewModel.selectedTab {
            case .all: return ("bubble.left.and.bubble.right.fill", "No messages yet", "All sent and received hazard reports will appear here")
            case .queue: return ("tray.fill", "No pending messages", "Your reports will queue here when internet is unavailable")
            case .delivered: return ("icloud.and.arrow.up.fill", "No delivered messages", "Successfully sent reports will appear here")
            case .relayed: return ("arrowshape.turn.up.right.fill", "No relayed messages", "Messages relayed from other users will appear here")
            case .peers: return ("antenna.radiowaves.left.and.right", "No peers found", "Start the mesh service to discover nearby devices")
            }
        }()

        return VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 48)).foregroundStyle(.tertiary)
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(subtitle).font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}
