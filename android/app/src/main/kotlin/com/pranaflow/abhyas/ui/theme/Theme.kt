package com.pranaflow.abhyas.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val VedicSerenityColorScheme = darkColorScheme(
    primary = SanctuaryColors.Primary,
    onPrimary = SanctuaryColors.OnPrimary,
    primaryContainer = SanctuaryColors.PrimaryContainer,
    onPrimaryContainer = SanctuaryColors.OnPrimaryContainer,
    secondary = SanctuaryColors.Secondary,
    onSecondary = SanctuaryColors.OnSecondary,
    secondaryContainer = SanctuaryColors.SecondaryContainer,
    onSecondaryContainer = SanctuaryColors.OnPrimaryContainer,
    tertiary = SanctuaryColors.Tertiary,
    onTertiary = SanctuaryColors.OnTertiary,
    tertiaryContainer = SanctuaryColors.TertiaryContainer,
    onTertiaryContainer = SanctuaryColors.OnPrimaryContainer,
    background = SanctuaryColors.Surface,
    onBackground = SanctuaryColors.OnSurface,
    surface = SanctuaryColors.Surface,
    onSurface = SanctuaryColors.OnSurface,
    surfaceVariant = SanctuaryColors.SurfaceHighest,
    onSurfaceVariant = SanctuaryColors.OnSurfaceVariant,
    surfaceContainerLowest = SanctuaryColors.SurfaceLowest,
    surfaceContainerLow = SanctuaryColors.SurfaceLow,
    surfaceContainer = SanctuaryColors.SurfaceContainer,
    surfaceContainerHigh = SanctuaryColors.SurfaceHigh,
    surfaceContainerHighest = SanctuaryColors.SurfaceHighest,
    outline = SanctuaryColors.Outline,
    outlineVariant = SanctuaryColors.OutlineVariant,
    error = SanctuaryColors.Error,
    errorContainer = SanctuaryColors.ErrorContainer,
)

@Composable
fun VedicSerenityTheme(
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = VedicSerenityColorScheme,
        typography = SanctuaryTypography,
        content = content,
    )
}
