//
//  MenuScene.swift
//  Snakey
//
//  Created by Ryan Sabouri on 1/25/25.
//

import Foundation
import SpriteKit

class MenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)
        createMenu()
    }
    
    private func createMenu() {
        let titleLabel = SKLabelNode(fontNamed: "Avenir-Black")
        titleLabel.text = "SNAKE GAME"
        titleLabel.fontSize = 48
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        addChild(titleLabel)
        
        let difficulties = [
            ("Easy", 0.2),
            ("Medium", 0.1),
            ("Hard", 0.05)
        ]
        
        for (index, (name, speed)) in difficulties.enumerated() {
            let button = SKLabelNode(fontNamed: "Avenir-Black")
            button.text = name
            button.fontSize = 36
            button.position = CGPoint(x: size.width/2, y: size.height * 0.5 - CGFloat(index) * 60)
            button.name = name
            addChild(button)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            guard let name = node.name else { continue }
            switch name {
            case "Easy":
                startGame(speed: 0.2)
            case "Medium":
                startGame(speed: 0.1)
            case "Hard":
                startGame(speed: 0.05)
            default:
                break
            }
        }
    }
    
    private func startGame(speed: TimeInterval) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        gameScene.initialGameSpeed = speed
        view?.presentScene(gameScene, transition: .doorsOpenVertical(withDuration: 0.5))
    }
}
