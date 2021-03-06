//
//  GameScene.swift
//  Spheres
//
//  Created by Felix Hedlund on 26/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import SpriteKit
import AVFoundation

struct PhysicsCategory {
    //0 = empty
    //1 = obstacle
    //2 = yellow
    //3 = red
    //4 = blue
    static let Empty      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Barrier   : UInt32 = 0b1   // 1
    static let Yellow: UInt32 = 0b10      // 2
    static let Red: UInt32 = 0b11         // 3
    static let Blue: UInt32 = 0b100       // 4
    static let Avatar: UInt32 = 0b101     // 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var controller: GameViewController!
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    var spheresLayer: SKNode!
    var xPositions: Array<CGFloat>!
    var avatar: Avatar!
    var avatarPositions: Array<CGPoint>!
    var avatarSizeReference: CGSize!
    var obstaclePositions: Array<CGPoint>!
    var durationPercentage: NSTimeInterval!
    var durationPercentageWithPowerups: NSTimeInterval!
    var moveDuration: NSTimeInterval!
    var durationPercentageTemporaryFast: NSTimeInterval!
    var durationPercentageTemporarySlow: NSTimeInterval!
    var durationIncreasage: NSTimeInterval!
    let concurrentNodesQueue = dispatch_queue_create(
        "com.SphereHunt.allActiveNodesQueue", DISPATCH_QUEUE_CONCURRENT)
    var obstacleTexture: SKTexture
    var audioPlayer1: AVAudioPlayer!
    var audioPlayer2: AVAudioPlayer!
    var timerCount: NSTimeInterval!
    var musicTimer: NSTimer!
    var pieTimer: NSTimer!
    var pieTimerSeconds: NSTimer!
    var calculatedContainerNode: ContainerNode!
    var invincibleMode: Bool!
//    var start:CGPoint?
    var startTime:NSTimeInterval?
    
    init(view: SKView, size: CGSize){
        obstacleTexture = SKTexture(imageNamed: "Sphere-black")
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = UIColor(patternImage: UIImage(named: "Background")!)
        initScreenSizes()
        initXPositions()
        invincibleMode = false
        makeBackground()
        //drawLines()
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        spheresLayer = SKNode()
        self.addChild(spheresLayer)
        durationPercentage = 0.53
        durationPercentageWithPowerups = durationPercentage
        durationIncreasage = 0.13
        initiateAvatar()
        initiateObstaclePositions()
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "respondToSwipeGesture:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        view.addGestureRecognizer(swipeLeft)
        let point = convertPoint(avatar.position, fromNode: avatar)
        let yPoint = point.y * 2
        self.moveDuration = calculateDurationFromPoints(yPoint, pos: obstaclePositions![0].y)
        self.durationPercentageTemporaryFast = 0
        self.durationPercentageTemporarySlow = 0
        self.timerCount = 0
        
        self.setupAudioSession()
        let music = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("background", ofType: "wav")!)
        do{
        audioPlayer1 = try AVAudioPlayer(contentsOfURL: music, fileTypeHint: "wav")
        audioPlayer2 = try AVAudioPlayer(contentsOfURL: music, fileTypeHint: "wav")
        }catch{
            print("Could not play music")
        }
        self.playBackgroundMusic()
    }
    func setupAudioSession(){
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setActive(true)
        }catch{
            print("Could not set audiosession active")
        }
        do{
        try audioSession.setCategory(AVAudioSessionCategoryAmbient, withOptions:AVAudioSessionCategoryOptions.MixWithOthers)
        }catch{
            print("Could not set the audio session")
        }
        do{
            try audioSession.setActive(true)
        }catch{
            print("Could not set audiosession active")
        }
    }
    
    func makeBackground() {
        
        let backgroundTexture = SKTexture(imageNamed: "Background2")
        
        for var i:CGFloat = 0; i<3; i++ {
            
            var pos = CGRectGetMidY(self.frame) + (screenHeight * i)
            let destination = -CGRectGetMaxY(self.frame) - screenHeight/2
            
            //defining background; giving it height and moving width
            let background = SKSpriteNode()
            background.position = CGPoint(x: CGRectGetMidX(self.frame), y: pos)
            background.size = CGSize(width: self.screenSize.size.width, height: self.screenSize.size.height + (self.screenSize.size.height/15)*2)
            
            
            let distance = fabs(destination - pos)
            var duration = 0.030
            duration = (duration*NSTimeInterval(distance))
            
            //move background top to bottom; replace
            var shiftBackground = SKAction.moveToY(destination, duration: duration)
            let replaceBackground = SKAction.moveToY(CGRectGetMidY(self.frame) + screenHeight*2, duration: 0)
            
            var movingAndReplacingBackground: SKAction!
            background.texture = backgroundTexture
            if((i == 0) || (i==1)){
                movingAndReplacingBackground = SKAction.sequence([shiftBackground,replaceBackground])
                background.runAction(movingAndReplacingBackground, completion: {
                    pos = CGRectGetMidY(self.frame) + self.screenHeight*2
                    let distance = fabs(destination - pos)
                    duration = 0.030
                    duration = (duration*NSTimeInterval(distance))
                    shiftBackground = SKAction.moveToY(destination, duration: duration)
                    movingAndReplacingBackground = SKAction.repeatActionForever(SKAction.sequence([shiftBackground,replaceBackground]))
                    background.runAction(movingAndReplacingBackground)})
            }else{
                
                movingAndReplacingBackground = SKAction.repeatActionForever(SKAction.sequence([shiftBackground,replaceBackground]))
                background.runAction(movingAndReplacingBackground)
            }
            self.addChild(background)
        }
    }
    
    func addLoopingBackgroundImage(background: SKSpriteNode, backgroundTexture: SKTexture){
        let pos = CGRectGetMidY(self.frame) + screenHeight
        let destination = -CGRectGetMaxY(self.frame) - screenHeight/2
        
        //defining background; giving it height and moving width
        background.position = CGPoint(x: CGRectGetMidX(self.frame), y: pos)
        background.size = self.screenSize.size
        let distance = fabs(destination - pos)
        var duration = 0.008
        duration = (duration*NSTimeInterval(distance))
        background.texture = backgroundTexture
        //move background top to bottom; replace
        let shiftBackground = SKAction.moveToY(destination, duration: duration)
        let replaceBackground = SKAction.moveToY(CGRectGetMidY(self.frame) + screenHeight, duration: 0)
        
        let movingAndReplacingBackground = SKAction.repeatActionForever(SKAction.sequence([shiftBackground,replaceBackground]))
        background.runAction(movingAndReplacingBackground)
        self.addChild(background)
    }
    
    func returnToInitialState(){
        self.spheresLayer.removeAllChildren()
        self.controller.pie.hidden = true
        self.controller.scoreLabel.textColor = UIColor.blackColor()
        self.controller.pieLabel.hidden = true
        initiateAvatar()
        durationPercentage = 0.55
        durationPercentageWithPowerups = durationPercentage
        durationIncreasage = 0.13
        self.durationPercentageTemporaryFast = 0
        self.durationPercentageTemporarySlow = 0
        
        let point = convertPoint(avatar.position, fromNode: avatar)
        let yPoint = point.y * 2
        self.moveDuration = calculateDurationFromPoints(yPoint, pos: obstaclePositions![0].y)
        self.timerCount = 0
        startTime = nil
        self.userInteractionEnabled = true
        
    }
    func playBackgroundMusic(){
        let music = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("background", ofType: "wav")!)
        if(audioPlayer1.playing){
            do{
                try audioPlayer2 = AVAudioPlayer(contentsOfURL: music)
            }catch{
                print("Could not play music")
            }
            audioPlayer2.prepareToPlay()
            audioPlayer2.play()
        }else{
            do{
                try audioPlayer1 = AVAudioPlayer(contentsOfURL: music)
            }catch{
                print("Could not play music")
            }
            audioPlayer1.prepareToPlay()
            audioPlayer1.play()
        }
        self.musicTimer = NSTimer.scheduledTimerWithTimeInterval(18.4, target: self, selector: Selector("playBackgroundMusic"), userInfo: nil, repeats: false)
    }
    func stopMusic(){
        self.musicTimer.invalidate()
        self.audioPlayer1.stop()
        self.audioPlayer2.stop()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func runLastCalculatedSpheres(containerNode: ContainerNode){
        containerNode.hidden = false
        self.runPastAvatar(containerNode)
        
    }
    
    func addSpheres(leftSphere: Sphere, middleLeftSphere: Sphere, middleRightSphere: Sphere, rightSphere: Sphere) -> ContainerNode{
        //0 = empty
        //1 = obstacle
        //2 = gold
        //3 = fire
        //4 = ice
        
        //Gör en del av denna uträkning i förväg???
        let containerNode = ContainerNode();
        self.spheresLayer.addChild(containerNode)
        
        var sphere: Sphere!
        for index in 0...3{
            switch index{
            case 0:
                sphere = leftSphere
            case 1:
                sphere = middleLeftSphere
            case 2:
                sphere = middleRightSphere
            case 3:
                sphere = rightSphere
            default:
                break;
            }
            
            sphere.position = obstaclePositions![index] as CGPoint
            
            if(sphere.name != ""){
                sphere.physicsBody = SKPhysicsBody(circleOfRadius: sphere.size.width/2.2) // 1
            }else{
                sphere.physicsBody = SKPhysicsBody(circleOfRadius: avatar.size.width/2.2) // 1
            }
            sphere.physicsBody?.dynamic = true // 2
            
            //println(String(index) + " " + tuple.name)
            let name = sphere.name! as String
            switch name{
            case "Sphere-black":
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Barrier // 3
            case "Sphere-yellow":
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Yellow
            case "Sphere-red":
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Red
            case "Sphere-blue":
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Blue
            case "":
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Empty
            default:
                print("tuple does not have a name")
            }
            
            sphere.physicsBody?.contactTestBitMask = PhysicsCategory.Avatar // 4
            sphere.physicsBody?.collisionBitMask = PhysicsCategory.Empty // 5
            
            
            containerNode.addChild(sphere)
            sphere.runAction(SKAction.group([SKAction.fadeInWithDuration(0),
                SKAction.scaleTo(1.0, duration: 0.25)]))
            containerNode.hidden = true
            
        }
        return containerNode
        
    }
    func runPastAvatar(node: SKNode){
        
        //println(node.position.y)
        let point = convertPoint(avatar.position, fromNode: avatar)
        
        let yPoint = point.y * 2
        
        self.moveDuration = calculateDurationFromPoints(yPoint, pos: node.position.y)
        let moveDurationCopy = self.moveDuration
        
        node.runAction(SKAction.moveToY(yPoint, duration: moveDurationCopy), completion: {
            self.removeLastNode(node)})
        
    }
    private func initiateAvatar(){
        avatarSizeReference = CGSize(width: screenSize.maxX/6, height: screenSize.maxX/6)
        avatar = Avatar(fileName: "Avatar-white", size: avatarSizeReference, alpha: 0, xScale: 1.1, yScale: 1.1)
        
        addAvatarPositions()
        addAvatarToScreen()
        
        avatar.physicsBody = SKPhysicsBody(rectangleOfSize: avatar.size) // 1
        avatar.physicsBody?.dynamic = true // 2
        avatar.physicsBody?.categoryBitMask = PhysicsCategory.Avatar // 3
        //avatar.physicsBody?.contactTestBitMask = PhysicsCategory.Avatar // 4
        avatar.physicsBody?.collisionBitMask = PhysicsCategory.Empty // 5
    }
    private func addAvatarPositions(){
        let yPosition = -screenSize.maxY/2 + avatar.size.height*2
        let position1 = CGPointMake(xPositions![0] as CGFloat, yPosition)
        let position2 = CGPointMake(xPositions![1] as CGFloat, yPosition)
        let position3 = CGPointMake(xPositions![2] as CGFloat, yPosition)
        let position4 = CGPointMake(xPositions![3] as CGFloat, yPosition)
        self.avatarPositions = [position1, position2, position3, position4]
        
    }
    private func addAvatarToScreen() {
        avatar.position = avatarPositions![2] as CGPoint
        
        //CGPointMake(screenSize.minX + screenSize.maxX/8, -screenSize.maxY/2 + avatar.size.height/2)
        
        self.addChild(avatar)
        
        avatar.runAction(
            SKAction.sequence([
                SKAction.waitForDuration(0.25, withRange: 0.5),
                SKAction.group([
                    SKAction.fadeInWithDuration(0.25),
                    SKAction.scaleTo(1.0, duration: 0.25)
                    ])
                ]))
        
    }
    private func drawLines(){
        let line1 = SKShapeNode()
        let path1 = CGPathCreateMutable()
        
        let xPoint1 = (screenSize.maxX/4)
        CGPathMoveToPoint(path1, nil, xPoint1, -screenSize.maxY)
        CGPathAddLineToPoint(path1, nil, xPoint1,screenSize.maxY)
        
        line1.path = path1
        line1.strokeColor = UIColor.lightGrayColor()
        line1.lineWidth = 3.0
        self.addChild(line1)
        
        let line2 = SKShapeNode()
        let path2 = CGPathCreateMutable()
        let xPoint2 = (-screenSize.maxX/4)
        CGPathMoveToPoint(path2, nil, xPoint2, -screenSize.maxY)
        CGPathAddLineToPoint(path2, nil, xPoint2,screenSize.maxY)
        
        line2.path = path2
        line2.strokeColor = UIColor.lightGrayColor()
        line2.lineWidth = 3.0
        self.addChild(line2)
        
        let line3 = SKShapeNode()
        let path3 = CGPathCreateMutable()
        let xPoint3 = (screenSize.minX)
        CGPathMoveToPoint(path3, nil, xPoint3, -screenSize.maxY)
        CGPathAddLineToPoint(path3, nil, xPoint3,screenSize.maxY)
        
        line3.path = path3
        line3.strokeColor = UIColor.lightGrayColor()
        line3.lineWidth = 3.0
        self.addChild(line3)
        
    }
    private func initXPositions(){
        let xPosition1 = -screenSize.maxX/2 + screenSize.maxX/8
        let xPosition2 = screenSize.minX - screenSize.maxX/8
        let xPosition3 = screenSize.minX + screenSize.maxX/8
        let xPosition4 = screenSize.maxX/2 - screenSize.maxX/8
        self.xPositions = [xPosition1, xPosition2, xPosition3, xPosition4]
    }
    
    func initiateObstaclePositions(){
        let yPosition = screenSize.maxY/2
        let position1 = CGPointMake(xPositions![0] as CGFloat, yPosition)
        let position2 = CGPointMake(xPositions![1] as CGFloat, yPosition)
        let position3 = CGPointMake(xPositions![2] as CGFloat, yPosition)
        let position4 = CGPointMake(xPositions![3] as CGFloat, yPosition)
        self.obstaclePositions = [position1, position2, position3, position4]
    }
    
    private func initScreenSizes(){
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = self.screenSize.width;
        screenHeight = self.screenSize.height;
    }
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if(!self.controller.isPaused){
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                let elapsedTime = CACurrentMediaTime() - startTime!
                if(elapsedTime > 0.3){
                    //do nothing
                }else{
                switch swipeGesture.direction {
                case UISwipeGestureRecognizerDirection.Right:
                    tryMoveAvatarRight(elapsedTime);
                case UISwipeGestureRecognizerDirection.Left:
                    tryMoveAvatarLeft(elapsedTime);
                default:
                    break
                    }}
            }}
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if(touches.count > 1){
            return;
        }
        if let _:UITouch = touches.first{
//            let location:CGPoint = touch.locationInView(self.view!)
//            start = location
            startTime = CACurrentMediaTime()
            //println(startTime)
        }
    }
    
    
    
    func tryMoveAvatarRight(elapsedTime: NSTimeInterval){
        
        
        let avatarPosition = avatar.position.x
        var newPosition: CGPoint?
        for index in 0...3{
            let xReference = avatarPositions![index].x as CGFloat
            if(xReference > 0){
                if(avatarPosition <= xReference*1.3 && avatarPosition >= xReference*0.7){
                    if(index != 3){
                        newPosition = avatarPositions![index+1] as CGPoint
                    }
                }
            }else{
                if(avatarPosition >= xReference*1.3 && avatarPosition <= xReference*0.7){
                    if(index != 3){
                        newPosition = avatarPositions![index+1] as CGPoint
                    }
                }
            }
        }
        if(newPosition != nil){
            moveAvatar(newPosition!, elapsedTime: elapsedTime)
        }
    }
    func tryMoveAvatarLeft(elapsedTime: NSTimeInterval){
        let avatarPosition = avatar.position.x
        var newPosition: CGPoint?
        var index = 0
        var indexReal = 3
        while( index < 3){
            let xReference = avatarPositions![indexReal].x as CGFloat
            if(xReference > 0){
                if(avatarPosition <= xReference*1.3 && avatarPosition >= xReference*0.7){
                    newPosition = avatarPositions![indexReal-1] as CGPoint
                }
            }else{
                if(avatarPosition >= xReference*1.3 && avatarPosition <= xReference*0.7){
                    newPosition = avatarPositions![indexReal-1] as CGPoint
                }
            }
            indexReal--
            index++
        }
        if(newPosition != nil){
            moveAvatar(newPosition!, elapsedTime: elapsedTime)
        }
    }
    func moveAvatar(position: CGPoint, elapsedTime: NSTimeInterval){
//        let Duration: NSTimeInterval = 0.20
//            * durationPercentageWithPowerups
        
        let moveA = SKAction.moveTo(position, duration: elapsedTime * 1.45)
        moveA.timingMode = .EaseOut
        avatar.runAction(moveA)
    }
    func calculateDurationFromPoints(destination: CGFloat, pos: CGFloat) -> NSTimeInterval{
        let distance = fabs(destination - pos)
        let duration = 0.008
        return (duration*NSTimeInterval(distance))*durationPercentageWithPowerups
    }
    
    func setSpeed(speedPercentage: NSTimeInterval, changeObstacles: Bool){
        durationPercentage = durationPercentage * speedPercentage
        durationPercentageWithPowerups = durationPercentage + durationPercentageTemporaryFast + durationPercentageTemporarySlow
        dispatch_barrier_sync(self.concurrentNodesQueue){
            let allActiveNodes = self.spheresLayer.children
            let count = allActiveNodes.count
            
            for index in 0...count-1{
                let node = allActiveNodes[index] as! ContainerNode
                node.removeAllActions()
                if(changeObstacles){
                    let row = node.children
                    for rowIndex in 0...row.count-1{
                        let sphere = row[rowIndex] as! Sphere
                        if(sphere.isObstacle){
                            sphere.texture = self.obstacleTexture
                            var newSize: CGSize!
                            if(self.invincibleMode!){
                                newSize = self.controller.gameEngine.halfSize
                            }else{
                                newSize = self.controller.gameEngine.obstacleSize
                                
                            }
                            sphere.runAction(SKAction.resizeToWidth(newSize.width, height: newSize.height, duration: 0.5))
                        }
                    }
                }
                if(node.hidden == false){
                    self.runPastAvatar(node)
                }
            }
        }
    }
    func getMoveDuration() -> NSTimeInterval{
        if(self.controller.gameEngine.game == true){
            let allActiveNodes = self.spheresLayer.children
            let count = allActiveNodes.count
            
            let node2 = allActiveNodes[count-2] as! ContainerNode
            var node = allActiveNodes[count-1] as! ContainerNode
            
            if(node.hidden == true){
                node = node2
            }
            
            let point = convertPoint(avatar.position, fromNode: avatar)
            let yPoint = point.y * 2
            
            
            let duration = calculateDurationFromPoints(yPoint, pos: node.position.y)
            
            return self.moveDuration/2 - (self.moveDuration - duration)
        }else{
            return self.moveDuration/2
        }
    }
    
    func pauseGame(){
        dispatch_barrier_sync(self.concurrentNodesQueue){
            let allActiveNodes = self.spheresLayer.children
            let count = allActiveNodes.count
            
            for index in 0...count-1{
                let node = allActiveNodes[index] as! ContainerNode
                node.removeAllActions()
            }
        }
    }
    
    func removeLastNode(node: SKNode){
        node.removeFromParent()
        
    }
    func sphereDidCollideWithAvatar(sphere:SKSpriteNode, avatar:SKSpriteNode) {
        if(avatar.physicsBody!.categoryBitMask == PhysicsCategory.Avatar){
            if(sphere.physicsBody!.categoryBitMask != PhysicsCategory.Barrier){
                let containerNode = sphere.parent as! ContainerNode
                if(containerNode.pointCollected == false){
                    containerNode.pointCollected = true
                    self.controller.gameEngine.increaseScore()
                }
            }
            var pickedUpSphere = false
            switch sphere.physicsBody!.categoryBitMask {
            case PhysicsCategory.Empty:
                sphere.removeFromParent()
            case PhysicsCategory.Red:
                pickedUpSphere = true
                self.avatarAddColor(sphere)
            case PhysicsCategory.Yellow:
                pickedUpSphere = true
                self.avatarAddColor(sphere)
            case PhysicsCategory.Blue:
                pickedUpSphere = true
                self.avatarAddColor(sphere)
            case PhysicsCategory.Barrier:
                if(!(self.avatar.hasYellow && self.avatar.hasRed && self.avatar.hasBlue)){
                    self.controller.showGameOver()
                    //println("End Game")
                }else{
                    pickedUpSphere = true
                    sphere.runAction(SKAction.fadeOutWithDuration(0.10))
                    //Double point if barrier is absorbed
                    self.controller.gameEngine.increaseScore()
                    self.controller.gameEngine.increaseScore()
                }
            default: print("PhysicsBody does not have a categoryBitMask")
            }
            if(pickedUpSphere){
                sphere.physicsBody?.categoryBitMask = PhysicsCategory.Empty
                let sequence = SKAction.sequence([SKAction.resizeToWidth(avatarSizeReference.width*1.3, height: avatarSizeReference.height*1.3, duration: 0.15),
                SKAction.resizeToWidth(avatarSizeReference.width, height: avatarSizeReference.height, duration: 0.15),
                    SKAction.resizeToWidth(avatarSizeReference.width*1.15, height: avatarSizeReference.height*1.15, duration: 0.15),
                    SKAction.resizeToWidth(avatarSizeReference.width, height: avatarSizeReference.height, duration: 0.15)])
                avatar.runAction(sequence)
                
                if(self.avatar.hasBlue && self.avatar.hasRed && self.avatar.hasYellow){
                    let music = SKAction.playSoundFileNamed("sphere_all.wav", waitForCompletion: false)
                    self.runAction(music)
                }else{
                    let music = SKAction.playSoundFileNamed("sphere.wav", waitForCompletion: false)
                    self.runAction(music)
                    
                }}
        }
        
    }
    func avatarAddColor(sphere:SKSpriteNode){
        sphere.runAction(SKAction.fadeOutWithDuration(0.10))
        var newTexture: SKTexture!
        var changeAllObstacles = false
        self.controller.pie.hidden = false
        switch sphere.name!{
        case "Sphere-yellow":
            if(avatar.hasRed == false && avatar.hasBlue == false && avatar.hasYellow == false){
                self.controller.pie.image = UIImage(named: "Pie-yellow")
                newTexture = SKTexture(imageNamed: "Avatar-yellow")
            }else if(avatar.hasRed == true && avatar.hasBlue == false && avatar.hasYellow == false){
                self.controller.pie.image = UIImage(named: "Pie-orange")
                newTexture = SKTexture(imageNamed: "Avatar-orange")
            }else if(avatar.hasRed == false && avatar.hasBlue == true && avatar.hasYellow == false){
                self.controller.pie.image = UIImage(named: "Pie-green")
                newTexture = SKTexture(imageNamed: "Avatar-green")
            }else if(avatar.hasYellow == true){
                if(avatar.hasBlue || avatar.hasRed){
                    let music = SKAction.playSoundFileNamed("no_more_invincible.wav", waitForCompletion: false)
                    self.runAction(music)
                }
                avatar.hasBlue = false
                avatar.hasRed = false
                self.durationPercentageTemporarySlow = 0
                self.durationPercentageTemporaryFast = 0
                    self.controller.pie.image = UIImage(named: "Pie-yellow")
                    newTexture = SKTexture(imageNamed: "Avatar-yellow")
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-black")
                    self.invincibleMode = false
                }else if(avatar.hasRed == true && avatar.hasBlue == true && avatar.hasYellow == false){
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-white")
                    self.controller.pie.image = UIImage(named: "Pie-colors")
                    newTexture = SKTexture(imageNamed: "Avatar-colors")
                    invincibleMode = true
                }
                self.controller.scoreLabel.textColor = UIColor.yellowColor()
                avatar.hasYellow = true
                setSpeed(1, changeObstacles: changeAllObstacles)
            case "Sphere-blue":
                if(avatar.hasRed == false && avatar.hasBlue == false && avatar.hasYellow == false){
                    self.controller.pie.image = UIImage(named: "Pie-blue")
                    newTexture = SKTexture(imageNamed: "Avatar-blue")
                }else if(avatar.hasRed == true && avatar.hasBlue == false && avatar.hasYellow == false){
                    self.controller.pie.image = UIImage(named: "Pie-purple")
                    newTexture = SKTexture(imageNamed: "Avatar-purple")
                }else if(avatar.hasRed == false && avatar.hasBlue == false && avatar.hasYellow == true){
                    self.controller.pie.image = UIImage(named: "Pie-green")
                    newTexture = SKTexture(imageNamed: "Avatar-green")
                }else if(avatar.hasBlue == true){
                    if(avatar.hasRed || avatar.hasYellow){
                        let music = SKAction.playSoundFileNamed("no_more_invincible.wav", waitForCompletion: false)
                        self.runAction(music)
                    }
                    avatar.hasYellow = false
                    avatar.hasRed = false
                    self.durationPercentageTemporaryFast = 0
                    self.controller.scoreLabel.textColor = UIColor.blackColor()
                    self.controller.pie.image = UIImage(named: "Pie-blue")
                    newTexture = SKTexture(imageNamed: "Avatar-blue")
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-black")
                    self.invincibleMode = false
                }else if(avatar.hasRed == true && avatar.hasBlue == false && avatar.hasYellow == true){
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-white")
                    self.controller.pie.image = UIImage(named: "Pie-colors")
                    newTexture = SKTexture(imageNamed: "Avatar-colors")
                    invincibleMode = true
                }
                avatar.hasBlue = true
                self.durationPercentageTemporarySlow = durationIncreasage
                setSpeed(1, changeObstacles: changeAllObstacles)
            case "Sphere-red":
                if(avatar.hasRed == false && avatar.hasBlue == false && avatar.hasYellow == false){
                    self.controller.pie.image = UIImage(named: "Pie-red")
                    newTexture = SKTexture(imageNamed: "Avatar-red")
                }else if(avatar.hasRed == false && avatar.hasBlue == true && avatar.hasYellow == false){
                    self.controller.pie.image = UIImage(named: "Pie-purple")
                    newTexture = SKTexture(imageNamed: "Avatar-purple")
                }else if(avatar.hasRed == false && avatar.hasBlue == false && avatar.hasYellow == true){
                    self.controller.pie.image = UIImage(named: "Pie-orange")
                    newTexture = SKTexture(imageNamed: "Avatar-orange")
                }else if(avatar.hasRed == true){
                    if(avatar.hasBlue || avatar.hasYellow){
                        let music = SKAction.playSoundFileNamed("no_more_invincible.wav", waitForCompletion: false)
                        self.runAction(music)
                    }
                    avatar.hasBlue = false
                    avatar.hasYellow = false
                    self.durationPercentageTemporarySlow = 0
                    self.controller.scoreLabel.textColor = UIColor.blackColor()
                    self.controller.pie.image = UIImage(named: "Pie-red")
                    newTexture = SKTexture(imageNamed: "Avatar-red")
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-black")
                    self.invincibleMode = false
                }else if(avatar.hasRed == false && avatar.hasBlue == true && avatar.hasYellow == true){
                    changeAllObstacles = true
                    self.obstacleTexture = SKTexture(imageNamed: "Sphere-white")
                    self.controller.pie.image = UIImage(named: "Pie-colors")
                    newTexture = SKTexture(imageNamed: "Avatar-colors")
                    invincibleMode = true
                }
                avatar.hasRed = true
                self.durationPercentageTemporaryFast = -durationIncreasage
                setSpeed(1, changeObstacles: changeAllObstacles)
            default:
                avatar.hasRed = false
                avatar.hasBlue = false
                avatar.hasYellow = false
                self.controller.pie.hidden = true
                newTexture = SKTexture(imageNamed: "Avatar-white")
            
        }
            self.timerCount = 10
            self.controller.pieLabel.hidden = false
            self.controller.pieLabel.text = String(Int(self.timerCount))
            self.avatar.texture = newTexture
            avatar.timerID++
            self.pieTimerSeconds = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("pieTimer:"), userInfo: avatar.timerID, repeats: true)
            self.pieTimer = NSTimer.scheduledTimerWithTimeInterval(self.timerCount, target: self, selector: Selector("changeAvatarToInitialState:"), userInfo: avatar.timerID, repeats: false)
    }
    func pieTimer(timer: NSTimer){
        let timerID = timer.userInfo as! Int
        if((timerID == avatar.timerID) && self.timerCount > 0){
            self.timerCount = self.timerCount-1
            self.controller.pieLabel.text = String(Int(self.timerCount))
        }else{
            timer.invalidate()
        }
        
    }
    
    func pausePieTimer(){
        if(self.timerCount > 0){
            self.pieTimerSeconds.invalidate()
            self.pieTimer.invalidate()
        }
    }
    func startPieTimer(){
        if(self.timerCount > 0){
            self.pieTimerSeconds = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("pieTimer:"), userInfo: avatar.timerID, repeats: true)
            
            self.pieTimer = NSTimer.scheduledTimerWithTimeInterval(self.timerCount, target: self, selector: Selector("changeAvatarToInitialState:"), userInfo: avatar.timerID, repeats: false)
        }
    }
    
    func changeAvatarToInitialState(timer: NSTimer){
        let timerID = timer.userInfo as! Int
        if(timerID == avatar.timerID){
            var changeAllObstacles = false
            if(avatar.hasRed == true && avatar.hasBlue == true && avatar.hasYellow == true){
                obstacleTexture = SKTexture(imageNamed: "Sphere-black")
                changeAllObstacles = true
                invincibleMode = false
            }
            self.controller.pieLabel.hidden = true
            avatar.hasRed = false
            avatar.hasYellow = false
            avatar.hasBlue = false
            durationPercentageTemporaryFast = 0
            durationPercentageTemporarySlow = 0
            self.controller.scoreLabel.textColor = UIColor.blackColor()
            setSpeed(1, changeObstacles: changeAllObstacles)
            self.controller.pie.hidden = true
            
            avatar.texture = SKTexture(imageNamed: "Avatar-white")
            
            let sequence = SKAction.sequence([SKAction.resizeToWidth(avatarSizeReference.width*0.6, height: avatarSizeReference.height*0.2, duration: 0.15),
                SKAction.resizeToWidth(avatarSizeReference.width, height: avatarSizeReference.height, duration: 0.15),
                SKAction.resizeToWidth(avatarSizeReference.width*0.55, height: avatarSizeReference.height*0.85, duration: 0.15),
                SKAction.resizeToWidth(avatarSizeReference.width, height: avatarSizeReference.height, duration: 0.15)])
            avatar.runAction(sequence)
            
            let music = SKAction.playSoundFileNamed("no_more_invincible.wav", waitForCompletion: false)
            self.runAction(music)
        }
    }
    func didBeginContact(contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if(firstBody.node?.parent != nil && secondBody.node?.parent != nil){
            sphereDidCollideWithAvatar(firstBody.node as! SKSpriteNode, avatar: secondBody.node as! SKSpriteNode)
        }
    }
    
    func animateGameOver(completion: () -> ()) {
        let music = SKAction.playSoundFileNamed("obstacle.wav", waitForCompletion: false)
        self.runAction(music)
        let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        avatar.runAction(action, completion: completion)
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
