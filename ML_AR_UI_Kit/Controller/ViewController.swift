//
//  ViewController.swift
//  ML_AR_UI_Kit
//
//  Created by Dylan Lualdi on 22/03/2019.
//  Copyright © 2019 Dylan Lualdi. All rights reserved.
//


import UIKit
import ARKit
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage



class ViewController: UIViewController, UIGestureRecognizerDelegate, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var latestAccuracy : String = "0%"
    
    var observingTagNodes = [TagNodesInView?]()
    var observingInfoNodes = [InfoNodesInView?]()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    // The view controller that displays the status and "restart experience" UI.
    private lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the session delegate
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        // Hook up status view controller callback.
        statusViewController.restartExperienceHandler = { [unowned self] in
            
            //remove all nodes
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                node.removeFromParentNode()
            }
            
            self.restartSession()
        }
        
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // Check if touched a node
        if let scnView = self.sceneView {
            // check what nodes are tapped
            let p = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(p, options: [:])
            // check that we clicked on at least one object
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result = hitResults[0]
                let node = result.node
                
                if node.name == "info" {
                    
                } else {
                    if let index = Int(node.name ?? "0") {
                        if let storedNode = observingTagNodes[index] {
                            
                            if let nodeView = storedNode.nodeView as? TagNodeView {
                                if nodeView.bgView.tag == 0 {
                                    addInfoNode(node: node, x: 0, y: 0.3, z: -0.02,
                                                wikiDesc: storedNode.wikiDescription ?? "",
                                                wikiImgUrl: storedNode.wikiImgURL ?? "", wikiUrl: storedNode.wikiURL ?? "")
                                    
                                    observingTagNodes[index]!.infoNode = observingInfoNodes.last??.node
                                    
                                    nodeView.bgView.tag = 1
                                    nodeView.bgView.backgroundColor = UIColor.green
                                } else {
                                    
                                    if let infoNode = storedNode.infoNode {
                                        infoNode.removeFromParentNode()
                                    }
                                    
                                    nodeView.bgView.backgroundColor = UIColor.white
                                    nodeView.bgView.tag = 0
                                }
                            }
                            
                            
                        }
                    }
                }
                
                
                return
                

            }
        }
        
        // ADD NEW TAG NODE
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            //add node if an object is recognised
            if latestPrediction != "..." {
                
                DispatchQueue.main.async {
                    let node : SCNNode = self.createNewTagParentNode(self.latestPrediction)
                    self.sceneView.scene.rootNode.addChildNode(node)
                    node.position = worldCoord
                }
                
                
            }
        }
    }
    
    func createNewTagParentNode(_ text : String) -> SCNNode {
        
        // BILLBOARD CONSTRAINT to focus the camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        //plane where the object is going to be attached
        let plane = SCNPlane(width: 0.2, height: 0.08)
        plane.cornerRadius = 0.01
        
        // load the view
        let nodeView = TagNodeView(frame: CGRect(x: 0, y: 0, width: 400, height: 150))
        nodeView.mainLabel.text = latestPrediction.capitalized
        nodeView.accuracyLabel.text = latestAccuracy
        
        plane.firstMaterial?.diffuse.contents = nodeView
        
        //create node and give geomegtry
        let tagNode = SCNNode(geometry: plane)
        let (minBound, maxBound) = plane.boundingBox
        tagNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, 0.1/2)
        tagNode.constraints = [billboardConstraint]
        tagNode.name = observingTagNodes.count.description
        
        let storedTagNode = TagNodesInView(node: tagNode, nodeView: nodeView, wikiDescription: "Unable to load data, please try again", wikiImgURL: "", wikiURL: "", infoNode: nil)
        requestWikiInfo(keyword: latestPrediction, node: storedTagNode)
        
        return tagNode
    }
    
    func addInfoNode(node: SCNNode, x: Float, y: Float, z: Float, wikiDesc: String, wikiImgUrl: String, wikiUrl: String) {
        
        let infoView = InfoNodeView(frame: CGRect(x: 0, y: 0, width: 300, height: 450))
        
        
        infoView.descriptionText = wikiDesc
        infoView.imageUrl = wikiImgUrl
        infoView.wikiUrl = wikiUrl
        infoView.update()
        
        let newNode = node.clone()
        let plane = SCNPlane(width: 0.35, height: 0.45)
        plane.cornerRadius = 0.01
        
        plane.firstMaterial?.diffuse.contents = infoView
        newNode.geometry = plane
        let position = SCNVector3(x: node.position.x, y: node.position.y + 1, z: node.position.z)
        newNode.position = position//node.position
        
        newNode.name = "info"
        
        DispatchQueue.main.async {
            self.sceneView.scene.rootNode.addChildNode(newNode)
        }
        
        
        let storedInfoNode = InfoNodesInView(node: newNode, parentTagNode: node, nodeView: infoView)
        
        infoView.node = storedInfoNode
        
        observingInfoNodes.append(storedInfoNode)
        
       
        DispatchQueue.main.async {
            let position = SCNVector3(x: x, y: y, z: z)
            self.updatePositionAndOrientationOf(newNode, withPosition: position, relativeTo: node, animated: true)
        }
                
    }
    
    func requestWikiInfo(keyword: String, node: TagNodesInView ) {
        
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages|info", "exintro" : "", "inprop" : "url", "explaintext" : "", "titles" : keyword, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]
        
        var nodeInView = node
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                
                let wikiJSON : JSON = JSON(response.result.value!)
                
                let pageid = wikiJSON["query"]["pageids"][0].stringValue
                
                let wikiDescription = wikiJSON["query"]["pages"][pageid]["extract"].stringValue
                let wikiImageURL = wikiJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                let wikiURL = wikiJSON["query"]["pages"][pageid]["fullurl"].stringValue
                
                nodeInView.wikiDescription = wikiDescription
                nodeInView.wikiImgURL = wikiImageURL
                nodeInView.wikiURL = wikiURL
                
                if let nodeView = node.nodeView as? TagNodeView {
                    nodeView.update(description: wikiDescription, imageUrl: wikiImageURL)
                }
                
                self.observingTagNodes.append(nodeInView)
            }
            else {
                self.observingTagNodes.append(nodeInView)
                print("Error \(String(describing: response.result.error))")
                
            }
        }
    }
    
    // Easy reposition of node with animation
    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode, animated: Bool) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
        
        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z
        
        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)

        
//        let scaleUp = SCNAction.scale(by: 5, duration: 1)
//        scaleUp.timingMode = .easeInEaseOut;
//        node.runAction(scaleUp)
        if animated {
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = node.transform
            animation.toValue = SCNMatrix4(updatedTransform)
            animation.duration = 0.6
            node.addAnimation(animation, forKey: nil)
        } else {
            node.transform = SCNMatrix4(updatedTransform)
        }        
        
    }
    
    
    
    
    // MARK: - ARSessionDelegate ------------------------
    // --------------------------------------------------
    
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
        
    }
    
    
    // Vision classification request and model
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    // Run the Vision+ML classifier on the current image buffer.
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    
    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]
        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        if let bestResult = classifications.first(where: { result in result.confidence > 0.1 }),
            let label = bestResult.identifier.split(separator: ",").first {
            identifierString = String(label)
            confidence = bestResult.confidence
        } else {
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.displayClassifierResults()
        }
    }
    
    // Show the classification results in the UI.
    private func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            latestPrediction = "..."
            statusViewController.statusView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            return // No object was classified.
        }
        
        statusViewController.statusView.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
        latestPrediction = self.identifierString
        latestAccuracy = String(format: "%.2f", self.confidence * 100) + "%"
        
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)
    }
    
    
    // MARK: - AR Session Handling
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Filter out optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) { }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }
    
    private func restartSession() {
        statusViewController.cancelAllScheduledMessages()
        statusViewController.showMessage("RESTARTING SESSION")
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Error handling
    
    private func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.restartSession()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    
}

