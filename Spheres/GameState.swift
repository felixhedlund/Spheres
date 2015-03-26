//
//  GameState.swift
//  Spheres
//
//  Created by Felix Hedlund on 24/03/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import Foundation

class GameState {
    var highScore: Int
    
    class var sharedInstance: GameState {
        struct Singleton {
            static let instance = GameState()
        }
        
        return Singleton.instance
    }
    
    init() {
        // Init
        highScore = 0
        
        // Load game state
        let defaults = NSUserDefaults.standardUserDefaults()
        
        highScore = defaults.integerForKey("highScore")
    }
    
    func saveState() {
        // Store in user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(highScore, forKey: "highScore")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}