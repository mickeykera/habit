package com.habittracker.app.ui.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import java.time.LocalDate

@Composable
fun WeekStrip(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    val dayLabels = listOf("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su")

    // Find the Monday of current selected week
    val currentZeroBasedDay = (selectedDate.dayOfWeek.value + 5) % 7 // Monday = 0
    val monday = selectedDate.minusDays(currentZeroBasedDay.toLong())
    val weekDates = (0..6).map { monday.plusDays(it.toLong()) }
    val today = LocalDate.now()

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(PageGround)
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        weekDates.forEachIndexed { index, date ->
            val isSelected = date == selectedDate
            val isToday = date == today

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier
                    .clip(CircleShape)
                    .then(
                        if (isSelected) {
                            Modifier.background(CardSurface)
                        } else {
                            Modifier
                        }
                    )
                    .clickable { onDateSelected(date) }
                    .padding(vertical = 6.dp, horizontal = 4.dp)
                    .height(64.dp)
            ) {
                Text(
                    text = dayLabels[index],
                    fontSize = 11.sp,
                    color = if (isSelected) CobaltBlue else MutedText,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(4.dp))
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .then(
                            when {
                                isSelected -> Modifier
                                    .background(CobaltBlue.copy(alpha = 0.12f))
                                    .border(2.dp, CobaltBlue, CircleShape)
                                isToday -> Modifier
                                    .background(CardSurface)
                                else -> Modifier
                            }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = date.dayOfMonth.toString(),
                        fontSize = 13.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                        fontFamily = FontFamily.Monospace,
                        color = if (isSelected || isToday) CobaltBlue else PrimaryText
                    )
                }
            }
        }
    }
}
