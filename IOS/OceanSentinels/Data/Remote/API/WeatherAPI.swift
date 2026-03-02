import Foundation

// MARK: - WeatherAPI.com Service

/// Replaces Retrofit WeatherApi interface.
/// Base URL: https://api.weatherapi.com/v1/
final class WeatherAPIService {
    
    private let baseURL = "https://api.weatherapi.com/v1/"
    private let apiKey: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(apiKey: String = AppConfig.weatherApiKey) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    private func url(_ path: String, queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(string: baseURL + path)!
        var items = queryItems
        items.insert(URLQueryItem(name: "key", value: apiKey), at: 0)
        components.queryItems = items
        return components.url!
    }
    
    // MARK: - Current Weather
    
    func getCurrentWeather(location: String) async throws -> WeatherResponse {
        let url = url("current.json", queryItems: [
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "aqi", value: "no")
        ])
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(WeatherResponse.self, from: data)
    }
    
    // MARK: - Forecast
    
    func getForecast(location: String, days: Int = 3) async throws -> WeatherResponse {
        let url = url("forecast.json", queryItems: [
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "days", value: "\(days)"),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "yes")
        ])
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(WeatherResponse.self, from: data)
    }
    
    // MARK: - Marine Weather
    
    func getMarineWeather(location: String, days: Int = 3) async throws -> MarineResponse {
        let url = url("marine.json", queryItems: [
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "days", value: "\(days)")
        ])
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(MarineResponse.self, from: data)
    }
}
