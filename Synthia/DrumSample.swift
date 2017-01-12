//
//  DrumSample.swift
//  Synthia
//
//  Created by joshua on 3/10/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import Foundation
import AVFoundation

class DrumSample {
    var sampleIndex: Int?
    var sampleFile: AVAudioFile?
    var hasCompletedPlayback = true
    let playerNode = AVAudioPlayerNode()
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
    
    init(sampleIndex: Int) {
        self.sampleIndex = sampleIndex
        let samplePath = Bundle.main.path(forResource: "sample-" + String(sampleIndex), ofType: "wav", inDirectory: "pack-0")
        let sampleFileUrl = URL(string: samplePath!)
        do {
            sampleFile = try AVAudioFile(forReading: sampleFileUrl!)
        } catch {}
    }
    
    func changeSamplePack(_ packIndex: Int) {
        if playerNode.isPlaying {
            playerNode.stop()
        }
        let samplePath = Bundle.main.path(forResource: "sample-" + String(sampleIndex!), ofType: "wav", inDirectory: "pack-" + String(packIndex))
        let sampleFileUrl = URL(string: samplePath!)
        do {
            sampleFile = try AVAudioFile(forReading: sampleFileUrl!)
        } catch {}
    }
    
    func trigger() {
        if !hasCompletedPlayback {
            playerNode.stop()
        }
        hasCompletedPlayback = false
        playerNode.scheduleFile(sampleFile!, at: nil, completionHandler: {
            self.hasCompletedPlayback = true
        })
        playerNode.play()
    }
}
