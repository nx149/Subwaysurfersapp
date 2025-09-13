/*
 SUMMARY OF THIS PAGE
 -------------------
 • Shows live video from the iPhone’s front camera.
 • Extracts body pose from each camera frame using Vision.
 • Collects the last 60 frames of pose data.
 • Sends the frames into the Core ML model (Jumpingjacks.mlmodel).
 • Displays that Predictions > Output > Label as text on top of the live camera feed.

 In short:
 👉 The page watches your movement and passes this information to the ML model to analyse


 HOW TO RUN THIS PAGE
 -------------------
 
DONE: (The 3 steps are done)
 1. Open this project in Xcode.
 2. Make sure `Jumpingjacks.mlmodel` is added to the project (drag it into the navigator if missing).
 3. Go to the app’s Info.plist and confirm:
      Privacy - Camera Usage Description = "Camera access is required to analyze jumping jacks"
 
 

 TO DO: (The below steps are not done because a real iphone is need to access the camera)
 4. Connect a real iPhone or iPad (⚠️ the Simulator does NOT support the camera).
 5. Select your device as the run target in Xcode.
 6. Press ▶ Run.
 7. On the device, allow camera permission when asked.
 8. Stand in front of the camera and perform exercises.
 9. The prediction label will update live at the bottom of the screen.
*/


import SwiftUI

// Main SwiftUI view
struct JumpingjackLiveView: View {
    @StateObject private var analyzer = JumpingjackLiveAnalyzer()  // Live analyzer
    
    var body: some View {
        ZStack {
            // Live camera feed
            JumpingjackCameraPreview(session: analyzer.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI to show model prediction
            VStack {
                Spacer()
                Text("Live Prediction: \(analyzer.modelLabel)")
                    .font(.title)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
            }
        }
    }
}

#Preview{
    JumpingjackLiveView()
}
