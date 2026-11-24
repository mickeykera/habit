package com.habittracker.app.ui.report

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
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
import com.habittracker.app.ui.components.HairlineDivider

@Composable
fun ReportScreen(habitDao: HabitDao) {
    val habits by habitDao.getActiveHabits().collectAsState(initial = emptyList())
    val dayLabels = listOf("M", "T", "W", "T", "F", "S", "S")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .padding(16.dp)
    ) {
        Text(
            text = "Report",
            fontSize = 28.sp,
            fontWeight = FontWeight.Medium,
            color = PrimaryText
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Matrix ledger card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(12.dp)
        ) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Habit",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MutedText,
                    modifier = Modifier.weight(1f)
                )
                dayLabels.forEach { d ->
                    Box(modifier = Modifier.width(28.dp), contentAlignment = Alignment.Center) {
                        Text(d, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = MutedText)
                    }
                }
                Box(modifier = Modifier.width(38.dp), contentAlignment = Alignment.CenterEnd) {
                    Text("Total", fontSize = 11.sp, color = MutedText)
                }
            }

            HairlineDivider()

            // Habit rows
            habits.forEach { habit ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = habit.title,
                        fontSize = 14.sp,
                        color = PrimaryText,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    (0..6).forEach { _ ->
                        Box(
                            modifier = Modifier.width(28.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            // Completed / Scheduled indicator
                            Box(
                                modifier = Modifier
                                    .size(14.dp)
                                    .clip(RoundedCornerShape(3.dp))
                                    .background(CobaltBlue)
                            )
                        }
                    }

                    Box(modifier = Modifier.width(38.dp), contentAlignment = Alignment.CenterEnd) {
                        Text(
                            text = "100%",
                            fontSize = 12.sp,
                            fontFamily = FontFamily.Monospace,
                            fontWeight = FontWeight.Medium,
                            color = SecondaryText
                        )
                    }
                }
                HairlineDivider()
            }

            // Summary row
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Daily %",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MutedText,
                    modifier = Modifier.weight(1f)
                )
                dayLabels.forEach { _ ->
                    Box(modifier = Modifier.width(28.dp), contentAlignment = Alignment.Center) {
                        Text(
                            text = "80%",
                            fontSize = 10.sp,
                            fontFamily = FontFamily.Monospace,
                            color = SecondaryText
                        )
                    }
                }
                Box(modifier = Modifier.width(38.dp), contentAlignment = Alignment.CenterEnd) {
                    Text(
                        text = "86%",
                        fontSize = 12.sp,
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.SemiBold,
                        color = CobaltBlue
                    )
                }
            }
        }
    }
}
