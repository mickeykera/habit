package com.habittracker.app.ui.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PrimaryText
import java.time.LocalDate

@Composable
fun WeekStrip(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    val dayLabels = listOf("S", "M", "T", "W", "T", "F", "S")

    // Find the Sunday of current selected week
    val currentZeroBasedDay = selectedDate.dayOfWeek.value % 7
    val sunday = selectedDate.minusDays(currentZeroBasedDay.toLong())
    val weekDates = (0..6).map { sunday.plusDays(it.toLong()) }
    val today = LocalDate.now()

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        weekDates.forEachIndexed { index, date ->
            val isSelected = date == selectedDate
            val isToday = date == today

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clip(CircleShape)
                    .clickable { onDateSelected(date) }
                    .padding(vertical = 4.dp, horizontal = 6.dp)
            ) {
                Text(
                    text = dayLabels[index],
                    fontSize = 12.sp,
                    color = if (isSelected) CobaltBlue else MutedText,
                    fontWeight = FontWeight.Medium
                )
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(CircleShape)
                        .then(
                            when {
                                isSelected -> Modifier.background(CobaltBlue)
                                isToday -> Modifier.border(1.dp, CobaltBlue.copy(alpha = 0.5f), CircleShape)
                                else -> Modifier
                            }
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = date.dayOfMonth.toString(),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        fontFamily = FontFamily.Monospace,
                        color = if (isSelected) CobaltLabel else PrimaryText
                    )
                }
            }
        }
    }
}
