package com.habittracker.app.ui.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.data.HabitType
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText

@Composable
fun AddHabitDialog(
    onDismiss: () -> Unit,
    onSave: (title: String, type: HabitType, days: List<Int>) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var habitType by remember { mutableStateOf(HabitType.BUILD) }
    var isDaily by remember { mutableStateOf(true) }
    var selectedDays by remember { mutableStateOf(setOf<Int>()) }

    val dayNames = listOf("S", "M", "T", "W", "T", "F", "S")

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PageGround,
        shape = RoundedCornerShape(12.dp),
        title = {
            Text("New Habit", fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = PrimaryText)
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = CobaltBlue,
                        unfocusedBorderColor = Hairline
                    )
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Type picker
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(CircleShape)
                        .background(CardSurface)
                        .padding(4.dp)
                ) {
                    HabitType.entries.forEach { type ->
                        val isSelected = habitType == type
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(CircleShape)
                                .background(if (isSelected) CobaltBlue else Color.Transparent)
                                .clickable { habitType = type }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = type.displayName,
                                color = if (isSelected) CobaltLabel else PrimaryText,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Daily Schedule", fontSize = 14.sp, color = PrimaryText)
                    Switch(
                        checked = isDaily,
                        onCheckedChange = { isDaily = it },
                        colors = SwitchDefaults.colors(checkedThumbColor = CobaltBlue)
                    )
                }

                if (!isDaily) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        dayNames.forEachIndexed { index, name ->
                            val isSel = selectedDays.contains(index)
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .clip(CircleShape)
                                    .background(if (isSel) CobaltBlue else CardSurface)
                                    .border(1.dp, Hairline, CircleShape)
                                    .clickable {
                                        selectedDays = if (isSel) selectedDays - index else selectedDays + index
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = name,
                                    fontSize = 12.sp,
                                    color = if (isSel) CobaltLabel else PrimaryText
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (title.isNotBlank()) {
                        onSave(title.trim(), habitType, if (isDaily) emptyList() else selectedDays.toList())
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue),
                shape = CircleShape,
                enabled = title.isNotBlank()
            ) {
                Text("Save", color = CobaltLabel)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = MutedText)
            }
        }
    )
}
