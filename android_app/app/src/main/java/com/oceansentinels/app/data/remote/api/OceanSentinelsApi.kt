package com.oceansentinels.app.data.remote.api

import com.oceansentinels.app.data.remote.dto.*
import okhttp3.MultipartBody
import retrofit2.Response
import retrofit2.http.*

/**
 * Retrofit API service interface for Ocean Sentinels backend
 */
interface OceanSentinelsApi {

    // ============= Authentication =============
    
    @FormUrlEncoded
    @POST("auth/login")
    suspend fun login(
        @Field("username") username: String,
        @Field("password") password: String
    ): Response<AuthResponseDto>
    
    @POST("auth/register")
    suspend fun register(
        @Body request: RegisterRequestDto
    ): Response<UserDto>
    
    // ============= Users =============
    
    @GET("users/me")
    suspend fun getCurrentUser(): Response<UserDto>
    
    @PUT("users/me")
    suspend fun updateCurrentUser(
        @Body request: UserUpdateRequestDto
    ): Response<UserDto>
    
    @GET("users/")
    suspend fun getAllUsers(): Response<List<UserDto>>
    
    @GET("users/{id}")
    suspend fun getUser(
        @Path("id") id: Int
    ): Response<UserDto>
    
    @DELETE("users/{id}")
    suspend fun deleteUser(
        @Path("id") id: Int
    ): Response<Unit>
    
    @POST("users/create")
    suspend fun adminCreateUser(
        @Body request: RegisterRequestDto
    ): Response<UserDto>
    
    // ============= Incidents =============
    
    @GET("incidents/")
    suspend fun getIncidents(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20,
        @Query("status") status: String? = null,
        @Query("hazard_type") hazardType: String? = null,
        @Query("urgency") urgency: String? = null,
        @Query("search") search: String? = null
    ): Response<IncidentListResponseDto>
    
    @GET("incidents/{id}")
    suspend fun getIncident(
        @Path("id") id: Int
    ): Response<IncidentDto>
    
    @POST("incidents/")
    suspend fun createIncident(
        @Body request: CreateIncidentRequestDto
    ): Response<IncidentDto>

    /**
     * Bulk check which mesh message IDs have already been delivered to the server.
     * Called when a device comes online to discover messages already uploaded by
     * other mesh peers. Those can be marked DELIVERED locally and stop relaying.
     */
    @POST("incidents/mesh/check")
    suspend fun checkMeshMessages(
        @Body request: MeshCheckRequestDto
    ): Response<MeshCheckResponseDto>
    
    @PUT("incidents/{id}/verify")
    suspend fun verifyIncident(
        @Path("id") id: Int
    ): Response<MessageResponseDto>
    
    @PUT("incidents/{id}/deploy")
    suspend fun deployResponse(
        @Path("id") id: Int
    ): Response<MessageResponseDto>
    
    @PUT("incidents/{id}/resolve")
    suspend fun resolveIncident(
        @Path("id") id: Int
    ): Response<MessageResponseDto>
    
    @PUT("incidents/{id}/assign")
    suspend fun assignIncident(
        @Path("id") id: Int,
        @Body body: Map<String, Int>
    ): Response<MessageResponseDto>
    
    @GET("incidents/assigned/me")
    suspend fun getMyAssignedIncidents(
        @Query("page") page: Int = 1,
        @Query("size") size: Int = 20
    ): Response<IncidentListResponseDto>
    
    // ============= Analytics =============
    
    @GET("analytics/dashboard")
    suspend fun getDashboardAnalytics(): Response<DashboardAnalyticsDto>
    
    @GET("analytics/incidents/timeline")
    suspend fun getIncidentsTimeline(
        @Query("days") days: Int = 30
    ): Response<IncidentsTimelineDto>
    
    @GET("analytics/incidents/distribution")
    suspend fun getIncidentsDistribution(): Response<IncidentsDistributionDto>
    
    @GET("analytics/geographic")
    suspend fun getGeographicAnalytics(): Response<GeographicAnalyticsDto>
    
    // ============= File Upload =============
    
    @Multipart
    @POST("upload/incident-photo")
    suspend fun uploadIncidentPhoto(
        @Part photo: MultipartBody.Part
    ): Response<UploadResponseDto>
}

/**
 * Response for file upload
 */
data class UploadResponseDto(
    val url: String,
    val filename: String
)
