//
//  PadHandler.swift
//  Synthia
//
//  Created by Joshua Escribano on 3/23/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import Foundation
import UIKit

func touchesInView(_ touches: Set<UITouch>, view: UIView) -> Set<UITouch> {
    var touchesInView = Set<UITouch>()
    for touch in touches {
        let location = touch.location(in: nil)
        let viewRect = view.convert(view.bounds, to: nil)

        if viewRect.contains(location) {
            touchesInView.insert(touch)
        }
    }
    
    return touchesInView
}

class Pad {
    var isOn = false
    var touches = Set<UITouch>()
    
    init() {}
    
    init (isOn: Bool, touch: UITouch) {
        self.isOn = isOn
        touches = [touch]
    }
    
    init (isOn: Bool, touches: Set<UITouch>) {
        self.isOn = isOn
        self.touches = touches
    }
}

class PadHandler {
    var pads =  [Pad]()
    var padLabels = [UILabel]()
    var audioEngine: AudioEngine?
    
    init (audioEngine: AudioEngine, padLabels: [UILabel]) {
        self.audioEngine = audioEngine
        self.padLabels = padLabels
        for _ in padLabels {
            pads.append(Pad())
        }
    }
    
    func processTouchesBegan(_ touches: Set<UITouch>) {
        for (i, padLabel) in padLabels.enumerated() {
            let touchesInPad = touchesInView(touches, view: padLabel)
            if touchesInPad.count > 0 {
                if !pads[i].isOn {
                    turnOnPad(i)
                    pads[i].touches = touchesInPad
                    updatePadTouchLocation(i)
                } else {
                    pads[i].touches = pads[i].touches.union(touchesInPad)
                    updatePadTouchLocation(i)
                }
            }
        }
    }
    
    func processTouchesMoved(_ touches: Set<UITouch>) {
        for (i, padLabel) in padLabels.enumerated() {
            let touchesInPad = touchesInView(touches, view: padLabel)
            let padTouchesIntersect = pads[i].touches.intersection(touches)
            if !padTouchesIntersect.isEmpty {
                let remainingTouchesInPad = padTouchesIntersect.intersection(touchesInPad)
                if remainingTouchesInPad.isEmpty {
                    turnOffPad(i)
                } else {
                    pads[i].touches = remainingTouchesInPad
                    updatePadTouchLocation(i)
                }
            }
            if touchesInPad.count > 0 {
                if !pads[i].isOn {
                    turnOnPad(i)
                    pads[i].touches = touchesInPad
                    updatePadTouchLocation(i)
                } else {
                    pads[i].touches = pads[i].touches.union(touchesInPad)
                    updatePadTouchLocation(i)
                }
            }
        }
    }
    
    func processTouchesEnded(_ touches: Set<UITouch>) {
        for (i, _) in padLabels.enumerated() {
            for touch in pads[i].touches.intersection(touches) {
                pads[i].touches.remove(touch)
            }
            if pads[i].touches.isEmpty {
                turnOffPad(i)
            } else {
                updatePadTouchLocation(i)
            }
        }
    }
    
    func turnOnPad(_ index: Int) {
        padLabels[index].backgroundColor = padOnColor
        audioEngine!.voiceArray[index].start(index)
    }
    
    func turnOffPad(_ index: Int) {
        pads[index].isOn = false
        pads[index].touches.removeAll(keepingCapacity: false)
        padLabels[index].backgroundColor = padOffColor
        audioEngine!.voiceArray[index].stop()
    }
    
    func updatePadTouchLocation(_ index: Int) {
        var touch: UITouch?
        if pads[index].touches.count == 1 {
            touch = pads[index].touches.first
        }
        touch = pads[index].touches.sorted(by: { (t1: UITouch, t2: UITouch)  -> Bool in
            return t1.location(in: nil).y > t2.location(in: nil).y
        }).first!
        let locationRatio = Float(touch!.location(in: padLabels[index]).y/padLabels[index].frame.height)
        audioEngine!.voiceArray[index].calculateWaveRatios(locationRatio)
    }
    
    func clear() {
        for i in 0...pads.count - 1 {
            turnOffPad(i)
        }
    }
}
