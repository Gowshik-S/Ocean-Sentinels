# Ocean Sentinels Android App — Full Kotlin Source Audit

**Date:** June 2025  
**Scope:** All Kotlin source files under `app/src/main/java/com/oceansentinels/app/`  
**Versions:** Kotlin 1.9.22, Compose BOM 2024.02.00, Hilt 2.50, Room 2.6.1, Accompanist 0.34.0  
**Build Target:** Release APK  

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1     |
| WARNING  | 7     |
| INFO     | 5     |

---

## CRITICAL Issues

### 1. OceanPasswordField — Passwords displayed in plain text

| Field | Value |
|-------|-------|
| **File** | `presentation/ui/components/TextFields.kt` |
| **Lines** | 89–143 |
| **Severity** | **CRITICAL** |

`OceanPasswordField` calls `OceanTextField`, but `OceanTextField` has **no `visualTransformation` parameter**. The `PasswordVisualTransformation()` is never applied to the underlying `OutlinedTextField`. The trailing eye icon toggles `passwordVisible`, but the variable is unused beyond the icon swap — passwords are always rendered as plain text.

The comment on lines 142–143 confirms this is known-unfinished work:
```
// Apply visual transformation separately if needed
// Note: Since OceanTextField wraps OutlinedTextField, we need to handle this differently
```

**Impact:** Every password field in the app (Login, Register) shows the password in clear text. Critical for a release build.

**Fix:** Add a `visualTransformation` parameter to `OceanTextField` and pass it through to `OutlinedTextField`. Then pass `PasswordVisualTransformation()` / `VisualTransformation.None` from `OceanPasswordField` based on `passwordVisible`.

---

## WARNING Issues

### 2. MapScreen — Deprecated `LocalLifecycleOwner` import

| Field | Value |
|-------|-------|
| **File** | `presentation/ui/screens/map/MapScreen.kt` |
| **Line** | 16 |
| **Severity** | WARNING |

Imports `androidx.compose.ui.platform.LocalLifecycleOwner`, which is **deprecated** since Compose UI 1.6.0 (this project uses BOM `2024.02.00` = Compose UI ~1.6.2). The correct import is `androidx.lifecycle.compose.LocalLifecycleOwner`.

**Impact:** Deprecation warning during build. Will become a compile error in a future Compose version.

**Fix:** Change import to `import androidx.lifecycle.compose.LocalLifecycleOwner`.

---

### 3. WeatherViewModel — Direct data-layer dependency (architecture violation)

| Field | Value |
|-------|-------|
| **File** | `presentation/viewmodel/WeatherViewModel.kt` |
| **Line** | 6 |
| **Severity** | WARNING |

Imports `com.oceansentinels.app.data.repository.WeatherRepository` directly — a concrete class from the **data layer**. All other ViewModels depend on domain-layer interfaces. No `WeatherRepository` interface exists in `domain/repository/`.

**Impact:** Not a compile error, but violates the clean architecture enforced everywhere else. Makes `WeatherViewModel` untestable without the real `WeatherRepository` implementation.

**Fix:** Create `domain/repository/WeatherRepository.kt` interface, have the data-layer implementation implement it, add `@Binds` in `RepositoryModule`.

---

### 4. UserRepositoryImpl.updateUser() — Never calls the API

| Field | Value |
|-------|-------|
| **File** | `data/repository/UserRepositoryImpl.kt` |
| **Lines** | 148–183 |
| **Severity** | WARNING |

Constructs a `UserUpdateRequestDto` but never sends it via `api`. Only updates the local Room cache. The comment says _"The API might need a specific endpoint for updating other users."_

**Impact:** Admin user edits (name, phone, location, active status) appear saved but are **lost on next server sync**. The `UserUpdateRequestDto` object is created and immediately discarded.

**Fix:** Call the appropriate API endpoint (`api.updateUser(id, request)`) before updating local cache; or remove the unused DTO construction.

---

### 5. AuthRepositoryImpl.refreshToken() — Always fails

| Field | Value |
|-------|-------|
| **File** | `data/repository/AuthRepositoryImpl.kt` |
| **Lines** | 157–161 |
| **Severity** | WARNING |

Returns `Result.failure(Exception("Token refresh not implemented"))` unconditionally.

**Impact:** When the auth token expires, the app cannot renew it. Users will be silently logged out or start receiving 401 errors. For a release build this means sessions have a hard expiry with no recovery.

**Fix:** Implement a refresh-token API call, or at minimum force the user back to the login screen cleanly when the token expires.

---

### 6. IncidentRepositoryImpl.syncIncidents() — No-op sync

| Field | Value |
|-------|-------|
| **File** | `data/repository/IncidentRepositoryImpl.kt` |
| **Lines** | 210–225 |
| **Severity** | WARNING |

Iterates `getPendingSyncIncidents()` and only logs each. Then calls `getIncidents(IncidentFilters())` to refresh from server. Offline-created incidents are **never uploaded** to the server.

**Impact:** Any incidents created while offline will appear in the local DB but never reach the backend. After a fresh data pull they vanish.

**Fix:** For each pending incident, call `api.createIncident(...)` before clearing the pending-sync flag.

---

### 7. CreateIncidentRequestDto — `photoUrl` silently dropped

| Field | Value |
|-------|-------|
| **File** | `data/remote/dto/IncidentDto.kt` |
| **Lines** | 78–100 |
| **Severity** | WARNING |

`CreateIncidentRequest` (domain model, line 117 of `Incident.kt`) has a `photoUrl: String?` field. The `CreateIncidentRequestDto` has **no `photoUrl` field**, and `fromDomain()` does not map it.

**Impact:** Photos attached to incident reports are silently discarded during API submission.

**Fix:** Add `@SerializedName("photo_url") val photoUrl: String? = null` to `CreateIncidentRequestDto` and map it in `fromDomain()`.

---

### 8. MeshModule — Manual construction bypasses Hilt scoping

| Field | Value |
|-------|-------|
| **File** | `di/MeshModule.kt` |
| **Lines** | (entire file) |
| **Severity** | WARNING |

`MeshMessageRepository` is provided via `@Provides` with manual constructor invocation: `MeshMessageRepository(meshMessageDao, bleMeshManager, networkConnectivityManager, deviceIdentifier)`. It's annotated `@Singleton`, which is correct, but if any of its dependencies are **not** singletons, Hilt could inject different instances than the ones used during construction.

This is currently safe because all deps are also `@Singleton`, but it's fragile. If someone removes `@Singleton` from `BleMeshManager` or `DeviceIdentifier`, the module silently creates a stale instance.

**Impact:** Low risk today, but a maintenance trap.

**Fix:** Make `MeshMessageRepository` use `@Inject constructor` and let Hilt handle it, or add an interface + `@Binds`.

---

## INFO Issues

### 9. Converters.toStringList() — Comma delimiter is fragile

| Field | Value |
|-------|-------|
| **File** | `data/local/database/Converters.kt` |
| **Lines** | ~25–30 |
| **Severity** | INFO |

Splits and joins by `","`. If any list entry contains a comma, deserialization will produce corrupted data. Currently used only for BLE MAC-address relay paths (no commas), so it's safe today.

**Fix (hardening):** Switch to JSON array serialization via Gson.

---

### 10. Duplicate `parseDateTime()` extension function

| Field | Value |
|-------|-------|
| **Files** | `data/remote/dto/UserDto.kt`, `data/remote/dto/IncidentDto.kt` |
| **Severity** | INFO |

The same `private fun String.parseDateTime(): LocalDateTime?` is copy-pasted in both files. Not a compile error, but a DRY violation.

**Fix:** Extract to a shared `DateTimeUtils.kt` in a `util/` package.

---

### 11. Enum.fromValue() defaults silently mask bad data

| Field | Value |
|-------|-------|
| **Files** | `domain/model/User.kt`, `domain/model/Incident.kt`, `data/mesh/MeshMessage.kt` |
| **Severity** | INFO |

All enum `fromValue()` companion functions return a default value (e.g., `PUBLIC`, `OTHER`, `LOW`, `PENDING`) when the input string doesn't match any entry. No logging or telemetry.

**Impact:** If the API sends an unexpected enum string, the app silently maps it to a wrong default. This can cause hard-to-debug issues in production.

**Fix:** Add `Timber.w("Unknown value: $value, defaulting to ...")` in each `fromValue()`.

---

### 12. IncidentRepositoryImpl.getMyReports() — Identical to getIncidents()

| Field | Value |
|-------|-------|
| **File** | `data/repository/IncidentRepositoryImpl.kt` |
| **Lines** | 116–119 |
| **Severity** | INFO |

Simply delegates to `getIncidents(filters)`. The comment says the API filters by user based on the auth token. This is fine if the API contract guarantees it, but means there's no client-side distinction between "all incidents" and "my reports."

---

### 13. WeatherRepository companion constants — Empty API keys at build time

| Field | Value |
|-------|-------|
| **File** | `data/repository/WeatherRepository.kt` |
| **Severity** | INFO |

`BuildConfig.WEATHERAPI_KEY` and `BuildConfig.INDIAN_API_KEY` default to `""` in `build.gradle.kts` if not set in `local.properties`. The app won't crash but every weather API call will return 401/403.

**Fix:** Add a runtime check or build-time validation that the keys are non-empty for release builds.

---

## Verified — No Issues Found

The following areas were fully audited and **no compile errors, missing imports, or type mismatches** were found:

| Category | Status |
|----------|--------|
| **ViewModel ↔ Repository method signatures** | All match. Every repository method called by ViewModels exists in the interface and implementation. |
| **Repository Interface ↔ Impl bindings** | All 4 `@Binds` declarations in `RepositoryModule` correctly pair interfaces with implementations. |
| **Domain Model ↔ Entity mappings** | `UserEntity`, `IncidentEntity`, `MeshMessageEntity` all have correct `toDomain()` and `fromDomain()` functions. |
| **Domain Model ↔ DTO mappings** | All DTO `toDomain()` functions match domain model constructors (except `photoUrl` noted above). |
| **API interface return types** | All Retrofit interfaces return `Response<T>` or raw DTOs consistently. Repository impls handle both correctly. |
| **Room DAO queries** | All `@Query` SQL matches entity column names. Return types (`Flow<List<T>>`, `suspend fun`, `List<T>`) are correct. |
| **Navigation routes ↔ Screen arguments** | All 15 screen routes in `Screen.kt` match `OceanNavHost.kt` composable wiring. `incidentId` typed as `Int` consistently. |
| **Hilt @Inject constructors** | All `@AndroidEntryPoint` classes and `@HiltViewModel` classes have matching `@Inject constructor` declarations. |
| **@OptIn annotations** | All uses of `ExperimentalMaterial3Api` and `ExperimentalPermissionsApi` are correctly annotated and imported. |
| **Mesh type chain** | `MeshMessage`, `MeshPeer`, `MeshNetworkStatus`, `MeshMessageStatus`, `MeshTransport` — all referenced types exist and are correctly used across ViewModel → Repository → DAO → Entity. |
| **DemoRoleButton** | Defined in `Buttons.kt` (line 263), imported via wildcard in `LoginScreen.kt`. No issue. |
| **UI Component references** | All component functions (`StatusBadge`, `UrgencyBadge`, `OceanTextField`, `StatsCard`, etc.) are defined and imported correctly across all screens. |
| **BuildConfig fields** | `API_BASE_URL`, `MAPBOX_ACCESS_TOKEN`, `WEATHERAPI_KEY`, `INDIAN_API_KEY` all declared in `build.gradle.kts`. |
| **Accompanist dependency** | `accompanist-permissions` v0.34.0 declared in `libs.versions.toml` and consumed in `build.gradle.kts`. |

---

## Recommendations for Release

1. **Fix the password field immediately** — this is a user-visible security bug.
2. **Implement token refresh** or add explicit re-login flow on 401 responses.
3. **Add the `photoUrl` field** to `CreateIncidentRequestDto` so photos aren't silently lost.
4. **Implement real sync** in `syncIncidents()` or disable offline incident creation.
5. **Wire `updateUser()` to the API** or document that admin edits are local-only.
6. **Update the deprecated `LocalLifecycleOwner` import** to avoid future breakage.
7. **Validate API keys** are non-empty in release builds.
