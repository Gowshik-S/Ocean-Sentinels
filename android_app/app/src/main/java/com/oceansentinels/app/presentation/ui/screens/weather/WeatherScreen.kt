package com.oceansentinels.app.presentation.ui.screens.weather

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.oceansentinels.app.data.remote.dto.*
import com.oceansentinels.app.domain.model.UserRole
import com.oceansentinels.app.domain.model.UserSession
import com.oceansentinels.app.presentation.ui.components.OceanBottomNavBar
import com.oceansentinels.app.presentation.ui.theme.OceanColors
import com.oceansentinels.app.presentation.viewmodel.AuthViewModel
import com.oceansentinels.app.presentation.viewmodel.WeatherViewModel
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Weather Screen — Live weather from WeatherAPI.com
 * Gradient header, current conditions, hourly forecast,
 * 3-day forecast, marine data
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeatherScreen(
    onNavigateBack: () -> Unit,
    onNavigateToHome: () -> Unit,
    onNavigateToAlerts: () -> Unit,
    onNavigateToReport: () -> Unit,
    onNavigateToProfile: () -> Unit,
    onNavigateToAdmin: (() -> Unit)? = null,
    onNavigateToMesh: (() -> Unit)? = null,
    weatherViewModel: WeatherViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val currentWeather by weatherViewModel.currentWeather.collectAsState()
    val forecast by weatherViewModel.forecast.collectAsState()
    val marineWeather by weatherViewModel.marineWeather.collectAsState()
    val indianCityWeather by weatherViewModel.indianCityWeather.collectAsState()
    val weatherAlerts by weatherViewModel.weatherAlerts.collectAsState()
    val currentCity by weatherViewModel.currentCity.collectAsState()
    val isLoading by weatherViewModel.isLoading.collectAsState()
    val error by weatherViewModel.error.collectAsState()
    val currentLocation by weatherViewModel.currentLocation.collectAsState()

    val userSession by authViewModel.userSession.collectAsState()
    val userRole = (userSession as? UserSession.Authenticated)?.user?.role ?: UserRole.PUBLIC

    val scrollState = rememberScrollState()

    Scaffold(
        bottomBar = {
            OceanBottomNavBar(
                activeTab = "weather",
                onNavigateToHome = onNavigateToHome,
                onNavigateToAlerts = onNavigateToAlerts,
                onNavigateToWeather = { },
                onNavigateToReport = onNavigateToReport,
                onNavigateToProfile = onNavigateToProfile,
                userRole = userRole,
                onNavigateToAdmin = onNavigateToAdmin,
                onNavigateToMesh = onNavigateToMesh
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .background(MaterialTheme.colorScheme.background)
                .verticalScroll(scrollState)
        ) {
            // Gradient header
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                OceanColors.DashboardBlue,
                                OceanColors.Secondary
                            )
                        )
                    )
                    .statusBarsPadding()
                    .padding(20.dp)
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Weather",
                                style = MaterialTheme.typography.headlineMedium,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Default.LocationOn,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp),
                                    tint = OceanColors.Primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = currentWeather?.location?.name ?: currentLocation,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color.White.copy(alpha = 0.9f)
                                )
                            }
                        }
                        IconButton(onClick = { weatherViewModel.refresh() }) {
                            Icon(
                                Icons.Default.Refresh,
                                contentDescription = "Refresh",
                                tint = Color.White
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Current weather main display
                    if (isLoading && currentWeather == null) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(150.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(color = Color.White)
                        }
                    } else if (currentWeather != null) {
                        CurrentWeatherCard(currentWeather!!)
                    } else if (error != null) {
                        Text(
                            text = "Unable to load weather: $error",
                            color = Color.White.copy(alpha = 0.7f),
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.padding(vertical = 24.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // IMD (Indian Meteorological) City Weather from IndianAPI
            if (indianCityWeather != null) {
                ImdForecastSection(indianCityWeather!!)
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            // Weather alerts
            if (weatherAlerts.isNotEmpty()) {
                WeatherAlertsSection(weatherAlerts)
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Weather details grid
            if (currentWeather != null) {
                WeatherDetailsGrid(currentWeather!!.current)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Hourly forecast
            if (forecast?.forecast != null) {
                HourlyForecastSection(forecast!!)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // 3-day forecast
            if (forecast?.forecast != null) {
                DailyForecastSection(forecast!!.forecast!!)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Marine data
            if (marineWeather != null) {
                MarineDataSection(marineWeather!!)
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun CurrentWeatherCard(weather: WeatherResponse) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                text = "${weather.current.tempC.toInt()}°",
                style = MaterialTheme.typography.displayLarge.copy(fontSize = 72.sp),
                color = Color.White,
                fontWeight = FontWeight.Light
            )
            Text(
                text = weather.current.condition.text,
                style = MaterialTheme.typography.titleMedium,
                color = Color.White.copy(alpha = 0.9f)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Feels like ${weather.current.feelslikeC.toInt()}°C",
                style = MaterialTheme.typography.bodySmall,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
        // Weather icon from API
        AsyncImage(
            model = "https:${weather.current.condition.icon}".replace("64x64", "128x128"),
            contentDescription = weather.current.condition.text,
            modifier = Modifier.size(100.dp),
            contentScale = ContentScale.Fit
        )
    }
}

@Composable
private fun WeatherDetailsGrid(current: CurrentWeather) {
    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Text(
            text = "Weather Details",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Air,
                label = "Wind",
                value = "${current.windKph} km/h",
                subValue = current.windDir
            )
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.WaterDrop,
                label = "Humidity",
                value = "${current.humidity}%",
                subValue = null
            )
        }
        Spacer(modifier = Modifier.height(12.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Visibility,
                label = "Visibility",
                value = "${current.visKm} km",
                subValue = null
            )
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Speed,
                label = "Pressure",
                value = "${current.pressureMb.toInt()} mb",
                subValue = null
            )
        }
        Spacer(modifier = Modifier.height(12.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.WbSunny,
                label = "UV Index",
                value = "${current.uv}",
                subValue = getUvLabel(current.uv)
            )
            WeatherDetailCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Grain,
                label = "Precipitation",
                value = "${current.precipMm} mm",
                subValue = null
            )
        }
    }
}

@Composable
private fun WeatherDetailCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    label: String,
    value: String,
    subValue: String?
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = OceanColors.DashboardBlue.copy(alpha = 0.1f)
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .padding(14.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = OceanColors.Secondary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(10.dp))
            Column {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                if (subValue != null) {
                    Text(
                        text = subValue,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun HourlyForecastSection(weather: WeatherResponse) {
    val forecast = weather.forecast ?: return
    val todayHours = forecast.forecastDay.firstOrNull()?.hour ?: return
    val currentHour = LocalDateTime.now().hour
    val upcomingHours = todayHours.filter { hourWeather ->
        try {
            val hourTime = hourWeather.time.split(" ").getOrNull(1)?.split(":")?.firstOrNull()?.toIntOrNull() ?: 0
            hourTime >= currentHour
        } catch (e: Exception) { true }
    }

    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Text(
            text = "Hourly Forecast",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            items(upcomingHours) { hour ->
                HourlyCard(hour)
            }
        }
    }
}

@Composable
private fun HourlyCard(hour: HourWeather) {
    val time = try {
        val parts = hour.time.split(" ")
        if (parts.size >= 2) parts[1].substring(0, 5) else hour.time
    } catch (e: Exception) { hour.time }

    Card(
        colors = CardDefaults.cardColors(
            containerColor = OceanColors.DashboardBlue.copy(alpha = 0.12f)
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = time,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(6.dp))
            AsyncImage(
                model = "https:${hour.condition.icon}",
                contentDescription = hour.condition.text,
                modifier = Modifier.size(36.dp)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "${hour.tempC.toInt()}°",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold
            )
            if (hour.chanceOfRain > 0) {
                Text(
                    text = "${hour.chanceOfRain}%",
                    style = MaterialTheme.typography.labelSmall,
                    color = OceanColors.Secondary
                )
            }
        }
    }
}

@Composable
private fun DailyForecastSection(forecast: WeatherForecast) {
    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Text(
            text = "3-Day Forecast",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))

        forecast.forecastDay.forEach { day ->
            DailyForecastRow(day)
            if (day != forecast.forecastDay.last()) {
                HorizontalDivider(
                    modifier = Modifier.padding(vertical = 4.dp),
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                )
            }
        }
    }
}

@Composable
private fun DailyForecastRow(day: ForecastDay) {
    val dayName = try {
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val date = java.time.LocalDate.parse(day.date, formatter)
        if (date == java.time.LocalDate.now()) "Today"
        else date.format(DateTimeFormatter.ofPattern("EEE", Locale.ENGLISH))
    } catch (e: Exception) { day.date }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = OceanColors.DashboardBlue.copy(alpha = 0.08f)
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = dayName,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.width(50.dp)
            )
            AsyncImage(
                model = "https:${day.day.condition.icon}",
                contentDescription = day.day.condition.text,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = day.day.condition.text,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f)
            )
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${day.day.maxtempC.toInt()}° / ${day.day.mintempC.toInt()}°",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                if (day.day.dailyChanceOfRain > 0) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.WaterDrop,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = OceanColors.Secondary
                        )
                        Text(
                            text = "${day.day.dailyChanceOfRain}%",
                            style = MaterialTheme.typography.labelSmall,
                            color = OceanColors.Secondary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MarineDataSection(marine: MarineResponse) {
    val todayMarine = marine.forecast.forecastDay.firstOrNull() ?: return
    val currentHour = LocalDateTime.now().hour
    val nearestHour = todayMarine.hour.minByOrNull {
        val hr = try { it.time.split(" ").getOrNull(1)?.split(":")?.firstOrNull()?.toIntOrNull() ?: 0 } catch (e: Exception) { 0 }
        kotlin.math.abs(hr - currentHour)
    } ?: return

    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Text(
            text = "Marine Conditions",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = OceanColors.Secondary.copy(alpha = 0.1f)
            ),
            shape = RoundedCornerShape(12.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    MarineStat(
                        icon = Icons.Default.Waves,
                        label = "Wave Height",
                        value = "${nearestHour.sigHtMt ?: "N/A"} m"
                    )
                    MarineStat(
                        icon = Icons.Default.Height,
                        label = "Swell",
                        value = "${nearestHour.swellHtMt ?: "N/A"} m"
                    )
                    MarineStat(
                        icon = Icons.Default.Thermostat,
                        label = "Water Temp",
                        value = "${nearestHour.waterTempC ?: "N/A"}°C"
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    MarineStat(
                        icon = Icons.Default.Navigation,
                        label = "Swell Dir",
                        value = nearestHour.swellDir ?: "N/A"
                    )
                    MarineStat(
                        icon = Icons.Default.Timer,
                        label = "Swell Period",
                        value = "${nearestHour.swellPeriodSecs ?: "N/A"} s"
                    )
                    MarineStat(
                        icon = Icons.Default.Air,
                        label = "Wind",
                        value = "${nearestHour.windKph} km/h"
                    )
                }
            }
        }
    }
}

@Composable
private fun MarineStat(
    icon: ImageVector,
    label: String,
    value: String
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = OceanColors.Secondary,
            modifier = Modifier.size(22.dp)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

private fun getUvLabel(uv: Double): String {
    return when {
        uv <= 2 -> "Low"
        uv <= 5 -> "Moderate"
        uv <= 7 -> "High"
        uv <= 10 -> "Very High"
        else -> "Extreme"
    }
}

/**
 * IMD (Indian Meteorological Department) forecast from IndianAPI
 */
@Composable
private fun ImdForecastSection(weather: IndianCityWeatherResponse) {
    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Default.Flag,
                contentDescription = null,
                tint = OceanColors.Warning,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "IMD Forecast — ${weather.city ?: "India"}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(modifier = Modifier.height(12.dp))
        
        // Temperature from IMD
        val currentTemp = weather.weather?.current?.temperature
        val humidity = weather.weather?.current?.humidity
        
        if (currentTemp != null || humidity != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = OceanColors.Warning.copy(alpha = 0.08f)
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    if (currentTemp != null) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Current", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("${currentTemp.max?.value?.toInt() ?: "--"}°C", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Min", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("${currentTemp.min?.value?.toInt() ?: "--"}°C", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, color = OceanColors.Secondary)
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Max", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("${currentTemp.max?.value?.toInt() ?: "--"}°C", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, color = OceanColors.Error)
                        }
                    }
                    if (humidity != null) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Humidity", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("${humidity.morning ?: "--"}%", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, color = OceanColors.Info)
                        }
                    }
                }
            }
        }
        
        // IMD Forecast descriptions
        val forecasts = weather.weather?.forecast ?: emptyList()
        if (forecasts.isNotEmpty()) {
            Spacer(modifier = Modifier.height(12.dp))
            forecasts.forEach { day ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Icon(
                            Icons.Default.CalendarToday,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                            tint = OceanColors.DashboardBlue
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = day.date ?: "Upcoming",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                            if (day.description != null) {
                                Text(
                                    text = day.description,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Weather alerts section showing live alerts from IndianAPI
 */
@Composable
private fun WeatherAlertsSection(alerts: List<String>) {
    Column(modifier = Modifier.padding(horizontal = 20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Default.Warning,
                contentDescription = null,
                tint = OceanColors.Error,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "Active Weather Alerts",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = OceanColors.Error
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        alerts.forEach { alert ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 3.dp),
                colors = CardDefaults.cardColors(
                    containerColor = OceanColors.Error.copy(alpha = 0.08f)
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Text(
                    text = alert,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(12.dp),
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}
