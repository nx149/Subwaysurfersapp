//
//  JumpingjackCameraPreview.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 13/9/25.
//

import SwiftUI
import AVFoundation

// This struct displays the live camera
struct JumpingjackCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession  // Camera session
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        // Setup AVCaptureVideoPreviewLayer to show live camera feed
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
