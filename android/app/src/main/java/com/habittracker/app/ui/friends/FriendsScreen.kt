package com.habittracker.app.ui.friends

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.service.SupabaseSyncService
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.InverseSurface
import com.habittracker.app.theme.InverseText
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.SecondaryText

@Composable
fun FriendsScreen(syncService: SupabaseSyncService) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current
    var timeframe by remember { mutableStateOf("This Week") }
    var showAddDialog by remember { mutableStateOf(false) }
    var friendCodeInput by remember { mutableStateOf("") }
    val friends = remember { syncService.getFriends() } // Empty by default: zero seed data!

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        // Top Bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(modifier = Modifier.size(36.dp)) // Spacer to center title

            Text(
                text = "Friends",
                fontSize = 20.sp,
                fontWeight = FontWeight.Medium,
                color = PrimaryText
            )

            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(CardSurface)
                    .border(1.dp, Hairline, CircleShape)
                    .clickable { showAddDialog = true },
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Friend", tint = CobaltBlue, modifier = Modifier.size(16.dp))
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // User Card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CardSurface)
                .border(1.5.dp, CobaltBlue.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(CobaltBlue),
                contentAlignment = Alignment.Center
            ) {
                Text("ME", color = CobaltLabel, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            }

            Column(modifier = Modifier.padding(start = 12.dp)) {
                Text(syncService.displayName, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Code: ${syncService.friendCode}",
                        fontSize = 12.sp,
                        color = MutedText,
                        fontFamily = FontFamily.Monospace
                    )
                    Spacer(modifier = Modifier.size(6.dp))
                    Icon(
                        imageVector = Icons.Default.ContentCopy,
                        contentDescription = "Copy",
                        tint = CobaltBlue,
                        modifier = Modifier
                            .size(12.dp)
                            .clickable {
                                clipboardManager.setText(AnnotatedString(syncService.friendCode))
                                Toast.makeText(context, "Copied friend code", Toast.LENGTH_SHORT).show()
                            }
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "100%",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    color = CobaltBlue
                )
                Text("Rank #1", fontSize = 11.sp, color = SecondaryText)
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Timeframe Selector
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
                .padding(3.dp),
            horizontalArrangement = Arrangement.SpaceAround
        ) {
            listOf("Today", "This Week", "This Month").forEach { tf ->
                val isSel = timeframe == tf
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(6.dp))
                        .background(if (isSel) CobaltBlue else Color.Transparent)
                        .clickable { timeframe = tf }
                        .padding(vertical = 7.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = tf,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (isSel) CobaltLabel else PrimaryText
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Friends List or Clean Empty State
        if (friends.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardSurface)
                    .border(1.dp, Hairline, RoundedCornerShape(14.dp))
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(CobaltBlue.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.People,
                            contentDescription = null,
                            tint = CobaltBlue,
                            modifier = Modifier.size(28.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Text(
                        text = "It's always nice to have someone by your side. Tap + to invite a friend.",
                        fontSize = 14.sp,
                        color = SecondaryText,
                        textAlign = TextAlign.Center,
                        lineHeight = 20.sp
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = { showAddDialog = true },
                        colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, tint = CobaltLabel, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.size(4.dp))
                        Text("Add Friend", color = CobaltLabel, fontSize = 13.sp)
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardSurface)
                    .border(1.dp, Hairline, RoundedCornerShape(14.dp))
            ) {
                itemsIndexed(friends) { index, friend ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${index + 1}",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = MutedText,
                            modifier = Modifier.size(20.dp)
                        )
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(CircleShape)
                                .background(InverseSurface),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(friend.avatarInitials, color = InverseText, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                        }
                        Column(modifier = Modifier.padding(start = 12.dp)) {
                            Text(friend.displayName, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = PrimaryText)
                            Text("${friend.totalCompletions} done · ${friend.currentStreak}d streak", fontSize = 11.sp, color = MutedText)
                        }
                        Spacer(modifier = Modifier.weight(1f))
                        Text(
                            text = "${(friend.completionRate * 100).toInt()}%",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Monospace,
                            color = CobaltBlue
                        )
                    }
                }
            }
        }
    }

    if (showAddDialog) {
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Add Friend", fontWeight = FontWeight.SemiBold) },
            text = {
                Column {
                    Text("Enter your friend's 6-character code:", fontSize = 13.sp, color = SecondaryText)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = friendCodeInput,
                        onValueChange = { if (it.length <= 6) friendCodeInput = it.uppercase() },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        Toast.makeText(context, "Added friend code $friendCodeInput", Toast.LENGTH_SHORT).show()
                        showAddDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue),
                    enabled = friendCodeInput.length == 6
                ) {
                    Text("Add", color = CobaltLabel)
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel", color = MutedText)
                }
            }
        )
    }
}
