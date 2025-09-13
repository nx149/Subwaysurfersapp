//
//  JumpingjackLiveAnalyzer.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 13/9/25.
//
import SwiftUI
import AVFoundation
import Vision
import CoreML

// This class handles live camera input and Core ML predictions
class JumpingjackLiveAnalyzer: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Published variable to show predicted label in the UI
    @Published var modelLabel: String = "-"
    
    // Capture session for live video
    let captureSession = AVCaptureSession()
    
    // Video output for getting frames
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Core ML model
    private var mlModel: Jumpingjacks? = nil
    
    // Buffer to store last 60 frames of keypoints for ML input
    private var frameBuffer: [[[Float]]] = []
    
    override init() {
        super.init()
        setupCamera()            // Setup camera session
        mlModel = try? Jumpingjacks()   // Load ML model
    }
    
    // Setup front camera and start capture session
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        // Get front camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        captureSession.addInput(input)
        
        // Set delegate to process each frame
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()  // Start camera
    }
    
    // Delegate function called for each video frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert sampleBuffer to pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Vision request to detect human body pose
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
        
        // Take first detected person (if any)
        guard let observation = request.results?.first else { return }
        
        // List of key joints to extract
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .neck
        ]
        
        // Extract x, y, confidence for each joint
        var keypoints: [[Float]] = []
        for joint in jointNames {
            if let pt = try? observation.recognizedPoint(joint) {
                keypoints.append([Float(pt.x), Float(pt.y), Float(pt.confidence)])
            } else {
                keypoints.append([0,0,0]) // If joint not detected
            }
        }
        
        // Add this frame to buffer, keep only last 60 frames
        frameBuffer.append(keypoints)
        if frameBuffer.count > 60 { frameBuffer.removeFirst() }
        
        // Run ML model only if we have 60 frames
        if frameBuffer.count == 60, let model = mlModel {
            // Convert buffer to MLMultiArray for model input
            let mlArray = try! MLMultiArray(shape: [60,3,18], dataType: .float32)
            for f in 0..<60 {
                for c in 0..<3 {
                    for k in 0..<18 {
                        mlArray[[NSNumber(value:f), NSNumber(value:c), NSNumber(value:k)]] = NSNumber(value: frameBuffer[f][k][c])
                    }
                }
            }
            
            // Get model prediction
            if let output = try? model.prediction(input: JumpingjacksInput(poses: mlArray)) {
                DispatchQueue.main.async {
                    // Update UI with predicted label
                    self.modelLabel = output.label
                }
            }
        }
    }
}
