package com.example.blindcheck

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.launch
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed // Import itemsIndexed
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

// Data class to hold the state for each grid item
data class GridItem(
    val id: Int,
    val name: String,
    val isVerified: Boolean = false
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BlindCheckTheme {
                val context = LocalContext.current
                var gridItems by remember {
                    mutableStateOf(
                        List(9) { index -> GridItem(id = index, name = "Item ${index + 1}") }
                    )
                }
                var currentEditingItemId by remember { mutableStateOf<Int?>(null) }

                val textReaderLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.StartActivityForResult()
                ) { result ->
                    if (result.resultCode == Activity.RESULT_OK) {
                        val recognizedText = result.data?.getStringExtra("recognizedText") ?: ""
                        val itemId = currentEditingItemId
                        if (itemId != null && recognizedText.isNotBlank()) {
                            gridItems = gridItems.map {
                                if (it.id == itemId) {
                                    it.copy(name = recognizedText) // Update the name
                                } else {
                                    it
                                }
                            }
                        }
                    }
                    currentEditingItemId = null // Reset
                }

                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    GridScreen(
                        items = gridItems,
                        onItemClick = { clickedItem ->
                            currentEditingItemId = clickedItem.id
                            val intent = Intent(context, TextReaderActivity::class.java)
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
                        },
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}

@Composable
fun GridScreen(
    items: List<GridItem>,
    onItemClick: (GridItem) -> Unit,
    onItemCheckedChange: (GridItem, Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        modifier = modifier
            .fillMaxSize()
            .padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // --- KEY CHANGE 1: Use itemsIndexed to get the index of each item ---
        itemsIndexed(items) { index, item ->
            GridCell(
                item = item,
                index = index, // Pass the index to the GridCell
                onNameClick = { onItemClick(item) },
                onCheckedChange = { isChecked -> onItemCheckedChange(item, isChecked) }
            )
        }
    }
}

@Composable
fun GridCell(
    item: GridItem,
    index: Int, // Receive the index
    onNameClick: () -> Unit,
    onCheckedChange: (Boolean) -> Unit
) {
    // --- KEY CHANGE 2: Calculate coordinates from the index ---
    val row = (index / 3) + 1
    val col = (index % 3) + 1

    Column(
        modifier = Modifier
            .aspectRatio(1f) // Makes the cell a square
            .border(1.dp, Color.LightGray, RoundedCornerShape(8.dp))
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween // Pushes content to top and bottom
    ) {
        // This inner column groups the text and coordinates at the top
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = item.name,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(bottom = 4.dp)
                    .clickable(onClick = onNameClick)
            )

            // --- KEY CHANGE 3: Display the coordinates ---
            Text(
                text = "($row, $col)",
                fontSize = 12.sp,
                color = Color.Gray
            )
        }

        Checkbox(
            checked = item.isVerified,
            onCheckedChange = onCheckedChange,
            modifier = Modifier.padding(top = 8.dp) // Add some space above checkbox
        )
    }
}

@Preview(showBackground = true)
@Composable
fun GridScreenPreview() {
    BlindCheckTheme {
        val items = List(9) { index -> GridItem(id = index, name = "Item ${index + 1}", isVerified = index % 2 == 0) }
        GridScreen(items = items, onItemClick = {}, onItemCheckedChange = { _, _ -> })
    }
}
