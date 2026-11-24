package com.habittracker.app.ui.auth

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowOutward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.habittracker.app.service.SupabaseSyncService
import com.habittracker.app.theme.CardBrush
import com.habittracker.app.theme.CardSurface
import com.habittracker.app.theme.CobaltBlue
import com.habittracker.app.theme.CobaltEnamelBrush
import com.habittracker.app.theme.CobaltLabel
import com.habittracker.app.theme.Hairline
import com.habittracker.app.theme.MutedText
import com.habittracker.app.theme.PageGround
import com.habittracker.app.theme.PrimaryText
import com.habittracker.app.theme.ReverseBevel
import com.habittracker.app.theme.SecondaryText
import com.habittracker.app.theme.TopLightBevel
import com.habittracker.app.theme.WellBrush
import com.habittracker.app.ui.components.EngravedDivider
import kotlinx.coroutines.launch

@Composable
fun AuthScreen(
    syncService: SupabaseSyncService,
    onAuthSuccess: () -> Unit,
    onDismiss: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val scrollState = rememberScrollState()

    var isSignUp by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageGround)
            .verticalScroll(scrollState)
            .padding(horizontal = 20.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (onDismiss != null) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close",
                        tint = MutedText
                    )
                }
            }
        } else {
            Spacer(modifier = Modifier.height(24.dp))
        }

        // Brand Icon & Title
        Box(
            modifier = Modifier
                .size(64.dp)
                .shadow(3.dp, RoundedCornerShape(16.dp))
                .clip(RoundedCornerShape(16.dp))
                .background(CardBrush)
                .border(1.dp, TopLightBevel, RoundedCornerShape(16.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = CobaltBlue,
                modifier = Modifier.size(32.dp)
            )
        }

        Spacer(modifier = Modifier.height(14.dp))

        Text(
            text = "Habit Tracker",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = PrimaryText
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "Build discipline, break barriers.",
            fontSize = 14.sp,
            color = SecondaryText
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Toggle Switcher Pill (Recessed Trough)
        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(WellBrush)
                .border(1.dp, ReverseBevel, CircleShape)
                .padding(4.dp)
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .then(
                        if (!isSignUp) {
                            Modifier
                                .shadow(2.dp, CircleShape)
                                .clip(CircleShape)
                                .background(CobaltEnamelBrush)
                                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
                        } else {
                            Modifier.clip(CircleShape)
                        }
                    )
                    .clickable {
                        isSignUp = false
                        errorMessage = null
                    }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Sign In",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (!isSignUp) CobaltLabel else PrimaryText
                )
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .then(
                        if (isSignUp) {
                            Modifier
                                .shadow(2.dp, CircleShape)
                                .clip(CircleShape)
                                .background(CobaltEnamelBrush)
                                .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
                        } else {
                            Modifier.clip(CircleShape)
                        }
                    )
                    .clickable {
                        isSignUp = true
                        errorMessage = null
                    }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Create Account",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isSignUp) CobaltLabel else PrimaryText
                )
            }
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Error Banner
        AnimatedVisibility(visible = errorMessage != null) {
            errorMessage?.let { msg ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0xFFFFEBEE))
                        .border(1.dp, Color(0xFFFFCDD2), RoundedCornerShape(10.dp))
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Warning,
                        contentDescription = null,
                        tint = Color(0xFFD32F2F),
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text(text = msg, fontSize = 13.sp, color = Color(0xFFD32F2F))
                }
                Spacer(modifier = Modifier.height(12.dp))
            }
        }

        // Form Card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(4.dp, RoundedCornerShape(16.dp))
                .clip(RoundedCornerShape(16.dp))
                .background(CardBrush)
                .border(1.dp, TopLightBevel, RoundedCornerShape(16.dp))
                .padding(18.dp)
        ) {
            if (isSignUp) {
                Text(text = "Display Name", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SecondaryText)
                Spacer(modifier = Modifier.height(4.dp))
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    placeholder = { Text("e.g. Alex Rivera") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(modifier = Modifier.height(14.dp))
            }

            Text(text = "Email Address", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SecondaryText)
            Spacer(modifier = Modifier.height(4.dp))
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                placeholder = { Text("name@example.com") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(14.dp))

            Text(text = "Password", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SecondaryText)
            Spacer(modifier = Modifier.height(4.dp))
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                placeholder = { Text("••••••••") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(18.dp))

            Button(
                onClick = {
                    errorMessage = null
                    isLoading = true
                    scope.launch {
                        val result = if (isSignUp) {
                            syncService.signUp(email, password, displayName.ifBlank { "Habit Tracker" })
                        } else {
                            syncService.signIn(email, password)
                        }
                        isLoading = false
                        result.onSuccess {
                            onAuthSuccess()
                        }.onFailure { err ->
                            errorMessage = err.message ?: "Authentication failed"
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .shadow(2.dp, RoundedCornerShape(12.dp))
                    .border(1.dp, Color.White.copy(alpha = 0.5f), RoundedCornerShape(12.dp)),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = CobaltBlue),
                enabled = !isLoading && email.isNotBlank() && password.isNotBlank()
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = CobaltLabel, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else {
                    Text(
                        text = if (isSignUp) "Create Account" else "Sign In",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = CobaltLabel
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // OR Divider
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(modifier = Modifier.weight(1f)) { EngravedDivider() }
            Text(
                text = "OR CONTINUE WITH",
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                color = MutedText,
                modifier = Modifier.padding(horizontal = 8.dp)
            )
            Box(modifier = Modifier.weight(1f)) { EngravedDivider() }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // OAuth Options (Supabase OAuth)
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            OAuthButtonRow(
                title = "Continue with Google",
                onClick = {
                    val url = syncService.getOAuthUrl("google")
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                }
            )

            OAuthButtonRow(
                title = "Continue with Apple",
                onClick = {
                    val url = syncService.getOAuthUrl("apple")
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                }
            )

            OAuthButtonRow(
                title = "Continue with GitHub",
                onClick = {
                    val url = syncService.getOAuthUrl("github")
                    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                }
            )
        }

        Spacer(modifier = Modifier.height(30.dp))
    }
}

@Composable
private fun OAuthButtonRow(
    title: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(2.dp, RoundedCornerShape(12.dp))
            .clip(RoundedCornerShape(12.dp))
            .background(CardBrush)
            .border(1.dp, TopLightBevel, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = PrimaryText
        )
        Spacer(modifier = Modifier.weight(1f))
        Icon(
            imageVector = Icons.Default.ArrowOutward,
            contentDescription = null,
            tint = MutedText,
            modifier = Modifier.size(14.dp)
        )
    }
}
