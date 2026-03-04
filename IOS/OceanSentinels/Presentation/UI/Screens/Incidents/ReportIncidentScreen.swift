import SwiftUI
import CoreLocation

// MARK: - ReportIncidentScreen

struct ReportIncidentScreen: View {
    @Environment(IncidentViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var selectedHazardType: HazardType?
    @State private var selectedUrgency: UrgencyLevel = .medium
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var locationDescription = ""
    @State private var isGettingLocation = false
    @State private var locationError: String?
    @State private var meshFallbackMessage: String?

    @StateObject private var locationManager = SimpleLocationManager()

    private var hasLocation: Bool { !latitude.isEmpty && !longitude.isEmpty }
    private var isFormValid: Bool {
        !description.isEmpty && selectedHazardType != nil && hasLocation
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info banner
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill").foregroundStyle(Color.oceanInfo)
                    Text("Your report helps protect our marine environment. Please provide accurate details.")
                        .font(.caption).foregroundStyle(Color.oceanInfo)
                }
                .padding(16)
                .background(Color.oceanInfo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                // Description
                OceanTextArea(
                    label: "Description",
                    text: $description,
                    placeholder: "Detailed description of what you observed..."
                )

                // Hazard Type
                VStack(alignment: .leading, spacing: 8) {
                    Label("Hazard Type *", systemImage: "tag.fill").font(.subheadline).foregroundStyle(.secondary)
                    Picker("Hazard Type", selection: $selectedHazardType) {
                        Text("Select hazard type").tag(HazardType?.none)
                        ForEach(HazardType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.compatSystemGray6, in: RoundedRectangle(cornerRadius: 8))
                }

                // Urgency
                VStack(alignment: .leading, spacing: 8) {
                    Label("Urgency Level", systemImage: "exclamationmark.circle.fill").font(.subheadline).foregroundStyle(.secondary)
                    Picker("Urgency", selection: $selectedUrgency) {
                        ForEach(UrgencyLevel.allCases, id: \.self) { level in
                            Text(level.value.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Location Section
                Text("Location").font(.headline)

                // GPS Location Card
                HStack(spacing: 12) {
                    Image(systemName: hasLocation ? "location.fill" : "location.slash.fill")
                        .font(.title3)
                        .foregroundStyle(hasLocation ? Color.oceanSuccess : Color.oceanWarning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isGettingLocation ? "Detecting GPS location..." : hasLocation ? "Location detected" : "Location unavailable")
                            .font(.subheadline.weight(.semibold))
                        if hasLocation {
                            Text("\(latitude), \(longitude)").font(.caption).foregroundStyle(.secondary)
                        }
                        if let locationError {
                            Text(locationError).font(.caption).foregroundStyle(Color.oceanDanger)
                        }
                    }
                    Spacer()
                    if isGettingLocation {
                        ProgressView()
                    } else {
                        Button { requestLocation() } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasLocation ? Color.oceanSuccess.opacity(0.08) : Color.oceanWarning.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(hasLocation ? Color.oceanSuccess : Color.oceanWarning, lineWidth: 1)
                        )
                )

                OceanLocationField(text: $locationDescription, onGetLocation: { requestLocation() })

                // Photo Section
                Text("Photo Evidence (Optional)").font(.headline)
                HStack(spacing: 12) {
                    Button {
                        // TODO: Camera picker
                    } label: {
                        Label("Camera", systemImage: "camera").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // TODO: Photo library picker
                    } label: {
                        Label("Gallery", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                // Error
                if case .error(let message) = viewModel.createIncidentState {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.oceanDanger)
                        Text(message).font(.caption).foregroundStyle(Color.oceanDanger)
                    }
                    .padding(12)
                    .background(Color.oceanDanger.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // Mesh fallback
                if let meshFallbackMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(Color.oceanInfo)
                        Text(meshFallbackMessage).font(.caption).foregroundStyle(Color.oceanInfo)
                    }
                    .padding(12)
                    .background(Color.oceanInfo.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }

                // Submit
                OceanPrimaryButton(
                    text: "Submit Report",
                    action: submitReport,
                    isEnabled: isFormValid && viewModel.createIncidentState != .loading,
                    isLoading: viewModel.createIncidentState == .loading,
                    icon: "paperplane.fill"
                )
            }
            .padding(16)
        }
        .navigationTitle("Report Hazard")
        .compatInlineNavigationTitle()
        .onAppear { requestLocation() }
        .onChange(of: viewModel.createIncidentState) { _, newState in
            if case .success = newState {
                viewModel.resetCreateState()
                dismiss()
            } else if case .meshFallbackSuccess(let msg) = newState {
                meshFallbackMessage = msg
                viewModel.resetCreateState()
            }
        }
    }

    private func submitReport() {
        guard let hazardType = selectedHazardType else { return }
        viewModel.createIncident(
            request: CreateIncidentRequest(
                hazardType: hazardType,
                location: locationDescription.isEmpty ? "\(latitude), \(longitude)" : locationDescription,
                latitude: Double(latitude),
                longitude: Double(longitude),
                description: description,
                urgency: selectedUrgency,
                contactInfo: nil,
                photoUrl: nil
            )
        )
    }

    private func requestLocation() {
        isGettingLocation = true
        locationError = nil
        locationManager.requestLocation { result in
            isGettingLocation = false
            switch result {
            case .success(let location):
                latitude = String(format: "%.6f", location.coordinate.latitude)
                longitude = String(format: "%.6f", location.coordinate.longitude)
            case .failure(let error):
                locationError = error.localizedDescription
            }
        }
    }
}

// MARK: - SimpleLocationManager

final class SimpleLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<CLLocation, any Error>) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation(completion: @escaping (Result<CLLocation, any Error>) -> Void) {
        self.completion = completion
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            completion?(.success(location))
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        completion?(.failure(error))
        completion = nil
    }
}
