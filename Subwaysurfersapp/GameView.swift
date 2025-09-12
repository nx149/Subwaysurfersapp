//
//  GameView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 23/8/25.
//

import SwiftUI
import SceneKit
import CoreML
import Vision
import UIKit
import AVFoundation

struct DetectedObstacle {
    let type: String
    let confidence: Double
    let lane: Int
    let xPosition: Float
    let detectionTime: TimeInterval
    
    func isSameObstacle(as other: DetectedObstacle) -> Bool {
        return self.type == other.type &&
               self.lane == other.lane &&
               abs(self.xPosition - other.xPosition) < 2.0
    }
}

struct GameView: View {
    @State private var scene: SCNScene? = nil
    @State private var trackNodes: [SCNNode] = []
    @State private var currentLane: Int = 1
    @State private var playerDead: Bool = false
    @State private var obstacleModel: ObstacleClassifieryup?
    @State private var jumpinModel: Trackingjumpingjacks?
    @State private var gameTimer: Timer?

    let lanePositions: [Float] = [-5, -2, 1]
    let trackSpeed: Float = 15.0
    let trackLength: Float = 40.0
    @State private var lastUpdateTime: TimeInterval = 0

    let obstacleLabels: [String] = ["fenceobstacle", "thethingobstalce", "trainobstacle"]

    @State private var obstacleHitCount: Int = 0
    @State private var maxObstacleHits: Int = 2
    @State private var lastObstacleHitTime: TimeInterval = 0

    //jumping jack system challenge thing
    @State private var inJumpingJackChallenge = false
    @State private var jumpingJackCount = 0
    @State private var challengeStartTime: Date? = nil
    @State private var challengeTimeRemaining: Int = 10
    @State private var lastJumpDetectionTime: TimeInterval = 0
    @State private var challengeTimer: Timer?

    var body: some View {
        ZStack {
            SceneView(
                scene: scene ?? SCNScene(),
                pointOfView: scene?.rootNode.childNode(withName: "mainCamera", recursively: true),
                options: [.autoenablesDefaultLighting]
            )
            .ignoresSafeArea()
            .gesture(
                DragGesture()
                    .onEnded { value in
                        guard !playerDead && !inJumpingJackChallenge else { return }
                        if value.translation.width < -50 {
                            movePlayer(to: max(currentLane - 1, 0))
                        } else if value.translation.width > 50 {
                            movePlayer(to: min(currentLane + 1, lanePositions.count - 1))
                        }
                    }
            )
            .onAppear {
                setupGame()
            }
            .onDisappear {
                cleanupGame()
            }

            //overlay for jumpinjack challenge
            if inJumpingJackChallenge {
                jumpingJackOverlay
            }

            if playerDead {
                gameOverOverlay
            }
        }
    }
    
    private var jumpingJackOverlay: some View {
        VStack(spacing: 20) {
            Text("EXERCISE TO SURVIVE!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.red)
            
            Text("Do 5 Jumping Jacks!")
                .font(.title2)
                .foregroundColor(.white)
            
            HStack {
                Text("Completed: \(jumpingJackCount)/5")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Time: \(challengeTimeRemaining)s")
                    .font(.headline)
                    .foregroundColor(challengeTimeRemaining <= 3 ? .red : .orange)
            }
            
            Text("Jump with arms up and down!")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .padding()
    }
    
    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("u died lol!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            
            if obstacleHitCount > 0 {
                Text("Hit \(obstacleHitCount) obstacles!")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            if jumpingJackCount < 5 && challengeStartTime != nil {
                Text("Failed jumping jack challenge!")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            Button("Restart Game") {
                restartGame()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }

    func setupGame() {
        scene = makeScene()
        loadMLModel()
        loadJumpingJackModel()
        startGameLoop()
    }
    
    func loadMLModel() {
        do {
            obstacleModel = try ObstacleClassifieryup(configuration: MLModelConfiguration())
            print("Obstacle ML model loaded successfully")
        } catch {
            print("Failed to load obstacle ML model:", error)
        }
    }

    func loadJumpingJackModel() {
        do {
            jumpinModel = try Trackingjumpingjacks(configuration: MLModelConfiguration())
            print("Jumping jack ML model loaded successfully")
        } catch {
            print("Failed to load jumping jack ML model:", error)
        }
    }
    
    func cleanupGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        challengeTimer?.invalidate()
        challengeTimer = nil
        
        obstacleHitCount = 0
        inJumpingJackChallenge = false
        jumpingJackCount = 0
        challengeStartTime = nil
        challengeTimeRemaining = 10
    }

    func makeScene() -> SCNScene {
        let scene = SCNScene()
        addLight(to: scene)
        addTrack(to: scene)
        addPlayer(to: scene)
        scene.rootNode.addChildNode(makeCamera())
        return scene
    }

    func addLight(to scene: SCNScene) {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 200
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.position = SCNVector3(0, 10, 10)
        directionalLight.eulerAngles = SCNVector3(-Float.pi/4, 0, 0)
        scene.rootNode.addChildNode(directionalLight)
    }

    func addTrack(to scene: SCNScene) {
        for i in 0..<3 {
            let trackNode: SCNNode
            if let trackScene = SCNScene(named: "Subway_Surfers_Maps.usdz") {
                trackNode = SCNNode()
                for child in trackScene.rootNode.childNodes {
                    trackNode.addChildNode(child.clone())
                }
            } else {
                trackNode = createFallbackTrack()
            }
            trackNode.position = SCNVector3(Float(i) * trackLength, -1, 0)
            trackNode.scale = SCNVector3(0.15, 0.15, 0.15)
            trackNode.eulerAngles = SCNVector3(0, Float.pi, 0)
            scene.rootNode.addChildNode(trackNode)
            trackNodes.append(trackNode)
        }
    }
    
    func createFallbackTrack() -> SCNNode {
        let trackNode = SCNNode()
        return trackNode
    }

    func addPlayer(to scene: SCNScene) {
        let playerNode: SCNNode
        if let playerScene = SCNScene(named: "Roblox-Noob.usdz") {
            playerNode = SCNNode()
            for child in playerScene.rootNode.childNodes {
                playerNode.addChildNode(child.clone())
            }
        } else {
            let playerGeometry = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0.1)
            playerGeometry.firstMaterial?.diffuse.contents = UIColor.blue
            playerNode = SCNNode(geometry: playerGeometry)
        }
        
        playerNode.name = "player"
        playerNode.position = SCNVector3(0, 0, lanePositions[currentLane])
        playerNode.scale = SCNVector3(0.008, 0.008, 0.008)
        playerNode.eulerAngles = SCNVector3(0, Float.pi, 0)
        scene.rootNode.addChildNode(playerNode)

        let runAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 0.2)
            ])
        )
        playerNode.runAction(runAction, forKey: "running")
    }

    func movePlayer(to lane: Int) {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else { return }
        currentLane = lane
        let moveAction = SCNAction.move(
            to: SCNVector3(playerNode.position.x, playerNode.position.y, lanePositions[lane]),
            duration: 0.2
        )
        playerNode.runAction(moveAction, forKey: "moving")
    }

    func makeCamera() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.name = "mainCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 5, 12)
        cameraNode.eulerAngles = SCNVector3(-Float.pi/6, 0, 0)
        return cameraNode
    }

    func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            guard !playerDead else { return }
            let currentTime = Date().timeIntervalSince1970
            if lastUpdateTime == 0 { lastUpdateTime = currentTime }
            let deltaTime = Float(currentTime - lastUpdateTime)
            lastUpdateTime = currentTime

            if !inJumpingJackChallenge {
                updateTrack(deltaTime: deltaTime)
                updateCamera()
                
                if Int(currentTime * 10) % 4 == 0 {
                    checkCollisionsWithTrackAnalysis()
                }
            } else {
                //heck for jumping jacks
                processJumpingJackChallenge()
            }
        }
    }

    func updateTrack(deltaTime: Float) {
        for track in trackNodes {
            track.position.x -= trackSpeed * deltaTime
            if track.position.x < -trackLength {
                track.position.x += trackLength * Float(trackNodes.count)
            }
        }
    }

    func updateCamera() {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true),
              let cameraNode = scene?.rootNode.childNode(withName: "mainCamera", recursively: true) else { return }

        let targetPosition = SCNVector3(
            playerNode.position.x - 10,
            playerNode.position.y + 5,
            playerNode.position.z + 0
        )
        let currentPos = cameraNode.position
        let lerpFactor: Float = 0.1
        cameraNode.position = SCNVector3(
            currentPos.x + (targetPosition.x - currentPos.x) * lerpFactor,
            currentPos.y + (targetPosition.y - currentPos.y) * lerpFactor,
            currentPos.z + (targetPosition.z - currentPos.z) * lerpFactor
        )
        cameraNode.look(at: playerNode.position)
    }

    func checkCollisionsWithML() {
        guard !playerDead, let model = obstacleModel, let scene = scene else { return }
        guard let playerNode = scene.rootNode.childNode(withName: "player", recursively: true) else { return }
        
        if let cameraImage = captureCurrentLaneImage(),
           let buffer = cameraImage.toCVPixelBuffer() {
            do {
                let prediction = try model.prediction(image: buffer)
                var bestObstacle: DetectedObstacle? = nil
                var maxProbability: Double = 0
                
                for label in obstacleLabels {
                    if let prob = prediction.targetProbability[label] {
                        print("Obstacle \(label): \(String(format: "%.4f", prob))")
                        if prob > 0.001 && prob > maxProbability {
                            maxProbability = prob
                            bestObstacle = DetectedObstacle(
                                type: label,
                                confidence: prob,
                                lane: currentLane,
                                xPosition: playerNode.position.x,
                                detectionTime: Date().timeIntervalSince1970
                            )
                        }
                    }
                }
                
                if let obstacle = bestObstacle {
                    print("Best obstacle detected: \(obstacle.type) with confidence \(obstacle.confidence)")
                    trackObstacleHit(obstacle)
                }
                
            } catch {
                print("ML error:", error)
            }
        }
    }

    func trackObstacleHit(_ obstacle: DetectedObstacle) {
        guard obstacle.lane == currentLane else { return }
        let currentTime = Date().timeIntervalSince1970
        
        if obstacle.confidence > 0.001 && isObstacleInDangerZone(obstacle) {
            obstacleHitCount += 1
            lastObstacleHitTime = currentTime
            print("Obstacle hit! Count: \(obstacleHitCount)/\(maxObstacleHits)")
            
            if obstacleHitCount >= maxObstacleHits {
                print("you hv hit 2 obstacles start ur jumping jack challenge now!")
                triggerJumpingJackChallenge()
                return
            }
        }
    }

    //jumpingajck thing
    func triggerJumpingJackChallenge() {
        print("time to do ur jumping jackets. boi")
        inJumpingJackChallenge = true
        jumpingJackCount = 0
        challengeStartTime = Date()
        challengeTimeRemaining = 10
        
        // stop game movement stop time time machine boi
        gameTimer?.invalidate()
        
        //countdown timer
        challengeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.challengeTimeRemaining -= 1
            print("Challenge time remaining: \(self.challengeTimeRemaining)")
            
            if self.challengeTimeRemaining <= 0 {
                self.challengeTimer?.invalidate()
                if self.jumpingJackCount < 5 {
                    print("CHALLENGE FAILED - YOU DIE!")
                    self.playerDies()
                } else {
                    print("CHALLENGE COMPLETED - YOU SURVIVE!")
                    self.challengeCompleted()
                }
            }
        }
        
        //game loop for jump detection
        startGameLoop()
    }

    func processJumpingJackChallenge() {
        guard inJumpingJackChallenge,
              let jumpinModel = jumpinModel else { return }

        // get current pose data from camera
        if let poseArray = extractPoseArrayFromCamera() {
            if let mlArray = floatArrayToMLMultiArray(poseArray) {
                do {
                    let prediction = try jumpinModel.prediction(poses: mlArray)
                    
                    // check for jumping jack prediction
                    if let jumpingJackProb = prediction.labelProbabilities["JumpingJack"] {
                        print("Jumping Jack probability: \(String(format: "%.4f", jumpingJackProb))")
                        
                        let currentTime = Date().timeIntervalSince1970
                        
                        // detect jumping jack with confidence more than 0.7
                        if jumpingJackProb > 0.7 && (currentTime - lastJumpDetectionTime) > 0.8 {
                            jumpingJackCount += 1
                            lastJumpDetectionTime = currentTime
                            print("yay u did a jumping jack! Count: \(jumpingJackCount)/5")
                            
                            // check if challenge completed
                            if jumpingJackCount >= 5 {
                                challengeCompleted()
                            }
                        }
                    }
                    
                    for (label, prob) in prediction.labelProbabilities {
                        if prob > 0.1 { // only print significant probabilities
                            print("  \(label): \(String(format: "%.3f", prob))")
                        }
                    }
                    
                } catch {
                    print("Jumping jack ML error:", error)
                }
            }
        }
    }
    
    func challengeCompleted() {
        print("JUMPING JACK CHALLENGE COMPLETED!")
        inJumpingJackChallenge = false
        challengeTimer?.invalidate()
        challengeTimer = nil
        
        // Reset obstacle count and resume normal gameplay
        obstacleHitCount = 0
        
        // Restart normal game loop
        gameTimer?.invalidate()
        startGameLoop()
    }

    func floatArrayToMLMultiArray(_ array: [Float]) -> MLMultiArray? {
        do {
            let mlArray = try MLMultiArray(shape: [NSNumber(value: array.count)], dataType: .float32)
            for (i, value) in array.enumerated() {
                mlArray[i] = NSNumber(value: value)
            }
            return mlArray
        } catch {
            print("Error creating MLMultiArray:", error)
            return nil
        }
    }

    func extractPoseArrayFromCamera() -> [Float]? {
        guard let image = captureCurrentLaneImage(),
              let buffer = image.toCVPixelBuffer() else { return nil }
        return getCurrentPoses(from: buffer)
    }

    func getCurrentPoses(from pixelBuffer: CVPixelBuffer) -> [Float]? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let firstPerson = observations.first else {
                print("No pose detected")
                return nil
            }

            var poseArray: [Float] = []
            let joints = try firstPerson.recognizedPoints(.all)
            
            // convert pose points to array format
            for (jointName, point) in joints {
                if point.confidence > 0.5 {
                    //only use confident detections
                    poseArray.append(Float(point.location.x))
                    poseArray.append(Float(point.location.y))
                    poseArray.append(Float(point.confidence))
                } else {
                    // zeros for low-confidence data thing
                    poseArray.append(0.0)
                    poseArray.append(0.0)
                    poseArray.append(0.0)
                }
            }
            
            print("Extracted \(poseArray.count) pose values")
            return poseArray
            
        } catch {
            print("Pose detection error:", error)
            return nil
        }
    }

    func captureCurrentLaneImage() -> UIImage? {
        guard let scene = scene,
              let cameraNode = scene.rootNode.childNode(withName: "mainCamera", recursively: true),
              let playerNode = scene.rootNode.childNode(withName: "player", recursively: true) else { return nil }
        
        let focusedCameraNode = cameraNode.clone()
        focusedCameraNode.position = SCNVector3(
            playerNode.position.x - 8,
            playerNode.position.y + 5,
            lanePositions[currentLane]
        )
        focusedCameraNode.eulerAngles = SCNVector3(0, 0, 0)
        
        let lookAtPoint = SCNVector3(
            playerNode.position.x + 8,
            playerNode.position.y,
            lanePositions[currentLane]
        )
        focusedCameraNode.look(at: lookAtPoint)
        
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        renderer.pointOfView = focusedCameraNode
        
        let image = renderer.snapshot(atTime: CACurrentMediaTime(), with: CGSize(width: 224, height: 224), antialiasingMode: .none)
        return image
    }

    func isObstacleInDangerZone(_ obstacle: DetectedObstacle) -> Bool {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else { return false }
        let distanceAhead = obstacle.xPosition - playerNode.position.x
        return abs(distanceAhead) < 5.0 && obstacle.lane == currentLane // danger zone increased
    }

    func checkCollisionsWithTrackAnalysis() {
        guard !playerDead else { return }
        checkCollisionsWithML()
    }

    func playerDies() {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else { return }
        playerDead = true
        inJumpingJackChallenge = false
        
        playerNode.removeAllActions()
        let fallAction = SCNAction.sequence([
            SCNAction.rotateBy(x: CGFloat(Float.pi)/2, y: 0, z: 0, duration: 0.5),
            SCNAction.fadeOut(duration: 0.5)
        ])
        playerNode.runAction(fallAction)
        
        gameTimer?.invalidate()
        gameTimer = nil
        challengeTimer?.invalidate()
        challengeTimer = nil
        
        print("u died loser lololol!")
    }

    func restartGame() {
        cleanupGame()
        playerDead = false
        currentLane = 1
        lastUpdateTime = 0
        trackNodes.removeAll()
        setupGame()
    }
}

//camera preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 160))
        
        guard let session = session else { return view }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(size.width),
                                       Int(size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                              width: Int(size.width),
                              height: Int(size.height),
                              bitsPerComponent: 8,
                              bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                              space: rgbColorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

#Preview {
    GameView()
}
