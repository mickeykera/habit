package com.habittracker.app.ui.report

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.Habit
import com.habittracker.app.data.HabitDao
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.GoldMedalBrush
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import com.habittracker.app.ui.components.EngravedDivider
import com.habittracker.app.ui.components.HairlineDivider
import java.time.LocalDate
import java.time.format.DateTimeFormatter

enum class ReportTab {
    WEEKLY, MONTHLY, YEARLY
}

@Composable
fun ReportScreen(habitDao: HabitDao) {
    var selectedTab by remember { mutableStateOf(ReportTab.WEEKLY) }
    var selectedWeekStart by remember {
        val today = LocalDate.now()
        val monday = today.minusDays(((today.dayOfWeek.value + 6) % 7).toLong())
        mutableStateOf(monday)
    }
    var selectedYear by remember { mutableIntStateOf(LocalDate.now().year) }

    val habits by habitDao.getActiveHabits().collectAsState(initial = emptyList())
    val dayLabels = listOf("M", "T", "W", "T", "F", "S", "S")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
    ) {
        // Top Recessed Segmented Trough
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(WellBrush)
                .border(1.dp, ReverseBevel, RoundedCornerShape(12.dp))
                .padding(4.dp),
            horizontalArrangement = Arrangement.SpaceAround
        ) {
            ReportTab.entries.forEach { tab ->
                val isSelected = selectedTab == tab
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .shadow(if (isSelected) 2.dp else 0.dp, RoundedCornerShape(8.dp))
                        .clip(RoundedCornerShape(8.dp))
                        .background(if (isSelected) CobaltEnamelBrush else Color.Transparent)
                        .then(
                            if (isSelected) Modifier.border(1.dp, Color.White.copy(alpha = 0.6f), RoundedCornerShape(8.dp)) else Modifier
                        )
                        .clickable { selectedTab = tab }
                        .padding(vertical = 8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = tab.name.lowercase().replaceFirstChar { it.uppercase() },
                        fontSize = 14.sp,
                        fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                        color = if (isSelected) CobaltLabel else PrimaryText
                    )
                }
            }
        }

        EngravedDivider()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            when (selectedTab) {
                ReportTab.WEEKLY -> {
                    // Week Switcher < dd/MM ~ dd/MM >
                    val weekEnd = selectedWeekStart.plusDays(6)
                    val fmt = DateTimeFormatter.ofPattern("dd/MM")
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = { selectedWeekStart = selectedWeekStart.minusWeeks(1) }) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Prev", tint = PrimaryText)
                        }
                        Text(
                            text = "< ${selectedWeekStart.format(fmt)} ~ ${weekEnd.format(fmt)} >",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium,
                            fontFamily = FontFamily.Monospace,
                            color = PrimaryText
                        )
                        IconButton(onClick = { selectedWeekStart = selectedWeekStart.plusWeeks(1) }) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next", tint = PrimaryText)
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Ruled Matrix Card
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(3.dp, RoundedCornerShape(14.dp))
                            .clip(RoundedCornerShape(14.dp))
                            .background(CardBrush)
                            .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
                            .padding(14.dp)
                    ) {
                        // Header
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("Habit", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = MutedText, modifier = Modifier.weight(1f))
                            dayLabels.forEach { d ->
                                Box(modifier = Modifier.width(26.dp), contentAlignment = Alignment.Center) {
                                    Text(d, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = MutedText)
                                }
                            }
                            Box(modifier = Modifier.width(38.dp), contentAlignment = Alignment.CenterEnd) {
                                Text("Total", fontSize = 11.sp, color = MutedText)
                            }
                        }

                        EngravedDivider()

                        // Rows
                        if (habits.isEmpty()) {
                            Text("No habits found", fontSize = 13.sp, color = MutedText, modifier = Modifier.padding(vertical = 12.dp))
                        } else {
                            habits.forEach { habit ->
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.Star, contentDescription = null, tint = CobaltBlue, modifier = Modifier.size(12.dp))
                                        Spacer(modifier = Modifier.size(6.dp))
                                        Text(habit.title, fontSize = 13.sp, color = PrimaryText, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                    }

                                    (0..6).forEach { _ ->
                                        Box(modifier = Modifier.width(26.dp), contentAlignment = Alignment.Center) {
                                            Box(
                                                modifier = Modifier
                                                    .size(16.dp)
                                                    .shadow(1.dp, RoundedCornerShape(3.dp))
                                                    .clip(RoundedCornerShape(3.dp))
                                                    .background(CobaltEnamelBrush)
                                                    .border(0.5.dp, Color.White.copy(alpha = 0.6f), RoundedCornerShape(3.dp))
                                            )
                                        }
                                    }

                                    Box(modifier = Modifier.width(38.dp), contentAlignment = Alignment.CenterEnd) {
                                        Text("100%", fontSize = 11.sp, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.SemiBold, color = CobaltBlue)
                                    }
                                }
                                EngravedDivider()
                            }
                        }

                        // Best Day Highlight Row
                        Spacer(modifier = Modifier.height(10.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(WellBrush)
                                .border(1.dp, ReverseBevel, RoundedCornerShape(8.dp))
                                .padding(10.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(16.dp)
                                        .clip(CircleShape)
                                        .background(GoldMedalBrush),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text("★", fontSize = 10.sp, color = Color(0xFF261C02))
                                }
                                Spacer(modifier = Modifier.size(6.dp))
                                Text("Best Day: Wednesday", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = PrimaryText)
                            }
                            Text("100% completed", fontSize = 12.sp, fontFamily = FontFamily.Monospace, color = CobaltBlue)
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    // 4-column KPI Footer
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ReportKpiBox(modifier = Modifier.weight(1f), title = "Met (%)", value = "90%")
                        ReportKpiBox(modifier = Modifier.weight(1f), title = "Best Day", value = "We")
                        ReportKpiBox(modifier = Modifier.weight(1f), title = "Total Done", value = "24")
                        ReportKpiBox(modifier = Modifier.weight(1f), title = "Best Streak", value = "12d")
                    }
                }

                ReportTab.MONTHLY -> {
                    // Month selector < 2026 Nov >
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = {}) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Prev", tint = PrimaryText)
                        }
                        Text("< 2026 Nov >", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = PrimaryText)
                        IconButton(onClick = {}) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next", tint = PrimaryText)
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // 2-column Grid of Mini Monthly Cards
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        habits.take(2).forEach { habit ->
                            MiniMonthlyCard(modifier = Modifier.weight(1f), title = habit.title)
                        }
                    }
                }

                ReportTab.YEARLY -> {
                    // Year selector < 2026 >
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(onClick = { selectedYear -= 1 }) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, contentDescription = "Prev", tint = PrimaryText)
                        }
                        Text("< $selectedYear >", fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace, color = PrimaryText)
                        IconButton(onClick = { selectedYear += 1 }) {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = "Next", tint = PrimaryText)
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Stacked list of habit heatmap cards
                    habits.forEach { habit ->
                        YearlyHeatmapCard(habit = habit)
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun ReportKpiBox(modifier: Modifier = Modifier, title: String, value: String) {
    Box(
        modifier = modifier
            .shadow(2.dp, RoundedCornerShape(12.dp))
            .clip(RoundedCornerShape(12.dp))
            .background(CardBrush)
            .border(1.dp, TopLightBevel, RoundedCornerShape(12.dp))
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(value, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace, color = CobaltBlue)
            Spacer(modifier = Modifier.height(2.dp))
            Text(title, fontSize = 10.sp, color = MutedText)
        }
    }
}

@Composable
private fun MiniMonthlyCard(modifier: Modifier = Modifier, title: String) {
    Column(
        modifier = modifier
            .shadow(2.dp, RoundedCornerShape(14.dp))
            .clip(RoundedCornerShape(14.dp))
            .background(CardBrush)
            .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
            .padding(12.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text(title, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText, maxLines = 1)
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(4.dp))
                    .background(CobaltEnamelBrush)
                    .border(0.5.dp, Color.White.copy(alpha = 0.6f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 4.dp, vertical = 2.dp)
            ) {
                Text("PERFECT", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = CobaltLabel)
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        // 7-column day grid
        Column {
            for (r in 0 until 4) {
                Row(modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    for (c in 0 until 7) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .shadow(0.5.dp, RoundedCornerShape(2.dp))
                                .clip(RoundedCornerShape(2.dp))
                                .background(CobaltEnamelBrush)
                                .border(0.5.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(2.dp))
                        )
                    }
                }
            }
        }
        EngravedDivider(modifier = Modifier.padding(vertical = 8.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("83%", fontSize = 13.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace, color = CobaltBlue)
            Text("25d done", fontSize = 11.sp, color = SecondaryText)
        }
    }
}

@Composable
private fun YearlyHeatmapCard(habit: Habit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(3.dp, RoundedCornerShape(14.dp))
            .clip(RoundedCornerShape(14.dp))
            .background(CardBrush)
            .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Star, contentDescription = null, tint = CobaltBlue, modifier = Modifier.size(14.dp))
                Spacer(modifier = Modifier.size(6.dp))
                Text(habit.title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
            }
            Text("93.7% · 342D", fontSize = 13.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace, color = CobaltBlue)
        }
        Spacer(modifier = Modifier.height(10.dp))
        // GitHub-style 52-week contribution heatmap
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            for (w in 0 until 52) {
                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    for (d in 0 until 7) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(RoundedCornerShape(1.5.dp))
                                .background(CobaltEnamelBrush)
                        )
                    }
                }
            }
        }
    }
}
