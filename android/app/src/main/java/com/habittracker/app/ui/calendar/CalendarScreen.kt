package com.habittracker.app.ui.calendar

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.Habit
import com.habittracker.app.data.HabitDao
import com.habittracker.app.data.HabitType
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.ui.components.HairlineDivider
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

@Composable
fun CalendarScreen(
    habitDao: HabitDao,
    onOpenAdd: () -> Unit = {}
) {
    var currentMonth by remember { mutableStateOf(YearMonth.now()) }
    var selectedDay by remember { mutableStateOf(LocalDate.now()) }
    var selectedHabitId by remember { mutableStateOf<String?>(null) }
    var isShowingOverallRate by remember { mutableStateOf(false) }
    var showScopeMenu by remember { mutableStateOf(false) }
    var scopeFilter by remember { mutableStateOf("Overall") }

    val habits by habitDao.getActiveHabits().collectAsState(initial = emptyList())
    val monthFormatter = remember { DateTimeFormatter.ofPattern("MM/yyyy") }
    val dayNames = listOf("M", "T", "W", "T", "F", "S", "S")

    val daysInMonth = currentMonth.lengthOfMonth()
    val firstDayOfMonth = currentMonth.atDay(1)
    val leadingEmptyDays = (firstDayOfMonth.dayOfWeek.value + 6) % 7 // Monday = 0

    val filteredHabits = habits.filter { habit ->
        if (selectedHabitId != null) {
            habit.id == selectedHabitId
        } else {
            when (scopeFilter) {
                "Build Only" -> habit.habitType == HabitType.BUILD
                "Quit Only" -> habit.habitType == HabitType.QUIT
                else -> true
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        // Top Bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left Filter Icon Button
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(CardSurface)
                    .border(1.dp, Hairline, CircleShape)
                    .clickable { showScopeMenu = true },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.FilterList, contentDescription = "Filter", tint = PrimaryText, modifier = Modifier.size(16.dp))

                DropdownMenu(expanded = showScopeMenu, onDismissRequest = { showScopeMenu = false }) {
                    listOf("Overall", "Build Only", "Quit Only").forEach { opt ->
                        DropdownMenuItem(
                            text = { Text(opt) },
                            onClick = {
                                scopeFilter = opt
                                selectedHabitId = null
                                showScopeMenu = false
                            }
                        )
                    }
                }
            }

            // Center Dropdown
            Box {
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(CardSurface)
                        .border(1.dp, Hairline, RoundedCornerShape(16.dp))
                        .clickable { showScopeMenu = true }
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (selectedHabitId != null) (habits.find { it.id == selectedHabitId }?.title ?: "Habit") else scopeFilter,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Medium,
                        color = PrimaryText
                    )
                    Spacer(modifier = Modifier.size(4.dp))
                    Icon(Icons.Default.KeyboardArrowDown, contentDescription = null, tint = MutedText, modifier = Modifier.size(14.dp))
                }
            }

            // Right Add Button
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(CardSurface)
                    .border(1.dp, Hairline, CircleShape)
                    .clickable { onOpenAdd() },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add", tint = CobaltBlue, modifier = Modifier.size(16.dp))
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Habit Filter Chips
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val isAllSelected = selectedHabitId == null
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (isAllSelected) CobaltBlue else CardSurface)
                    .border(1.dp, if (isAllSelected) Color.Transparent else Hairline, RoundedCornerShape(16.dp))
                    .clickable { selectedHabitId = null }
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "All",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = if (isAllSelected) CobaltLabel else PrimaryText
                )
            }

            habits.forEach { habit ->
                val isSel = selectedHabitId == habit.id
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(if (isSel) CobaltBlue else CardSurface)
                        .border(1.dp, if (isSel) Color.Transparent else Hairline, RoundedCornerShape(16.dp))
                        .clickable { selectedHabitId = habit.id }
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = habit.title,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isSel) CobaltLabel else PrimaryText
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Monthly Calendar Card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(14.dp))
                .padding(14.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { currentMonth = currentMonth.minusMonths(1) }) {
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Prev", tint = PrimaryText)
                }
                Text(
                    text = currentMonth.format(monthFormatter),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    color = PrimaryText
                )
                IconButton(onClick = { currentMonth = currentMonth.plusMonths(1) }) {
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next", tint = PrimaryText)
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                dayNames.forEach {
                    Text(it, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = MutedText)
                }
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 4.dp))

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
                            val dayNum = cellIndex - leadingEmptyDays + 1
                            val date = currentMonth.atDay(dayNum)
                            val isSel = selectedDay == date
                            val isToday = date == LocalDate.now()

                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.clickable { selectedDay = date }
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .then(
                                            when {
                                                isSel -> Modifier.border(2.dp, CobaltBlue, CircleShape)
                                                isToday -> Modifier.border(1.dp, CobaltBlue.copy(alpha = 0.5f), CircleShape)
                                                else -> Modifier
                                            }
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "$dayNum",
                                        fontSize = 13.sp,
                                        fontFamily = FontFamily.Monospace,
                                        color = PrimaryText
                                    )
                                }
                                if (isToday) {
                                    Box(
                                        modifier = Modifier
                                            .size(3.dp)
                                            .clip(CircleShape)
                                            .background(CobaltBlue)
                                    )
                                }
                            }
                        } else {
                            Box(modifier = Modifier.size(32.dp))
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Stats Summary Card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(14.dp))
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Circular Progress Ring
            Box(
                modifier = Modifier.size(110.dp),
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    drawCircle(
                        color = Hairline,
                        style = Stroke(width = 8.dp.toPx())
                    )
                    drawArc(
                        color = CobaltBlue,
                        startAngle = -90f,
                        sweepAngle = 0.84f * 360f,
                        useCenter = false,
                        style = Stroke(width = 8.dp.toPx(), cap = StrokeCap.Round)
                    )
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = if (isShowingOverallRate) "82%" else "84%",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace,
                        color = CobaltBlue
                    )
                    Text(
                        text = if (isShowingOverallRate) "Overall Rate" else "Monthly Rate",
                        fontSize = 11.sp,
                        color = MutedText
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // ⇄ Toggle Button
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .background(PageGround)
                    .border(1.dp, Hairline, RoundedCornerShape(12.dp))
                    .clickable { isShowingOverallRate = !isShowingOverallRate }
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.SwapHoriz, contentDescription = null, tint = SecondaryText, modifier = Modifier.size(14.dp))
                Spacer(modifier = Modifier.size(4.dp))
                Text(
                    text = if (isShowingOverallRate) "Show Monthly" else "Show Overall",
                    fontSize = 11.sp,
                    color = SecondaryText
                )
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 12.dp))

            // 2x2 KPI Grid
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                KpiCard(modifier = Modifier.weight(1f), title = "Best Streaks", value = "14 Day")
                KpiCard(modifier = Modifier.weight(1f), title = "Perfect Days", value = "8 Day")
            }
            Spacer(modifier = Modifier.height(10.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                KpiCard(modifier = Modifier.weight(1f), title = "Habits Done", value = "42")
                KpiCard(modifier = Modifier.weight(1f), title = "Daily Average", value = "4.2")
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Done Today Card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(14.dp))
                .padding(14.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Done Today", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = PrimaryText)
                Text("More >", fontSize = 12.sp, color = MutedText)
            }
            HairlineDivider(modifier = Modifier.padding(vertical = 8.dp))
            Text(
                text = "${selectedDay.month.name.take(3)} ${selectedDay.dayOfMonth}: All habits on track",
                fontSize = 13.sp,
                color = CobaltBlue
            )
        }
    }
}

@Composable
private fun KpiCard(modifier: Modifier = Modifier, title: String, value: String) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(PageGround)
            .border(1.dp, Hairline, RoundedCornerShape(10.dp))
            .padding(10.dp)
    ) {
        Column {
            Text(title, fontSize = 11.sp, color = MutedText)
            Spacer(modifier = Modifier.height(2.dp))
            Text(value, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.Monospace, color = PrimaryText)
        }
    }
}
