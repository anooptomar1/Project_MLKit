//
//  ViewController.swift
//  Project_MLKit
//
//  Created by iOS Development on 6/21/18.
//  Copyright © 2018 Genisys. All rights reserved.
//

import AVFoundation
import CoreVideo
import UIKit
import FirebaseMLVision

class CameraViewController: UIViewController {

  
  private var currentDetector: Detector = .onDeviceText
  private lazy var captureSession = AVCaptureSession()
  private lazy var sessionQueue = DispatchQueue(label: Constants.sessionQueueLabel)
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private lazy var vision = Vision.vision()
  private lazy var onDeviceTextDetector = vision.textDetector()
  private var cameraView = UIView()
  private lazy var annotationOverlayView: UIView = {
    precondition(isViewLoaded)
    let annotationOverlayView = UIView(frame: .zero)
    annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
    return annotationOverlayView
  }()

 

  

 

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.addSubview(cameraView)
    cameraView.frame = self.view.frame
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    cameraView.layer.addSublayer(previewLayer)
    setUpAnnotationOverlayView()
    setUpCaptureSessionOutput()
    setUpCaptureSessionInput()
   
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    startSession()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    stopSession()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    previewLayer.frame = cameraView.frame
  }

  // MARK: On-Device Detection

  private func detectTextOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
    onDeviceTextDetector.detect(in: image) { features, error in
      guard error == nil, let features = features, !features.isEmpty else {
        self.removeDetectionAnnotations()
        print("On-Device text detector returned no results.")
        return
      }
      self.removeDetectionAnnotations()
      for feature in features {
        guard feature is VisionTextBlock, let block = feature as? VisionTextBlock else { continue }
        
        for line in block.lines {
          
          for element in line.elements {
            let normalizedRect = CGRect(
              x: element.frame.origin.x / width,
              y: element.frame.origin.y / height,
              width: element.frame.size.width / width,
              height: element.frame.size.height / height
            )
            let convertedRect = self.previewLayer.layerRectConverted(
              fromMetadataOutputRect: normalizedRect
            )
            
            
             
           
            let label = UILabel(frame: convertedRect)
            let value = element.text.map({"\($0)"})
            let numArray = ["0","1","2","3","4","5","6","7","8","9"]
            let num = value.detectElement(element: numArray)
            
            UIUtilities.addRectangle(convertedRect,to: self.annotationOverlayView,color: UIColor.green)
            label.text = num.first
            label.textAlignment = .center
         
            label.adjustsFontSizeToFitWidth = true
            self.annotationOverlayView.addSubview(label)
          }
        }
      }
    }
  }

  // MARK: - Private

  private func setUpCaptureSessionOutput() {
    sessionQueue.async {
      self.captureSession.beginConfiguration()
      self.captureSession.sessionPreset = AVCaptureSession.Preset.medium

      let output = AVCaptureVideoDataOutput()
      output.videoSettings =
        [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
      let outputQueue = DispatchQueue(label: Constants.videoDataOutputQueueLabel)
      output.setSampleBufferDelegate(self, queue: outputQueue)
      guard self.captureSession.canAddOutput(output) else {
        print("Failed to add capture session output.")
        return
      }
      self.captureSession.addOutput(output)
      self.captureSession.commitConfiguration()
    }
  }

  private func setUpCaptureSessionInput() {
    sessionQueue.async {
      let cameraPosition: AVCaptureDevice.Position =  .back
      guard let device = self.captureDevice(forPosition: cameraPosition) else {
        print("Failed to get capture device for camera position: \(cameraPosition)")
        return
      }
      do {
        let currentInputs = self.captureSession.inputs
        for input in currentInputs {
          self.captureSession.removeInput(input)
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard self.captureSession.canAddInput(input) else {
          print("Failed to add capture session input.")
          return
        }
        self.captureSession.addInput(input)
      } catch {
        print("Failed to create capture device input: \(error.localizedDescription)")
      }
    }
  }

  private func startSession() {
    sessionQueue.async {
      self.captureSession.startRunning()
    }
  }

  private func stopSession() {
    sessionQueue.async {
      self.captureSession.stopRunning()
    }
  }

  private func setUpAnnotationOverlayView() {
    cameraView.addSubview(annotationOverlayView)
    NSLayoutConstraint.activate([
      annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
      annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
      annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
      annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
      ])
  }

  private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: .unspecified
    )
    return discoverySession.devices.first { $0.position == position }
  }

  private func removeDetectionAnnotations() {
    for annotationView in annotationOverlayView.subviews {
      annotationView.removeFromSuperview()
    }
  }

  private func convertedPoints(from points: [NSValue],width: CGFloat,height: CGFloat) -> [NSValue] {
    return points.map {
      let cgPointValue = $0.cgPointValue
      let normalizedPoint = CGPoint(x: cgPointValue.x / width, y: cgPointValue.y / height)
      let cgPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
      let value = NSValue(cgPoint: cgPoint)
      return value
    }
  }

  private func normalizedPoint(fromVisionPoint point: VisionPoint,width: CGFloat,height: CGFloat) -> CGPoint {
    let cgPoint = CGPoint(x: CGFloat(point.x.floatValue), y: CGFloat(point.y.floatValue))
    var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
    normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
    return normalizedPoint
  }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

  func captureOutput( _ output: AVCaptureOutput,didOutput sampleBuffer: CMSampleBuffer,from connection: AVCaptureConnection) {
   
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Failed to get image buffer from sample buffer.")
      return
    }


    let visionImage = VisionImage(buffer: sampleBuffer)
    let metadata = VisionImageMetadata()
    
    
    metadata.orientation = .rightTop
    let orientation = UIUtilities.imageOrientation(
      fromDevicePosition:  .back
    )
    
    let visionOrientation = UIUtilities.visionImageOrientation(from: orientation)
    metadata.orientation = visionOrientation
    visionImage.metadata = metadata
    let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
    let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
    switch currentDetector {
    case .onDeviceText:
      detectTextOnDevice(in: visionImage, width: imageWidth, height: imageHeight)
    }
  }
}

// MARK: - Constants

public enum Detector: String {
  case onDeviceText = "On-Device Text"
}

private enum Constants {
  static let videoDataOutputQueueLabel = "com.smartivity.VideoDataOutputQueue"
  static let sessionQueueLabel = "com.smartivity.SessionQueue"
  static let smallDotRadius: CGFloat = 4.0
}

