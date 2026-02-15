package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.data.remote.dto.*
import com.oceansentinels.app.data.repository.WeatherRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class WeatherViewModel @Inject constructor(
    private val weatherRepository: WeatherRepository
) : ViewModel() {

    // WeatherAPI.com data (for marine + global fallback)
    private val _currentWeather = MutableStateFlow<WeatherResponse?>(null)
    val currentWeather: StateFlow<WeatherResponse?> = _currentWeather.asStateFlow()

    private val _forecast = MutableStateFlow<WeatherResponse?>(null)
    val forecast: StateFlow<WeatherResponse?> = _forecast.asStateFlow()

    private val _marineWeather = MutableStateFlow<MarineResponse?>(null)
    val marineWeather: StateFlow<MarineResponse?> = _marineWeather.asStateFlow()

    // IndianAPI.in data
    private val _indianCityWeather = MutableStateFlow<IndianCityWeatherResponse?>(null)
    val indianCityWeather: StateFlow<IndianCityWeatherResponse?> = _indianCityWeather.asStateFlow()

    private val _indianGlobalWeather = MutableStateFlow<IndianGlobalWeatherResponse?>(null)
    val indianGlobalWeather: StateFlow<IndianGlobalWeatherResponse?> = _indianGlobalWeather.asStateFlow()

    // Live weather alerts derived from forecast descriptions
    private val _weatherAlerts = MutableStateFlow<List<String>>(emptyList())
    val weatherAlerts: StateFlow<List<String>> = _weatherAlerts.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _currentLocation = MutableStateFlow("Chennai")
    val currentLocation: StateFlow<String> = _currentLocation.asStateFlow()

    private val _currentCity = MutableStateFlow("Chennai")
    val currentCity: StateFlow<String> = _currentCity.asStateFlow()

    init {
        loadWeather("Chennai")
    }

    /**
     * Update location from GPS/user preference
     */
    fun updateLocation(city: String, region: String? = null) {
        _currentCity.value = city
        _currentLocation.value = if (region != null) "$city, $region" else city
        loadWeather(city)
    }

    fun loadWeather(location: String) {
        _currentLocation.value = location
        _currentCity.value = location.split(",").firstOrNull()?.trim() ?: location
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            // 1. Load IndianAPI city weather (IMD data — primary for Indian cities)
            weatherRepository.getIndianCityWeather(_currentCity.value).fold(
                onSuccess = { response ->
                    _indianCityWeather.value = response
                    Timber.d("IndianAPI weather loaded for: ${response.city}")
                    // Extract alerts from forecast descriptions
                    extractAlerts(response)
                },
                onFailure = { e ->
                    Timber.w(e, "IndianAPI city weather failed, using fallback")
                }
            )

            // 2. Load IndianAPI global weather (for temp, forecast, hourly)
            weatherRepository.getGlobalWeatherForecast(location, 3).fold(
                onSuccess = { _indianGlobalWeather.value = it },
                onFailure = { Timber.w(it, "IndianAPI global weather failed") }
            )

            // 3. Load WeatherAPI.com current (for condition icons, detailed data)
            weatherRepository.getCurrentWeather(location).fold(
                onSuccess = { _currentWeather.value = it },
                onFailure = { 
                    if (_indianCityWeather.value == null && _indianGlobalWeather.value == null) {
                        _error.value = it.message
                    }
                }
            )

            // 4. Load WeatherAPI.com forecast (for hourly icons)
            weatherRepository.getForecast(location, 3).fold(
                onSuccess = { _forecast.value = it },
                onFailure = { /* non-critical */ }
            )

            // 5. Load marine weather
            weatherRepository.getMarineWeather(location, 3).fold(
                onSuccess = { _marineWeather.value = it },
                onFailure = { /* non-critical */ }
            )

            _isLoading.value = false
        }
    }

    /**
     * Extract weather alerts from IMD forecast descriptions
     */
    private fun extractAlerts(response: IndianCityWeatherResponse) {
        val alerts = mutableListOf<String>()
        val forecasts = response.weather?.forecast ?: emptyList()
        
        forecasts.forEach { day ->
            val desc = day.description?.lowercase() ?: return@forEach
            // Flag severe weather conditions as alerts
            when {
                "heavy rain" in desc || "very heavy rain" in desc -> 
                    alerts.add("Heavy Rain Alert: ${day.description} on ${day.date}")
                "thunderstorm" in desc -> 
                    alerts.add("Thunderstorm Warning: ${day.description} on ${day.date}")
                "cyclone" in desc || "cyclonic" in desc -> 
                    alerts.add("Cyclone Alert: ${day.description} on ${day.date}")
                "storm" in desc -> 
                    alerts.add("Storm Warning: ${day.description} on ${day.date}")
                "flood" in desc -> 
                    alerts.add("Flood Warning: ${day.description} on ${day.date}")
                "moderate rain" in desc || "rain" in desc ->
                    alerts.add("Rain Alert: ${day.description} on ${day.date}")
            }
        }

        // Also check temperature extremes
        val maxTemp = response.weather?.current?.temperature?.max?.value
        if (maxTemp != null && maxTemp > 40) {
            alerts.add("Heat Wave Warning: Max temperature ${maxTemp}°C")
        }

        _weatherAlerts.value = alerts
        Timber.d("Extracted ${alerts.size} weather alerts")
    }

    fun refresh() {
        loadWeather(_currentLocation.value)
    }
}
