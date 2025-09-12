//
//  GameView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 23/8/25.
//

import SwiftUI
import SceneKit
import CoreML

struct DetectedObstacle {
    let type: String
    let confidence: Double
    let lane: Int
    let xPosition: Float
    let detectionTime: TimeInterval
    
    //check if obstacle is the same as the other one
    func isSameObstacle(as other: DetectedObstacle) -> Bool {
        return self.type == other.type &&
               self.lane == other.lane &&
               abs(self.xPosition - other.xPosition) < 2.0 // within 2u
    }
}

struct GameView: View {
    @State private var scene: SCNScene? = nil
    @State private var trackNodes: [SCNNode] = []
    @State private var currentLane: Int = 1
    @State private var playerDead: Bool = false
    @State private var obstacleModel: ObstacleClassifieryup?
    @State private var gameTimer: Timer?

    let lanePositions: [Float] = [-5, -2, 1]
    let trackSpeed: Float = 15.0
    let trackLength: Float = 40.0
    @State private var lastUpdateTime: TimeInterval = 0

    let obstacleLabels: [String] = ["fenceobstacle", "thethingobstalce", "trainobstacle"]

    @State private var obstacleHitCount: Int = 0
    @State private var maxObstacleHits: Int = 2 // die after hitting 2 obstacles
    @State private var lastObstacleHitTime: TimeInterval = 0

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
                        guard !playerDead else { return } // dead aniamtion boiii
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

            if playerDead {
                gameOverOverlay
            }
        }
    }
    
    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("u died lol!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            
            Text("Hit \(obstacleHitCount) obstacles!")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("Returning to main menu...")
                .font(.headline)
                .foregroundColor(.gray)
        
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }

    func setupGame() {
        scene = makeScene()
        loadMLModel()
        startGameLoop()
    }
    
    func loadMLModel() {
        do {
            obstacleModel = try ObstacleClassifieryup(configuration: MLModelConfiguration())
        } catch {
            print("Failed to load ML model:", error)
        }
    }
    
    func cleanupGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        
        // reset obstacle tracking system
        obstacleHitCount = 0
        
    }

    //setup for scene running scene boi
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
        
        // Directional light for shadows and depth
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
                trackNode = createFallbackTrack() //fallback smartfella scroll down to seee
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
        print("FART") //lolboi
        
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

        // running animation boi
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

// loop of the game
    func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            guard !playerDead else { return }
            
            let currentTime = Date().timeIntervalSince1970
            if lastUpdateTime == 0 { lastUpdateTime = currentTime }
            let deltaTime = Float(currentTime - lastUpdateTime)
            lastUpdateTime = currentTime

            updateTrack(deltaTime: deltaTime)
            updateCamera()
            
            // check ml
            if Int(currentTime * 10) % 4 == 0 {
                checkCollisionsWithTrackAnalysis()
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
            cameraNode.position = targetPosition
            cameraNode.look(at: playerNode.position)
        
        // smooth camera movement
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
        guard !playerDead, let model = obstacleModel, let scene = scene else {
            print("ML check failed - playerDead: \(playerDead), model: \(obstacleModel != nil), scene: \(scene != nil)")
            return
        }
        
        guard let playerNode = scene.rootNode.childNode(withName: "player", recursively: true) else { return }
        
   // capture what the camea is seeing
        if let cameraImage = captureCurrentLaneImage(),
           let buffer = cameraImage.toCVPixelBuffer() {
            do {
                let prediction = try model.prediction(image: buffer)
                print("(\(currentLane)) fart")
                
                var bestObstacle: DetectedObstacle? = nil
                var maxProbability: Double = 0
                
                for label in obstacleLabels {
                    if let prob = prediction.targetProbability[label] {
                        print("  \(label): \(String(format: "%.6f", prob))")
                        
                        // threshold and only check current lane
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
                    print("obstacle in (\(currentLane)) lane. Confidence: \(obstacle.confidence)")
                    trackObstacleHit(obstacle)
                }
                
            } catch {
                print("ML error:", error)
            }
        } else {
            print("cldnt capture image")
        }
    }
    
// hit any 2 obstacles sytstem
    func trackObstacleHit(_ obstacle: DetectedObstacle) {
        print(" you've hit an obstacle in lane (\(currentLane)): \(obstacle.type) - confidence: \(obstacle.confidence)")
        
        // only count obstacles in current lane
        guard obstacle.lane == currentLane else {
            print("idk wut to print ignore obstacle in other lanes")
            return
        }
        
        let currentTime = Date().timeIntervalSince1970
        
        // hit count for any obstacle with decent DECENT BTW DECENT BOI confidence
        if obstacle.confidence > 0.002 && isObstacleInDangerZone(obstacle) {
            obstacleHitCount += 1
            lastObstacleHitTime = currentTime
            
            print("Obstacle hit! Count: \(obstacleHitCount)/\(maxObstacleHits)")
            
            // die once hit 2 obstacles kidna laggy but oh well
            if obstacleHitCount >= maxObstacleHits {
                print("u've hit \(maxObstacleHits) obstacles now u die loser lol")
                playerDies()
                return
            }
        }
    }
    
    // current lane image capture for ml
    func captureCurrentLaneImage() -> UIImage? {
        guard let scene = scene,
              let cameraNode = scene.rootNode.childNode(withName: "mainCamera", recursively: true),
              let playerNode = scene.rootNode.childNode(withName: "player", recursively: true) else {
            return nil
        }
        
        let focusedCameraNode = cameraNode.clone()
        
        // camera
        let currentLaneZ = lanePositions[currentLane]
        focusedCameraNode.position = SCNVector3(
            playerNode.position.x - 8,
            playerNode.position.y + 5,
            currentLaneZ
        )
        
        focusedCameraNode.eulerAngles = SCNVector3(0, 0, 0)
        
        let lookAtPoint = SCNVector3(
            playerNode.position.x + 8,
            playerNode.position.y,
            currentLaneZ
        )
        focusedCameraNode.look(at: lookAtPoint)
        
        // renderer
        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        renderer.pointOfView = focusedCameraNode
        
        let image = renderer.snapshot(atTime: CACurrentMediaTime(), with: CGSize(width: 224, height: 224), antialiasingMode: .none)
        return image
    }

    // obstacle in danger zone or no
    func isObstacleInDangerZone(_ obstacle: DetectedObstacle) -> Bool {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else {
            return false
        }
        
        guard obstacle.lane == currentLane else {
            return false
        }
        
        let playerX = playerNode.position.x
        let obstacleX = obstacle.xPosition
        
        // obstacle dangerous if too close
        let distanceAhead = obstacleX - playerX
        let dangerZone: Float = 2.0
        
        print("how close u r boi (Current Lane \(currentLane)) - Player X: \(playerX), Obstacle X: \(obstacleX), Distance ahead: \(distanceAhead)")
        
        return abs(distanceAhead) < dangerZone
    }

    // collisions checker
    func checkCollisionsWithTrackAnalysis() {
        guard !playerDead, let model = obstacleModel, let scene = scene else { return }
        
        checkCollisionsWithML()
    }

    func playerDies() {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else { return }
        playerDead = true
        
        playerNode.removeAllActions()
        
        let fallAction = SCNAction.sequence([
            SCNAction.rotateBy(x: CGFloat(Float.pi)/2, y: 0, z: 0, duration: 0.5),
            SCNAction.fadeOut(duration: 0.5)
        ])
        playerNode.runAction(fallAction)
        
        gameTimer?.invalidate()
        gameTimer = nil
        
        print("u died loser lol! Hit \(obstacleHitCount) obstacles!")
    }

    func restartGame() {
        cleanupGame()
        
        // reset
        playerDead = false
        currentLane = 1
        lastUpdateTime = 0
        trackNodes.removeAll()
        
        //restart
        setupGame()
    }
    
    func navigateToHome() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: ContentView())
            window.makeKeyAndVisible()
        }
    }
}

// extensions convert uimimage to cvpixelbuffer
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
