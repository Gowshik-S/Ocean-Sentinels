package com.oceansentinels.app.data.remote.api

import com.oceansentinels.app.data.remote.dto.MarineResponse
import com.oceansentinels.app.data.remote.dto.WeatherResponse
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * WeatherAPI.com Retrofit interface
 * Base URL: https://api.weatherapi.com/v1/
 */
interface WeatherApi {

    @GET("current.json")
    suspend fun getCurrentWeather(
        @Query("key") apiKey: String,
        @Query("q") location: String,
        @Query("aqi") aqi: String = "no"
    ): WeatherResponse

    @GET("forecast.json")
    suspend fun getForecast(
        @Query("key") apiKey: String,
        @Query("q") location: String,
        @Query("days") days: Int = 3,
        @Query("aqi") aqi: String = "no",
        @Query("alerts") alerts: String = "yes"
    ): WeatherResponse

    @GET("marine.json")
    suspend fun getMarineWeather(
        @Query("key") apiKey: String,
        @Query("q") location: String,
        @Query("days") days: Int = 3
    ): MarineResponse
}
