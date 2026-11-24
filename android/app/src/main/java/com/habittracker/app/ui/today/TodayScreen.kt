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
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.shadow
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
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import com.habittracker.app.ui.components.CompletionCircle
import com.habittracker.app.ui.components.HairlineDivider
import com.habittracker.app.ui.components.InverseBadge
import kotlinx.coroutines.launch
import java.time.LocalDate

enum class TodayFilter(val label: String) {
    ALL("All"),
    BUILD("Build"),
    QUIT("Quit")
}

@Composable
fun TodayScreen(
    habitDao: HabitDao,
    syncService: com.habittracker.app.service.SupabaseSyncService? = null,
    onOpenAdd: () -> Unit = {}
) {
    val scope = rememberCoroutineScope()
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var selectedFilter by remember { mutableStateOf(TodayFilter.ALL) }
    var showFilterMenu by remember { mutableStateOf(false) }

    val activeHabits by habitDao.getActiveHabits().collectAsState(initial = emptyList())
    val selectedDateString = selectedDate.toString()
    val dailyLogs by habitDao.getLogsForDate(selectedDateString).collectAsState(initial = emptyList())

    val zeroBasedWeekday = selectedDate.dayOfWeek.value % 7
    val scheduledHabits = activeHabits.filter { habit ->
        val isScheduled = habit.isScheduledOn(zeroBasedWeekday)
        if (!isScheduled) return@filter false
        when (selectedFilter) {
            TodayFilter.ALL -> true
            TodayFilter.BUILD -> habit.habitType == HabitType.BUILD
            TodayFilter.QUIT -> habit.habitType == HabitType.QUIT
        }
    }

    val completedCount = scheduledHabits.count { habit ->
        dailyLogs.any { it.habitId == habit.id && it.isCompleted }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
    ) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left: Filter Pill
            Box {
                Row(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(CardSurface)
                        .clickable { showFilterMenu = true }
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = selectedFilter.label,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = PrimaryText
                    )
                    Spacer(modifier = Modifier.size(4.dp))
                    Icon(
                        imageVector = Icons.Default.KeyboardArrowDown,
                        contentDescription = "Filter",
                        tint = MutedText,
                        modifier = Modifier.size(14.dp)
                    )
                }

                DropdownMenu(
                    expanded = showFilterMenu,
                    onDismissRequest = { showFilterMenu = false }
                ) {
                    TodayFilter.entries.forEach { filter ->
                        DropdownMenuItem(
                            text = { Text(filter.label) },
                            onClick = {
                                selectedFilter = filter
                                showFilterMenu = false
                            }
                        )
                    }
                }
            }

            // Center: Today Title + Count
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Today",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Medium,
                    color = PrimaryText
                )
                Text(
                    text = "$completedCount / ${scheduledHabits.size}",
                    fontSize = 12.sp,
                    fontFamily = FontFamily.Monospace,
                    color = CobaltBlue
                )
            }

            // Right: Profile/Status Button
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(CardSurface)
                    .clickable { onOpenAdd() },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add",
                    tint = CobaltBlue,
                    modifier = Modifier.size(18.dp)
                )
            }
        }

        // 7-day Horizontal Week Strip
        WeekStrip(
            selectedDate = selectedDate,
            onDateSelected = { selectedDate = it }
        )

        Spacer(modifier = Modifier.height(10.dp))

        // Habit List
        if (scheduledHabits.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = 60.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(CobaltBlue.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = CobaltBlue,
                            modifier = Modifier.size(26.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                    Text("No habits scheduled", fontSize = 17.sp, fontWeight = FontWeight.Medium, color = SecondaryText)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Tap + to create or unfilter habits", fontSize = 13.sp, color = MutedText)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(scheduledHabits, key = { it.id }) { habit ->
                    val log = dailyLogs.find { it.habitId == habit.id }
                    val isDone = log?.isCompleted == true

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (isDone) CobaltBlue.copy(alpha = 0.08f) else CardSurface)
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
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Left: Icon Badge
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .then(
                                    if (isDone) {
                                        Modifier
                                            .background(CobaltBlue.copy(alpha = 0.12f))
                                            .border(1.dp, CobaltBlue.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
                                    } else {
                                        Modifier
                                            .background(WellBrush)
                                            .border(1.dp, ReverseBevel, RoundedCornerShape(10.dp))
                                    }
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                tint = if (isDone) CobaltBlue else SecondaryText,
                                modifier = Modifier.size(18.dp)
                            )
                        }

                        // Center: Title + Pill
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(horizontal = 12.dp)
                        ) {
                            Text(
                                text = habit.title,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Medium,
                                color = PrimaryText,
                                maxLines = 1
                            )
                            Spacer(modifier = Modifier.height(3.dp))
                            if (habit.habitType == HabitType.QUIT) {
                                InverseBadge("QUIT")
                            } else {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(if (isDone) CobaltBlue.copy(alpha = 0.1f) else PageGround)
                                        .border(1.dp, if (isDone) CobaltBlue.copy(alpha = 0.3f) else Hairline, RoundedCornerShape(8.dp))
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = if (isDone) "1/1" else "0/1",
                                        fontSize = 11.sp,
                                        fontFamily = FontFamily.Monospace,
                                        color = if (isDone) CobaltBlue else MutedText
                                    )
                                }
                            }
                        }

                        // Right: Streak + Completion Circle
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "1d",
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = if (isDone) CobaltBlue else MutedText
                            )
                            Spacer(modifier = Modifier.height(2.dp))
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

                                        // Auto-save to Supabase in background
                                        syncService?.let { service ->
                                            if (service.isConfigured) {
                                                val newlyDone = if (!isDone) completedCount + 1 else maxOf(0, completedCount - 1)
                                                val sched = maxOf(1, scheduledHabits.size)
                                                service.syncDailyStats(
                                                    completedCount = newlyDone,
                                                    scheduledCount = sched,
                                                    completionRate = newlyDone.toDouble() / sched,
                                                    activeStreak = 1
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}
