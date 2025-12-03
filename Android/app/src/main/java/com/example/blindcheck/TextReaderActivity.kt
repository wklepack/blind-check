package com.example.blindcheck

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.OptIn
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class TextReaderActivity : ComponentActivity() {

    private val hasCameraPermission = mutableStateOf(false)
    private val recognizedTextState = mutableStateOf("")
    private lateinit var cellName: String

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            hasCameraPermission.value = true
        } else {
            Toast.makeText(this, "Permissions not granted by the user.", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        cellName = intent.getStringExtra("cellName") ?: ""

        hasCameraPermission.value = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        setContent {
            if (hasCameraPermission.value) {
                val recognizedText = recognizedTextState.value
                if (recognizedText.isEmpty()) {
                    CameraScreen(
                        cellName = cellName,
                        onImageCaptured = { imageProxy ->
                            processImageWithMLKit(imageProxy)
                        },
                        onError = { error ->
                            Log.e(TAG, "Image capture error", error)
                            Toast.makeText(this, "Capture failed.", Toast.LENGTH_SHORT).show()
                        }
                    )
                } else {
                    ConfirmationScreen(
                        cellName = cellName,
                        scannedText = recognizedText,
                        onSave = {
                            val cleanRecognizedText = recognizedText.replace("\n", " ").replace(Regex("\\s+"), " ").trim()
                            val cellNameWords = cellName.lowercase().split(" ").filter { it.isNotBlank() }.toSet()
                            val recognizedWords = cleanRecognizedText.lowercase().split(" ").filter { it.isNotBlank() }.toSet()

                            val matchingWords = cellNameWords.intersect(recognizedWords)

                            val matchThreshold = 0.5 // 50% of words must match

                            val isVerified = if (cellNameWords.isNotEmpty()) {
                                (matchingWords.size.toFloat() / cellNameWords.size.toFloat()) >= matchThreshold
                            } else {
                                false
                            }

                            val resultIntent = Intent().apply {
                                putExtra("isVerified", isVerified)
                            }
                            setResult(Activity.RESULT_OK, resultIntent)
                            finish()
                        },
                        onScanAgain = {
                            recognizedTextState.value = ""
                        }
                    )
                }
            } else {
                PermissionRequestScreen {
                    requestPermissionLauncher.launch(Manifest.permission.CAMERA)
                }
            }
        }
    }

    @OptIn(ExperimentalGetImage::class)
    private fun processImageWithMLKit(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    recognizedTextState.value = visionText.text.ifBlank { "No text found." }
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Text recognition failed", e)
                    recognizedTextState.value = "Recognition failed."
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }

    companion object {
        private const val TAG = "TextReaderActivity"
    }
}

@Composable
fun PermissionRequestScreen(onRequestPermission: () -> Unit) {
    LaunchedEffect(Unit) {
        onRequestPermission()
    }
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("Requesting camera permission...")
    }
}

@Composable
fun ConfirmationScreen(
    cellName: String,
    scannedText: String,
    onSave: () -> Unit,
    onScanAgain: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Scanning for: $cellName",
                color = Color.White.copy(alpha = 0.7f),
                fontSize = 18.sp,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            Text(
                text = scannedText,
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(bottom = 32.dp)
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Button(onClick = onSave) {
                    Text("Save")
                }
                Button(onClick = onScanAgain) {
                    Text("Scan Again")
                }
            }
        }
    }
}

@Composable
fun CameraScreen(
    cellName: String,
    onImageCaptured: (ImageProxy) -> Unit,
    onError: (ImageCaptureException) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    var imageCapture: ImageCapture? by remember { mutableStateOf(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx)
                val executor = ContextCompat.getMainExecutor(ctx)

                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.setSurfaceProvider(previewView.surfaceProvider)
                    }
                    val capture = ImageCapture.Builder()
                        .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                        .build()
                    imageCapture = capture
                    val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            cameraSelector,
                            preview,
                            capture
                        )
                    } catch (e: Exception) {
                        Log.e("CameraScreen", "Use case binding failed", e)
                    }
                }, executor)
                previewView
            },
            modifier = Modifier.fillMaxSize()
        )

        Text(
            text = "Scanning for: $cellName",
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(16.dp)
                .background(Color.Black.copy(alpha = 0.5f))
                .padding(8.dp),
            color = Color.White,
            fontSize = 16.sp
        )

        Button(
            onClick = {
                val capture = imageCapture ?: return@Button
                capture.takePicture(
                    ContextCompat.getMainExecutor(context),
                    object : ImageCapture.OnImageCapturedCallback() {
                        override fun onCaptureSuccess(image: ImageProxy) {
                            onImageCaptured(image)
                        }
                        override fun onError(exception: ImageCaptureException) {
                            onError(exception)
                        }
                    }
                )
            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 60.dp)
        ) {
            Text("Capture & Read Text")
        }
    }
}
