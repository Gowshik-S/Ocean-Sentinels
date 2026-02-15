## Plan: Kotlin Android Mobile App for Ocean-Hazard

Create a native Android mobile application using Kotlin and Jetpack Compose that clones the existing Ocean-Hazard web frontend, providing a full-featured coastal safety reporting system for citizens and rescue teams.

### Steps

1. **Set up Android project structure** with Jetpack Compose, Hilt DI, Retrofit, and Navigation Component in a new `android_app/` directory with clean architecture layers (data, domain, presentation).

2. **Implement authentication module** with login/registration screens, JWT token management using EncryptedSharedPreferences, and automatic token refresh - mirroring [frontend/scripts/auth.js](frontend/scripts/auth.js) functionality.

3. **Create incident reporting feature** with hazard type selection, GPS location detection, photo capture, urgency selection, and form validation - replicating [frontend/scripts/report-modal.js](frontend/scripts/report-modal.js).

4. **Build "My Reports" screen** with RecyclerView/LazyColumn showing user's reports, status badges, filtering, and detail view - cloning [my-reports.html](frontend/pages/my-reports.html).

5. **Develop role-based incident dashboard** for Admin/Authority/Rescue roles with filtering, search, and actions (Verify, Deploy, Resolve) - based on [incident-reports.html](frontend/pages/incident-reports.html).

6. **Implement analytics dashboard** with charts using MPAndroidChart showing incident trends, status distribution, and urgency levels - mirroring [authority-analytics.html](frontend/pages/authority-analytics.html).

7. **Add admin management screens** for creating/managing rescue teams and authorities - cloning [admin-dashboard.html](frontend/pages/admin-dashboard.html).

8. **Integrate Google Maps SDK** for displaying incidents on map, location picker for reports, and user location tracking - replacing Mapbox from web version.

### Further Considerations

1. **Push Notifications**: Should we implement Firebase Cloud Messaging for real-time incident alerts? Recommended: Yes, for rescue teams.

2. **Offline Support**: Do you need offline capability with local Room database caching and sync when online? This adds complexity but improves reliability.

3. **Target SDK & Min SDK**: Recommended min SDK 24 (Android 7.0) for 95%+ device coverage. Confirm if different requirements exist.

add all these feature and lemme gimme a figma design which you can refer - https://www.figma.com/design/DEwUbt4grKJtDaB0OBRp1v/Ocean-Sentinels?node-id=50-30&t=II0wTf1rtNVjcktp-1

