package com.example.blindcheck

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.blindcheck.ui.theme.BlindCheckTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Data class to hold the state for each grid item
data class GridItem(
    val id: Int,
    val name: String,
    val isVerified: Boolean = false
)

class MainActivity : ComponentActivity() {
    private lateinit var contractNumber: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        contractNumber = intent.getStringExtra("contractNumber") ?: ""

        setContent {
            BlindCheckTheme {
                val context = LocalContext.current
                val initialCellTexts = listOf(
                    "Michael Johnson", "Emily Davis", "Christopher Miller",
                    "Jessica Anderson", "Daniel Thompson", "Ashley Martinez",
                    "James Wilson", "Sarah Harris", "Andrew Clark"
                )

                var gridItems by remember {
                    mutableStateOf(
                        List(9) { index -> GridItem(id = index, name = initialCellTexts[index]) }
                    )
                }
                var currentEditingItemId by remember { mutableStateOf<Int?>(null) }
                var isVerifying by remember { mutableStateOf(false) }
                var showSuccessDialog by remember { mutableStateOf(false) }
                val scope = rememberCoroutineScope()

                var activityResult by remember { mutableStateOf<ActivityResult?>(null) }

                val textReaderLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.StartActivityForResult()
                ) { result ->
                    activityResult = result
                }

                LaunchedEffect(activityResult) {
                    val result = activityResult
                    if (result != null && result.resultCode == Activity.RESULT_OK) {
                        val isVerified = result.data?.getBooleanExtra("isVerified", false) ?: false
                        val itemId = currentEditingItemId
                        if (itemId != null && isVerified) {
                            gridItems = gridItems.map {
                                if (it.id == itemId) {
                                    it.copy(isVerified = true)
                                } else {
                                    it
                                }
                            }
                        }
                        currentEditingItemId = null
                        activityResult = null
                    }
                }

                if (showSuccessDialog) {
                    AlertDialog(
                        onDismissRequest = { 
                            showSuccessDialog = false
                            val intent = Intent(context, LoginActivity::class.java)
                            context.startActivity(intent)
                        },
                        title = { Text("Success") },
                        text = { Text("Data sent successfully.") },
                        confirmButton = {
                            TextButton(
                                onClick = {
                                    showSuccessDialog = false
                                    val intent = Intent(context, LoginActivity::class.java)
                                    context.startActivity(intent)
                                }
                            ) {
                                Text("OK")
                            }
                        }
                    )
                }

                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Column(
                        modifier = Modifier
                            .padding(innerPadding)
                            .padding(16.dp)
                            .fillMaxSize()
                    ) {
                        Text(
                            text = "Name: User Name",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        Text(
                            text = "Contract Number: $contractNumber",
                            style = MaterialTheme.typography.bodyMedium
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            GridScreen(
                                items = gridItems,
                                onItemClick = { clickedItem ->
                                    currentEditingItemId = clickedItem.id
                                    val intent = Intent(context, TextReaderActivity::class.java).apply {
                                        putExtra("cellName", clickedItem.name)
                                    }
                                    textReaderLauncher.launch(intent)
                                },
                                onItemCheckedChange = { clickedItem, isChecked ->
                                    gridItems = gridItems.map { item ->
                                        if (item.id == clickedItem.id) {
                                            item.copy(isVerified = isChecked)
                                        } else {
                                            item
                                        }
                                    }
                                }
                            )
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Button(
                                onClick = {
                                    scope.launch {
                                        isVerifying = true
                                        delay(2000)
                                        isVerifying = false
                                        showSuccessDialog = true
                                    }
                                },
                                modifier = Modifier.weight(1f),
                                enabled = !isVerifying
                            ) {
                                if (isVerifying) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(24.dp),
                                        color = MaterialTheme.colorScheme.onPrimary
                                    )
                                } else {
                                    Text(text = "Verify")
                                }
                            }
                            Button(
                                onClick = {
                                    val intent = Intent(context, LoginActivity::class.java)
                                    context.startActivity(intent)
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Text(text = "Cancel")
                            }
                        }
                    }
                }
            }
        }
    }
}

// GridScreen composable remains unchanged
@Composable
fun GridScreen(
    items: List<GridItem>,
    onItemClick: (GridItem) -> Unit,
    onItemCheckedChange: (GridItem, Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        itemsIndexed(items) { index, item ->
            GridCell(
                item = item,
                index = index,
                onClick = { onItemClick(item) },
                onCheckedChange = { isChecked -> onItemCheckedChange(item, isChecked) }
            )
        }
    }
}

@Composable
fun GridCell(
    item: GridItem,
    index: Int,
    onClick: () -> Unit,
    onCheckedChange: (Boolean) -> Unit
) {
    val row = (index / 3) + 1
    val col = (index % 3) + 1

    Column(
        modifier = Modifier
            .aspectRatio(1f)
            .border(1.dp, Color.LightGray, RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            // --- KEY CHANGE: Adjust padding ---
            // Reduce horizontal padding to give text more space
            .padding(horizontal = 4.dp, vertical = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // This Box takes up the available space in the middle
        Box(
            modifier = Modifier
                .weight(1f) // This makes the Box expand and pushes other elements to the edges
                .fillMaxSize(),
            contentAlignment = Alignment.Center // Center the content inside the Box
        ) {
            // A new column to hold the name and coordinates
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                // 1. Scanned Text is now on top
                Text(
                    text = item.name.ifEmpty { "..." },
                    fontSize = if (item.name.isEmpty()) 16.sp else 12.sp,
                    fontWeight = if (item.name.isEmpty()) FontWeight.Normal else FontWeight.Bold,
                    textAlign = TextAlign.Center,
                    color = if (item.name.isEmpty()) Color.LightGray else MaterialTheme.colorScheme.onSurface
                )
                // Add a small space only if there is a name
                if (item.name.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(2.dp))
                }
                // 2. Coordinates are now below the name
                Text(
                    text = "($row, $col)",
                    fontSize = 10.sp,
                    color = Color.Gray
                )
            }
        }

        // Reduce space around the Checkbox
        Box(
            modifier = Modifier
                .height(32.dp) // Constrain the height of the checkbox area
                .fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            Checkbox(
                checked = item.isVerified,
                onCheckedChange = onCheckedChange
            )
        }
    }
}


@Preview(showBackground = true)
@Composable
fun GridScreenPreview() {
    BlindCheckTheme {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Name: User Name", style = MaterialTheme.typography.titleLarge)
            Text("Contract Number: 123456789", style = MaterialTheme.typography.bodyMedium)
            Spacer(modifier = Modifier.height(16.dp))
            // Preview a cell with and without text
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Box(modifier = Modifier.weight(1f)) {
                    GridCell(item = GridItem(0, "Scanned Text Here", true), index = 0, onClick = {}, onCheckedChange = {})
                }
                Box(modifier = Modifier.weight(1f)) {
                    GridCell(item = GridItem(1, "", false), index = 1, onClick = {}, onCheckedChange = {})
                }
            }
        }
    }
}
