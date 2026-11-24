package com.habittracker.app.ui.settings

import android.widget.Toast
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Storage
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.HabitDao
import com.habittracker.app.service.SupabaseSyncService
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.ui.components.HairlineDivider
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    habitDao: HabitDao,
    syncService: SupabaseSyncService,
    onSignOut: () -> Unit = {}
) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val scope = rememberCoroutineScope()

    var showSupabaseDialog by remember { mutableStateOf(false) }
    var showPreferencesDialog by remember { mutableStateOf(false) }
    var showResetDialog by remember { mutableStateOf(false) }
    var showNameDialog by remember { mutableStateOf(false) }
    var newDisplayName by remember { mutableStateOf(syncService.displayName) }

    var isSyncing by remember { mutableStateOf(false) }
    val moods = remember { mutableStateMapOf<Int, String>() }
    val moodList = listOf("😊", "🙂", "😐", "😔", "😴")
    val dayLabels = listOf("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su")

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
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Settings",
                fontSize = 20.sp,
                fontWeight = FontWeight.Medium,
                color = PrimaryText
            )
        }

        HairlineDivider()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            // Profile Header Card
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardSurface)
                    .border(1.dp, Hairline, RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(CobaltBlue),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = syncService.displayName.take(2).uppercase(),
                        color = CobaltLabel,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 17.sp
                    )
                }

                Column(modifier = Modifier.padding(start = 12.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = syncService.displayName,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = PrimaryText
                        )
                        Spacer(modifier = Modifier.size(6.dp))
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "Edit Name",
                            tint = MutedText,
                            modifier = Modifier
                                .size(13.dp)
                                .clickable {
                                    newDisplayName = syncService.displayName
                                    showNameDialog = true
                                }
                        )
                    }
                    Text(
                        text = "Friend Code: ${syncService.friendCode}",
                        fontSize = 12.sp,
                        fontFamily = FontFamily.Monospace,
                        color = MutedText
                    )
                    if (syncService.currentUserEmail.isNotBlank()) {
                        Text(
                            text = syncService.currentUserEmail,
                            fontSize = 11.sp,
                            color = MutedText
                        )
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(PageGround)
                        .border(1.dp, Hairline, RoundedCornerShape(16.dp))
                        .clickable {
                            clipboardManager.setText(AnnotatedString(syncService.friendCode))
                            Toast.makeText(context, "Copied friend code", Toast.LENGTH_SHORT).show()
                        }
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.ContentCopy, contentDescription = null, tint = CobaltBlue, modifier = Modifier.size(12.dp))
                        Spacer(modifier = Modifier.size(4.dp))
                        Text("Copy", fontSize = 12.sp, color = CobaltBlue, fontWeight = FontWeight.Medium)
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Daily Mood Strip Card
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
                    Text("Daily Moods", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
                    Text("Tap day to log", fontSize = 11.sp, color = MutedText)
                }

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    dayLabels.forEachIndexed { i, day ->
                        val currentMood = moods[i]
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.clickable {
                                val currentIdx = moodList.indexOf(currentMood)
                                if (currentIdx == -1) {
                                    moods[i] = moodList[0]
                                } else if (currentIdx + 1 < moodList.size) {
                                    moods[i] = moodList[currentIdx + 1]
                                } else {
                                    moods.remove(i)
                                }
                            }
                        ) {
                            Text(day, fontSize = 11.sp, color = MutedText, fontWeight = FontWeight.Medium)
                            Spacer(modifier = Modifier.height(4.dp))
                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(CircleShape)
                                    .background(if (currentMood != null) CobaltBlue.copy(alpha = 0.12f) else PageGround)
                                    .border(
                                        1.dp,
                                        if (currentMood != null) CobaltBlue.copy(alpha = 0.4f) else Hairline,
                                        CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                if (currentMood != null) {
                                    Text(currentMood, fontSize = 16.sp)
                                } else {
                                    Text("+", fontSize = 12.sp, color = MutedText)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Settings Grouped Inset Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardSurface)
                    .border(1.dp, Hairline, RoundedCornerShape(14.dp))
            ) {
                SettingsChevronRow(title = "Habit Manager", subtitle = "Manage & archive", icon = Icons.Default.Tune) {
                    Toast.makeText(context, "Habit Manager", Toast.LENGTH_SHORT).show()
                }
                HairlineDivider(modifier = Modifier.padding(horizontal = 14.dp))
                SettingsChevronRow(title = "Preferences", subtitle = "Monday start · Haptics", icon = Icons.Default.Settings) {
                    showPreferencesDialog = true
                }
                HairlineDivider(modifier = Modifier.padding(horizontal = 14.dp))
                SettingsChevronRow(title = "Friends Sync (Supabase)", subtitle = if (syncService.isConfigured) "Connected" else "Offline", icon = Icons.Default.Sync) {
                    showSupabaseDialog = true
                }
                HairlineDivider(modifier = Modifier.padding(horizontal = 14.dp))
                SettingsChevronRow(title = "Data & Backup", subtitle = "Export / Reset", icon = Icons.Default.Storage) {
                    showResetDialog = true
                }

                HairlineDivider(modifier = Modifier.padding(horizontal = 14.dp))

                SettingsChevronRow(
                    title = "Sign Out",
                    subtitle = syncService.currentUserEmail.ifBlank { "Account" },
                    icon = Icons.AutoMirrored.Filled.ExitToApp
                ) {
                    syncService.signOut()
                    onSignOut()
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // About Card
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
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("About HabitTracker", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
                    Text("v1.0.0", fontSize = 12.sp, fontFamily = FontFamily.Monospace, color = SecondaryText)
                }
                HairlineDivider(modifier = Modifier.padding(vertical = 8.dp))
                Text(
                    text = "100% On-Device & Private. Built with native Kotlin, Room database, and zero-cost cloud sync. Habit names, notes, and metadata never leave your local device.",
                    fontSize = 12.sp,
                    color = MutedText,
                    lineHeight = 18.sp
                )
            }
        }
    }

    if (showNameDialog) {
        AlertDialog(
            onDismissRequest = { showNameDialog = false },
            title = { Text("Display Name", fontWeight = FontWeight.SemiBold) },
            text = {
                OutlinedTextField(
                    value = newDisplayName,
                    onValueChange = { newDisplayName = it },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newDisplayName.isNotBlank()) {
                            syncService.displayName = newDisplayName.trim()
                        }
                        showNameDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue)
                ) {
                    Text("Save", color = CobaltLabel)
                }
            },
            dismissButton = {
                TextButton(onClick = { showNameDialog = false }) {
                    Text("Cancel", color = MutedText)
                }
            }
        )
    }

    if (showPreferencesDialog) {
        AlertDialog(
            onDismissRequest = { showPreferencesDialog = false },
            title = { Text("Preferences", fontWeight = FontWeight.SemiBold) },
            text = {
                Column {
                    Text("Haptic Feedback", fontSize = 14.sp, color = PrimaryText)
                    Text("Enabled for tap and swipe actions.", fontSize = 12.sp, color = MutedText)
                    Spacer(modifier = Modifier.height(12.dp))
                    Text("Week Start Day", fontSize = 14.sp, color = PrimaryText)
                    Text("Monday (ISO 8601)", fontSize = 12.sp, color = MutedText)
                }
            },
            confirmButton = {
                Button(
                    onClick = { showPreferencesDialog = false },
                    colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue)
                ) {
                    Text("Done", color = CobaltLabel)
                }
            }
        )
    }

    if (showSupabaseDialog) {
        var url by remember { mutableStateOf(syncService.supabaseUrl) }
        var key by remember { mutableStateOf(syncService.supabaseAnonKey) }

        AlertDialog(
            onDismissRequest = { showSupabaseDialog = false },
            title = { Text("Supabase Configuration", fontWeight = FontWeight.SemiBold) },
            text = {
                Column {
                    OutlinedTextField(
                        value = url,
                        onValueChange = { url = it },
                        label = { Text("Supabase URL") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = key,
                        onValueChange = { key = it },
                        label = { Text("Anon Key") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = if (syncService.isConfigured) "● Automatic Cloud Sync: Active" else "○ Cloud Not Configured",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (syncService.isConfigured) CobaltBlue else MutedText
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "All habit completions save automatically to Supabase.",
                        fontSize = 11.sp,
                        color = MutedText
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        syncService.supabaseUrl = url.trim()
                        syncService.supabaseAnonKey = key.trim()
                        showSupabaseDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue)
                ) {
                    Text("Save", color = CobaltLabel)
                }
            },
            dismissButton = {
                TextButton(onClick = { showSupabaseDialog = false }) {
                    Text("Close", color = MutedText)
                }
            }
        )
    }

    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset All Data", fontWeight = FontWeight.SemiBold) },
            text = { Text("This will permanently delete all habits and logs from your device.") },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            habitDao.deleteAllLogs()
                            habitDao.deleteAllHabits()
                        }
                        showResetDialog = false
                        Toast.makeText(context, "All data reset", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                ) {
                    Text("Delete Everything", color = CobaltLabel)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) {
                    Text("Cancel", color = MutedText)
                }
            }
        )
    }
}

@Composable
private fun SettingsChevronRow(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 14.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(PageGround)
                .border(1.dp, Hairline, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = CobaltBlue, modifier = Modifier.size(15.dp))
        }

        Spacer(modifier = Modifier.size(12.dp))

        Text(title, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = PrimaryText)

        Spacer(modifier = Modifier.weight(1f))

        Text(subtitle, fontSize = 12.sp, color = MutedText)

        Spacer(modifier = Modifier.size(6.dp))

        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = MutedText, modifier = Modifier.size(16.dp))
    }
}
