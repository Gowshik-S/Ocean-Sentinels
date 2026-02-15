package com.oceansentinels.app.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * DTOs for IndianAPI.in Weather API responses
 * Docs: https://indianapi.in/documentation/weather-api
 */

// ============= Indian City Weather =============

data class IndianCityWeatherResponse(
    @SerializedName("city") val city: String = "",
    @SerializedName("weather") val weather: IndianWeatherData? = null
)

data class IndianWeatherData(
    @SerializedName("current") val current: IndianCurrentWeather? = null,
    @SerializedName("forecast") val forecast: List<IndianForecastDay>? = null,
    @SerializedName("astronomical") val astronomical: IndianAstronomical? = null
)

data class IndianCurrentWeather(
    @SerializedName("humidity") val humidity: IndianHumidity? = null,
    @SerializedName("rainfall") val rainfall: Double? = null,
    @SerializedName("temperature") val temperature: IndianTemperature? = null
)

data class IndianHumidity(
    @SerializedName("evening") val evening: Int? = null,
    @SerializedName("morning") val morning: Int? = null
)

data class IndianTemperature(
    @SerializedName("max") val max: IndianTempValue? = null,
    @SerializedName("min") val min: IndianTempValue? = null
)

data class IndianTempValue(
    @SerializedName("value") val value: Double? = null,
    @SerializedName("departure") val departure: Double? = null
)

data class IndianForecastDay(
    @SerializedName("date") val date: String? = null,
    @SerializedName("max_temp") val maxTemp: Int? = null,
    @SerializedName("min_temp") val minTemp: Int? = null,
    @SerializedName("description") val description: String? = null
)

data class IndianAstronomical(
    @SerializedName("sunset") val sunset: String? = null,
    @SerializedName("moonset") val moonset: String? = null,
    @SerializedName("sunrise") val sunrise: String? = null,
    @SerializedName("moonrise") val moonrise: String? = null
)

// ============= Global Current Weather =============

data class IndianGlobalCurrentResponse(
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("feels_like") val feelsLike: Double = 0.0,
    @SerializedName("humidity") val humidity: Int = 0,
    @SerializedName("wind_speed") val windSpeed: Double = 0.0,
    @SerializedName("wind_direction") val windDirection: String = "",
    @SerializedName("condition") val condition: String = "",
    @SerializedName("uv_index") val uvIndex: Int = 0
)

// ============= Global Weather + Forecast =============

data class IndianGlobalWeatherResponse(
    @SerializedName("location") val location: String? = null,
    @SerializedName("current") val current: IndianGlobalCurrent? = null,
    @SerializedName("forecast") val forecast: List<IndianGlobalForecastDay>? = null
)

data class IndianGlobalCurrent(
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("feels_like") val feelsLike: Double = 0.0,
    @SerializedName("humidity") val humidity: Int = 0,
    @SerializedName("wind_speed") val windSpeed: Double = 0.0,
    @SerializedName("wind_direction") val windDirection: String = "",
    @SerializedName("condition") val condition: String = "",
    @SerializedName("uv_index") val uvIndex: Int = 0
)

data class IndianGlobalForecastDay(
    @SerializedName("date") val date: String? = null,
    @SerializedName("max_temp") val maxTemp: Double = 0.0,
    @SerializedName("min_temp") val minTemp: Double = 0.0,
    @SerializedName("sunrise") val sunrise: String? = null,
    @SerializedName("sunset") val sunset: String? = null,
    @SerializedName("moonrise") val moonrise: String? = null,
    @SerializedName("moonset") val moonset: String? = null,
    @SerializedName("moon_phase") val moonPhase: String? = null,
    @SerializedName("hourly") val hourly: List<IndianGlobalHourly>? = null
)

data class IndianGlobalHourly(
    @SerializedName("time") val time: String? = null,
    @SerializedName("temperature") val temperature: Double = 0.0,
    @SerializedName("feels_like") val feelsLike: Double = 0.0,
    @SerializedName("humidity") val humidity: Int = 0,
    @SerializedName("wind_speed") val windSpeed: Double = 0.0,
    @SerializedName("wind_direction") val windDirection: String = "",
    @SerializedName("condition") val condition: String = "",
    @SerializedName("chance_of_rain") val chanceOfRain: Int = 0
)
