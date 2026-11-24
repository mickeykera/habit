package com.habittracker.app.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Flat single-color brushes for clean minimal surfaces
val PaperGroundBrush: Brush = SolidColor(PageGround)
val CardBrush: Brush = SolidColor(CardSurface)
val WellBrush: Brush = SolidColor(CardSurface)
val CobaltEnamelBrush: Brush = SolidColor(CobaltBlue)
val CharcoalBrush: Brush = SolidColor(InverseSurface)
val TopLightBevel: Brush = SolidColor(Color.Transparent)
val ReverseBevel: Brush = SolidColor(Color.Transparent)
val GoldMedalBrush: Brush = SolidColor(CobaltBlue)
val SilverMedalBrush: Brush = SolidColor(CardSurface)
val BronzeMedalBrush: Brush = SolidColor(CardSurface)

private val LightColorScheme = lightColorScheme(
    primary = CobaltBlue,
    onPrimary = CobaltLabel,
    background = PageGround,
    onBackground = PrimaryText,
    surface = CardSurface,
    onSurface = PrimaryText,
    outline = Hairline
)

val EditorialTypography = Typography(
    headlineLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 32.sp,
        color = PrimaryText,
        letterSpacing = (-0.5).sp
    ),
    titleMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        color = PrimaryText
    ),
    bodyLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        color = PrimaryText
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        color = SecondaryText
    ),
    labelMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 13.sp,
        color = MutedText
    )
)

@Composable
fun HabitTrackerTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography = EditorialTypography,
        content = content
    )
}
