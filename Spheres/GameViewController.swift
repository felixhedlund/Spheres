//
//  GameViewController.swift
//  Spheres
//
//  Created by Felix Hedlund on 26/02/2015.
//  Copyright (c) 2015 Felix Hedlund. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController {
    @IBOutlet weak var pauseButton: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var pie: UIImageView!
    @IBOutlet weak var pieLabel: UILabel!
    @IBOutlet weak var musicButton: UIImageView!
    @IBOutlet weak var scoreBoard: UIImageView!
    @IBOutlet weak var questionMark: UIImageView!
    @IBOutlet weak var explanationBoard: UIImageView!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet weak var highScoreLabelNumber: UILabel!
    @IBOutlet weak var currentScoreLabel: UILabel!
    @IBOutlet weak var currentScoreLabelNumber: UILabel!
    var tapGestureRecognizer: UITapGestureRecognizer!
    var gameEngine: GameEngine!
    var scene: GameScene!
    var isMusicOn: Bool!
    var isPaused: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = view as! SKView
        scene = GameScene(view: skView, size: skView.bounds.size)
        scene.controller = self
        // Configure the view.
        //        skView.showsFPS = true
        //        skView.showsNodeCount = true
        skView.multipleTouchEnabled = false
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        pauseButton.image = UIImage(named: "Pause")
        musicButton.image = UIImage(named: "Music-on")
        
        isMusicOn = true
        isPaused = false
        self.musicButton.userInteractionEnabled = true
        self.pauseButton.userInteractionEnabled = true
        self.scoreBoard.userInteractionEnabled = true
        self.questionMark.userInteractionEnabled = true
        
        let recognizer = UITapGestureRecognizer(target: self, action:Selector("tapMusicButton:"));
        recognizer.numberOfTapsRequired = 1;
        musicButton.addGestureRecognizer(recognizer);
        
        let pauseRecognizer = UITapGestureRecognizer(target: self, action:Selector("tapPauseButton:"));
        pauseRecognizer.numberOfTapsRequired = 1;
        pauseButton.addGestureRecognizer(pauseRecognizer)
        
        let pauseRecognizer2 = UITapGestureRecognizer(target: self, action:Selector("tapPauseButton:"));
        pauseRecognizer2.numberOfTapsRequired = 1;
        scoreBoard.addGestureRecognizer(pauseRecognizer2)
        
        let pauseRecognizer4 = UITapGestureRecognizer(target: self, action:Selector("tapQuestionMark:"));
        pauseRecognizer4.numberOfTapsRequired = 1;
        questionMark.addGestureRecognizer(pauseRecognizer4)
        
        scoreBoard.image = UIImage(named: "ScoreBoard")
        questionMark.image = UIImage(named: "Question")
        scoreBoard.hidden = true
        highScoreLabel.hidden = true
        highScoreLabelNumber.hidden = true
        currentScoreLabel.hidden = true
        currentScoreLabelNumber.hidden = true
        questionMark.hidden = true
    
        pie.hidden = true
        pieLabel.hidden = true
        skView.presentScene(scene)
        gameEngine = GameEngine(controller: self, scene: scene)
        gameEngine.startGame()
        
        let playedBefore = GameState.sharedInstance.playedBefore
        if(!playedBefore){
            explanationBoard.image = UIImage(named: "ExplanationBoard")
            explanationBoard.hidden = false
            
            let pauseRecognizer3 = UITapGestureRecognizer(target: self, action:Selector("tapPauseButton:"));
            pauseRecognizer3.numberOfTapsRequired = 1;
            explanationBoard.addGestureRecognizer(pauseRecognizer3)
            
            self.tapPauseButton(self.pauseButton)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    func showGameOver() {
        self.gameEngine.game = false
        //gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        self.tapPauseButton(self.pauseButton)
        scene.animateGameOver()            {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideGameOver")
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    func hideGameOver() {
        //        view.removeGestureRecognizer(tapGestureRecognizer)
        //        tapGestureRecognizer = nil
        
        //gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
    }
    
    func tapQuestionMark(_: AnyObject){
        
            explanationBoard.image = UIImage(named: "ExplanationBoard")
            explanationBoard.hidden = false
            
            let pauseRecognizer3 = UITapGestureRecognizer(target: self, action:Selector("tapPauseButton:"));
            pauseRecognizer3.numberOfTapsRequired = 1;
            explanationBoard.addGestureRecognizer(pauseRecognizer3)

            highScoreLabel.hidden = true
            highScoreLabelNumber.hidden = true
            currentScoreLabel.hidden = true
            currentScoreLabelNumber.hidden = true
            questionMark.hidden = true
            GameState.sharedInstance.playedBefore = false
        
    }
    
    func tapPauseButton(_: AnyObject){
        if(isPaused == false){
            self.pauseButton.image = UIImage(named: "Play")
            isPaused = true
            self.gameEngine.pauseGame()
            
        }else{
            self.pauseButton.image = UIImage(named: "Pause")
            isPaused = false
            self.gameEngine.playGame()
        }
    }
    
    func tapMusicButton(_: AnyObject) {
        if(isMusicOn == true){
            self.musicButton.image = UIImage(named: "Music-off")
            isMusicOn = false
            self.scene.stopMusic()
        }else{
            self.musicButton.image = UIImage(named: "Music-on")
            isMusicOn = true
            self.scene.playBackgroundMusic()
        }
    }
}
