import Foundation

// MARK: - WeatherAPI.com DTOs

struct WeatherResponse: Codable {
    let location: WeatherLocation
    let current: CurrentWeather
    let forecast: WeatherForecast?
}

struct WeatherLocation: Codable {
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double
    let tzId: String
    let localtime: String
    
    enum CodingKeys: String, CodingKey {
        case name, region, country, lat, lon
        case tzId = "tz_id"
        case localtime
    }
}

struct CurrentWeather: Codable {
    let tempC: Double
    let tempF: Double
    let isDay: Int
    let condition: WeatherCondition
    let windMph: Double
    let windKph: Double
    let windDir: String
    let pressureMb: Double
    let precipMm: Double
    let humidity: Int
    let cloud: Int
    let feelslikeC: Double
    let feelslikeF: Double
    let visKm: Double
    let uv: Double
    let gustKph: Double
    
    enum CodingKeys: String, CodingKey {
        case tempC = "temp_c"
        case tempF = "temp_f"
        case isDay = "is_day"
        case condition
        case windMph = "wind_mph"
        case windKph = "wind_kph"
        case windDir = "wind_dir"
        case pressureMb = "pressure_mb"
        case precipMm = "precip_mm"
        case humidity, cloud
        case feelslikeC = "feelslike_c"
        case feelslikeF = "feelslike_f"
        case visKm = "vis_km"
        case uv
        case gustKph = "gust_kph"
    }
}

struct WeatherCondition: Codable {
    let text: String
    let icon: String
    let code: Int
}

struct WeatherForecast: Codable {
    let forecastDay: [ForecastDay]
    
    enum CodingKeys: String, CodingKey {
        case forecastDay = "forecastday"
    }
}

struct ForecastDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let day: DayWeather
    let astro: Astro
    let hour: [HourWeather]
}

struct DayWeather: Codable {
    let maxtempC: Double
    let mintempC: Double
    let avgtempC: Double
    let maxwindKph: Double
    let totalprecipMm: Double
    let avghumidity: Double
    let dailyChanceOfRain: Int
    let condition: WeatherCondition
    let uv: Double
    
    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case mintempC = "mintemp_c"
        case avgtempC = "avgtemp_c"
        case maxwindKph = "maxwind_kph"
        case totalprecipMm = "totalprecip_mm"
        case avghumidity
        case dailyChanceOfRain = "daily_chance_of_rain"
        case condition, uv
    }
}

struct Astro: Codable {
    let sunrise: String
    let sunset: String
    let moonrise: String
    let moonset: String
    let moonPhase: String
    
    enum CodingKeys: String, CodingKey {
        case sunrise, sunset, moonrise, moonset
        case moonPhase = "moon_phase"
    }
}

struct HourWeather: Codable, Identifiable {
    var id: String { time }
    let time: String
    let tempC: Double
    let condition: WeatherCondition
    let windKph: Double
    let humidity: Int
    let feelslikeC: Double
    let chanceOfRain: Int
    let isDay: Int
    
    enum CodingKeys: String, CodingKey {
        case time
        case tempC = "temp_c"
        case condition
        case windKph = "wind_kph"
        case humidity
        case feelslikeC = "feelslike_c"
        case chanceOfRain = "chance_of_rain"
        case isDay = "is_day"
    }
}

// MARK: - Marine DTOs

struct MarineResponse: Codable {
    let location: WeatherLocation
    let forecast: MarineForecast
}

struct MarineForecast: Codable {
    let forecastDay: [MarineForecastDay]
    
    enum CodingKeys: String, CodingKey {
        case forecastDay = "forecastday"
    }
}

struct MarineForecastDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let day: DayWeather
    let hour: [MarineHourWeather]
}

struct MarineHourWeather: Codable, Identifiable {
    var id: String { time }
    let time: String
    let tempC: Double
    let condition: WeatherCondition
    let windKph: Double
    let humidity: Int
    let sigHtMt: Double?
    let swellHtMt: Double?
    let swellDir: String?
    let swellPeriodSecs: Double?
    let waterTempC: Double?
    let tideHeightMt: String?
    
    enum CodingKeys: String, CodingKey {
        case time
        case tempC = "temp_c"
        case condition
        case windKph = "wind_kph"
        case humidity
        case sigHtMt = "sig_ht_mt"
        case swellHtMt = "swell_ht_mt"
        case swellDir = "swell_dir"
        case swellPeriodSecs = "swell_period_secs"
        case waterTempC = "water_temp_c"
        case tideHeightMt = "tide_height_mt"
    }
}
