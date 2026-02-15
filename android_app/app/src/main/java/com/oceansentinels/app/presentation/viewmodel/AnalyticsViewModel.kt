package com.oceansentinels.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.oceansentinels.app.domain.model.*
import com.oceansentinels.app.domain.repository.AnalyticsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for analytics-related operations
 */
@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val analyticsRepository: AnalyticsRepository
) : ViewModel() {

    // Dashboard analytics
    private val _dashboardAnalytics = MutableStateFlow<DashboardAnalytics?>(null)
    val dashboardAnalytics: StateFlow<DashboardAnalytics?> = _dashboardAnalytics.asStateFlow()

    // Timeline data
    private val _timeline = MutableStateFlow<IncidentsTimeline?>(null)
    val timeline: StateFlow<IncidentsTimeline?> = _timeline.asStateFlow()

    // Distribution data
    private val _distribution = MutableStateFlow<IncidentsDistribution?>(null)
    val distribution: StateFlow<IncidentsDistribution?> = _distribution.asStateFlow()

    // Geographic data
    private val _geographic = MutableStateFlow<GeographicAnalytics?>(null)
    val geographic: StateFlow<GeographicAnalytics?> = _geographic.asStateFlow()

    // Loading state
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Error state
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // Timeline period (days)
    private val _timelinePeriod = MutableStateFlow(30)
    val timelinePeriod: StateFlow<Int> = _timelinePeriod.asStateFlow()

    init {
        loadAllAnalytics()
    }

    /**
     * Load all analytics data
     */
    fun loadAllAnalytics() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val result = analyticsRepository.getAllAnalytics()

            result.fold(
                onSuccess = { data ->
                    _dashboardAnalytics.value = data.dashboard
                    _timeline.value = data.timeline
                    _distribution.value = data.distribution
                    _geographic.value = data.geographic
                    Timber.d("Analytics loaded successfully")
                },
                onFailure = { error ->
                    _error.value = error.message
                    Timber.e(error, "Failed to load analytics")
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load dashboard analytics only
     */
    fun loadDashboardAnalytics() {
        viewModelScope.launch {
            _isLoading.value = true

            val result = analyticsRepository.getDashboardAnalytics()

            result.fold(
                onSuccess = { data ->
                    _dashboardAnalytics.value = data
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load timeline for specified period
     */
    fun loadTimeline(days: Int = 30) {
        viewModelScope.launch {
            _isLoading.value = true
            _timelinePeriod.value = days

            val result = analyticsRepository.getIncidentsTimeline(days)

            result.fold(
                onSuccess = { data ->
                    _timeline.value = data
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load distribution data
     */
    fun loadDistribution() {
        viewModelScope.launch {
            _isLoading.value = true

            val result = analyticsRepository.getIncidentsDistribution()

            result.fold(
                onSuccess = { data ->
                    _distribution.value = data
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Load geographic analytics
     */
    fun loadGeographic() {
        viewModelScope.launch {
            _isLoading.value = true

            val result = analyticsRepository.getGeographicAnalytics()

            result.fold(
                onSuccess = { data ->
                    _geographic.value = data
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )

            _isLoading.value = false
        }
    }

    /**
     * Refresh all analytics
     */
    fun refresh() {
        loadAllAnalytics()
    }

    /**
     * Clear error
     */
    fun clearError() {
        _error.value = null
    }
}
