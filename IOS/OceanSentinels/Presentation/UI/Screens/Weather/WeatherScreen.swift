import SwiftUI

// MARK: - WeatherScreen

struct WeatherScreen: View {
    @Environment(WeatherViewModel.self) private var weatherViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Gradient header
                weatherHeader
                
                // IMD Forecast
                if let indianWeather = weatherViewModel.indianCityWeather {
                    imdForecastSection(indianWeather)
                }
                
                // Weather alerts
                if !weatherViewModel.weatherAlerts.isEmpty {
                    weatherAlertsSection
                }
                
                // Weather details grid
                if let current = weatherViewModel.currentWeather?.current {
                    weatherDetailsGrid(current)
                }
                
                // Hourly forecast
                if let weather = weatherViewModel.currentWeather {
                    hourlyForecastSection(weather)
                }
                
                // 3-day forecast
                if !weatherViewModel.forecast.isEmpty {
                    dailyForecastSection(weatherViewModel.forecast)
                }
                
                // Marine data
                if let marine = weatherViewModel.marineWeather {
                    marineDataSection(marine)
                }
                
                Spacer(minLength: 24)
            }
        }
        .navigationTitle("Weather")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { weatherViewModel.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { weatherViewModel.refresh() }
    }

    // MARK: - Header

    private var weatherHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Weather").font(.title.bold()).foregroundStyle(.white)
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").font(.caption).foregroundStyle(Color.oceanPrimary)
                        Text(weatherViewModel.currentWeather?.location.name ?? weatherViewModel.currentLocation)
                            .font(.subheadline).foregroundStyle(.white.opacity(0.9))
                    }
                }
                Spacer()
                Button { weatherViewModel.refresh() } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.white)
                }
            }

            if weatherViewModel.isLoading && weatherViewModel.currentWeather == nil {
                ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 150)
            } else if let weather = weatherViewModel.currentWeather {
                currentWeatherCard(weather)
            } else if let error = weatherViewModel.error {
                Text("Unable to load weather: \(error)")
                    .foregroundStyle(.white.opacity(0.7)).font(.subheadline)
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color.oceanInfo, Color.oceanSecondary], startPoint: .top, endPoint: .bottom)
        )
    }

    private func currentWeatherCard(_ weather: WeatherResponse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weather.current.tempC))°")
                    .font(.system(size: 72, weight: .light)).foregroundStyle(.white)
                Text(weather.current.condition.text)
                    .font(.headline).foregroundStyle(.white.opacity(0.9))
                Text("Feels like \(Int(weather.current.feelslikeC))°C")
                    .font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            AsyncImage(url: URL(string: "https:\(weather.current.condition.icon)".replacingOccurrences(of: "64x64", with: "128x128"))) { phase in
                if let image = phase.image { image.resizable().scaledToFit() }
                else { ProgressView().tint(.white) }
            }
            .frame(width: 100, height: 100)
        }
    }

    // MARK: - Weather Details Grid

    private func weatherDetailsGrid(_ current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Details").font(.headline).padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                weatherDetailCard(icon: "wind", label: "Wind", value: "\(current.windKph) km/h", sub: current.windDir)
                weatherDetailCard(icon: "humidity.fill", label: "Humidity", value: "\(current.humidity)%", sub: nil)
                weatherDetailCard(icon: "eye.fill", label: "Visibility", value: "\(current.visKm) km", sub: nil)
                weatherDetailCard(icon: "gauge.medium", label: "Pressure", value: "\(Int(current.pressureMb)) mb", sub: nil)
                weatherDetailCard(icon: "sun.max.fill", label: "UV Index", value: "\(current.uv)", sub: uvLabel(current.uv))
                weatherDetailCard(icon: "cloud.rain.fill", label: "Precipitation", value: "\(current.precipMm) mm", sub: nil)
            }
            .padding(.horizontal, 20)
        }
    }

    private func weatherDetailCard(icon: String, label: String, value: String, sub: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color.oceanSecondary).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.semibold))
                if let sub { Text(sub).font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.oceanInfo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Hourly Forecast

    private func hourlyForecastSection(_ weather: WeatherResponse) -> some View {
        let hours = weather.forecast?.forecastDay.first?.hour ?? []
        let currentHour = Calendar.current.component(.hour, from: Date())
        let upcoming = hours.filter { h in
            guard let hourStr = h.time.split(separator: " ").last?.split(separator: ":").first,
                  let hr = Int(hourStr) else { return true }
            return hr >= currentHour
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast").font(.headline).padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upcoming, id: \.time) { hour in
                        hourlyCard(hour)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func hourlyCard(_ hour: HourWeather) -> some View {
        let time = String(hour.time.split(separator: " ").last?.prefix(5) ?? "")
        return VStack(spacing: 6) {
            Text(time).font(.caption).foregroundStyle(.secondary)
            AsyncImage(url: URL(string: "https:\(hour.condition.icon)")) { phase in
                if let image = phase.image { image.resizable().scaledToFit() }
                else { Image(systemName: "cloud.fill") }
            }
            .frame(width: 36, height: 36)
            Text("\(Int(hour.tempC))°").font(.subheadline.bold())
            if hour.chanceOfRain > 0 {
                Text("\(hour.chanceOfRain)%").font(.caption2).foregroundStyle(Color.oceanSecondary)
            }
        }
        .padding(12)
        .background(Color.oceanInfo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Forecast

    private func dailyForecastSection(_ days: [ForecastDay]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3-Day Forecast").font(.headline).padding(.horizontal, 20)
            VStack(spacing: 8) {
                ForEach(days, id: \.date) { day in
                    dailyRow(day)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func dailyRow(_ day: ForecastDay) -> some View {
        let dayName: String = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            if let date = fmt.date(from: day.date), Calendar.current.isDateInToday(date) { return "Today" }
            if let date = fmt.date(from: day.date) {
                let dayFmt = DateFormatter()
                dayFmt.dateFormat = "EEE"
                return dayFmt.string(from: date)
            }
            return day.date
        }()

        return HStack {
            Text(dayName).font(.subheadline.weight(.medium)).frame(width: 50, alignment: .leading)
            AsyncImage(url: URL(string: "https:\(day.day.condition.icon)")) { phase in
                if let image = phase.image { image.resizable().scaledToFit() }
                else { Image(systemName: "cloud.fill") }
            }
            .frame(width: 32, height: 32)
            Text(day.day.condition.text).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(Int(day.day.maxtempC))° / \(Int(day.day.mintempC))°").font(.subheadline.weight(.semibold))
                if day.day.dailyChanceOfRain > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill").font(.caption2).foregroundStyle(Color.oceanSecondary)
                        Text("\(day.day.dailyChanceOfRain)%").font(.caption2).foregroundStyle(Color.oceanSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.oceanInfo.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - IMD Forecast

    private func imdForecastSection(_ weather: IndianCityWeatherResponse) -> some View {
        let temperature = weather.weather?.current?.temperature
        let humidityOpt = weather.weather?.current?.humidity
        let forecastDays = weather.weather?.forecast ?? []
        let cityName = weather.city.isEmpty ? "India" : weather.city
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill").foregroundStyle(Color.oceanWarning)
                Text("IMD Forecast — \(cityName)").font(.headline)
            }
            .padding(.horizontal, 20)

            if let temp = temperature {
                HStack(spacing: 24) {
                    VStack { Text("Current").font(.caption).foregroundStyle(.secondary); Text("\(Int(temp.max?.value ?? 0))°C").font(.title3.bold()) }
                    VStack { Text("Min").font(.caption).foregroundStyle(.secondary); Text("\(Int(temp.min?.value ?? 0))°C").font(.subheadline.weight(.medium)).foregroundStyle(Color.oceanSecondary) }
                    VStack { Text("Max").font(.caption).foregroundStyle(.secondary); Text("\(Int(temp.max?.value ?? 0))°C").font(.subheadline.weight(.medium)).foregroundStyle(Color.oceanDanger) }
                    if let humidity = humidityOpt {
                        VStack { Text("Humidity").font(.caption).foregroundStyle(.secondary); Text("\(Int(humidity.morning ?? 0))%").font(.subheadline.weight(.medium)).foregroundStyle(Color.oceanInfo) }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.oceanWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }

            ForEach(forecastDays, id: \.date) { day in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "calendar").font(.caption).foregroundStyle(Color.oceanInfo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.date ?? "Upcoming").font(.caption.weight(.semibold))
                        if let desc = day.description { Text(desc).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Marine Data

    private func marineDataSection(_ marine: MarineResponse) -> some View {
        guard let todayMarine = marine.forecast.forecastDay.first else { return AnyView(EmptyView()) }
        let currentHour = Calendar.current.component(.hour, from: Date())
        guard let nearestHour = todayMarine.hour.min(by: { a, b in
            let hrA = Int(a.time.split(separator: " ").last?.split(separator: ":").first ?? "") ?? 0
            let hrB = Int(b.time.split(separator: " ").last?.split(separator: ":").first ?? "") ?? 0
            return abs(hrA - currentHour) < abs(hrB - currentHour)
        }) else { return AnyView(EmptyView()) }

        return AnyView(VStack(alignment: .leading, spacing: 12) {
            Text("Marine Conditions").font(.headline).padding(.horizontal, 20)
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    marineStat(icon: "water.waves", label: "Wave Height", value: nearestHour.sigHtMt.map { String(format: "%.1f", $0) + " m" } ?? "N/A")
                    marineStat(icon: "arrow.up.and.down", label: "Swell", value: nearestHour.swellHtMt.map { String(format: "%.1f", $0) + " m" } ?? "N/A")
                    marineStat(icon: "thermometer.medium", label: "Water Temp", value: nearestHour.waterTempC.map { String(format: "%.1f", $0) + "°C" } ?? "N/A")
                }
                HStack(spacing: 16) {
                    marineStat(icon: "location.north.fill", label: "Swell Dir", value: nearestHour.swellDir ?? "N/A")
                    marineStat(icon: "timer", label: "Swell Period", value: nearestHour.swellPeriodSecs.map { String(format: "%.1f", $0) + " s" } ?? "N/A")
                    marineStat(icon: "wind", label: "Wind", value: "\(nearestHour.windKph) km/h")
                }
            }
            .padding(16)
            .background(Color.oceanSecondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        })
    }

    private func marineStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.body).foregroundStyle(Color.oceanSecondary)
            Text(value).font(.caption.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weather Alerts

    private var weatherAlertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.oceanDanger)
                Text("Active Weather Alerts").font(.headline).foregroundStyle(Color.oceanDanger)
            }
            .padding(.horizontal, 20)

            ForEach(weatherViewModel.weatherAlerts) { alert in
                Text(alert.description)
                    .font(.caption)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.oceanDanger.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func uvLabel(_ uv: Double) -> String {
        switch uv {
        case ...2: return "Low"
        case ...5: return "Moderate"
        case ...7: return "High"
        case ...10: return "Very High"
        default: return "Extreme"
        }
    }
}
