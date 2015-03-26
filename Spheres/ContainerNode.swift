//
//  ContainerNode.swift
//  Spheres
//
//  Created by Felix Hedlund on 26/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import Foundation
import SpriteKit

class ContainerNode: SKNode{
    var pointCollected: Bool!
    
    override init(){
        pointCollected = false
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}