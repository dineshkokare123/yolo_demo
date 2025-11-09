import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'dart:ui' as ui; 

void main() => runApp(const YOLODemo());


.
int _safelyParseClassId(Map<String, dynamic> detection, List<String> labels) {
  // 1. Check for the numeric ID keys first (for robustness)
  final dynamic numericIdValue = detection['class_id'] ?? detection['id'];
  
  if (numericIdValue is int) {
    return numericIdValue;
  }
  
  // 2. If numeric ID is missing, check for the class NAME keys
  final dynamic classNameValue = detection['class'] ?? detection['className'];
  
  if (classNameValue is String) {
    // FIX: Normalize the class name to lowercase for reliable lookup
    final String className = classNameValue.toLowerCase();
    
    // Look up the index of the class name in the provided labels list
    final int index = labels.indexOf(className);
    
    // If found, indexOf returns the index (0-79). If not found, it returns -1.
    return index;
  }
  
  // If nothing is found, return -1 (Unknown Label)
  return -1;
}

// --- MAIN WIDGETS ---

class YOLODemo extends StatefulWidget {
  const YOLODemo({super.key});

  @override
  YOLODemoState createState() => YOLODemoState();
}

class YOLODemoState extends State<YOLODemo> {
  YOLO? yolo;
  File? selectedImageFile;
  List<Map<String, dynamic>> results = [];
  bool isLoading = false;
  ui.Size? originalImageSize;

  // IMPORTANT: Ensure this list is 80 items long and correct for COCO dataset
  final List<String> cocoLabels = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 
    'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign', 
    'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 
    'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 
    'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 
    'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 
    'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 
    'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange', 
    'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 
    'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 
    'laptop', 'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 
    'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase', 
    'scissors', 'teddy bear', 'hair drier', 'toothbrush',
  ];

  
  // --- YOLO INITIALIZATION ---
  @override
  void initState() {
    super.initState();
    loadYOLO();
  }

  @override
  void dispose() {
    yolo?.dispose();
    super.dispose();
  }

  Future<void> loadYOLO() async {
    setState(() => isLoading = true);
    
    yolo = YOLO(
      modelPath: 'yolo11n',
      task: YOLOTask.detect,
      classifierOptions: {'labels': cocoLabels}, 
      useMultiInstance: true 
    );

    await yolo!.loadModel();
    setState(() => isLoading = false);
  }

  // --- IMAGE PICKING AND DETECTION (ON MAIN THREAD) ---
  Future<void> pickAndDetect() async {
    if (yolo == null || isLoading) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final file = File(image.path);
      final imageBytes = await file.readAsBytes();

      setState(() {
        selectedImageFile = file;
        results = [];
        isLoading = true; 
        originalImageSize = null; 
      });

      // 1. Decode image on the main thread to get dimensions (SAFE)
      try {
        final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        
        originalImageSize = ui.Size(
            frameInfo.image.width.toDouble(), 
            frameInfo.image.height.toDouble()
        );
      } catch (e) {
         if (kDebugMode) {
           print('Error decoding image dimensions: $e');
         }
         originalImageSize = const ui.Size(640, 640); // Fallback
      }
      
      // 2. Perform prediction on the main UI thread (BLOCKING)
      final Map<String, dynamic>? predictionMap = await yolo!.predict(
        imageBytes,
        confidenceThreshold: 0.25, 
      );
      
      // 3. Update the UI state
      setState(() {
        final List<dynamic>? boxes = predictionMap?['boxes'] as List<dynamic>?;
        results = boxes?.cast<Map<String, dynamic>>() ?? [];
        isLoading = false;

        if (results.isNotEmpty) {
            if (kDebugMode) {
              print('--- RAW DETECTION MAP ---');
            }
            if (kDebugMode) {
              print(results.first);
            }
            if (kDebugMode) {
              print('---------------------------');
            }
        }
      });
    }
  }

  // --- WIDGET BUILDER ---
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('YOLO Quick Demo 🚀')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display Image with Bounding Boxes
              if (selectedImageFile != null && originalImageSize != null)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: AspectRatio(
                    aspectRatio: originalImageSize!.width / originalImageSize!.height,
                    child: CustomPaint(
                      // CustomPainter draws the boxes and labels
                      painter: BoxPainter(
                        detections: results,
                        labels: cocoLabels,
                        originalSize: originalImageSize!,
                      ),
                      // Image.file is the child, drawing the image on the main thread
                      child: Image.file(selectedImageFile!, fit: BoxFit.contain),
                    ),
                  ),
                )
              else if (selectedImageFile != null)
                const SizedBox(height: 300, child: Center(child: Text('Loading Image...')))
              else
                const SizedBox(height: 300, child: Center(child: Text('Pick an image to start detection.'))),

              const SizedBox(height: 20),

              if (isLoading && selectedImageFile != null)
                const CircularProgressIndicator()
              else if (selectedImageFile != null)
                Text('Detected **${results.length}** objects'),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: yolo != null && !isLoading ? pickAndDetect : null,
                child: const Text('Pick Image & Detect'),
              ),

              const SizedBox(height: 20),

              // Show detection results list
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final detection = results[index];
                    
                    // FIX: Pass the cocoLabels list to the helper function
                    final int classId = _safelyParseClassId(detection, cocoLabels);
                    final double confidence = (detection['confidence'] as double?) ?? 0.0;
                    
                    final String className = classId >= 0 && classId < cocoLabels.length
                        ? cocoLabels[classId]
                        : 'Unknown Label (ID: $classId)';

                    return ListTile(
                      title: Text(className), 
                      subtitle: Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%'
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER IMPLEMENTATION ---
class BoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final List<String> labels;
  final ui.Size originalSize;

  BoxPainter({
    required this.detections, 
    required this.labels,
    required this.originalSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate scaling factors: Widget size vs. Original Image size
    final double scaleX = size.width / originalSize.width;
    final double scaleY = size.height / originalSize.height;
    
    for (var detection in detections) {
      final List<dynamic>? box = detection['box'] as List<dynamic>?; 
      if (box == null || box.length < 4) continue;
      
      // FIX: Pass the labels list to the helper function
      final int classId = _safelyParseClassId(detection, labels);
      final double confidence = (detection['confidence'] as double?) ?? 0.0;
      
      final String label = classId >= 0 && classId < labels.length
          ? labels[classId]
          : 'Unknown';
      
      final String displayText = '$label (${(confidence * 100).toStringAsFixed(0)}%)';

      // 1. Apply scaling to detection coordinates
      final double left = (box[0] as num).toDouble() * scaleX;
      final double top = (box[1] as num).toDouble() * scaleY;
      final double right = (box[2] as num).toDouble() * scaleX;
      final double bottom = (box[3] as num).toDouble() * scaleY;
      
      final Rect rect = Rect.fromLTRB(left, top, right, bottom);

      // 2. Draw the bounding box
      canvas.drawRect(rect, boxPaint);

      // 3. Draw the label text and background
      textPainter.text = TextSpan(
        text: displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      
      // Draw background for text (for readability)
      canvas.drawRect(
        Rect.fromLTWH(
          left, 
          top - textPainter.height - 2, 
          textPainter.width + 4, 
          textPainter.height + 2
        ), 
        Paint()..color = Colors.red.withOpacity(0.8)
      );

      // Draw the text
      textPainter.paint(canvas, Offset(left + 2, top - textPainter.height - 1));
    }
  }

  @override
  bool shouldRepaint(BoxPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.originalSize != originalSize;
  }
}
