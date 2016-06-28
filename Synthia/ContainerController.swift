//
//  ContainerController.swift
//  Synthia
//
//  Created by Joshua Escribano on 3/12/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import Foundation
import UIKit

class ContainerController: UIViewController {

    var synthController = SynthViewController()
    var sequencerController = SequencerViewController()
    
    var page = 0
    var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = UIScreen.mainScreen().bounds
        scrollView = UIScrollView(frame: rect)
        scrollView.contentSize = CGSize(width: rect.width, height: rect.height)
        view.addSubview(scrollView)
        
        synthController.delegate = self
        addChildViewController(synthController)
        synthController.view.frame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        scrollView.addSubview(synthController.view)
        synthController.didMoveToParentViewController(self)
        
        sequencerController.delegate = self
        addChildViewController(sequencerController)
        sequencerController.view.frame = CGRect(x: rect.width, y: 0, width: rect.width, height: rect.height)
        scrollView.addSubview(sequencerController.view)
        sequencerController.didMoveToParentViewController(self)
    }
    
    func pageWantsPageChange() {
        page = (page + 1) % 2
        let width = view.bounds.width
        self.scrollView.setContentOffset(CGPoint(x: CGFloat(self.page) * width, y: 0), animated: false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == UIEventSubtype.MotionShake {
            synthController.fxSlider!.value = 0
            synthController.fxStepper!.value = 0
            synthController.fxSlider!.thumbTintColor = delayTimeSliderThumbColor
            synthController.fxSlider!.minimumTrackTintColor = delayTimeSliderThumbColor
            synthController.audioEngine!.resetFXValues()
            synthController.audioEngine!.stopVoices()
            synthController.padHandler!.clear()
            
            if motion == UIEventSubtype.MotionShake {
                sequencerController.stopPlayback()
                for colBtn in sequencerController.drumButtons {
                    for btn in colBtn {
                        btn.backgroundColor = padOffColor
                    }
                }
            }
        }
    }
}