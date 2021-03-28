# ObjectDetection_iOS
Object detection on iOS mobile device with Vision and Core ML(mlmodel)
## Shibuya Scramble Crossing Live Camera
Test on iphone 8  
![](https://github.com/popCain/ObjectDetection_iOS/blob/main/image/objectDetection.gif)
## Core ML Framework
![](https://github.com/popCain/ObjectDetection_iOS/blob/main/image/coreml.png)  
Core ML supports Vision for analyzing images, Natural Language for processing text, Speech for converting audio to text, and Sound Analysis for identifying sounds in audio. Core ML itself builds on top of low-level primitives like Accelerate and BNNS, as well as Metal Performance Shaders,optimizes on-device performance by leveraging the CPU, GPU, and Neural Engine while minimizing its memory footprint and power consumption. 
## Core ML Models
* [Models from Core ML research community](https://developer.apple.com/machine-learning/models/)
* [Models trained on Create ML](https://developer.apple.com/machine-learning/create-ml/)
* [Models transformed from tensorflow format](https://github.com/popCain/TFtoCoreML/tree/main/mlmodels_IOU0.4_Conf0.6)
## Coding Process（[Detection Reference](https://developer.apple.com/documentation/vision/recognizing_objects_in_live_capture)）
1. Set Up Live Capture
2. Initialize Request(Make a request)
3. VNImageRequestHandler(Handle the request)
4. CompletionHandler(Process the results)
