package com.habittracker.app.ui.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.HabitDao
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.SecondaryText
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

@Composable
fun CalendarScreen(habitDao: HabitDao) {
    var currentMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDay by remember { mutableStateOf<LocalDate?>(null) }
    val habits by habitDao.getActiveHabits().collectAsState(initial = emptyList())

    val monthFormatter = remember { DateTimeFormatter.ofPattern("MMMM yyyy") }
    val dayNames = listOf("S", "M", "T", "W", "T", "F", "S")

    val daysInMonth = currentMonth.lengthOfMonth()
    val firstDayOfMonth = currentMonth.atDay(1)
    val leadingEmptyDays = firstDayOfMonth.dayOfWeek.value % 7

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .padding(16.dp)
    ) {
        // Month switcher
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { currentMonth = currentMonth.minusMonths(1) }) {
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Prev Month")
            }
            Text(
                text = currentMonth.format(monthFormatter),
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold,
                color = PrimaryText
            )
            IconButton(onClick = { currentMonth = currentMonth.plusMonths(1) }) {
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next Month")
            }
        }

        // Success Metric Header
        Column(
            modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "84%",
                fontSize = 42.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace,
                color = CobaltBlue
            )
            Text(
                text = "Monthly Success Rate",
                fontSize = 13.sp,
                color = MutedText
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Calendar Grid
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(12.dp)
        ) {
            // Days of week header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                dayNames.forEach { name ->
                    Text(
                        text = name,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = MutedText
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Day cells
            val totalCells = leadingEmptyDays + daysInMonth
            val rows = (totalCells + 6) / 7

            for (r in 0 until rows) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
                    horizontalArrangement = Arrangement.SpaceAround
                ) {
                    for (c in 0 until 7) {
                        val cellIndex = r * 7 + c
                        if (cellIndex in leadingEmptyDays until leadingEmptyDays + daysInMonth) {
                            val dayNumber = cellIndex - leadingEmptyDays + 1
                            val date = currentMonth.atDay(dayNumber)
                            val isSel = selectedDay == date

                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(if (isSel) CobaltBlue else Color.Transparent)
                                    .clickable { selectedDay = if (isSel) null else date },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = dayNumber.toString(),
                                    fontSize = 13.sp,
                                    fontFamily = FontFamily.Monospace,
                                    color = if (isSel) CobaltLabel else PrimaryText
                                )
                            }
                        } else {
                            Box(modifier = Modifier.size(34.dp))
                        }
                    }
                }
            }
        }

        // Day breakdown card
        selectedDay?.let { day ->
            Spacer(modifier = Modifier.height(16.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(CardSurface)
                    .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                    .padding(14.dp)
            ) {
                Text(
                    text = "${day.dayOfWeek.name.take(3)}, ${day.month.name.take(3)} ${day.dayOfMonth}",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = PrimaryText
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = "80% — 4 of 5 habits completed",
                    fontSize = 13.sp,
                    fontFamily = FontFamily.Monospace,
                    color = CobaltBlue
                )
            }
        }
    }
}
