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
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
fun SettingsScreen(habitDao: HabitDao, syncService: SupabaseSyncService) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    val scope = rememberCoroutineScope()

    var showSupabaseDialog by remember { mutableStateOf(false) }
    var showResetDialog by remember { mutableStateOf(false) }
    var isSyncing by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Text("Settings", fontSize = 28.sp, fontWeight = FontWeight.Medium, color = PrimaryText)

        Spacer(modifier = Modifier.height(16.dp))

        // Profile & Sync Section
        Text("PROFILE & SYNC", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = MutedText)
        Spacer(modifier = Modifier.height(6.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(14.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Display Name", fontSize = 15.sp, color = PrimaryText)
                Text(syncService.displayName, fontSize = 15.sp, color = SecondaryText)
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Friend Code", fontSize = 15.sp, color = PrimaryText)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable {
                        clipboardManager.setText(AnnotatedString(syncService.friendCode))
                        Toast.makeText(context, "Copied friend code", Toast.LENGTH_SHORT).show()
                    }
                ) {
                    Text(
                        text = syncService.friendCode,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace,
                        color = CobaltBlue
                    )
                }
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Supabase Sync", fontSize = 15.sp, color = PrimaryText)
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (syncService.isConfigured) Color(0xFF22C55E) else Color.Red)
                )
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 12.dp))

            Button(
                onClick = {
                    scope.launch {
                        isSyncing = true
                        val res = syncService.syncDailyStats(5, 5, 1.0, 5)
                        isSyncing = false
                        val msg = if (res.isSuccess) "Sync successful" else "Sync failed: ${res.exceptionOrNull()?.message}"
                        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue),
                shape = RoundedCornerShape(8.dp),
                enabled = !isSyncing
            ) {
                Text(if (isSyncing) "Syncing…" else "Sync Now", color = CobaltLabel)
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Habit titles never leave your device. Only anonymized counts are synced.",
                fontSize = 11.sp,
                color = MutedText
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Data Management
        Text("DATA MANAGEMENT", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = MutedText)
        Spacer(modifier = Modifier.height(6.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(14.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showSupabaseDialog = true }
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Configure Supabase", fontSize = 15.sp, color = CobaltBlue)
            }

            HairlineDivider(modifier = Modifier.padding(vertical = 12.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showResetDialog = true }
                    .padding(vertical = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Reset All Data", fontSize = 15.sp, color = Color.Red)
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // About
        Text("ABOUT", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = MutedText)
        Spacer(modifier = Modifier.height(6.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(14.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Version", fontSize = 15.sp, color = PrimaryText)
                Text("1.0.0 (Android)", fontSize = 14.sp, fontFamily = FontFamily.Monospace, color = SecondaryText)
            }
        }
    }

    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text("Reset All Data") },
            text = { Text("Are you sure? This will delete all local habits and logs permanently.") },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            habitDao.deleteAllLogs()
                            habitDao.deleteAllHabits()
                        }
                        showResetDialog = false
                        Toast.makeText(context, "Data reset", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
                ) {
                    Text("Delete", color = Color.White)
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) {
                    Text("Cancel", color = MutedText)
                }
            }
        )
    }

    if (showSupabaseDialog) {
        var url by remember { mutableStateOf(syncService.supabaseUrl) }
        var key by remember { mutableStateOf(syncService.supabaseAnonKey) }

        AlertDialog(
            onDismissRequest = { showSupabaseDialog = false },
            title = { Text("Supabase Credentials") },
            text = {
                Column {
                    OutlinedTextField(
                        value = url,
                        onValueChange = { url = it },
                        label = { Text("URL") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = key,
                        onValueChange = { key = it },
                        label = { Text("Anon Key") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        syncService.supabaseUrl = url.trim()
                        syncService.supabaseAnonKey = key.trim()
                        showSupabaseDialog = false
                        Toast.makeText(context, "Credentials saved", Toast.LENGTH_SHORT).show()
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue)
                ) {
                    Text("Save", color = CobaltLabel)
                }
            },
            dismissButton = {
                TextButton(onClick = { showSupabaseDialog = false }) {
                    Text("Cancel", color = MutedText)
                }
            }
        )
    }
}
