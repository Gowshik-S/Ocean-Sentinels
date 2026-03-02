import Foundation

// MARK: - IndianAPI.in Weather Service

/// Replaces Retrofit IndianWeatherApi interface.
/// Base URL: https://weather.indianapi.in
final class IndianWeatherAPIService {
    
    private let baseURL = "https://weather.indianapi.in"
    private let apiKey: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(apiKey: String = AppConfig.indianApiKey) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    private func buildRequest(path: String, queryItems: [URLQueryItem]) -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = queryItems
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        return request
    }
    
    // MARK: - Indian City Weather (IMD data)
    
    func getIndianCityWeather(city: String) async throws -> IndianCityWeatherResponse {
        let request = buildRequest(
            path: "/india/weather",
            queryItems: [URLQueryItem(name: "city", value: city)]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(IndianCityWeatherResponse.self, from: data)
    }
    
    // MARK: - Global Current Weather
    
    func getGlobalCurrentWeather(location: String) async throws -> IndianGlobalCurrentResponse {
        let request = buildRequest(
            path: "/global/current",
            queryItems: [URLQueryItem(name: "location", value: location)]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(IndianGlobalCurrentResponse.self, from: data)
    }
    
    // MARK: - Global Weather + Forecast
    
    func getGlobalWeather(location: String, days: Int = 3) async throws -> IndianGlobalWeatherResponse {
        let request = buildRequest(
            path: "/global/weather",
            queryItems: [
                URLQueryItem(name: "location", value: location),
                URLQueryItem(name: "days", value: "\(days)")
            ]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(IndianGlobalWeatherResponse.self, from: data)
    }
}
