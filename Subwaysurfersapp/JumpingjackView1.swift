/*
 SUMMARY OF THIS PAGE
 -------------------
 • Take the default video JumpingjackVideo1.mp4
 • Sends video to Core ML model (Jumpingjacks.mlmodel).
 • The model predicts the exercise label (e.g. "second", "sixth", "Third", "11", "12" etc)
 • Displays that Predictions > Output > Label as text

 In short:
 👉 Page only analayses the video JumpingjackVideo1.mp4

*/

import SwiftUI
import AVKit
import Vision
import CoreML

// This class handles analyzing a video and predicting the exercise using Core ML
class ModelAnalyzer: ObservableObject {
    @Published var modelLabel: String = "-"          // Stores the model's predicted label
    @Published var statusText: String = "Press Analyze" // Stores status messages for the UI
    
    func analyzeVideo(videoName: String) {
        // Load the video from the app bundle
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            statusText = "Video not found"
            return
        }
        
        let asset = AVAsset(url: url)
        
        // Get the first video track from the asset
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            statusText = "No video track"
            return
        }
        
        // Set up AVAssetReader to read frames from the video
        let reader = try! AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        reader.add(readerOutput)
        reader.startReading()
        
        var posesPerFrame: [[[Float]]] = []  // Store keypoints for each frame
        
        // Loop through each frame of the video
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            
            // Create a Vision request to detect human body poses
            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
            
            // Get the first detected pose observation
            if let observation = request.results?.first {
                // List of joints to extract from the pose
                let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .leftEye, .rightEye, .leftEar, .rightEar,
                    .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
                    .leftWrist, .rightWrist, .leftHip, .rightHip,
                    .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .neck
                ]
                
                var keypoints: [[Float]] = [] // Store x, y, confidence for each joint
                
                // Loop through each joint and get its position and confidence
                for joint in jointNames {
                    if let pt = try? observation.recognizedPoint(joint) {
                        keypoints.append([Float(pt.x), Float(pt.y), Float(pt.confidence)])
                    } else {
                        // If joint not detected, store zeros
                        keypoints.append([0,0,0])
                    }
                }
                
                // Add this frame's keypoints to the array
                posesPerFrame.append(keypoints)
            }
        }
        
        // Ensure we have exactly 60 frames for the ML model input
        if posesPerFrame.count > 60 { posesPerFrame = Array(posesPerFrame.suffix(60)) }
        while posesPerFrame.count < 60 { posesPerFrame.insert(Array(repeating:[0,0,0], count:18), at:0) }
        
        // Convert keypoints to MLMultiArray format for Core ML
        let mlArray = try! MLMultiArray(shape: [60,3,18], dataType: .float32)
        for f in 0..<60 {
            for c in 0..<3 {
                for k in 0..<18 {
                    mlArray[[NSNumber(value:f), NSNumber(value:c), NSNumber(value:k)]] = NSNumber(value: posesPerFrame[f][k][c])
                }
            }
        }
        
        // Run the Core ML model on the prepared input
        do {
            let model = try Jumpingjacks()
            let input = JumpingjacksInput(poses: mlArray)
            let output = try model.prediction(input: input)
            
            // Update UI on main thread with the predicted label
            DispatchQueue.main.async {
                self.modelLabel = output.label
                self.statusText = "Analysis complete"
            }
        } catch {
            // Handle errors and update UI
            DispatchQueue.main.async {
                self.modelLabel = "-"
                self.statusText = "Model prediction failed: \(error)"
            }
        }
    }
}

// SwiftUI view to show the video and model prediction
struct JumpingjackView1: View {
    @StateObject private var analyzer = ModelAnalyzer()
    
    var body: some View {
        VStack(spacing: 20) {
            // Video player to show the jumping jack video
            VideoPlayer(player: AVPlayer(url: Bundle.main.url(forResource: "JumpingjackVideo1", withExtension: "mp4")!))
                .frame(height: 300)
            
            // Display the model's predicted label
            Text("Model Prediction: \(analyzer.modelLabel)")
                .font(.title)
            
            // Display status messages
            Text(analyzer.statusText)
                .foregroundColor(.gray)
            
            // Button to start analyzing the video
            Button("Analyze Video") {
                analyzer.analyzeVideo(videoName: "JumpingjackVideo1")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    JumpingjackView1()
}
