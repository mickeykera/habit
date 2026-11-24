package com.habittracker.app.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Divider
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CharcoalBrush
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.InverseSurface
import com.habittracker.app.theme.InverseText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush

@Composable
fun HairlineDivider(modifier: Modifier = Modifier) {
    HorizontalDivider(
        modifier = modifier.fillMaxWidth(),
        thickness = 1.dp,
        color = Hairline
    )
}

@Composable
fun EngravedDivider(modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        HorizontalDivider(
            thickness = 1.dp,
            color = Color.Black.copy(alpha = 0.08f)
        )
        HorizontalDivider(
            thickness = 1.dp,
            color = Color.White.copy(alpha = 0.8f)
        )
    }
}

@Composable
fun InverseBadge(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(6.dp))
            .background(CharcoalBrush)
            .border(0.75.dp, Color.White.copy(alpha = 0.25f), RoundedCornerShape(6.dp))
            .padding(horizontal = 8.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            color = InverseText,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
fun CompletionCircle(
    isCompleted: Boolean,
    isQuit: Boolean = false,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(28.dp)
            .shadow(if (isCompleted) 2.dp else 0.dp, CircleShape)
            .clip(CircleShape)
            .clickable { onClick() }
            .then(
                if (isCompleted) {
                    Modifier
                        .background(CobaltEnamelBrush)
                        .border(1.dp, Color.White.copy(alpha = 0.7f), CircleShape)
                } else {
                    Modifier
                        .background(WellBrush)
                        .border(1.dp, ReverseBevel, CircleShape)
                }
            ),
        contentAlignment = Alignment.Center
    ) {
        if (isCompleted) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = "Completed",
                tint = CobaltLabel,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}
