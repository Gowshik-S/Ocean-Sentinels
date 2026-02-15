package com.oceansentinels.app.di

import com.oceansentinels.app.data.repository.AnalyticsRepositoryImpl
import com.oceansentinels.app.data.repository.AuthRepositoryImpl
import com.oceansentinels.app.data.repository.IncidentRepositoryImpl
import com.oceansentinels.app.data.repository.UserRepositoryImpl
import com.oceansentinels.app.domain.repository.AnalyticsRepository
import com.oceansentinels.app.domain.repository.AuthRepository
import com.oceansentinels.app.domain.repository.IncidentRepository
import com.oceansentinels.app.domain.repository.UserRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for repository dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        authRepositoryImpl: AuthRepositoryImpl
    ): AuthRepository

    @Binds
    @Singleton
    abstract fun bindIncidentRepository(
        incidentRepositoryImpl: IncidentRepositoryImpl
    ): IncidentRepository

    @Binds
    @Singleton
    abstract fun bindAnalyticsRepository(
        analyticsRepositoryImpl: AnalyticsRepositoryImpl
    ): AnalyticsRepository

    @Binds
    @Singleton
    abstract fun bindUserRepository(
        userRepositoryImpl: UserRepositoryImpl
    ): UserRepository
}
