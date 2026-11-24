package com.habittracker.app.ui.friends

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
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
import com.habittracker.app.ui.components.HairlineDivider

@Composable
fun FriendsScreen(syncService: SupabaseSyncService) {
    val friends = remember { syncService.getDemoFriends() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .padding(16.dp)
    ) {
        Text(
            text = "Friends",
            fontSize = 28.sp,
            fontWeight = FontWeight.Medium,
            color = PrimaryText
        )

        Spacer(modifier = Modifier.height(16.dp))

        // User card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.5.dp, CobaltBlue.copy(alpha = 0.4f), RoundedCornerShape(8.dp))
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
                Text(
                    text = "ME",
                    color = CobaltLabel,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp
                )
            }

            Column(modifier = Modifier.padding(start = 12.dp)) {
                Text(syncService.displayName, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
                Text("Code: ${syncService.friendCode}", fontSize = 13.sp, color = MutedText, fontFamily = FontFamily.Monospace)
            }

            Spacer(modifier = Modifier.weight(1f))

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "100%",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    color = CobaltBlue
                )
                Text(
                    text = "5d streak",
                    fontSize = 12.sp,
                    color = SecondaryText,
                    fontFamily = FontFamily.Monospace
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "LEADERBOARD",
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = MutedText
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Friends list
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(CardSurface)
                .border(1.dp, Hairline, RoundedCornerShape(8.dp))
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
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MutedText,
                        modifier = Modifier.size(24.dp)
                    )

                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .clip(CircleShape)
                            .background(InverseSurface),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = friend.avatarInitials,
                            color = InverseText,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    Column(modifier = Modifier.padding(start = 12.dp)) {
                        Text(
                            text = friend.displayName,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium,
                            color = PrimaryText
                        )
                        Text(
                            text = "${friend.totalCompletions} done · ${friend.currentStreak}d streak",
                            fontSize = 12.sp,
                            color = MutedText
                        )
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Text(
                        text = "${(friend.completionRate * 100).toInt()}%",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Monospace,
                        color = CobaltBlue
                    )
                }

                if (index < friends.size - 1) {
                    HairlineDivider(modifier = Modifier.padding(start = 50.dp))
                }
            }
        }
    }
}
