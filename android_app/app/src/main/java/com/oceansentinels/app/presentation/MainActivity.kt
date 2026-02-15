package com.oceansentinels.app.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.navigation.compose.rememberNavController
import com.oceansentinels.app.presentation.navigation.OceanNavHost
import com.oceansentinels.app.presentation.ui.theme.OceanSentinelsTheme
import com.oceansentinels.app.presentation.viewmodel.ThemeViewModel
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main Activity for Ocean Sentinels Android App
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    private val themeViewModel: ThemeViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen
        installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display
        enableEdgeToEdge()
        
        setContent {
            val isDarkMode by themeViewModel.isDarkMode.collectAsState()
            
            OceanSentinelsTheme(darkTheme = isDarkMode) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    OceanNavHost(navController = navController)
                }
            }
        }
    }
}
