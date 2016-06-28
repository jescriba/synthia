//
//  Voice.swift
//  SimpleSynth
//
//  Created by Joshua Escribano on 1/16/16.
//  Copyright © 2016 Joshua Escribano. All rights reserved.
//

import Foundation
import AVFoundation

class Voice {
    var key: String?
    var bufferIndex = 0
    var playing = false
    let oscNode = AVAudioPlayerNode()
    let mixNode = AVAudioMixerNode()
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
    var audioBuffers = [AVAudioPCMBuffer]()
    let audioQueue = dispatch_queue_create("SynthQueue", DISPATCH_QUEUE_SERIAL)
    let audioSempahore = dispatch_semaphore_create(2)
    let samplesPerBuffer = AVAudioFrameCount(1024)
    var octave: Int?
    let baseFrequencies = ["C": 16.35, "C#": 17.32, "D": 18.35, "D#": 19.45, "E": 20.60, "F": 21.83, "F#":23.12, "G": 24.50, "G#": 25.96, "A": 27.50, "A#": 29.14, "B": 30.87]
    let possibleNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    var scaleNotes = [String]()
    var scaleBaseFrequencies: [Double]?
    var noteIndex: Int?
    var squareWaveRatio = Float(0)
    var triangleWaveRatio = Float(1)
    var sineWaveRatio = Float(0)
    
    init(withKey: String, withOctave: Int) {
        key = withKey
        octave = withOctave
        computeScaleBaseFrequenciesForKey(withKey)
        for _ in 0...1 {
            let audioBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: samplesPerBuffer)
            audioBuffers.append(audioBuffer)
        }
    }
    
    func start(padIndex: Int) {
        noteIndex = padIndex
                
        if !playing {
             startNote()
            playing = true
        }
        oscNode.play()
    }
    
    func startNote() {
        let unitVelocity = 2.0 * M_PI / audioFormat.sampleRate
        dispatch_async(audioQueue) {
            var sampleTime = 0
            var previousKey = self.key
            while (true) {
                if self.key != previousKey {
                    self.computeScaleBaseFrequenciesForKey(self.key!)
                    previousKey = self.key
                }
                dispatch_semaphore_wait(self.audioSempahore, DISPATCH_TIME_FOREVER)
                let targetFrequency = Float32(Double(self.octave!) * self.scaleBaseFrequencies![self.noteIndex!])
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                for i in 0...Int(self.samplesPerBuffer - 1) {
                    let carrierVelocity = targetFrequency * Float32(unitVelocity)
                    var sample = Float32(0)
                    var triangleSample = Float32(0)
                    var squareSample = Float32(0)
                    var sineSample = Float32(0)
                    
                    // WaveTypes
                    triangleSample = Float32(Float(2.0 / M_PI) * asin(sin(Float(M_PI) * Float(carrierVelocity) * Float(sampleTime))))
                    
                    sineSample = 0
                    
                    var intermediateVal = sinf(Float(carrierVelocity) * Float(sampleTime));
                    // sgn function
                    if (intermediateVal < 0) {
                        intermediateVal = -1;
                    } else if (intermediateVal > 0) {
                        intermediateVal = 1;
                    }
                    squareSample = 1 / 2 * intermediateVal;
                    
                    sample = self.squareWaveRatio * squareSample + self.triangleWaveRatio * triangleSample + self.sineWaveRatio * sineSample
                    
                    
                    audioBuffer.floatChannelData[0][i] = sample
                    audioBuffer.floatChannelData[1][i] = sample
                    sampleTime += 1
                }
                audioBuffer.frameLength = self.samplesPerBuffer
                self.oscNode.scheduleBuffer(audioBuffer, completionHandler: { () -> Void in
                    dispatch_semaphore_signal(self.audioSempahore)
                    return
                })
                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            }
        }
    }
    
    func stop() {
        if oscNode.playing {
            oscNode.stop()
        }
    }
    
    func changeKey(newKey: String) {
        key = newKey
        computeScaleBaseFrequenciesForKey(newKey)
    }
    
    // location is a float 0-1 representing the top to bottom of the pad
    func calculateWaveRatios(location: Float) {
        
        if location > 0.5 {
            triangleWaveRatio = (1 - location) + 0.5
            squareWaveRatio = 1 - triangleWaveRatio
            sineWaveRatio = 0
        } else {
            triangleWaveRatio = location + 0.5
            sineWaveRatio = 1 - triangleWaveRatio
            squareWaveRatio = 0
        }
    }
    
    func computeScaleBaseFrequenciesForKey(withKey: String) {
        scaleBaseFrequencies = [Double]()
        scaleBaseFrequencies!.append(baseFrequencies[withKey]!)
        scaleNotes.removeAll()
        scaleNotes.append(withKey)
        let previousNote = withKey
        var noteIndex = 0
        var previousNoteIndex = possibleNotes.indexOf(previousNote)
        
        // Calculate Major Scale
        for i in 0...(numberOfPads - 2) {
            if i != 2 && i != 6 {
                noteIndex = previousNoteIndex! + 2
            } else {
                noteIndex = previousNoteIndex! + 1
            }
            if noteIndex > baseFrequencies.keys.count - 1 {
                let modIndex = noteIndex % baseFrequencies.keys.count
                scaleNotes.append(possibleNotes[modIndex])
                scaleBaseFrequencies!.append(Double(2 * baseFrequencies[possibleNotes[modIndex]]!))
            } else {
                scaleNotes.append(possibleNotes[noteIndex])
                scaleBaseFrequencies!.append(baseFrequencies[possibleNotes[noteIndex]]!)
            }
            previousNoteIndex = noteIndex;
        }
    }
}

