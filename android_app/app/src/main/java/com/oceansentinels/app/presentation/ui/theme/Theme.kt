package com.oceansentinels.app.presentation.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * Light color scheme for Ocean Sentinels
 * Uses yellow/gold primary from design files
 */
private val LightColorScheme = lightColorScheme(
    primary = OceanColors.Primary,
    onPrimary = OceanColors.OnPrimary,
    primaryContainer = OceanColors.PrimaryLight,
    onPrimaryContainer = OceanColors.PrimaryDark,
    
    secondary = OceanColors.Secondary,
    onSecondary = OceanColors.OnSecondary,
    secondaryContainer = OceanColors.SecondaryLight,
    onSecondaryContainer = OceanColors.SecondaryDark,
    
    tertiary = OceanColors.Purple,
    onTertiary = Color.White,
    tertiaryContainer = OceanColors.InfoLight,
    onTertiaryContainer = OceanColors.Purple,
    
    error = OceanColors.Error,
    onError = OceanColors.OnError,
    errorContainer = OceanColors.ErrorLight,
    onErrorContainer = OceanColors.Error,
    
    background = OceanColors.Background,
    onBackground = OceanColors.OnBackground,
    
    surface = OceanColors.Surface,
    onSurface = OceanColors.OnSurface,
    surfaceVariant = OceanColors.SurfaceVariant,
    onSurfaceVariant = OceanColors.TextSecondary,
    
    outline = OceanColors.Divider,
    outlineVariant = OceanColors.CardBorder,
    
    scrim = OceanColors.Scrim
)

/**
 * Dark color scheme for Ocean Sentinels
 * Professional dark theme with excellent readability
 */
private val DarkColorScheme = darkColorScheme(
    primary = DarkModeColors.Primary,
    onPrimary = DarkModeColors.OnPrimary,
    primaryContainer = DarkModeColors.PrimaryVariant,
    onPrimaryContainer = DarkModeColors.OnPrimary,
    
    secondary = DarkModeColors.Secondary,
    onSecondary = DarkModeColors.OnSecondary,
    secondaryContainer = DarkModeColors.SecondaryVariant,
    onSecondaryContainer = DarkModeColors.TextPrimary,
    
    tertiary = DarkModeColors.Purple,
    onTertiary = DarkModeColors.Background,
    tertiaryContainer = DarkModeColors.Info,
    onTertiaryContainer = DarkModeColors.Background,
    
    error = DarkModeColors.Error,
    onError = DarkModeColors.OnError,
    errorContainer = DarkModeColors.ErrorLight,
    onErrorContainer = DarkModeColors.TextPrimary,
    
    background = DarkModeColors.Background,
    onBackground = DarkModeColors.TextPrimary,
    
    surface = DarkModeColors.Surface,
    onSurface = DarkModeColors.TextPrimary,
    surfaceVariant = DarkModeColors.SurfaceVariant,
    onSurfaceVariant = DarkModeColors.TextSecondary,
    
    outline = DarkModeColors.Border,
    outlineVariant = DarkModeColors.BorderMuted,
    
    scrim = OceanColors.Scrim,
    
    inverseSurface = DarkModeColors.TextPrimary,
    inverseOnSurface = DarkModeColors.Background,
    inversePrimary = OceanColors.Primary
)

/**
 * Ocean Sentinels App Theme
 */
@Composable
fun OceanSentinelsTheme(
    darkTheme: Boolean = false,
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val activity = view.context as? Activity
            activity?.window?.let { window ->
                // Use primary color for light theme, dark background for dark theme
                window.statusBarColor = if (darkTheme) {
                    DarkModeColors.Background.toArgb()
                } else {
                    colorScheme.primary.toArgb()
                }
                // Light status bar = dark icons (for light backgrounds), dark status bar = light icons
                WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            }
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
