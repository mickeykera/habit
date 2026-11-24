package com.habittracker.app.ui.today

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.Habit
import com.habittracker.app.data.HabitDao
import com.habittracker.app.data.HabitLog
import com.habittracker.app.data.HabitType
import com.habittracker.app.domain.StreakCalculator
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.ui.components.CompletionCircle
import com.habittracker.app.ui.components.HairlineDivider
import com.habittracker.app.ui.components.InverseBadge
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun TodayScreen(habitDao: HabitDao) {
    val scope = rememberCoroutineScope()
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var showAddDialog by remember { mutableStateOf(false) }

    val activeHabits by habitDao.getActiveHabits().collectAsState(initial = emptyList())
    val selectedDateString = selectedDate.toString()
    val dailyLogs by habitDao.getLogsForDate(selectedDateString).collectAsState(initial = emptyList())

    val zeroBasedWeekday = selectedDate.dayOfWeek.value % 7
    val scheduledHabits = activeHabits.filter { it.isScheduledOn(zeroBasedWeekday) }
    val completedCount = scheduledHabits.count { habit ->
        dailyLogs.any { it.habitId == habit.id && it.isCompleted }
    }

    val dateFormatter = remember { DateTimeFormatter.ofPattern("EEEE, MMM d") }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true },
                containerColor = CobaltBlue,
                contentColor = CobaltLabel,
                shape = CircleShape
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Habit")
            }
        },
        containerColor = PageGround
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = selectedDate.format(dateFormatter),
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Medium,
                    color = PrimaryText,
                    letterSpacing = (-0.5).sp
                )
                Text(
                    text = "$completedCount / ${scheduledHabits.size}",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = FontFamily.Monospace,
                    color = CobaltBlue
                )
            }

            // 7-day Horizontal Week Strip
            WeekStrip(
                selectedDate = selectedDate,
                onDateSelected = { selectedDate = it }
            )

            HairlineDivider(modifier = Modifier.padding(vertical = 8.dp))

            // Habit List
            if (scheduledHabits.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 60.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("No habits scheduled", fontSize = 18.sp, color = SecondaryText)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text("Tap + to create a habit", fontSize = 14.sp, color = MutedText)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(scheduledHabits, key = { it.id }) { habit ->
                        val log = dailyLogs.find { it.habitId == habit.id }
                        val isDone = log?.isCompleted == true

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 4.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(CardSurface)
                                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                                .clickable {
                                    scope.launch {
                                        val newLog = HabitLog(
                                            id = log?.id ?: java.util.UUID.randomUUID().toString(),
                                            habitId = habit.id,
                                            dateString = selectedDateString,
                                            isCompleted = !isDone,
                                            isSlip = false
                                        )
                                        habitDao.insertOrUpdateLog(newLog)
                                    }
                                }
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            CompletionCircle(
                                isCompleted = isDone,
                                isQuit = habit.habitType == HabitType.QUIT,
                                onClick = {
                                    scope.launch {
                                        val newLog = HabitLog(
                                            id = log?.id ?: java.util.UUID.randomUUID().toString(),
                                            habitId = habit.id,
                                            dateString = selectedDateString,
                                            isCompleted = !isDone,
                                            isSlip = false
                                        )
                                        habitDao.insertOrUpdateLog(newLog)
                                    }
                                }
                            )

                            Column(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(start = 12.dp)
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = habit.title,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = PrimaryText
                                    )
                                    if (habit.habitType == HabitType.QUIT) {
                                        Spacer(modifier = Modifier.size(6.dp))
                                        InverseBadge("QUIT")
                                    }
                                }
                            }

                            // Streak
                            Text(
                                text = "1d",
                                fontSize = 14.sp,
                                fontFamily = FontFamily.Monospace,
                                color = MutedText
                            )
                        }
                    }
                }
            }
        }

        if (showAddDialog) {
            AddHabitDialog(
                onDismiss = { showAddDialog = false },
                onSave = { title, type, days ->
                    scope.launch {
                        habitDao.insertHabit(
                            Habit(
                                title = title,
                                type = type.value,
                                scheduleDays = days.joinToString(",")
                            )
                        )
                    }
                    showAddDialog = false
                }
            )
        }
    }
}
