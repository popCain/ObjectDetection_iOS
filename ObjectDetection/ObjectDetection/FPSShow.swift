//
//  FPSShow.swift
//  ObjectDetection
//
//  Created by 张坤 on 2020/10/19.
//  Copyright © 2020 MachineThink. All rights reserved.
//

import Foundation
import UIKit

class FPSShow {
  
  let textLayer: CATextLayer

  init() {

    textLayer = CATextLayer()
    textLayer.foregroundColor = UIColor.red.cgColor
    textLayer.isHidden = true
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.fontSize = 14
    textLayer.font = UIFont(name: "Avenir", size: textLayer.fontSize)
    textLayer.alignmentMode = CATextLayerAlignmentMode.center
  }

  func addToLayer(_ parent: CALayer) {
    parent.addSublayer(textLayer)
  }

  func show(fps: String) {
    CATransaction.setDisableActions(true)

    textLayer.string = fps
    textLayer.isHidden = false

    let attributes = [
      NSAttributedString.Key.font: textLayer.font as Any
    ]

    let textRect = fps.boundingRect(with: CGSize(width: 400, height: 100),
                                      options: .truncatesLastVisibleLine,
                                      attributes: attributes, context: nil)
    let textSize = CGSize(width: textRect.width + 12, height: textRect.height)
    let textOrigin = CGPoint(x: 10, y: 20)
    textLayer.frame = CGRect(origin: textOrigin, size: textSize)
  }

  func hide() {
    textLayer.isHidden = true
  }
}

