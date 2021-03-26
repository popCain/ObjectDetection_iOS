import CoreMedia
import CoreML
import UIKit
import Vision

class ViewController: UIViewController {
  
  //let textLayer_speed:CATextLayer
  var startTime:Double = 0.0
  var FPS:String = "Detection Speed"
  //public let labels = ["gaara"]
  // 80类名称
/*
  public let labels = ["person", "bicycle", "car", "motorcycle", "airplane",
  "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign",
  "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
  "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag",
  "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite",
  "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
  "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana",
  "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza",
  "donut", "cake", "chair", "couch", "potted plant", "bed", "dining table",
  "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone",
  "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock",
  "vase", "scissors", "teddy bear", "hair drier", "toothbrush"]
*/
    
  @IBOutlet var videoPreview: UIView!

  var videoCapture: VideoCapture!
  var currentBuffer: CVPixelBuffer?
  
  // 模型初始化
  //let coreMLModel = MobileNetV1_SSDLite() //iphoneSE2 45FPS; iphone8 13FPS
  //let coreMLModel = MobileNetV2_SSDLite() //iphoneSE2 40, 41FPS; iphone8 10FPS
  //let coreMLModel = MobileNetV3_SSDLite_small() //iphoneSE2 30, 32FPS; iphone8 22FPS
  let coreMLModel = MobileNetV3_SSDLite_Large() //iphoneSE2 22FPS; iphone8 16FPS
  //let coreMLModel = MobileDet_SSDLite() //iphoneSE2 19, 20FPS; iphone8 12-15FPS
  // 用到了匿名函数来初始化属性：{}()
  // try 用在最后的有效操作代码前（出错时进入catch代码）
  lazy var visionModel: VNCoreMLModel = {
    do {
      return try VNCoreMLModel(for: coreMLModel.model)
    } catch {
      fatalError("Failed to create VNCoreMLModel: \(error)")
    }
  }()
  
    /*
        创建使用自己的 *.mlmodel模型的请求（completionHandler:{}为请求处理完成后的响应操作）
        typealias VNRequestCompletionHandler = (VNRequest, Error?) -> Void
        （类型别名 = 函数类型）
        故用【闭包表达式】作为实参 {（request, error） in 逻辑执行代码 } 闭包简写
     */
  // 匿名函数初始化属性
  lazy var visionRequest: VNCoreMLRequest = {
    let request = VNCoreMLRequest(model: visionModel, completionHandler: {
      [weak self] request, error in
      self?.processObservations(for: request, error: error)
    })

    // NOTE: If you use another crop/scale option, you must also change
    // how the BoundingBoxView objects get scaled when they are drawn.
    // Currently they assume the full input image is used.
    request.imageCropAndScaleOption = .scaleFill
    return request
  }()
  
  // 视频中抓取的一张图最多出现十个物体框
  let maxBoundingBoxViews = 10
  // BoundingBoxView类 类型的空数组
  var boundingBoxViews = [BoundingBoxView]()
  var fpsView = FPSShow()
  // color字典，label：对应相应的颜色
  var colors: [String: UIColor] = [:]

    
  override func viewDidLoad() {
    super.viewDidLoad()
    /*
    let textSize = CGSize(width: 20, height: 6)
    self.textLayer_speed.frame = CGRect(origin: CGPoint(x: 5, y: 20), size: textSize)
    self.textLayer_speed.isHidden = false
    self.textLayer_speed.string = self.FPS
    self.textLayer_speed.backgroundColor = UIColor.white.cgColor
    self.videoPreview.layer.addSublayer(self.textLayer_speed)
    */
    setUpBoundingBoxViews()
    setUpCamera()
  }
  
  // 加识别框view（位置框 + 描述标签（置信度））
  func setUpBoundingBoxViews() {
    // 最多十个框
    for _ in 0..<maxBoundingBoxViews {
      boundingBoxViews.append(BoundingBoxView())
    }
    // The label names are stored inside the MLModel's metadata.
    guard let userDefined = coreMLModel.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as? [String: String],
       let allLabels = userDefined["classes"] else {
      fatalError("Missing metadata")
    }

    let labels = allLabels.components(separatedBy: ",")
    print(labels)
    for label in labels {
      colors[label] = UIColor(red: CGFloat.random(in: 0...1),
                              green: CGFloat.random(in: 0...1),
                              blue: CGFloat.random(in: 0...1),
                              alpha: 1)
    }
  }
  
  // 设置摄像头图像抓取
  func setUpCamera() {
    // 自己的VideoCapture类
    videoCapture = VideoCapture()
    // 自己重写的委托
    videoCapture.delegate = self
    
    /*
        一，闭包：
                1.全局函数
                2.嵌套函数
                3.闭包表达式:{(参数-括号可省) in {执行逻辑代码} return 返回值}
     
        二，*注：将很长的【闭包表达式】作为“最后一个参数”传递给函数时，可将此闭包表达式替换成
     【尾随闭包】（并且不需写出参数标签）：函数名（参数1，参数2）{闭包表达式（最后一个参数）}
        
        三， setup（）函数两个参数，第二个参数为逃逸闭包（函数类型），故生命周期比外函数久：
            故可一直调用外函数的变量【success】
     */
    videoCapture.setUp(sessionPreset: .hd1280x720) { success in
      if success {
        // Add the video preview into the UI.
        if let previewLayer = self.videoCapture.previewLayer {
          self.videoPreview.layer.addSublayer(previewLayer)
          self.resizePreviewLayer()
        }

        // Add the bounding box layers to the UI, on top of the video preview.
        for box in self.boundingBoxViews {
          box.addToLayer(self.videoPreview.layer)
        }

        self.fpsView.addToLayer(self.videoPreview.layer)
        // Once everything is set up, we can start capturing live video.
        self.videoCapture.start()
      }
    }
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    resizePreviewLayer()
  }

  func resizePreviewLayer() {
    videoCapture.previewLayer?.frame = videoPreview.bounds
  }

  func predict(sampleBuffer: CMSampleBuffer) {
    if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      currentBuffer = pixelBuffer

      // Get additional info from the camera.
      var options: [VNImageOption : Any] = [:]
      if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
        options[.cameraIntrinsics] = cameraIntrinsicMatrix
      }

      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: options)
      do {
        // 当前时间
        startTime = CFAbsoluteTimeGetCurrent()
        try handler.perform([self.visionRequest])
      } catch {
        print("Failed to perform Vision request: \(error)")
      }

      currentBuffer = nil
    }
  }

  // 处理图像分析结果对象：Observation
  func processObservations(for request: VNRequest, error: Error?) {
    let endTime = CFAbsoluteTimeGetCurrent()
    print("代码执行时长为：%f 毫秒", (endTime - startTime)*1000)
    
    if (endTime - startTime) != 0 {
        self.FPS = "detection speed: " + String(1000/Int((endTime - startTime)*1000)) + " FPS"
        
    }
    
    //**********防止线程阻塞，异步执行*****************
    DispatchQueue.main.async {
        
      //self.textLayer_speed.string = self.FPS
      //print(request.results as Any)
      //从results属性中得图像分析结果对象：Observation
      if let results = request.results as? [VNRecognizedObjectObservation] {
        self.show(predictions: results)
      } else {
        print("weijianchadaowuti")
        self.show(predictions: [])
      }
    }
  }

  func show(predictions: [VNRecognizedObjectObservation]) {
    for i in 0..<boundingBoxViews.count {
      if i < predictions.count {
        let prediction = predictions[i]
        print("*********VNRecognizedObjectObservation**********")
        //print(prediction.labels.description)
        /*
         The predicted bounding box is in normalized image coordinates, with
         the origin in the lower-left corner.

         Scale the bounding box to the coordinate system of the video preview,
         which is as wide as the screen and has a 16:9 aspect ratio. The video
         preview also may be letterboxed at the top and bottom.

         Based on code from https://github.com/Willjay90/AppleFaceDetection

         NOTE: If you use a different .imageCropAndScaleOption, or a different
         video resolution, then you also need to change the math here!
        */

        let width = view.bounds.width
        let height = width * 16 / 9
        //let height = width * 8 / 5
        let offsetY = (view.bounds.height - height) / 2
        let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)
        let rect = prediction.boundingBox.applying(scale).applying(transform)

        // The labels array is a list of VNClassificationObservation objects,
        // with the highest scoring class first in the list.
        let bestClass = prediction.labels[0].identifier
        let confidence = 1 - prediction.labels[0].confidence

        // Show the bounding box.
        let label = String(format: "%@ %.1f", bestClass, confidence * 100)
        let color = colors[bestClass] ?? UIColor.red
        boundingBoxViews[i].show(frame: rect, label: label, color: color)
        
        self.fpsView.show(fps: self.FPS)
      } else {
        boundingBoxViews[i].hide()
      }
    }
  }
}

extension ViewController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
    predict(sampleBuffer: sampleBuffer)
  }
}
