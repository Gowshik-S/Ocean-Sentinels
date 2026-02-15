package com.oceansentinels.app.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * WeatherAPI.com response DTOs
 * Docs: https://www.weatherapi.com/docs/
 */
data class WeatherResponse(
    @SerializedName("location") val location: WeatherLocation,
    @SerializedName("current") val current: CurrentWeather,
    @SerializedName("forecast") val forecast: WeatherForecast? = null
)

data class WeatherLocation(
    @SerializedName("name") val name: String,
    @SerializedName("region") val region: String,
    @SerializedName("country") val country: String,
    @SerializedName("lat") val lat: Double,
    @SerializedName("lon") val lon: Double,
    @SerializedName("tz_id") val tzId: String,
    @SerializedName("localtime") val localtime: String
)

data class CurrentWeather(
    @SerializedName("temp_c") val tempC: Double,
    @SerializedName("temp_f") val tempF: Double,
    @SerializedName("is_day") val isDay: Int,
    @SerializedName("condition") val condition: WeatherCondition,
    @SerializedName("wind_mph") val windMph: Double,
    @SerializedName("wind_kph") val windKph: Double,
    @SerializedName("wind_dir") val windDir: String,
    @SerializedName("pressure_mb") val pressureMb: Double,
    @SerializedName("precip_mm") val precipMm: Double,
    @SerializedName("humidity") val humidity: Int,
    @SerializedName("cloud") val cloud: Int,
    @SerializedName("feelslike_c") val feelslikeC: Double,
    @SerializedName("feelslike_f") val feelslikeF: Double,
    @SerializedName("vis_km") val visKm: Double,
    @SerializedName("uv") val uv: Double,
    @SerializedName("gust_kph") val gustKph: Double
)

data class WeatherCondition(
    @SerializedName("text") val text: String,
    @SerializedName("icon") val icon: String,
    @SerializedName("code") val code: Int
)

data class WeatherForecast(
    @SerializedName("forecastday") val forecastDay: List<ForecastDay>
)

data class ForecastDay(
    @SerializedName("date") val date: String,
    @SerializedName("day") val day: DayWeather,
    @SerializedName("astro") val astro: Astro,
    @SerializedName("hour") val hour: List<HourWeather>
)

data class DayWeather(
    @SerializedName("maxtemp_c") val maxtempC: Double,
    @SerializedName("mintemp_c") val mintempC: Double,
    @SerializedName("avgtemp_c") val avgtempC: Double,
    @SerializedName("maxwind_kph") val maxwindKph: Double,
    @SerializedName("totalprecip_mm") val totalprecipMm: Double,
    @SerializedName("avghumidity") val avghumidity: Double,
    @SerializedName("daily_chance_of_rain") val dailyChanceOfRain: Int,
    @SerializedName("condition") val condition: WeatherCondition,
    @SerializedName("uv") val uv: Double
)

data class Astro(
    @SerializedName("sunrise") val sunrise: String,
    @SerializedName("sunset") val sunset: String,
    @SerializedName("moonrise") val moonrise: String,
    @SerializedName("moonset") val moonset: String,
    @SerializedName("moon_phase") val moonPhase: String
)

data class HourWeather(
    @SerializedName("time") val time: String,
    @SerializedName("temp_c") val tempC: Double,
    @SerializedName("condition") val condition: WeatherCondition,
    @SerializedName("wind_kph") val windKph: Double,
    @SerializedName("humidity") val humidity: Int,
    @SerializedName("feelslike_c") val feelslikeC: Double,
    @SerializedName("chance_of_rain") val chanceOfRain: Int,
    @SerializedName("is_day") val isDay: Int
)

data class MarineResponse(
    @SerializedName("location") val location: WeatherLocation,
    @SerializedName("forecast") val forecast: MarineForecast
)

data class MarineForecast(
    @SerializedName("forecastday") val forecastDay: List<MarineForecastDay>
)

data class MarineForecastDay(
    @SerializedName("date") val date: String,
    @SerializedName("day") val day: DayWeather,
    @SerializedName("hour") val hour: List<MarineHourWeather>
)

data class MarineHourWeather(
    @SerializedName("time") val time: String,
    @SerializedName("temp_c") val tempC: Double,
    @SerializedName("condition") val condition: WeatherCondition,
    @SerializedName("wind_kph") val windKph: Double,
    @SerializedName("humidity") val humidity: Int,
    @SerializedName("sig_ht_mt") val sigHtMt: Double? = null,
    @SerializedName("swell_ht_mt") val swellHtMt: Double? = null,
    @SerializedName("swell_dir") val swellDir: String? = null,
    @SerializedName("swell_period_secs") val swellPeriodSecs: Double? = null,
    @SerializedName("water_temp_c") val waterTempC: Double? = null,
    @SerializedName("tide_height_mt") val tideHeightMt: String? = null
)
