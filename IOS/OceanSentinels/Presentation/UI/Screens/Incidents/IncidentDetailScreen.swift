import SwiftUI

// MARK: - IncidentDetailScreen

struct IncidentDetailScreen: View {
    let incidentId: Int

    @Environment(IncidentViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    private var currentUser: User? {
        if case .authenticated(let user, _) = authViewModel.userSession { return user }
        return nil
    }
    private var canTakeAction: Bool {
        guard let role = currentUser?.role else { return false }
        return role == .admin || role == .rescueTeam || role == .authority
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.selectedIncident == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.selectedIncident == nil {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { viewModel.getIncident(id: incidentId) }
                }
            } else if let incident = viewModel.selectedIncident {
                incidentContent(incident)
            }
        }
        .navigationTitle("Incident Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.getIncident(id: incidentId) }
    }

    @ViewBuilder
    private func incidentContent(_ inc: Incident) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Reference ID card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reference ID").font(.caption).foregroundStyle(.secondary)
                        Text(inc.referenceId).font(.headline).foregroundStyle(Color.oceanPrimary)
                    }
                    Spacer()
                    StatusBadge(status: inc.status)
                }
                .padding(16)
                .background(Color.oceanPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                // Title & Description
                VStack(alignment: .leading, spacing: 12) {
                    Text(inc.hazardType.displayName).font(.title3.bold())
                    HStack(spacing: 8) {
                        HazardTypeBadge(hazardType: inc.hazardType)
                        UrgencyBadge(urgency: inc.urgency)
                    }
                    Divider()
                    Text("Description").font(.subheadline.weight(.semibold))
                    Text(inc.description).font(.body).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Label("Location", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundStyle(Color.oceanPrimary)
                    Text(inc.location).font(.body)
                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("Latitude").font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.6f", inc.latitude ?? 0)).font(.body.weight(.medium))
                        }
                        VStack(alignment: .leading) {
                            Text("Longitude").font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.6f", inc.longitude ?? 0)).font(.body.weight(.medium))
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                // Photo
                if let photoUrl = inc.photoUrl, let url = URL(string: photoUrl) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Photo Evidence", systemImage: "photo")
                            .font(.headline)
                            .foregroundStyle(Color.oceanPrimary)
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo.badge.exclamationmark").font(.largeTitle).foregroundStyle(.secondary)
                            default:
                                ProgressView()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                // Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Label("Timeline", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(Color.oceanPrimary)
                    timelineItem(title: "Reported", date: inc.createdAt, isCompleted: true)
                    timelineItem(title: "Verified", date: inc.verifiedAt, isCompleted: [.verified, .inProgress, .resolved].contains(inc.status))
                    timelineItem(title: "Response Deployed", date: inc.updatedAt, isCompleted: [.inProgress, .resolved].contains(inc.status))
                    timelineItem(title: "Resolved", date: inc.resolvedAt, isCompleted: inc.status == .resolved, isLast: true)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                // Actions
                if canTakeAction && inc.status != .resolved {
                    VStack(spacing: 12) {
                        Text("Actions").font(.headline)
                        switch inc.status {
                        case .pending:
                            OceanPrimaryButton(text: "Verify Incident", action: { viewModel.verifyIncident(id: inc.id) }, isLoading: viewModel.isLoading, icon: "checkmark.seal.fill")
                        case .verified:
                            OceanPrimaryButton(text: "Deploy Response", action: { viewModel.deployResponse(id: inc.id) }, isLoading: viewModel.isLoading, icon: "shippingbox.fill")
                        case .inProgress:
                            OceanPrimaryButton(text: "Mark as Resolved", action: { viewModel.resolveIncident(id: inc.id) }, isLoading: viewModel.isLoading, icon: "checkmark.circle.fill")
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func timelineItem(title: String, date: Date?, isCompleted: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isCompleted ? Color.oceanSuccess : Color(.systemGray4))
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.oceanSuccess : Color(.systemGray4))
                        .frame(width: 2, height: 24)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(isCompleted ? .primary : .secondary)
                if let date {
                    Text(date, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                } else if !isCompleted {
                    Text("Pending").font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}
