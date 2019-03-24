//
//  testingView.swift
//  test
//
//  Created by Dylan Lualdi on 23/03/2019.
//  Copyright © 2019 Dylan Lualdi. All rights reserved.
//

import UIKit

class TagNodeView: UINibView {
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet var accuracyLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    override var nibName: String {
        return "TagNodeView"
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 400, height: 150)
    }
    
    func update(description: String, imageUrl: String) {
        
        
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 5
        
        descriptionLabel.text = description.capitalized
        imageView.sd_setImage(with: URL(string: imageUrl)) { (image, error, cache, url) in }
        
    }
        

}


///helper class to reduce boilerplate of loading from Nib
open class UINibView : UIView {
    
    var nibView: UIView!
    
    open var nibName: String {
        get {
            print("UINibView.nibName should be overridden by subclass")
            return ""
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNib()
    }
    
    func setupNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        nibView = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        
        nibView.frame = bounds
        nibView.layer.masksToBounds = true
        
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .left, .right, .bottom]
        for attribute in attributes {
            let constraint = NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: self.nibView, attribute: attribute, multiplier: 1.0, constant: 0.0)
            self.addConstraint(constraint)
        }
        
        nibWasLoaded()
    }
    
    open func nibWasLoaded() {
        
    }
    
}
