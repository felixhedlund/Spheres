//
//  GameEngine.swift
//  Spheres
//
//  Created by Felix Hedlund on 25/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import Foundation
import SpriteKit

class GameEngine: NSObject{
    var controller: GameViewController
    var scene: GameScene
    var score: Int
    var spheresList = Array<Array<Int>>()
    var game: Bool
    var obstacleReference = SKSpriteNode(imageNamed: "Sphere-black")
    private let concurrentNodesQueue = dispatch_queue_create(
        "com.SphereHunt.gameEngineQueue", DISPATCH_QUEUE_CONCURRENT)
    var obstacleSize: CGSize!
    var halfSize: CGSize!
    var lastContainerNode: ContainerNode!
    var gameTimer: NSTimer!
    var highScore: Int!
    
    init(controller: GameViewController, scene: GameScene) {
        self.controller = controller
        self.scene = scene
        self.game = false
        self.score = 0
        self.highScore = GameState.sharedInstance.highScore
        
        super.init()
        self.initiateObstacleReference()
        for index in 0...100{
            generateSpheresLevel3()
        }
    }
    func startGame(){
        self.game = true
        
        firstCalculatedSpheres()
        
    }
    func pauseGame(){
        gameTimer.invalidate()
        self.scene.pausePieTimer()
        self.scene.pauseGame()
        
        if(GameState.sharedInstance.playedBefore == true){
        
        self.controller.scoreBoard.hidden = false
        self.controller.highScoreLabel.text = "High Score: "
         self.controller.highScoreLabelNumber.text = String(self.highScore)
        self.controller.highScoreLabel.hidden = false
            self.controller.highScoreLabelNumber.hidden = false
            self.controller.questionMark.hidden = false
        
        if(game == false){
            var scoreString = "Current Score: "
            if(score > highScore){
                scoreString = "New High Score: "
                GameState.sharedInstance.highScore = score
                GameState.sharedInstance.saveState()
            }
            self.controller.currentScoreLabel.text = scoreString
            self.controller.currentScoreLabelNumber.text = String(score)
        }else{
            self.controller.currentScoreLabel.text = "Current Score:"
            self.controller.currentScoreLabelNumber.text = String(score)
        }
        self.controller.currentScoreLabel.hidden = false
            self.controller.currentScoreLabelNumber.hidden = false
        }
    }
    func playGame(){
        self.controller.scoreBoard.hidden = true
        self.controller.highScoreLabel.hidden = true
        self.controller.highScoreLabelNumber.hidden = true
        self.controller.currentScoreLabel.hidden = true
        self.controller.currentScoreLabelNumber.hidden = true
        self.controller.questionMark.hidden = true
        if(GameState.sharedInstance.playedBefore == false){
            GameState.sharedInstance.playedBefore = true
            GameState.sharedInstance.saveState()
            self.controller.scoreBoard.image = UIImage(named: "ScoreBoard")
        }
        
        if(self.game == false){
            score = 0
            controller.scoreLabel.text = String(score)
            spheresList = Array<Array<Int>>()
            for index in 0...100{
                generateSpheresLevel3()
            }
            self.highScore = GameState.sharedInstance.highScore
            self.scene.returnToInitialState()
            self.game = true
            firstCalculatedSpheres()
        }else{
            let duration = self.scene.getMoveDuration()
            
            gameTimer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: Selector("addMoreSpheres"), userInfo: nil, repeats: false)
            
            self.scene.setSpeed(1, changeObstacles: false)
            self.scene.startPieTimer()
        }
        
        
        
    }
    
    func nothing(){
        
    }
    
    private func initiateObstacleReference(){
        obstacleReference.alpha = 0
        obstacleReference.xScale = 1.2
        obstacleReference.yScale = 1.2
        obstacleReference.size = CGSize(width: scene.screenSize.maxX/4, height: scene.screenSize.maxX/4)
        
        obstacleSize = CGSize(width: obstacleReference.size.width/1.15, height: obstacleReference.size.height/1.15)
        halfSize = CGSize(width: obstacleReference.size.width/1.75, height: obstacleReference.size.height/1.75)
        
    }
    
    func addMoreSpheres(){
        self.scene.runLastCalculatedSpheres(self.lastContainerNode)
        
        
        dispatch_sync(self.scene.concurrentNodesQueue){
            
            let spheresCopyList = self.spheresList
            let count = spheresCopyList.count
            let maxPlaceInlist = count-1
            var nbrInList = Int(arc4random_uniform(UInt32(maxPlaceInlist)))
            if(nbrInList > count-1 || nbrInList < 0){
                nbrInList = 0
            }
            let spheres = spheresCopyList[nbrInList]
            
            self.lastContainerNode = self.scene.addSpheres(self.getSphereFromNumber(spheres[0]), middleLeftSphere: self.getSphereFromNumber(spheres[1]), middleRightSphere: self.getSphereFromNumber(spheres[2]), rightSphere: self.getSphereFromNumber(spheres[3]))
        }
        
        var duration: NSTimeInterval!
        switch(self.scene.screenHeight){
            case 480.0:
                duration = (self.scene.moveDuration/2)*1.28
            case 568.0:
                duration = (self.scene.moveDuration/2)*1.15
            case 960:0
                duration = (self.scene.moveDuration/2)*0.56
            case 1104.0:
                duration = (self.scene.moveDuration/2)*0.35
            default:
                duration = self.scene.moveDuration/2
        }
        gameTimer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: Selector("addMoreSpheres"), userInfo: nil, repeats: false)
    }
    
    
    private func firstCalculatedSpheres(){
        let spheresCopyList = spheresList
        let count = spheresCopyList.count
        let maxPlaceInlist = count-1
        var nbrInList = Int(arc4random_uniform(UInt32(maxPlaceInlist)))
        if(nbrInList > count-1 || nbrInList < 0){
            nbrInList = 0
        }
        let spheres = spheresCopyList[nbrInList]
        
        lastContainerNode = self.scene.addSpheres(self.getSphereFromNumber(spheres[0]), middleLeftSphere: self.getSphereFromNumber(spheres[1]), middleRightSphere: self.getSphereFromNumber(spheres[2]), rightSphere: self.getSphereFromNumber(spheres[3]))
        
        addMoreSpheres()
    }
    
    private func getSphereFromNumber(number: Int) -> Sphere{
        
        
        //0 = empty
        //1 = obstacle
        //2 = gold
        //3 = fire
        //4 = ice
        
        switch number{
        case 0:
            return Sphere(fileName: "", size: halfSize, isObstacle: false, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale)
        case 1:
            var size: CGSize!
            if(self.scene.invincibleMode!){
                size = halfSize
            }else{
                size = obstacleSize
            }
            return Sphere(fileName: "Sphere-black", size: size, isObstacle: true, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale, texture: self.scene.obstacleTexture)
        case 2:
            return Sphere(fileName: "Sphere-yellow", size: halfSize, isObstacle: false, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale)
        case 3:
            return Sphere(fileName: "Sphere-red", size: halfSize, isObstacle: false, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale)
        case 4:
            return Sphere(fileName: "Sphere-blue", size: halfSize, isObstacle: false, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale)
        default:
            break;
        }
        return Sphere(fileName: "", size: halfSize, isObstacle: false, alpha: obstacleReference.alpha, xScale: obstacleReference.xScale, yScale: obstacleReference.yScale)
    }
    
    func generateSpheresLevel3(){
        var nbrObstacles = Int(arc4random_uniform(4))
        var nbrSpheres = Int(arc4random_uniform(3))
        if(nbrObstacles + nbrSpheres > 4){
            let choose = Int(arc4random_uniform(2))
            switch choose{
            case 0:
                nbrObstacles--
            case 1:
                nbrSpheres--
            default:
                nbrObstacles--
            }
        }
        
        var line = [0:0,1:0,2:0,3:0]
        var index = 0
        while(index <= nbrObstacles){
            if(index > 0){
                let positionValue = self.findPositionInLineRecursive(line, startPosition: 0, placed: false, sphere: false)
                let pos = Int(positionValue.keys.first!)
                line[pos] = positionValue[pos]
            }
            index++
        }
        
        while(index <= nbrSpheres){
            if(index > 0){
                let positionValue = self.findPositionInLineRecursive(line, startPosition: 0, placed: false, sphere: true)
                let pos = positionValue.keys.first
                line[pos!] = positionValue[pos!]
            }
            index++
        }
        spheresList.append([line[0]!,line[1]!,line[2]!,line[3]!])
        
    }
    func findPositionInLineRecursive(line: Dictionary<Int,Int>, startPosition: Int, placed: Bool, sphere: Bool) -> Dictionary<Int,Int>{
        var lineTemp = line;
        if(placed){
            return [startPosition: lineTemp[startPosition]!]
        }else{
            //let pos = Int(arc4random_uniform(UInt32(line.count)))
            var placedTemp = false
            var positions = lineTemp.keys.array
            var startPositionTemp = startPosition
            
            let rand = Int(arc4random_uniform(UInt32(positions.count)))
            let pos = positions[rand]
            
            if(line[pos] != 0){
                lineTemp.removeValueForKey(pos)
            }else{
                if(sphere == false){
                    lineTemp.updateValue(1, forKey: pos)
                }else{
                    let sphereValue = 2 + Int(arc4random_uniform(3))
                    lineTemp.updateValue(sphereValue, forKey: pos)
                }
                placedTemp = true
                startPositionTemp = pos
            }
            
            return self.findPositionInLineRecursive(lineTemp, startPosition: startPositionTemp, placed: placedTemp, sphere: sphere)
        }
    }
    func increaseScore(){
        score++
        if(self.scene.avatar.hasYellow){
            score++
        }
        let scoreCopy = score
        controller.scoreLabel.text = String(format: "%ld", scoreCopy)
        let pointLevelList = [5,10,20,40,60,80,100,120,200,300,400,500]
        
        for point: Int in pointLevelList{
            if((scoreCopy == point) || (self.scene.avatar.hasYellow && (scoreCopy == point + 1))){
                scene.setSpeed(1-self.scene.durationIncreasage, changeObstacles: false)
                self.scene.durationIncreasage =  self.scene.durationIncreasage - self.scene.durationIncreasage/13
            }
        }
    }
}