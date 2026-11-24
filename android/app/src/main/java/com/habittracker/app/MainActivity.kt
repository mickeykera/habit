package com.habittracker.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.AppDatabase
import com.habittracker.app.service.SupabaseSyncService
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.HabitTrackerTheme
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.ui.calendar.CalendarScreen
import com.habittracker.app.ui.components.HairlineDivider
import com.habittracker.app.ui.friends.FriendsScreen
import com.habittracker.app.ui.report.ReportScreen
import com.habittracker.app.ui.settings.SettingsScreen
import com.habittracker.app.ui.today.TodayScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val database = AppDatabase.getInstance(this)
        val habitDao = database.habitDao()
        val syncService = SupabaseSyncService(this)

        setContent {
            HabitTrackerTheme {
                MainScreen(habitDao, syncService)
            }
        }
    }
}

data class NavItem(val label: String, val icon: ImageVector)

@Composable
fun MainScreen(habitDao: com.habittracker.app.data.HabitDao, syncService: SupabaseSyncService) {
    var selectedIndex by remember { mutableIntStateOf(0) }

    val navItems = listOf(
        NavItem("Today", Icons.Default.Home),
        NavItem("Calendar", Icons.Default.CalendarMonth),
        NavItem("Friends", Icons.Default.People),
        NavItem("Report", Icons.Default.BarChart),
        NavItem("Settings", Icons.Default.Settings)
    )

    Scaffold(
        bottomBar = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PageGround)
            ) {
                Column {
                    HairlineDivider()
                    NavigationBar(
                        containerColor = PageGround,
                        tonalElevation = 0.dp,
                        modifier = Modifier.height(64.dp)
                    ) {
                        navItems.forEachIndexed { index, item ->
                            val isSelected = selectedIndex == index
                            NavigationBarItem(
                                selected = isSelected,
                                onClick = { selectedIndex = index },
                                icon = {
                                    Icon(
                                        imageVector = item.icon,
                                        contentDescription = item.label,
                                        tint = if (isSelected) CobaltBlue else MutedText
                                    )
                                },
                                label = {
                                    Text(
                                        text = item.label,
                                        fontSize = 11.sp,
                                        color = if (isSelected) CobaltBlue else MutedText
                                    )
                                },
                                colors = NavigationBarItemDefaults.colors(
                                    indicatorColor = Color.Transparent
                                )
                            )
                        }
                    }
                }
            }
        },
        containerColor = PageGround
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (selectedIndex) {
                0 -> TodayScreen(habitDao)
                1 -> CalendarScreen(habitDao)
                2 -> FriendsScreen(syncService)
                3 -> ReportScreen(habitDao)
                4 -> SettingsScreen(habitDao, syncService)
            }
        }
    }
}
