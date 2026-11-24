package com.habittracker.app.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

val PaperGroundBrush = Brush.verticalGradient(listOf(PaperLight, PaperDark))
val CardBrush = Brush.verticalGradient(listOf(CardTop, CardBottom))
val WellBrush = Brush.verticalGradient(listOf(WellTop, WellBottom))
val CobaltEnamelBrush = Brush.verticalGradient(listOf(CobaltLight, CobaltBlue, CobaltDeep))
val CharcoalBrush = Brush.verticalGradient(listOf(CharcoalLight, CharcoalDark))
val TopLightBevel = Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.85f), Color.Black.copy(alpha = 0.12f)))
val ReverseBevel = Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.18f), Color.White.copy(alpha = 0.75f)))
val GoldMedalBrush = Brush.verticalGradient(listOf(GoldLight, GoldMid, GoldDark))
val SilverMedalBrush = Brush.verticalGradient(listOf(SilverLight, SilverMid, SilverDark))
val BronzeMedalBrush = Brush.verticalGradient(listOf(BronzeLight, BronzeMid, BronzeDark))

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
