package com.pranaflow.abhyas

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.pranaflow.abhyas.ui.navigation.AbhyasApp

/**
 * Android native entry point for PranaFlow (Abhyas), launching the Vedic Serenity Compose UI
 * backed by the offline DataStore repositories and pure Kotlin :engine.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AbhyasApp()
        }
    }
}
