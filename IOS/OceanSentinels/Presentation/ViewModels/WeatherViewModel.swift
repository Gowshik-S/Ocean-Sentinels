import Foundation
import Observation

// MARK: - WeatherViewModel

/// ViewModel for weather data from dual APIs (IndianAPI.in + WeatherAPI.com).
///
/// Loads weather forecasts, marine data, and extracts severe weather alerts
/// from IMD forecast descriptions. Prioritises Indian Weather API for
/// Indian-region cities, falling back to WeatherAPI.com.
@Observable
@MainActor
final class WeatherViewModel {

    // MARK: - State

    var currentWeather: WeatherResponse?
    var forecast: [ForecastDay]
    var marineWeather: MarineResponse?
    var indianCityWeather: IndianCityWeatherResponse?
    var indianGlobalWeather: IndianGlobalWeatherResponse?
    var weatherAlerts: [WeatherAlert]
    var isLoading: Bool
    var error: String?

    // Location
    var currentLocation: String
    var currentLatitude: Double
    var currentLongitude: Double

    // MARK: - Dependencies

    private let weatherRepository: WeatherRepositoryImpl

    // MARK: - Init

    init(weatherRepository: WeatherRepositoryImpl) {
        self.weatherRepository = weatherRepository

        self.currentWeather = nil
        self.forecast = []
        self.marineWeather = nil
        self.indianCityWeather = nil
        self.indianGlobalWeather = nil
        self.weatherAlerts = []
        self.isLoading = false
        self.error = nil

        self.currentLocation = "Mumbai"
        self.currentLatitude = 19.076
        self.currentLongitude = 72.8777
    }

    // MARK: - Public API

    /// Update location and reload weather data.
    func updateLocation(location: String, latitude: Double, longitude: Double) {
        currentLocation = location
        currentLatitude = latitude
        currentLongitude = longitude
        loadWeather()
    }

    /// Load all weather data from both APIs.
    func loadWeather() {
        Task {
            isLoading = true
            error = nil

            // Load from both APIs concurrently using do/try/catch
            // (repo methods throw, not return Result)

            // WeatherAPI.com (current + forecast + marine)
            do {
                currentWeather = try await weatherRepository.getCurrentWeather(location: currentLocation)
            } catch {
                AppLogger.weather.warning("Failed to load current weather: \(error.localizedDescription)")
            }

            do {
                let response = try await weatherRepository.getForecast(location: currentLocation, days: 7)
                forecast = response.forecast?.forecastDay ?? []
            } catch {
                AppLogger.weather.warning("Failed to load forecast: \(error.localizedDescription)")
            }

            do {
                let coordString = "\(currentLatitude),\(currentLongitude)"
                marineWeather = try await weatherRepository.getMarineWeather(location: coordString, days: 3)
            } catch {
                AppLogger.weather.warning("Failed to load marine weather: \(error.localizedDescription)")
            }

            // IndianAPI.in
            do {
                indianCityWeather = try await weatherRepository.getIndianCityWeather(city: currentLocation)
            } catch {
                AppLogger.weather.warning("Failed to load Indian city weather: \(error.localizedDescription)")
            }

            do {
                let coordString = "\(currentLatitude),\(currentLongitude)"
                let globalWeather = try await weatherRepository.getGlobalWeatherForecast(location: coordString, days: 3)
                indianGlobalWeather = globalWeather
                extractAlerts(from: globalWeather)
            } catch {
                AppLogger.weather.warning("Failed to load Indian global weather: \(error.localizedDescription)")
            }

            isLoading = false
        }
    }

    /// Refresh all weather data.
    func refresh() {
        loadWeather()
    }

    // MARK: - Alert Extraction

    /// Parse IMD forecast descriptions for severe weather keywords.
    ///
    /// Scans daily forecast text for conditions like cyclone, flood, tsunami, etc.
    /// and generates structured `WeatherAlert` objects.
    private func extractAlerts(from response: IndianGlobalWeatherResponse) {
        var alerts: [WeatherAlert] = []

        let severeKeywords = [
            "cyclone", "storm", "flood", "tsunami", "heavy rain",
            "very heavy rain", "extremely heavy rain", "warning",
            "red alert", "orange alert", "severe"
        ]

        guard let forecastDays = response.forecast else {
            weatherAlerts = alerts
            return
        }

        for dailyWeather in forecastDays {
            // Scan available text fields for severe weather keywords
            var textToScan = ""
            if let dateStr = dailyWeather.date { textToScan += dateStr + " " }
            if let moonPhase = dailyWeather.moonPhase { textToScan += moonPhase + " " }

            // Also scan hourly conditions if available
            if let hourlyData = dailyWeather.hourly {
                for hourly in hourlyData {
                    textToScan += hourly.condition + " "
                }
            }

            let textLower = textToScan.lowercased()

            for keyword in severeKeywords where textLower.contains(keyword) {
                alerts.append(
                    WeatherAlert(
                        type: keyword.capitalized,
                        description: "Severe weather detected: \(keyword) conditions in forecast for \(dailyWeather.date ?? "unknown")",
                        severity: determineSeverity(for: keyword),
                        date: dailyWeather.date ?? ""
                    )
                )
                break // One alert per day
            }
        }

        weatherAlerts = alerts
    }

    private func determineSeverity(for keyword: String) -> AlertSeverity {
        switch keyword.lowercased() {
        case "cyclone", "tsunami", "extremely heavy rain", "red alert":
            return .extreme
        case "storm", "flood", "very heavy rain", "orange alert", "severe":
            return .severe
        case "heavy rain", "warning":
            return .moderate
        default:
            return .minor
        }
    }
}

// MARK: - Supporting Types

struct WeatherAlert: Identifiable {
    let id = UUID()
    let type: String
    let description: String
    let severity: AlertSeverity
    let date: String
}

enum AlertSeverity: String, CaseIterable {
    case extreme = "Extreme"
    case severe = "Severe"
    case moderate = "Moderate"
    case minor = "Minor"
}
