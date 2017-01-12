//
//  SequencerViewController.swift
//  Synthia
//
//  Created by Joshua Escribano on 3/6/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import UIKit
import Foundation

let drumBtnOnColor = UIColor(red: 0.73, green: 0.96, blue: 0.81, alpha: 1)
let drumBtnOnPlayingColor = UIColor(red: 0.64, green: 1, blue: 0.90, alpha: 1)

class SequencerViewController : UIViewController {
    weak var delegate: ContainerController?

    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    var audioEngine: AudioEngine?
    var toolbarView: UIView?
    var startPlaybackButton: UIButton?
    var bpmSlider: UISlider?
    var columnStepper: UIStepper?
    var presetStepper: UIStepper?
    var presetChangeLabel: UILabel?
    var presetChangeTimer: Timer?
    var isPlaying = false
    var bpm = 120
    var playIndex = 0
    var numberOfRows = 4
    var numberOfColumns = 8
    // [[], [], []]
    // drum buttons[row][column] = button
    var drumButtons = [[UIButton]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        toolbarView = UIView(frame: CGRect(x: 0, y:0, width: screenWidth, height: 55))
        toolbarView!.backgroundColor =  toolbarColor
        view.addSubview(toolbarView!)
        
        // Add Stepper
        let stepperFrame = CGRect(x: 2, y: 13.5, width: 45, height: 18)
        columnStepper = UIStepper(frame: stepperFrame)
        columnStepper!.value = 3
        columnStepper!.minimumValue = 2
        columnStepper!.maximumValue = 4
        columnStepper!.stepValue = 1
        columnStepper!.wraps = true
        columnStepper!.backgroundColor = octaveStepperBgColor
        columnStepper!.tintColor = octaveStepperColor
        columnStepper!.addTarget(self, action: #selector(SequencerViewController.changeColumns), for: UIControlEvents.touchUpInside)
        toolbarView!.addSubview(columnStepper!)
        
        // Add Preset Stepper
        let presetFrame = CGRect(x: 100, y: 13.5, width: 50, height: 18)
        presetStepper = UIStepper(frame: presetFrame)
        presetStepper!.value = 0
        presetStepper!.minimumValue = 0
        presetStepper!.maximumValue = 3
        presetStepper!.stepValue = 1
        presetStepper!.wraps = true
        presetStepper!.backgroundColor = octaveStepperBgColor
        presetStepper!.tintColor = octaveStepperColor
        presetStepper!.addTarget(self, action: #selector(SequencerViewController.changePreset), for: UIControlEvents.touchUpInside)
        toolbarView!.addSubview(presetStepper!)
        
        // SynthButton Temporarily
        let synthBtnFrame = CGRect(x: screenWidth - 47, y: 5, width: 45, height: 45)
        let synthButton = UIButton(frame: synthBtnFrame)
        synthButton.backgroundColor = changeModeButtonColor
        synthButton.setTitle("S", for: UIControlState())
        synthButton.setTitleColor(UIColor.white, for: UIControlState())
        synthButton.layer.cornerRadius = 15
        synthButton.addTarget(self, action: #selector(SequencerViewController.goToSynth), for: UIControlEvents.touchUpInside)
        toolbarView!.addSubview(synthButton)
        
        // Add Playback Buttons
        let startPlaybackFrame = CGRect(x: synthBtnFrame.minX - 47, y: 5, width: 45, height: 45)
        startPlaybackButton = UIButton(frame: startPlaybackFrame)
        startPlaybackButton!.titleLabel!.adjustsFontSizeToFitWidth = true
        startPlaybackButton!.setTitle("▶︎", for: UIControlState())
        startPlaybackButton!.titleLabel!.sizeToFit()
        startPlaybackButton!.addTarget(self, action: #selector(SequencerViewController.togglePlayback), for: UIControlEvents.touchUpInside)
        toolbarView!.addSubview(startPlaybackButton!)
        
        // Add bpm slider
        let bpmSliderWidth = startPlaybackFrame.origin.x - presetStepper!.frame.maxX + 5
        let bpmSliderFrame = CGRect(x: presetStepper!.frame.maxX + 5, y: 5, width: bpmSliderWidth, height: 45)
        bpmSlider = UISlider(frame: bpmSliderFrame)
        bpmSlider!.thumbTintColor = delayTimeSliderThumbColor
        bpmSlider!.tintColor = delayTimeSliderThumbColor
        bpmSlider!.minimumValue = 0
        bpmSlider!.maximumValue = 170
        bpmSlider!.value = 84
        bpmSlider!.addTarget(self, action: #selector(SequencerViewController.changeBpm), for: UIControlEvents.valueChanged)
        toolbarView!.addSubview(bpmSlider!)
        calculateGrid()
        
        if isPlaying {
            playStep()
        }
        
        audioEngine = AudioEngine()
    }
    
    func calculateGrid() {
        drumButtons.removeAll()
        let remainingHeight = screenHeight - toolbarView!.frame.height
        let drumBtnHeight = remainingHeight / CGFloat(numberOfRows)
        let drumBtnWidth = screenWidth / CGFloat(numberOfColumns)
        for row in 0...(numberOfRows - 1) {
            var columnArray = [UIButton]()
            for col in 0...(numberOfColumns - 1) {
                let x = CGFloat(col) * drumBtnWidth
                let y = CGFloat(row) * drumBtnHeight + toolbarView!.frame.height
                let btn = UIButton(frame: CGRect(x: x, y: y, width: drumBtnWidth, height: drumBtnHeight))
                btn.backgroundColor = padOffColor
                btn.layer.borderWidth = 0.5
                btn.layer.borderColor = btnBorderColor.cgColor
                btn.tag = row * numberOfColumns + col
                btn.addTarget(self, action: #selector(SequencerViewController.toggleDrumBtn(_:)), for: UIControlEvents.touchUpInside)
                view.addSubview(btn)
                columnArray.append(btn)
            }
            drumButtons.append(columnArray)
        }

    }
    
    func changeBpm() {
        bpm = Int(bpmSlider!.value)
    }
    
    func changePreset() {
        for drumSample in audioEngine!.drumArray {
            drumSample.changeSamplePack(Int(presetStepper!.value))
        }
        displayPresetChangeLabel()
    }
    
    func displayPresetChangeLabel() {
        if presetChangeTimer != nil {
            presetChangeTimer!.invalidate()
            presetChangeLabel!.removeFromSuperview()
        }
        
        let maxY = presetStepper!.frame.maxY + 5
        presetChangeLabel = UILabel(frame: CGRect(origin: CGPoint(x: presetStepper!.frame.minX, y: maxY), size: CGSize.zero))
        presetChangeLabel!.text = "Preset pack " + String(Int(presetStepper!.value))
        presetChangeLabel!.textColor = octaveStepperColor
        presetChangeLabel!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        presetChangeLabel!.sizeToFit()
        view.addSubview(presetChangeLabel!)
        
        presetChangeTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(SequencerViewController.removePresetChangeLabel), userInfo: nil, repeats: false)
    }
    
    func removePresetChangeLabel() {
        presetChangeLabel!.removeFromSuperview()
        presetChangeTimer = nil
    }
    
    func changeColumns() {
        numberOfColumns = Int(pow(2, columnStepper!.value))
        // remove from superviews
        for colBtn in drumButtons {
            for btn in colBtn {
                btn.removeFromSuperview()
            }
        }
        calculateGrid()
    }
    
    func goToSynth() {
        delegate?.pageWantsPageChange()
    }
    
    func toggleDrumBtn(_ sender: UIButton) {
        let row = Int(sender.tag / numberOfColumns)
        let col = sender.tag - row * numberOfColumns
        if drumButtons[row][col].backgroundColor == drumBtnOnColor {
            // off
            drumButtons[row][col].backgroundColor = padOffColor
        } else {
            // on
            drumButtons[row][col].backgroundColor = drumBtnOnColor
        }
    }
    
    func startPlayback() {
        startPlaybackButton!.setTitle("◼︎", for: UIControlState())
        isPlaying = true
        playStep()
    }
    
    func stopPlayback() {
        startPlaybackButton!.setTitle("▶︎", for: UIControlState())
        //audioEngine!.stopPlayback()
        for drum in audioEngine!.drumArray {
            if drum.playerNode.isPlaying {
                drum.playerNode.stop()
            }
        }
        isPlaying = false
    }
    
    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    func playStep() {
        if isPlaying {
            playIndex = playIndex % numberOfColumns
            let indicesToPlay = getIndicesToPlayAndHighlightColumn(playIndex)
            audioEngine!.triggerDrumSamplesForIndices(indicesToPlay)
            playIndex += 1
            let timeInterval = TimeInterval(Float(240) / Float(numberOfColumns * bpm))
            Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(SequencerViewController.playStep), userInfo: nil, repeats: false)
        }
    }
    
    func getIndicesToPlayAndHighlightColumn(_ index: Int) -> [Int] {
        var indicesToPlay = [Int]()
        var row = 0
        for colBtn in self.drumButtons {
            if colBtn[index].backgroundColor == drumBtnOnColor {
                colBtn[index].backgroundColor = drumBtnOnPlayingColor
                indicesToPlay.append(row)
            } else {
                colBtn[index].backgroundColor = padOnColor
            }
            var prevCol = index - 1
            if index == 0 {
                prevCol = self.numberOfColumns - 1
            }
            if colBtn[prevCol].backgroundColor == padOnColor {
                colBtn[prevCol].backgroundColor = padOffColor
            } else if colBtn[prevCol].backgroundColor == drumBtnOnPlayingColor {
                colBtn[prevCol].backgroundColor = drumBtnOnColor
            }
            row += 1
        }
        return indicesToPlay
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
}
