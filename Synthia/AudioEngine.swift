//
//  AudioEngine.swift
//  SimpleSynth
//
//  Created by Joshua Escribano on 1/16/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import Foundation
import AVFoundation

enum FXType: String {
    case DelayTime,DelayWetness,ReverbWetness,DistortionWetness,CutOffFrequency
}

class AudioEngine {
    var playbackFilePlayer =  AVAudioPlayerNode()
    var engine = AVAudioEngine()
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
    var fxValue = Float(0)
    var fxType = FXType.DelayTime
    let dryMasterMixerNode = AVAudioMixerNode()
    var key = "C"
    var octave = 4
    var delayNode: AVAudioUnitDelay?
    var reverbNode: AVAudioUnitReverb?
    var eqNode: AVAudioUnitEQ?
    var distortionNode: AVAudioUnitDistortion?
    var playbackOutputFile: AVAudioFile?
    var playbackFileUrl: NSURL?

    // 0 stoped 1 paused 2 playing
    var playbackStatus = 0
    var recording = false
    var voiceArray = [Voice]()
    var drumArray = [DrumSample]()
    
    init() {
        // TODO: Refactor to introduce notions of synth vs drum vs master mixing and fx modes
        // This is a quick constructor to get sequencer working
        let numOfRowsForDrums = 4
        for i in 0...(numOfRowsForDrums - 1) {
            let drumSample = DrumSample(sampleIndex: i)
            engine.attachNode(drumSample.playerNode)
            engine.connect(drumSample.playerNode, to: engine.mainMixerNode, format: audioFormat)
            drumArray.append(drumSample)
        }
        
        do {
            try engine.start()
        } catch {
            print("Engine Crashed")
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            try audioSession.setCategory("AVAudioSessionCategoryPlayback")
            
        } catch  {
            print("audio session crash")
        }
    }
    
    init (numberOfVoices: Int, withKey: String, withOctave: Int) {
        playbackFileUrl = nil
        engine.attachNode(dryMasterMixerNode)
        for _ in 0...(numberOfVoices - 1) {
            let voice = Voice(withKey: withKey, withOctave: withOctave)
            voiceArray.append(voice)
            engine.attachNode(voice.oscNode)
            engine.connect(voice.oscNode, to: dryMasterMixerNode, format: audioFormat)
        }
        delayNode = AVAudioUnitDelay()
        delayNode!.bypass = false
        delayNode!.delayTime = 0.68
        delayNode!.wetDryMix = 10
        reverbNode = AVAudioUnitReverb()
        reverbNode!.bypass = false
        reverbNode!.wetDryMix = 20
        eqNode = AVAudioUnitEQ(numberOfBands: 1)
        eqNode!.bands.first!.filterType = AVAudioUnitEQFilterType.LowPass
        eqNode!.bands.first!.frequency = 800
        eqNode!.bands.first!.bypass = false
        eqNode!.globalGain = 0
        eqNode!.bypass = false
        distortionNode = AVAudioUnitDistortion()
        distortionNode!.bypass = false
        distortionNode!.wetDryMix = 0
        engine.attachNode(delayNode!)
        engine.attachNode(reverbNode!)
        engine.attachNode(eqNode!)
        engine.attachNode(distortionNode!)
        engine.attachNode(playbackFilePlayer)
        engine.connect(dryMasterMixerNode, to: delayNode!, format: audioFormat)
        engine.connect(delayNode!, to: reverbNode!, format: audioFormat)
        engine.connect(reverbNode!, to: eqNode!, format: audioFormat)
        engine.connect(eqNode!, to: distortionNode!, format: audioFormat)
        engine.connect(distortionNode!, to: engine.mainMixerNode, format: audioFormat)
        engine.connect(playbackFilePlayer, to: engine.mainMixerNode, format: audioFormat)
        
        do {
            try engine.start()
        } catch {
            print("Engine Crashed")
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            try audioSession.setCategory("AVAudioSessionCategoryPlayback")

        } catch  {
            print("audio session crash")
        }
    }
    
    func changeOctave(octave: Int) {
        self.octave = octave
        for voice in voiceArray {
            voice.octave = octave
        }
    }
    
    func changeKey(key: String) {
        self.key = key
        for voice in voiceArray {
            voice.changeKey(key)
        }
    }
    
    // Refactor this to use custom setter same for the above
    func changeFXValue(newFXValue: Float) {
        var convertedFXValue = Float(0)
        switch fxType {
        case FXType.DelayTime:
            convertedFXValue = newFXValue * Float(2)
            delayNode!.delayTime = NSTimeInterval(convertedFXValue)
        case FXType.DelayWetness:
            convertedFXValue = newFXValue * Float(100)
            delayNode!.wetDryMix = convertedFXValue
        case FXType.DistortionWetness:
            convertedFXValue = newFXValue * Float(100)
            distortionNode!.wetDryMix = convertedFXValue
        case FXType.ReverbWetness:
            convertedFXValue = newFXValue * Float(100)
            reverbNode!.wetDryMix = convertedFXValue
        case FXType.CutOffFrequency:
            convertedFXValue = Float(5)
            eqNode!.bands.first!.frequency = exp(newFXValue)
        }
        fxValue = convertedFXValue
    }
    
    func resetFXValues() {
        delayNode!.delayTime = 0
        delayNode!.wetDryMix = 0
        reverbNode!.wetDryMix = 0
        distortionNode!.wetDryMix = 0
        eqNode!.bands.first!.frequency = 22000
        fxValue = 0
        fxType = FXType.DelayTime
    }
    
    func stopVoices() {
        for voice in voiceArray {
            voice.stop()
        }
    }
    
    func reset() {
        engine.stop()
        do {
            try engine.start()
        } catch {
            print("Engine Crashed")
        }
    }
    
    func startRecording() {
        if !recording {
            recording = true
            
            if playbackFileUrl == nil {
                playbackFileUrl = NSURL(string: NSTemporaryDirectory() + "playbackOutput.caf")
            }
            
            let mainMixer = engine.mainMixerNode
            do {
                self.playbackOutputFile = try AVAudioFile(forWriting: playbackFileUrl!, settings: mainMixer.outputFormatForBus(0).settings)
            } catch {
                print("Playback set up error")
            }
            
            if !engine.running {
                do {
                    try engine.start()
                } catch {
                    print("Engine crashed")
                }
            }
            mainMixer.installTapOnBus(0, bufferSize: 1024, format: audioFormat, block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) -> Void in
                do {
                    try self.playbackOutputFile!.writeFromBuffer(buffer)
                } catch {
                    print("Error writing buffer")
                }
            })
        }
    }
    
    func stopRecording() {
        if recording {
            engine.mainMixerNode.removeTapOnBus(0)
            recording = false
        }
    }
    
    func startPlayback() {
        if !engine.running {
            do {
                try engine.start()
            } catch {
                print("Engine crashed")
            }
        }
        if playbackStatus == 1 {
            playbackFilePlayer.play()
            playbackStatus = 2
        } else {
            if playbackFileUrl != nil {
                var recordedFile: AVAudioFile?
                
                do {
                    try recordedFile = AVAudioFile(forReading: playbackFileUrl!)
                } catch {
                    print("Recorded File error")
                }
                
                playbackFilePlayer.scheduleFile(recordedFile!, atTime: nil, completionHandler: { () -> Void in
                    let playerTime = self.playbackFilePlayer.playerTimeForNodeTime(self.playbackFilePlayer.lastRenderTime!)
                    let delaySeconds = Double(recordedFile!.length - playerTime!.sampleTime) / recordedFile!.processingFormat.sampleRate
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delaySeconds) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), {
                        if self.playbackStatus == 0 {
                            self.playbackFilePlayer.stop()
                        } else if self.playbackStatus == 1 {
                            self.playbackFilePlayer.pause()
                        } else if self.playbackStatus == 2 {
                            self.startPlayback()
                        }
                    })
                })
                self.playbackFilePlayer.play()
                self.playbackStatus = 2
            }
        }
    }
    
    func pausePlayback() {
        playbackFilePlayer.pause()
        playbackStatus = 1
    }
    
    func stopPlayback() {
        playbackFilePlayer.stop()
        playbackStatus = 0
    }
    
    func triggerDrumSamplesForIndices(indices: [Int]) {
        // TODO:
        //
        for index in indices {
            drumArray[index].trigger()
        }
    }
}