//
//  InfoNodesInView.swift
//  ML_AR_UI_Kit
//
//  Created by Dylan Lualdi on 24/03/2019.
//  Copyright © 2019 Dylan Lualdi. All rights reserved.
//

import Foundation
import ARKit

struct InfoNodesInView {
    var node: SCNNode!
    var parentTagNode: SCNNode!
    var nodeView: UIView!
    
    init(node: SCNNode, parentTagNode: SCNNode, nodeView: UIView) {
        self.node = node
        self.parentTagNode = parentTagNode
        self.nodeView = nodeView
    }
}
