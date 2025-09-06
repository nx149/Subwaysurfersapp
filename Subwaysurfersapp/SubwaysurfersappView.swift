//
//  SubwaysurfersappView.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 30/8/25.
//
import SpriteKit
class Gamescene: SKScene {
    
    var ground = SKSpriteNode()
    
    func didMoveToView(view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y : 0.5)
    }
    
    func update(currentTime: CFTimeInterval) {
        
    }
    func createGrounds() {
        
        for 1 in 0...3 {
            let ground = SKSpriteNode(imageNamed: "G")
            
        }
        
    }
    
}

