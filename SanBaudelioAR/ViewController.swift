//
//  ViewController.swift
//  SanBaudelio2
//
//  Created by Sue Roh on 11/16/18.
//  Copyright © 2018 SOE Studio. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import FLAnimatedImage

let NUM_OF_TRACKED_IMGS = 2

// Paths
let SCENE_ASSETS_PATH = "art.scnassets/"
let COMP_PATH = "art.scnassets/Comp 1/"
let TR_IMG_PATHS : [String] = [
    "CamelFrontTR",
    "CamelAngleTR",
    "WallTextCamel"
]

// Keeps track of nodes in scene
var toRenderImgs: [UIImage] = []
var camelFrontNode: [SCNNode] = []
var camelAngleNode: [SCNNode] = []

// Anchor names
let CAMEL_FRONT = "Camel_Front"
let CAMEL_ANGLE = "Camel_Angle"

// Angle text dimensions
let TEXT_HEIGHT = CGFloat(0.074396)
let TEXT_WIDTH = CGFloat(0.14224)

//var timer: Timer?

class Home: UIViewController {
    @IBOutlet weak var infoButton: UIButton!
    var timer: Timer?
    
    // Click on info button & clear timeout
    @IBAction func onInfoButtonTouch(_ sender: Any) {
        clearTimer()
        self.performSegue(withIdentifier: "About", sender: self)
    }
    
    func loadImages() { // Preloads to-render images in scene
        for path in TR_IMG_PATHS {
            toRenderImgs.append(
                UIImage(named: SCENE_ASSETS_PATH + path)!
            )
        }
    }
    
    func clearTimer() {
        timer?.invalidate()
    }
    
    @objc func handleTouch(_ sender: UITapGestureRecognizer) {
        clearTimer()
        self.performSegue(withIdentifier: "Start", sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) { // Begins timeout to "Start" screen
        super.viewDidAppear(animated)
        self.loadImages()
        
        let touchGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(self.handleTouch)
            )
        self.view.addGestureRecognizer(touchGesture)
        
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
            self.performSegue(withIdentifier: "Start", sender: self)
        }

    }

    override func didReceiveMemoryWarning() { // To do: Factor out
        super.didReceiveMemoryWarning()
    }
}

class ARScene: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var imageView: FLAnimatedImageView!

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var instructions: UIImageView!
    @IBOutlet weak var descriptionBG: UIImageView!
    @IBOutlet weak var finishButton: UIButton!
    var hasPlayed: Bool! = false
    var expData1: Data?
    var expData2: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene(named: SCENE_ASSETS_PATH + "main.scn")!
        
        // Set the scene to the view
        sceneView?.scene = scene

        let data1 = try! Data(contentsOf: Bundle.main.url(forResource: "art.scnassets/Explanation1", withExtension: "gif")!)
        let data2 = try! Data(contentsOf: Bundle.main.url(forResource: "art.scnassets/Explanation2", withExtension: "gif")!)
        expData1 = data1
        expData2 = data2
        
        
        let nextExpGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(self.handleNext)
        )
        self.nextButton.isUserInteractionEnabled = true
        self.nextButton.addGestureRecognizer(nextExpGesture)
        
        let closeGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(self.handleClose)
        )
        self.finishButton.isUserInteractionEnabled = true
        self.finishButton.addGestureRecognizer(closeGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // Define render image location
        guard let arImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources",
            bundle: nil) else { return }
        
        // Configuration
        configuration.maximumNumberOfTrackedImages = NUM_OF_TRACKED_IMGS
        configuration.trackingImages = arImages

        // Run the view's session
        sceneView?.session.run(configuration)
    }
    
    @objc func handleNext(_ sender: UITapGestureRecognizer) {
        self.nextButton.isHighlighted = true
        self.nextButton.isHidden = true
        self.finishButton.isHidden = false
        self.imageView.animatedImage = FLAnimatedImage(animatedGIFData: self.expData2)
        self.imageView.loopCompletionBlock = {_ in
            self.imageView.stopAnimating()
        }
        UIView.animate(withDuration: 1, animations: {
            self.finishButton.alpha = 1
        })
    }
    
    @objc func handleClose(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 1, animations: {
            self.imageView.alpha = 0
            self.finishButton.alpha = 0
            self.descriptionBG.alpha = 0
        }, completion: {_ in
            self.imageView.isHidden = true
            self.finishButton.isHidden = true
            self.descriptionBG.isHidden = true
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARImageAnchor else {return}
        if let imageAnchor = anchor as? ARImageAnchor {
            let imageSize = imageAnchor.referenceImage.physicalSize
            
            let camelPlane = SCNPlane(
                width: CGFloat(imageSize.width),
                height: CGFloat(imageSize.height
            ))
            
            let camelToRenderNode = SCNNode(geometry: camelPlane)
            camelToRenderNode.name = anchor.name
            camelToRenderNode.eulerAngles.x = -.pi / 2
            
            let textPlane = SCNPlane(
                width: TEXT_WIDTH,
                height: TEXT_HEIGHT
            )
            let textToRenderNode = SCNNode(geometry: textPlane)
            let isFront = anchor.name == CAMEL_FRONT
            let camelImg = isFront ? toRenderImgs[0] : toRenderImgs[1]
                
            let positionX = isFront ?
                    -0.085:
                    Float(-TEXT_WIDTH / 3),
                positionY = isFront ?
                    Float(-imageSize.height / 2.2) :
                    Float(-imageSize.height / 2 - TEXT_HEIGHT / 2)
            
            textToRenderNode.position.z = 0.01 // So text and camel layers aren't fighting
            textToRenderNode.position.x = positionX
            textToRenderNode.position.y = positionY
            textPlane.firstMaterial?.diffuse.contents = toRenderImgs[2]
            camelPlane.firstMaterial?.diffuse.contents = camelImg
            camelToRenderNode.addChildNode(textToRenderNode)
            if (isFront) {
                camelFrontNode.append(camelToRenderNode)
            } else {
                camelAngleNode.append(camelToRenderNode)
            }
            camelToRenderNode.opacity = 0
            let fadeInAnimation = SCNAction.fadeIn(duration: 1)
            
            node.addChildNode(camelToRenderNode)
            
            camelToRenderNode.runAction(fadeInAnimation) {
                switch anchor.name {
                case CAMEL_FRONT:
                    camelFrontNode.removeFirst()
                    break
                case CAMEL_ANGLE:
                    camelAngleNode.removeFirst()
                    break
                default:
                    break
                }
            }
            
            if (!hasPlayed) {
                hasPlayed = true
                descriptionBG.isHidden = false
                UIView.animate(withDuration: 1,
                               animations: {
                                self.instructions.alpha = 0.0
                                self.descriptionBG.alpha = 1.0
                })
                imageView.isHidden = false
                imageView.alpha = 1.0
                imageView.animatedImage = FLAnimatedImage(animatedGIFData: expData1)
                self.imageView.loopCompletionBlock = {_ in
                    self.nextButton.isHidden = false
                    self.descriptionBG.isHidden = false
                    self.imageView.stopAnimating()
                    UIView.animate(withDuration: 1, animations: {
                        self.nextButton.alpha = 1.0
                        self.descriptionBG.alpha = 1.0
                    })
                }
            }
        }

    }
    
}
