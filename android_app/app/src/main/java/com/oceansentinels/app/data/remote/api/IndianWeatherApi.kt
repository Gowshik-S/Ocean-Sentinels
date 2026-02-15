package com.oceansentinels.app.data.remote.api

import com.oceansentinels.app.data.remote.dto.IndianCityWeatherResponse
import com.oceansentinels.app.data.remote.dto.IndianGlobalWeatherResponse
import com.oceansentinels.app.data.remote.dto.IndianGlobalCurrentResponse
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Query

/**
 * IndianAPI.in Weather API
 * Base URL: https://weather.indianapi.in
 * Docs: https://indianapi.in/documentation/weather-api
 */
interface IndianWeatherApi {

    /**
     * Get weather for an Indian city (IMD data)
     * Fuzzy matching on city name
     */
    @GET("india/weather")
    suspend fun getIndianCityWeather(
        @Header("x-api-key") apiKey: String,
        @Query("city") city: String
    ): IndianCityWeatherResponse

    /**
     * Get current weather for any global location
     */
    @GET("global/current")
    suspend fun getGlobalCurrentWeather(
        @Header("x-api-key") apiKey: String,
        @Query("location") location: String
    ): IndianGlobalCurrentResponse

    /**
     * Get weather + forecast for a global location
     */
    @GET("global/weather")
    suspend fun getGlobalWeather(
        @Header("x-api-key") apiKey: String,
        @Query("location") location: String,
        @Query("days") days: Int = 3
    ): IndianGlobalWeatherResponse
}
