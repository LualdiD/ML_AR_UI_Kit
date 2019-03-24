//
//  InfoNodesInView.swift
//  ML_AR_UI_Kit
//
//  Created by Dylan Lualdi on 24/03/2019.
//  Copyright © 2019 Dylan Lualdi. All rights reserved.
//

import Foundation
import ARKit

struct TagNodesInView {
    var node: SCNNode!
    var infoNode: SCNNode?
    var nodeView: UIView!
    var wikiDescription: String? = ""
    var wikiImgURL: String? = ""
    var wikiURL: String? = ""
    
    init(node: SCNNode, nodeView: UIView, wikiDescription: String?, wikiImgURL: String?, wikiURL: String?, infoNode: SCNNode?) {
        self.node = node
        self.nodeView = nodeView
        self.wikiDescription = wikiDescription
        self.wikiImgURL = wikiImgURL
        self.infoNode = infoNode
        self.wikiURL = wikiURL
    }
    
    
}
