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
import androidx.compose.ui.draw.shadow
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
import com.habittracker.app.theme.BronzeMedalBrush
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CharcoalBrush
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.GoldMedalBrush
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.InverseSurface
import com.habittracker.app.theme.InverseText
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.theme.SilverMedalBrush
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import com.habittracker.app.ui.components.EngravedDivider

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
                    .shadow(2.dp, CircleShape)
                    .clip(CircleShape)
                    .background(CardBrush)
                    .border(1.dp, TopLightBevel, CircleShape)
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
                .shadow(3.dp, RoundedCornerShape(14.dp))
                .clip(RoundedCornerShape(14.dp))
                .background(CardBrush)
                .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .shadow(2.dp, CircleShape)
                    .clip(CircleShape)
                    .background(CobaltEnamelBrush)
                    .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape),
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
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .clip(CircleShape)
                            .background(GoldMedalBrush)
                    )
                    Spacer(modifier = Modifier.size(3.dp))
                    Text("Rank #1", fontSize = 11.sp, color = SecondaryText)
                }
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Timeframe Selector (Recessed Trough)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(WellBrush)
                .border(1.dp, ReverseBevel, RoundedCornerShape(10.dp))
                .padding(3.dp),
            horizontalArrangement = Arrangement.SpaceAround
        ) {
            listOf("Today", "This Week", "This Month").forEach { tf ->
                val isSel = timeframe == tf
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .then(
                            if (isSel) {
                                Modifier
                                    .shadow(2.dp, RoundedCornerShape(8.dp))
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(CobaltEnamelBrush)
                                    .border(1.dp, Color.White.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
                            } else {
                                Modifier.clip(RoundedCornerShape(8.dp))
                            }
                        )
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
                    .shadow(3.dp, RoundedCornerShape(14.dp))
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBrush)
                    .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(WellBrush)
                            .border(1.dp, ReverseBevel, CircleShape),
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

                    Box(
                        modifier = Modifier
                            .shadow(2.dp, RoundedCornerShape(20.dp))
                            .clip(RoundedCornerShape(20.dp))
                            .background(CobaltEnamelBrush)
                            .border(1.dp, Color.White.copy(alpha = 0.6f), RoundedCornerShape(20.dp))
                            .clickable { showAddDialog = true }
                            .padding(horizontal = 18.dp, vertical = 9.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = CobaltLabel, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.size(4.dp))
                            Text("Add Friend", color = CobaltLabel, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(3.dp, RoundedCornerShape(14.dp))
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBrush)
                    .border(1.dp, TopLightBevel, RoundedCornerShape(14.dp))
            ) {
                itemsIndexed(friends) { index, friend ->
                    val rankBrush = when (index) {
                        0 -> GoldMedalBrush
                        1 -> SilverMedalBrush
                        2 -> BronzeMedalBrush
                        else -> WellBrush
                    }

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .shadow(1.dp, CircleShape)
                                .clip(CircleShape)
                                .background(rankBrush)
                                .border(0.5.dp, Color.White.copy(alpha = 0.7f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "${index + 1}",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (index < 3) Color(0xFF261C02) else PrimaryText
                            )
                        }
                        Spacer(modifier = Modifier.size(8.dp))
                        Box(
                            modifier = Modifier
                                .size(34.dp)
                                .clip(CircleShape)
                                .background(CharcoalBrush)
                                .border(0.75.dp, Color.White.copy(alpha = 0.25f), CircleShape),
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
                    if (index < friends.size - 1) {
                        EngravedDivider()
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
