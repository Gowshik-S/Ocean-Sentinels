import Foundation

// MARK: - IndianAPI.in Weather DTOs

struct IndianCityWeatherResponse: Codable {
    let city: String
    let weather: IndianWeatherData?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = (try? container.decode(String.self, forKey: .city)) ?? ""
        weather = try? container.decode(IndianWeatherData.self, forKey: .weather)
    }
    
    enum CodingKeys: String, CodingKey {
        case city, weather
    }
}

struct IndianWeatherData: Codable {
    let current: IndianCurrentWeather?
    let forecast: [IndianForecastDay]?
    let astronomical: IndianAstronomical?
}

struct IndianCurrentWeather: Codable {
    let humidity: IndianHumidity?
    let rainfall: Double?
    let temperature: IndianTemperature?
}

struct IndianHumidity: Codable {
    let evening: Int?
    let morning: Int?
}

struct IndianTemperature: Codable {
    let max: IndianTempValue?
    let min: IndianTempValue?
}

struct IndianTempValue: Codable {
    let value: Double?
    let departure: Double?
}

struct IndianForecastDay: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let maxTemp: Int?
    let minTemp: Int?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case date
        case maxTemp = "max_temp"
        case minTemp = "min_temp"
        case description
    }
}

struct IndianAstronomical: Codable {
    let sunset: String?
    let moonset: String?
    let sunrise: String?
    let moonrise: String?
}

// MARK: - Global Current Weather

struct IndianGlobalCurrentResponse: Codable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: String
    let condition: String
    let uvIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case condition
        case uvIndex = "uv_index"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = (try? container.decode(Double.self, forKey: .temperature)) ?? 0
        feelsLike = (try? container.decode(Double.self, forKey: .feelsLike)) ?? 0
        humidity = (try? container.decode(Int.self, forKey: .humidity)) ?? 0
        windSpeed = (try? container.decode(Double.self, forKey: .windSpeed)) ?? 0
        windDirection = (try? container.decode(String.self, forKey: .windDirection)) ?? ""
        condition = (try? container.decode(String.self, forKey: .condition)) ?? ""
        uvIndex = (try? container.decode(Int.self, forKey: .uvIndex)) ?? 0
    }
}

// MARK: - Global Weather + Forecast

struct IndianGlobalWeatherResponse: Codable {
    let location: String?
    let current: IndianGlobalCurrent?
    let forecast: [IndianGlobalForecastDay]?
}

struct IndianGlobalCurrent: Codable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: String
    let condition: String
    let uvIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case condition
        case uvIndex = "uv_index"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = (try? container.decode(Double.self, forKey: .temperature)) ?? 0
        feelsLike = (try? container.decode(Double.self, forKey: .feelsLike)) ?? 0
        humidity = (try? container.decode(Int.self, forKey: .humidity)) ?? 0
        windSpeed = (try? container.decode(Double.self, forKey: .windSpeed)) ?? 0
        windDirection = (try? container.decode(String.self, forKey: .windDirection)) ?? ""
        condition = (try? container.decode(String.self, forKey: .condition)) ?? ""
        uvIndex = (try? container.decode(Int.self, forKey: .uvIndex)) ?? 0
    }
}

struct IndianGlobalForecastDay: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let maxTemp: Double
    let minTemp: Double
    let sunrise: String?
    let sunset: String?
    let moonrise: String?
    let moonset: String?
    let moonPhase: String?
    let hourly: [IndianGlobalHourly]?
    
    enum CodingKeys: String, CodingKey {
        case date
        case maxTemp = "max_temp"
        case minTemp = "min_temp"
        case sunrise, sunset, moonrise, moonset
        case moonPhase = "moon_phase"
        case hourly
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try? container.decode(String.self, forKey: .date)
        maxTemp = (try? container.decode(Double.self, forKey: .maxTemp)) ?? 0
        minTemp = (try? container.decode(Double.self, forKey: .minTemp)) ?? 0
        sunrise = try? container.decode(String.self, forKey: .sunrise)
        sunset = try? container.decode(String.self, forKey: .sunset)
        moonrise = try? container.decode(String.self, forKey: .moonrise)
        moonset = try? container.decode(String.self, forKey: .moonset)
        moonPhase = try? container.decode(String.self, forKey: .moonPhase)
        hourly = try? container.decode([IndianGlobalHourly].self, forKey: .hourly)
    }
}

struct IndianGlobalHourly: Codable, Identifiable {
    var id: String { time ?? UUID().uuidString }
    let time: String?
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: String
    let condition: String
    let chanceOfRain: Int
    
    enum CodingKeys: String, CodingKey {
        case time, temperature
        case feelsLike = "feels_like"
        case humidity
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case condition
        case chanceOfRain = "chance_of_rain"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try? container.decode(String.self, forKey: .time)
        temperature = (try? container.decode(Double.self, forKey: .temperature)) ?? 0
        feelsLike = (try? container.decode(Double.self, forKey: .feelsLike)) ?? 0
        humidity = (try? container.decode(Int.self, forKey: .humidity)) ?? 0
        windSpeed = (try? container.decode(Double.self, forKey: .windSpeed)) ?? 0
        windDirection = (try? container.decode(String.self, forKey: .windDirection)) ?? ""
        condition = (try? container.decode(String.self, forKey: .condition)) ?? ""
        chanceOfRain = (try? container.decode(Int.self, forKey: .chanceOfRain)) ?? 0
    }
}
