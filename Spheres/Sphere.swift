//
//  Sphere.swift
//  Spheres
//
//  Created by Felix Hedlund on 25/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import Foundation
import SpriteKit

class Sphere: SKSpriteNode{
    var isObstacle: Bool
    
    init(fileName: String, size: CGSize, isObstacle: Bool, alpha: CGFloat, xScale: CGFloat, yScale: CGFloat) {
        self.isObstacle = isObstacle
        let texture = SKTexture(imageNamed: fileName)
        super.init(texture: texture, color: UIColor.clearColor(), size: size)
        //super.init(texture: texture, color: UIColor.clearColor(), size: size)
        self.name = fileName
        self.size = size
        self.alpha = alpha
        self.xScale = xScale
        self.yScale = yScale
        if(fileName == ""){
            self.texture = nil
        }
        self.zPosition = 5
    }
    
    init(fileName: String, size: CGSize, isObstacle: Bool, alpha: CGFloat, xScale: CGFloat, yScale: CGFloat, texture: SKTexture) {
        self.isObstacle = isObstacle
        let texture2 = texture
        super.init(texture: texture2, color: UIColor.clearColor(), size: size)
        self.name = fileName
        self.size = size
        self.alpha = alpha
        self.xScale = xScale
        self.yScale = yScale
        if(fileName == ""){
            self.texture = nil
        }
        
        self.zPosition = 5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}