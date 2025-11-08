# yolo_demo

# 🍎 Flutter YOLO Object Detection Demo (Ultralytics Plugin)

A robust Flutter application demonstrating real-time object detection using the **Ultralytics YOLO** plugin. This project allows users to select an image and display bounding boxes and class labels for detected objects based on the pre-trained COCO dataset (YOLOv8 nano model).

This repository serves as a working template and includes critical fixes necessary to make the Ultralytics plugin work stably with Flutter Isolates and complex data parsing.

## ✨ Features

* **Non-Blocking UI:** Object detection runs efficiently without freezing the main thread.
* **Bounding Box Visualization:** Draws accurate bounding boxes and confidence scores over the detected image.
* **Robust Data Parsing:** Safely handles various data formats returned by the native plugin, including converting string class names (e.g., `"apple"`) back to the required numeric index.
* **Standard COCO Labels:** Supports detection for all 80 common COCO classes (person, car, apple, etc.).
* **Error-Resilient:** Contains fixes for common Flutter/Plugin errors like Isolate initialization (`Bad state: The BackgroundIsolateBinaryMessenger...`) and runtime type errors (`type 'String' is not a subtype of type 'int?'`).

## ⚙️ Technical Stack

* **Framework:** Flutter (Tested on latest stable release)
* **Plugin:** `ultralytics_yolo`
* **Model:** YOLOv8n (YOLOv8 Nano)
* **Language:** Dart

## 🛠️ Key Fixes Implemented

This project specifically addresses stability issues found when integrating the plugin:

1.  **Isolate Crash Prevention:** Removed the standard `compute` function usage and isolated the detection to the **main UI thread** to bypass native initialization failures (`UI actions are only available on root isolate.`). *Note: Future updates to the plugin may re-enable background processing.*
2.  **Dynamic Class ID Resolution:** Implemented a helper function (`_safelyParseClassId`) that dynamically checks for and parses the class identifier, successfully handling cases where the plugin returns the **class name as a string** instead of the expected integer ID.
3.  **Type Safety:** Ensured all list and map casting (`List<dynamic>` to `List<Map<String, dynamic>>`) is explicit and safe.

## 📦 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone [Your Repository URL]
    cd yolo_demo
    ```
2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Ensure Platform Setup:**
    * **iOS/macOS:** Run `pod install` in the `ios/` directory if needed.
    * **Android:** Check the `android/app/build.gradle` file to ensure minimum required SDK version is met by the `ultralytics_yolo` plugin.
4.  **Run the app:**
    ```bash
    flutter run
    ```
5. Screenshots

    <img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-11-08 at 13 06 37" src="https://github.com/user-attachments/assets/31bdeacb-b571-4500-beb6-f25e53882e25" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-11-08 at 13 07 02" src="https://github.com/user-attachments/assets/0855a10d-62ba-4e1b-ad73-3c2a59ea1d1a" />


## 📸 Usage

1.  Click the **"Pick Image & Detect"** button.
2.  Select an image from your device gallery.
3.  The app will display the image with red bounding boxes and confidence labels drawn over detected objects.
4.  The list below the image shows the confidence and label for each detected object.


## 🤝 Contributing

Feel free to fork this repository, submit pull requests, or open issues if you find further stability improvements or updated methods for using background isolates with this plugin.
