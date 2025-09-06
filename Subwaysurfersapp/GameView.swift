//
//  GameView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 23/8/25.
//

import SwiftUI
import SceneKit

struct GameView: View {
    @State private var scene: SCNScene? = nil
    @State private var trackNodes: [SCNNode] = []
    @State private var obstacleNodes: [SCNNode] = []

    @State private var currentLane: Int = 0          // 0 = top lane, 1 = bottom lane
    let lanePositions: [Float] = [-1, 1]             // Z positions of the two lanes

    var body: some View {
        SceneView(
            scene: scene ?? SCNScene(),
            pointOfView: makeCamera(),
            options: [.autoenablesDefaultLighting]
        )
        .ignoresSafeArea()
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < 0 { movePlayer(to: 0) } // swipe
                    else { movePlayer(to: 1) }                            // swipepep
                }
        )
        .onAppear {
            let newScene = makeScene()
            scene = newScene
            startGameLoop()
        }
    }

//scene
    func makeScene() -> SCNScene {
        let scene = SCNScene()
        addLight(to: scene)
        addTrack(to: scene)
        addPlayer(to: scene)
        spawnInitialObstacles(in: scene)
        return scene
    }

    func addLight(to scene: SCNScene) {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
    }

    func addTrack(to scene: SCNScene) {
        for i in 0..<2 {
            if let trackScene = SCNScene(named: "Straight_Railway_Track.usdz") {
                let trackNode = SCNNode()
                for child in trackScene.rootNode.childNodes { trackNode.addChildNode(child) }
                trackNode.position = SCNVector3(-Float(i * 5), -1, 0)
                trackNode.scale = SCNVector3(0.02, 0.015, 0.015)
                trackNode.eulerAngles = SCNVector3(0, Float.pi/1, 0) // rotate 90degrees to face front! sideways
                scene.rootNode.addChildNode(trackNode)
                trackNodes.append(trackNode)
    
            }
        }
    }

//roblox character boi
    func addPlayer(to scene: SCNScene) {
        guard let playerScene = SCNScene(named: "Roblox-Noob.usdz") else { return }

        let playerNode = SCNNode()
        for child in playerScene.rootNode.childNodes { playerNode.addChildNode(child) }
        playerNode.name = "player"
        playerNode.position = SCNVector3(0, -0.5, lanePositions[currentLane])
        playerNode.scale = SCNVector3(0.008, 0.008, 0.008)
        playerNode.eulerAngles = SCNVector3(0, Float.pi/1, 0) // rotation
        scene.rootNode.addChildNode(playerNode)

        //ass running animation
        let runAction = SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 0.2)
            ])
        )
        playerNode.runAction(runAction)
    }

    func movePlayer(to lane: Int) {
        guard let playerNode = scene?.rootNode.childNode(withName: "player", recursively: true) else { return }
        currentLane = lane
        playerNode.position.z = lanePositions[lane] // snap to lane
    }

    func makeCamera() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(-10, 3, 0)       //thirdperson
        cameraNode.look(at: SCNVector3(0, 0, 0))
        return cameraNode
    }

//red cubes
    func spawnInitialObstacles(in scene: SCNScene) {
        for _ in 0..<5 { spawnObstacle(in: scene) }
    }

    func spawnObstacle(in scene: SCNScene) {
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.red
        let obstacle = SCNNode(geometry: box)
        obstacle.position = SCNVector3(-30, -0.5, lanePositions.randomElement()!)
        scene.rootNode.addChildNode(obstacle)
        obstacleNodes.append(obstacle)
    }

    func startGameLoop() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            updateTrack()
            updateObstacles()
        }
    }

    func updateTrack() {
        for track in trackNodes {
            track.position.x += 0.2
            if track.position.x > 15 { track.position.x -= 30 }
        
        }
    }

    func updateObstacles() {
        for obstacle in obstacleNodes {
            obstacle.position.x += 0.2
            if obstacle.position.x > 10 {
                obstacle.position.x = -30
                obstacle.position.z = lanePositions.randomElement()!
            }
        }
    }
}

#Preview {
    GameView()
}
