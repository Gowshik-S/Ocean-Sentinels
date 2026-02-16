package com.oceansentinels.app.data.repository

import com.oceansentinels.app.BuildConfig
import com.oceansentinels.app.data.remote.api.IndianWeatherApi
import com.oceansentinels.app.data.remote.api.WeatherApi
import com.oceansentinels.app.data.remote.dto.*
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for weather data
 * Uses IndianAPI.in for Indian city weather and alerts
 * Uses WeatherAPI.com as fallback for global/marine data
 */
@Singleton
class WeatherRepository @Inject constructor(
    private val weatherApi: WeatherApi,
    private val indianWeatherApi: IndianWeatherApi
) {
    companion object {
        val WEATHERAPI_KEY: String = BuildConfig.WEATHERAPI_KEY
        val INDIAN_API_KEY: String = BuildConfig.INDIAN_API_KEY
    }

    // ============= IndianAPI.in Methods =============

    /**
     * Get Indian city weather from IMD data
     */
    suspend fun getIndianCityWeather(city: String): Result<IndianCityWeatherResponse> {
        return try {
            val response = indianWeatherApi.getIndianCityWeather(INDIAN_API_KEY, city)
            Timber.d("IndianAPI city weather fetched for: ${response.city}")
            Result.success(response)
        } catch (e: Exception) {
            Timber.e(e, "Error fetching Indian city weather for $city")
            Result.failure(e)
        }
    }

    /**
     * Get global current weather conditions
     */
    suspend fun getGlobalCurrentWeather(location: String): Result<IndianGlobalCurrentResponse> {
        return try {
            val response = indianWeatherApi.getGlobalCurrentWeather(INDIAN_API_KEY, location)
            Result.success(response)
        } catch (e: Exception) {
            Timber.e(e, "Error fetching global current weather for $location")
            Result.failure(e)
        }
    }

    /**
     * Get global weather with forecast
     */
    suspend fun getGlobalWeatherForecast(location: String, days: Int = 3): Result<IndianGlobalWeatherResponse> {
        return try {
            val response = indianWeatherApi.getGlobalWeather(INDIAN_API_KEY, location, days)
            Result.success(response)
        } catch (e: Exception) {
            Timber.e(e, "Error fetching global weather forecast for $location")
            Result.failure(e)
        }
    }

    // ============= WeatherAPI.com Methods (fallback + marine) =============

    suspend fun getCurrentWeather(location: String): Result<WeatherResponse> {
        return try {
            val response = weatherApi.getCurrentWeather(WEATHERAPI_KEY, location)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getForecast(location: String, days: Int = 3): Result<WeatherResponse> {
        return try {
            val response = weatherApi.getForecast(WEATHERAPI_KEY, location, days)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getMarineWeather(location: String, days: Int = 3): Result<MarineResponse> {
        return try {
            val response = weatherApi.getMarineWeather(WEATHERAPI_KEY, location, days)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
