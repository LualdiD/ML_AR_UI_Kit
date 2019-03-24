//
//  testingInfoView.swift
//  ML_AR_UI_Kit
//
//  Created by Dylan Lualdi on 23/03/2019.
//  Copyright © 2019 Dylan Lualdi. All rights reserved.
//

import UIKit
import SDWebImage

class InfoNodeView: UINibView {

    override var nibName: String {
        return "InfoNodeView"
    }
    
    @IBOutlet weak var paperSwitch1: RAMPaperSwitch!
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    var node: InfoNodesInView?
    
    var descriptionText = ""
    var imageUrl = ""
    var wikiUrl = ""
    
    
    func update() {
        DispatchQueue.main.async {
            self.textView.text = self.descriptionText
            self.imageView.sd_setImage(with: URL(string: self.imageUrl)) { (image, error, cache, url) in }
            
        }
        
        self.setupPaperSwitch()
    }
    
    override func layoutSubviews() {
        textView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func setupPaperSwitch() {
        
        self.paperSwitch1.animationDidStartClosure = {(onAnimation: Bool) in
            
            self.animateLabel(self.textView, onAnimation: onAnimation, duration: self.paperSwitch1.duration)
            
        }
           
        
    }
    
    func animateLabel(_ label: UITextView, onAnimation: Bool, duration: TimeInterval) {
        UIView.transition(with: label, duration: duration, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
            label.textColor = onAnimation ? UIColor.white : UIColor.black
        }, completion:nil)
    }

 
    @IBAction func remove(_ sender: Any) {
        
        node?.node.removeFromParentNode()
        node?.parentTagNode.removeFromParentNode()
        
    }
    
}
