//
//  Sphere.swift
//  Spheres
//
//  Created by Felix Hedlund on 25/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import Foundation
import SpriteKit

class Avatar: SKSpriteNode{
    var hasBlue: Bool
    var hasYellow: Bool
    var hasRed: Bool
    var timerID: Int
    
    init(fileName: String, size: CGSize, alpha: CGFloat, xScale: CGFloat, yScale: CGFloat) {
        self.hasBlue = false
        self.hasYellow = false
        self.hasRed = false
        self.timerID = 0
        let texture = SKTexture(imageNamed: fileName)
        super.init(texture: texture, color: UIColor.whiteColor(), size: size)
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
    
    func hasColor() -> Bool{
        if(hasBlue == true || hasYellow == true || hasRed == true){
            return true
        }
        return false
    }
    
}