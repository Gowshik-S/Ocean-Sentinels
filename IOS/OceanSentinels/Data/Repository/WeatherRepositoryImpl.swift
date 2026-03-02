import Foundation
import os

/// Repository for weather data.
/// Uses IndianAPI.in for Indian city weather and alerts.
/// Uses WeatherAPI.com as fallback for global/marine data.
/// Replaces Kotlin WeatherRepository.
final class WeatherRepositoryImpl {
    
    private let weatherAPI: WeatherAPIService
    private let indianWeatherAPI: IndianWeatherAPIService
    private let logger = Logger(subsystem: "com.oceansentinels.app", category: "WeatherRepo")
    
    init(
        weatherAPI: WeatherAPIService = WeatherAPIService(),
        indianWeatherAPI: IndianWeatherAPIService = IndianWeatherAPIService()
    ) {
        self.weatherAPI = weatherAPI
        self.indianWeatherAPI = indianWeatherAPI
    }
    
    // MARK: - IndianAPI.in Methods
    
    /// Get Indian city weather from IMD data
    func getIndianCityWeather(city: String) async throws -> IndianCityWeatherResponse {
        logger.debug("Fetching Indian city weather for: \(city)")
        return try await indianWeatherAPI.getIndianCityWeather(city: city)
    }
    
    /// Get global current weather conditions
    func getGlobalCurrentWeather(location: String) async throws -> IndianGlobalCurrentResponse {
        return try await indianWeatherAPI.getGlobalCurrentWeather(location: location)
    }
    
    /// Get global weather with forecast
    func getGlobalWeatherForecast(location: String, days: Int = 3) async throws -> IndianGlobalWeatherResponse {
        return try await indianWeatherAPI.getGlobalWeather(location: location, days: days)
    }
    
    // MARK: - WeatherAPI.com Methods (fallback + marine)
    
    func getCurrentWeather(location: String) async throws -> WeatherResponse {
        return try await weatherAPI.getCurrentWeather(location: location)
    }
    
    func getForecast(location: String, days: Int = 3) async throws -> WeatherResponse {
        return try await weatherAPI.getForecast(location: location, days: days)
    }
    
    func getMarineWeather(location: String, days: Int = 3) async throws -> MarineResponse {
        return try await weatherAPI.getMarineWeather(location: location, days: days)
    }
}
