package com.habittracker.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.AppDatabase
import com.habittracker.app.data.Habit
import com.habittracker.app.service.SupabaseSyncService
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.HabitTrackerTheme
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import com.habittracker.app.ui.auth.AuthScreen
import com.habittracker.app.ui.calendar.CalendarScreen
import com.habittracker.app.ui.friends.FriendsScreen
import com.habittracker.app.ui.report.ReportScreen
import com.habittracker.app.ui.settings.SettingsScreen
import com.habittracker.app.ui.today.AddHabitDialog
import com.habittracker.app.ui.today.TodayScreen
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val database = AppDatabase.getInstance(this)
        val habitDao = database.habitDao()
        val syncService = SupabaseSyncService(this)

        setContent {
            HabitTrackerTheme {
                var isAuthenticated by remember { mutableStateOf(syncService.isAuthenticated) }

                if (!isAuthenticated) {
                    AuthScreen(
                        syncService = syncService,
                        onAuthSuccess = { isAuthenticated = true }
                    )
                } else {
                    MainScreen(
                        habitDao = habitDao,
                        syncService = syncService,
                        onSignOut = { isAuthenticated = false }
                    )
                }
            }
        }
    }
}

data class NavItem(val label: String, val icon: ImageVector)

@Composable
fun MainScreen(
    habitDao: com.habittracker.app.data.HabitDao,
    syncService: SupabaseSyncService,
    onSignOut: () -> Unit = {}
) {
    var selectedIndex by remember { mutableIntStateOf(0) }
    var showAddHabitDialog by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

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
                    .padding(horizontal = 20.dp, vertical = 10.dp)
                    .shadow(8.dp, RoundedCornerShape(32.dp))
                    .clip(RoundedCornerShape(32.dp))
                    .background(CardBrush)
                    .border(1.dp, TopLightBevel, RoundedCornerShape(32.dp))
                    .padding(horizontal = 8.dp, vertical = 6.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceAround,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    navItems.forEachIndexed { index, item ->
                        val isSelected = selectedIndex == index

                        if (index == 0 && selectedIndex == 0) {
                            // Smart + shortcut on Tab 1
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .shadow(4.dp, CircleShape)
                                    .clip(CircleShape)
                                    .background(CobaltEnamelBrush)
                                    .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
                                    .clickable { showAddHabitDialog = true },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = "Add Habit",
                                    tint = CobaltLabel,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        } else {
                            Box(
                                modifier = Modifier
                                    .height(38.dp)
                                    .clip(RoundedCornerShape(16.dp))
                                    .then(
                                        if (isSelected) {
                                            Modifier
                                                .background(WellBrush)
                                                .border(1.dp, ReverseBevel, RoundedCornerShape(16.dp))
                                        } else {
                                            Modifier
                                        }
                                    )
                                    .clickable { selectedIndex = index }
                                    .padding(horizontal = 14.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = item.icon,
                                    contentDescription = item.label,
                                    tint = if (isSelected) CobaltBlue else SecondaryText,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
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
            Crossfade(
                targetState = selectedIndex,
                animationSpec = tween(durationMillis = 220),
                label = "tabCrossfade"
            ) { targetIndex ->
                when (targetIndex) {
                    0 -> TodayScreen(habitDao, syncService = syncService, onOpenAdd = { showAddHabitDialog = true })
                    1 -> CalendarScreen(habitDao, onOpenAdd = { showAddHabitDialog = true })
                    2 -> FriendsScreen(syncService)
                    3 -> ReportScreen(habitDao)
                    4 -> SettingsScreen(habitDao, syncService, onSignOut = onSignOut)
                }
            }
        }

        if (showAddHabitDialog) {
            AddHabitDialog(
                onDismiss = { showAddHabitDialog = false },
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
                    showAddHabitDialog = false
                }
            )
        }
    }
}
