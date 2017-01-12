import UIKit
import MessageUI

let toolbarColor = UIColor(red: 0.82, green: 0.805, blue: 0.98, alpha: 0.3)
let padOnColor = UIColor(red: 0.9, green: 0.805, blue: 0.95, alpha: 1)
let padOffColor = UIColor(red: 0.82, green: 0.805, blue: 0.98, alpha: 1)
let noteLabelContainerColor = UIColor(red: 0.8, green: 0.65, blue: 0.98, alpha: 1)
let btnBorderColor = UIColor(red: 0.76, green: 0.705, blue: 1, alpha: 1)
let recordOnColor = UIColor(red: 0.99, green: 0.31, blue: 0.30, alpha: 1)
let recordOffColor = UIColor(red: 0.99, green: 0.48, blue: 0.47, alpha: 1)
let shareButtoncolor = UIColor(red: 0.19, green: 0.43, blue: 0.07, alpha: 1)
let octaveStepperColor = UIColor(red: 0.82, green: 0.63, blue: 0.55, alpha: 1)
let octaveStepperBgColor = UIColor.black
let keyStepperColor = UIColor(red: 0.82, green: 0.63, blue: 0.55, alpha: 1)
let keyStepperBgColor = UIColor.black
let fxStepperColor = UIColor(red: 0.82, green: 0.63, blue: 0.55, alpha: 1)
let fxStepperBgColor = UIColor.black
let fxSliderTintColor = UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
var fxSliderThumbColor = UIColor(red: 1, green: 0.90, blue: 0.61, alpha: 1)
let delayTimeSliderThumbColor = UIColor(red: 1, green: 0.90, blue: 0.61, alpha: 1)
let delayWetnessSliderThumbColor = UIColor(red: 0.36, green: 0.65, blue: 0.99, alpha: 1)
let reverbWetnessSliderThumbColor = UIColor(red: 0.50, green: 0.88, blue: 0.99, alpha: 1)
let distortionWetnessSliderThumbColor = UIColor(red: 0.7, green: 0.48, blue: 0.84, alpha: 1)
let changeModeButtonColor = UIColor(red: 0.99, green: 0.58, blue: 0.84, alpha: 1)
let eqCutoffSliderThumbColor = UIColor(red: 0.35, green: 0.99, blue: 0.63, alpha: 1)
let numberOfPads = 9

class SynthViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    weak var delegate: ContainerController?
    let possibleNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let fxTypes = [FXType.DelayTime, FXType.DelayWetness, FXType.ReverbWetness, FXType.DistortionWetness, FXType.CutOffFrequency]
    let backgroundView = UIView(frame: UIScreen.main.bounds)
    let helpBackgroundView = UIView(frame: UIScreen.main.bounds)
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    var padHandler: PadHandler?
    var audioEngine: AudioEngine?
    var noteLabelsContainer: UILabel?
    var noteLabels: [UILabel]?
    var shakeInstructionLabel: UILabel?
    var keyLabel: UILabel?
    var keyChangeLabel: UILabel?
    var keyChangeTimer: Timer?
    var octaveLabel: UILabel?
    var octaveChangeLabel: UILabel?
    var octaveChangeTimer: Timer?
    var fxTypeLabel: UILabel?
    var fxTypeChangeLabel: UILabel?
    var fxTypeChangeTimer: Timer?
    var fxValueLabel: UILabel?
    var keyStepper: UIStepper?
    var octaveStepper: UIStepper?
    var fxStepper: UIStepper?
    var drumSequencer: UIButton?
    var recordButton: UIButton?
    var shareButton: UIButton?
    var startPlaybackButton: UIButton?
    var fxSlider: UISlider?
    var instructionLabel: UILabel?
    var padToTouches = [Int: [UITouch]]()
    var recording = false
    var helpMode = false
    var isPlaying = false
    var hasRemovedLaunchScreen = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let widthOfPad = Int(ceil(Double(Int(screenWidth) - 2 * numberOfPads + 2) / Double(numberOfPads)))
        let heightOfPad = Int(screenHeight - 42)
        backgroundView.backgroundColor = UIColor.black
        backgroundView.isMultipleTouchEnabled = true
        view.addSubview(backgroundView)
        
        noteLabelsContainer = UILabel(frame: CGRect(x: 0, y: 55, width: Int(screenWidth), height: heightOfPad))
        noteLabelsContainer!.backgroundColor = noteLabelContainerColor
        noteLabelsContainer!.isMultipleTouchEnabled = true
        noteLabelsContainer!.isUserInteractionEnabled = true
        backgroundView.addSubview(noteLabelsContainer!)
        var padLabels = [UILabel]()
        for i in 0...(numberOfPads - 1) {
            let pad = UILabel(frame: CGRect(x: (widthOfPad + 1) * i, y: 55, width: widthOfPad, height: heightOfPad))
            pad.backgroundColor = padOffColor
            pad.isMultipleTouchEnabled = true
            padLabels.append(pad);
            backgroundView.addSubview(pad)
        }
        
        let toolbarView = UIView(frame: CGRect(x: 0, y:0, width: screenWidth, height: 55))
        toolbarView.backgroundColor =  toolbarColor
        backgroundView.addSubview(toolbarView)
        
        // Add Octave Stepper
        let octaveStepperFrame = CGRect(x: 2, y: 13.5, width: 45, height: 18)
        octaveStepper = UIStepper(frame: octaveStepperFrame)
        octaveStepper!.value = 4
        octaveStepper!.minimumValue = 1
        octaveStepper!.maximumValue = 8
        octaveStepper!.wraps = true
        octaveStepper!.backgroundColor = octaveStepperBgColor
        octaveStepper!.tintColor = octaveStepperColor
        octaveStepper!.addTarget(self, action: #selector(SynthViewController.changeOctave), for: UIControlEvents.valueChanged)
        toolbarView.addSubview(octaveStepper!)
        
        // Add Key Stepper
        let keyStepperFrame = CGRect(x: 100, y: 13.5, width: 50, height: 18)
        keyStepper = UIStepper(frame: keyStepperFrame)
        keyStepper!.value = 0
        keyStepper!.minimumValue = 0
        keyStepper!.maximumValue = 11
        keyStepper!.wraps = true
        keyStepper!.backgroundColor = keyStepperBgColor
        keyStepper!.tintColor = keyStepperColor
        keyStepper!.addTarget(self, action: #selector(SynthViewController.changeKey), for: UIControlEvents.valueChanged)
        let key = possibleNotes[Int(keyStepper!.value)]
        toolbarView.addSubview(keyStepper!)
        
        // Add Fx Stepper
        let fxStepperFrame = CGRect(x: 198, y: 13.5, width: 50, height: 18)
        fxStepper = UIStepper(frame: fxStepperFrame)
        fxStepper!.value = 0
        fxStepper!.minimumValue = 0
        fxStepper!.maximumValue = 4
        fxStepper!.wraps = true
        fxStepper!.backgroundColor = fxStepperBgColor
        fxStepper!.tintColor = fxStepperColor
        fxStepper!.addTarget(self, action: #selector(SynthViewController.changeFX), for: UIControlEvents.valueChanged)
        toolbarView.addSubview(fxStepper!)
        
        // Add Help Button
        let drumSequencerFrame = CGRect(x: screenWidth - 47, y: 5, width: 45, height: 45)
        drumSequencer = UIButton(frame: drumSequencerFrame)
        drumSequencer!.backgroundColor = changeModeButtonColor
        drumSequencer!.layer.cornerRadius = 15
        drumSequencer!.setTitleColor(UIColor.white, for: UIControlState())
        drumSequencer!.setTitle("D", for: UIControlState())
        drumSequencer!.addTarget(self, action: #selector(SynthViewController.goToDrumSequencer), for: UIControlEvents.touchUpInside)
        toolbarView.addSubview(drumSequencer!)
        
        // Add Record Button
        let recordButtonXPosition = drumSequencerFrame.origin.x - 50
        let recordButtonFrame = CGRect(x: recordButtonXPosition, y: 5, width: 45, height: 45)
        recordButton = UIButton(frame: recordButtonFrame)
        recordButton!.backgroundColor = recordOffColor
        recordButton!.layer.cornerRadius = 22.5
        recordButton!.addTarget(self, action: #selector(SynthViewController.toggleRecord), for: UIControlEvents.touchUpInside)
        toolbarView.addSubview(recordButton!)
        
        // Add Playback Buttons
        let startPlaybackFrame = CGRect(x: recordButtonFrame.origin.x - 50, y: 5, width: 45, height: 45)
        startPlaybackButton = UIButton(frame: startPlaybackFrame)
        startPlaybackButton!.titleLabel!.adjustsFontSizeToFitWidth = true
        startPlaybackButton!.setTitle("▶︎", for: UIControlState())
        startPlaybackButton!.titleLabel!.sizeToFit()
        startPlaybackButton!.addTarget(self, action: #selector(SynthViewController.togglePlayback), for: UIControlEvents.touchUpInside)
        toolbarView.addSubview(startPlaybackButton!)
        
        // Add FX Slider
        let sliderXPosition = fxStepper!.frame.maxX + 5
        let sliderWidth = (startPlaybackButton!.frame.origin.x - fxStepper!.frame.maxX + 4)
        let fxSliderFrame = CGRect(x: sliderXPosition, y: 5, width: sliderWidth, height: 45)
        fxSlider = UISlider(frame: fxSliderFrame)
        fxSlider!.minimumValue = 0
        fxSlider!.maximumValue = 1
        fxSlider!.maximumTrackTintColor = fxSliderTintColor
        fxSlider!.minimumTrackTintColor = delayTimeSliderThumbColor
        fxSlider!.thumbTintColor = delayTimeSliderThumbColor
        fxSlider!.addTarget(self, action: #selector(SynthViewController.fxValueChanged), for: UIControlEvents.valueChanged)
        toolbarView.addSubview(fxSlider!)
        
        audioEngine = AudioEngine(numberOfVoices: numberOfPads, withKey: key, withOctave: Int(octaveStepper!.value))
        padHandler = PadHandler(audioEngine: audioEngine!, padLabels: padLabels)
        
        fxSlider!.value = Float(audioEngine!.delayNode!.delayTime) / 2.0

        if !UserDefaults.standard.bool(forKey: "hasLaunchedSequencer") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedSequencer")
            UserDefaults.standard.synchronize()
            firstLaunchHelpScreen()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goToDrumSequencer() {
        audioEngine!.stopVoices()
        audioEngine!.stopRecording()
        audioEngine!.stopPlayback()
        audioEngine!.reset()
        delegate?.pageWantsPageChange()
    }
    
    func changeOctave() {
        audioEngine!.changeOctave(Int(octaveStepper!.value))
        displayOctaveChangeLabel()
    }
    
    func changeKey() {
        audioEngine!.changeKey(possibleNotes[Int(keyStepper!.value)])
        displayKeyChangeLabel()
    }
    
    func togglePlayback() {
        if isPlaying {
            startPlaybackButton!.setTitle("▶︎", for: UIControlState())
            audioEngine!.stopPlayback()
            isPlaying = false
        } else {
            startPlaybackButton!.setTitle("◼︎", for: UIControlState())
            audioEngine!.startPlayback()
            isPlaying = true
        }
    }
    
    func toggleRecord() {
        if recording {
            recordButton!.backgroundColor = recordOffColor
            audioEngine!.stopRecording()
            recordButton!.layer.removeAllAnimations()
            recordButton!.alpha = 1
            recording = false
        } else if !isPlaying {
            recordButton!.backgroundColor = recordOnColor
            audioEngine!.startRecording()
            UIView.animate(withDuration: 0.8, delay: 0.25, options: [UIViewAnimationOptions.repeat, UIViewAnimationOptions.autoreverse, UIViewAnimationOptions.allowUserInteraction], animations: {
                self.recordButton!.alpha = 0.6
                }, completion: nil)
            recording = true
        }
    }
    
    func addBlurView() -> UIView {
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            self.view.backgroundColor = UIColor.clear
            blurEffectView.frame = self.view.bounds
            return blurEffectView
        }
        else {
            helpBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            return helpBackgroundView
        }
    }
    
    func removeBlurView() {
        blurEffectView.removeFromSuperview()
        helpBackgroundView.removeFromSuperview()
    }
    
    func displayOctaveChangeLabel() {
        if octaveChangeTimer != nil {
            octaveChangeTimer!.invalidate()
            octaveChangeLabel!.removeFromSuperview()
        }
        
        let maxY = octaveStepper!.frame.maxY + 5
        octaveChangeLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: maxY), size: CGSize.zero))
        octaveChangeLabel!.text = "octave " + String(audioEngine!.octave)
        octaveChangeLabel!.textColor = octaveStepperColor
        octaveChangeLabel!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        octaveChangeLabel!.sizeToFit()
        view.addSubview(octaveChangeLabel!)
        
        octaveChangeTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(SynthViewController.removeOctaveChangeLabel), userInfo: nil, repeats: false)
    }
    
    func removeOctaveChangeLabel() {
        octaveChangeLabel!.removeFromSuperview()
        octaveChangeTimer = nil
    }
    
    func displayKeyChangeLabel() {
        if keyChangeTimer != nil {
            keyChangeTimer!.invalidate()
            keyChangeLabel!.removeFromSuperview()
        }
        let maxY = keyStepper!.frame.maxY + 5
        var minX = keyStepper!.frame.minX
        if octaveChangeLabel != nil && octaveChangeLabel!.frame.maxX > minX {
            minX = octaveChangeLabel!.frame.maxX + 5
        }
        keyChangeLabel = UILabel(frame: CGRect(origin: CGPoint(x: minX, y: maxY), size: CGSize.zero))
        keyChangeLabel!.text = "key of " + audioEngine!.key.lowercased() + " maj"
        keyChangeLabel!.textColor = keyStepperColor
        keyChangeLabel!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        keyChangeLabel!.sizeToFit()
        view.addSubview(keyChangeLabel!)
        
        keyChangeTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(SynthViewController.removeKeyChangeLabel), userInfo: nil, repeats: false)
    }
    
    func removeKeyChangeLabel() {
        keyChangeLabel!.removeFromSuperview()
        keyChangeTimer = nil
    }
    
    func displayFXTypeChangeLabel() {
        if fxTypeChangeTimer != nil {
            fxTypeChangeTimer!.invalidate()
            fxTypeChangeLabel!.removeFromSuperview()
        }
        let maxY = fxStepper!.frame.maxY + 5
        var minX = fxStepper!.frame.minX
        if keyChangeLabel != nil && keyChangeLabel!.frame.maxX > minX {
            minX = keyChangeLabel!.frame.maxX + 5
        }
        fxTypeChangeLabel = UILabel(frame: CGRect(origin: CGPoint(x: minX, y: maxY), size: CGSize.zero))
        fxTypeChangeLabel!.text = "fx is " + audioEngine!.fxType.rawValue.lowercased()
        fxTypeChangeLabel!.textColor = fxStepperColor
        fxTypeChangeLabel!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        fxTypeChangeLabel!.sizeToFit()
        view.addSubview(fxTypeChangeLabel!)
        
        fxTypeChangeTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(SynthViewController.removeFXTypeChangeLabel), userInfo: nil, repeats: false)
    }
    
    func removeFXTypeChangeLabel() {
        fxTypeChangeLabel!.removeFromSuperview()
        fxTypeChangeTimer = nil
    }
    
    func firstLaunchHelpScreen() {
        hasRemovedLaunchScreen = false
        let blurView = addBlurView()
        let mainScreenBounds = UIScreen.main.bounds
        let rect = CGRect(x: mainScreenBounds.width / 4, y: mainScreenBounds.height / 4,  width: mainScreenBounds.width / 2, height: mainScreenBounds.height / 2)
        instructionLabel = UILabel(frame: rect)
        instructionLabel!.textAlignment = NSTextAlignment.center
        instructionLabel!.text = "Turn up your volume and plug into headphones or speakers for the best experience. Check out the sweet drum sequencer mode by pressing the D button on the top right."
        instructionLabel!.textColor = padOffColor
        instructionLabel!.numberOfLines = 0
        blurView.addSubview(instructionLabel!)
        view.insertSubview(blurView, aboveSubview: view)
        Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(SynthViewController.removeLaunchViews), userInfo: nil, repeats: false)
    }
    
    func removeLaunchViews() {
        let lock = DispatchQueue(label: "removeLaunchScreen", attributes: [])
        lock.sync(execute: {
            if !self.hasRemovedLaunchScreen {
                self.instructionLabel!.removeFromSuperview()
                self.removeBlurView()
            }
            self.hasRemovedLaunchScreen = true
        })
    }
    
    func toggleHelpScreen() {
        if !helpMode {
            keyLabel = UILabel(frame: keyStepper!.frame)
            keyLabel!.textAlignment = NSTextAlignment.center
            keyLabel!.text = "key of " + audioEngine!.key.lowercased() + "maj"
            keyLabel!.textColor = keyStepperColor
            octaveLabel = UILabel(frame: octaveStepper!.frame)
            octaveLabel!.textAlignment = NSTextAlignment.center
            octaveLabel!.text = "octave " + String(audioEngine!.octave)
            octaveLabel!.textColor = octaveStepperColor
            fxTypeLabel = UILabel(frame: fxStepper!.frame)
            fxTypeLabel!.text = "fx " + audioEngine!.fxType.rawValue.lowercased()
            fxTypeLabel!.textColor = fxStepperColor
            fxTypeLabel!.sizeToFit()
            if fxTypeLabel!.frame.height != fxStepper!.frame.height {
                fxTypeLabel!.frame.size.height = fxStepper!.frame.height
            }
            fxTypeLabel!.textAlignment = NSTextAlignment.center
            var minX = fxSlider!.frame.minX
            if minX > fxSlider!.frame.minX - 5 {
                minX = fxTypeLabel!.frame.maxX + 5
            }
            let minY = fxSlider!.frame.minY
            fxValueLabel = UILabel(frame: CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize.zero))
            fxValueLabel!.textAlignment = NSTextAlignment.center
            fxValueLabel!.text = "fx value " + (NSString(format: "%.2f", audioEngine!.fxValue) as String)
            fxValueLabel!.textColor = fxSliderThumbColor
            fxValueLabel!.sizeToFit()
            if fxValueLabel!.frame.height != fxSlider!.frame.height {
                fxValueLabel!.frame.size.height = fxSlider!.frame.height
            }
            let shakeLabelX = UIScreen.main.bounds.width / 4
            let shakeLabelY = UIScreen.main.bounds.height / 3
            shakeInstructionLabel = UILabel(frame: CGRect(origin: CGPoint(x: shakeLabelX, y: shakeLabelY), size: CGSize.zero));
            shakeInstructionLabel!.text = "shake at any time to reset sound"
            shakeInstructionLabel!.textColor = padOffColor
            shakeInstructionLabel!.sizeToFit()
            
            var counter = 0
            noteLabels = [UILabel]()
            let blurView = addBlurView()
            drumSequencer!.setTitle("✕", for: UIControlState())
            shareButton = UIButton(frame: recordButton!.frame)
            shareButton!.addTarget(self, action: #selector(SynthViewController.shareRecording), for: UIControlEvents.touchUpInside)
            shareButton!.setTitle("⇡", for: UIControlState())
            shareButton!.backgroundColor = shareButtoncolor
            shareButton!.layer.cornerRadius = recordButton!.layer.cornerRadius
            self.view.addSubview(blurView)
            self.view.insertSubview(drumSequencer!, aboveSubview: blurView)
            self.view.insertSubview(keyLabel!, aboveSubview: blurView)
            self.view.insertSubview(octaveLabel!, aboveSubview: blurView)
            self.view.insertSubview(fxTypeLabel!, aboveSubview: blurView)
            self.view.insertSubview(fxValueLabel!, aboveSubview: blurView)
            self.view.insertSubview(shakeInstructionLabel!, aboveSubview: blurView)
            self.view.insertSubview(shareButton!, aboveSubview: blurView)
            noteLabels = [UILabel]()
            for padLabel in padHandler!.padLabels {
                let noteLabel = UILabel(frame: padLabel.frame)
                noteLabel.textAlignment = NSTextAlignment.center
                noteLabel.text = audioEngine!.voiceArray.first!.scaleNotes[counter]
                noteLabel.textColor = padLabel.backgroundColor
                self.view.insertSubview(noteLabel, aboveSubview: blurView)
                noteLabels!.append(noteLabel)
                counter += 1
            }
            helpMode = true
        } else {
            keyLabel!.removeFromSuperview()
            octaveLabel!.removeFromSuperview()
            fxValueLabel!.removeFromSuperview()
            fxTypeLabel!.removeFromSuperview()
            shakeInstructionLabel!.removeFromSuperview()
            shareButton!.removeFromSuperview()
            for noteLabel in noteLabels! {
                noteLabel.removeFromSuperview()
            }
            removeBlurView()
            drumSequencer!.setTitle("?", for: UIControlState())
            helpMode = false
        }
    }
    
    func shareRecording() {
        // TODO: Check can send text otherwise crashes and can send attachment
        if (audioEngine!.playbackOutputFile == nil) {
            return
        }
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        messageVC.body = "Check out my jam with synthia";
        messageVC.addAttachmentData(try! Data(contentsOf: URL(fileURLWithPath: audioEngine!.playbackFileUrl!.path)), typeIdentifier: "audio/mp3", filename: "my jam.mp3")
        messageVC.recipients = [""]
        messageVC.messageComposeDelegate = self;
        
        self.present(messageVC, animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case MessageComposeResult.cancelled:
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed:
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent:
            self.dismiss(animated: true, completion: nil)
        default:
            break;
        }
    }
    
    func fxValueChanged() {
        audioEngine!.changeFXValue(fxSlider!.value)
    }
    
    func changeFX() {
        let fxType = fxTypes[Int(fxStepper!.value)]
        fxSlider!.minimumValue = 0
        fxSlider!.maximumValue = 1
        switch fxType {
            case FXType.DelayTime:
                fxSlider!.thumbTintColor = delayTimeSliderThumbColor
                fxSlider!.minimumTrackTintColor = delayTimeSliderThumbColor
                fxSlider!.value = Float(audioEngine!.delayNode!.delayTime) / 2.0
                audioEngine!.fxValue = Float(audioEngine!.delayNode!.delayTime)
                audioEngine!.fxType = FXType.DelayTime
            case FXType.DelayWetness:
                fxSlider!.thumbTintColor = delayWetnessSliderThumbColor
                fxSlider!.minimumTrackTintColor = delayWetnessSliderThumbColor
                fxSlider!.value = audioEngine!.delayNode!.wetDryMix / 100.0
                audioEngine!.fxValue = audioEngine!.delayNode!.wetDryMix
                audioEngine!.fxType = FXType.DelayWetness
            case FXType.ReverbWetness:
                fxSlider!.thumbTintColor = reverbWetnessSliderThumbColor
                fxSlider!.minimumTrackTintColor = reverbWetnessSliderThumbColor
                fxSlider!.value = Float(audioEngine!.reverbNode!.wetDryMix) / 100.0
                audioEngine!.fxValue = Float(audioEngine!.reverbNode!.wetDryMix)
                audioEngine!.fxType = FXType.ReverbWetness
            case FXType.DistortionWetness:
                fxSlider!.thumbTintColor = distortionWetnessSliderThumbColor
                fxSlider!.minimumTrackTintColor = distortionWetnessSliderThumbColor
                fxSlider!.value = Float(audioEngine!.distortionNode!.wetDryMix) / 100.0
                audioEngine!.fxValue = Float(audioEngine!.distortionNode!.wetDryMix)
                audioEngine!.fxType = FXType.DistortionWetness
            case FXType.CutOffFrequency:
                fxSlider!.minimumValue = 3
                fxSlider!.maximumValue = 10
                fxSlider!.thumbTintColor = eqCutoffSliderThumbColor
                fxSlider!.minimumTrackTintColor = eqCutoffSliderThumbColor
                fxSlider!.value = log(Float(audioEngine!.eqNode!.bands.first!.frequency))
                audioEngine!.fxValue = Float(audioEngine!.eqNode!.bands.first!.frequency)
                audioEngine!.fxType = FXType.CutOffFrequency
        }
        displayFXTypeChangeLabel()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.hasRemovedLaunchScreen {
            self.removeBlurView()
            self.hasRemovedLaunchScreen = true
            return
        }
        let touchesInNoteLabelsContainer = event!.touches(for: noteLabelsContainer!)
        if touchesInNoteLabelsContainer != nil {
            padHandler!.processTouchesBegan(touches)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchesInNoteLabelsContainer = event!.touches(for: noteLabelsContainer!)
        if touchesInNoteLabelsContainer != nil {
            padHandler!.processTouchesMoved(touches)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchesInNoteLabelsContainer = event!.touches(for: noteLabelsContainer!)
        if touchesInNoteLabelsContainer != nil {
            padHandler!.processTouchesEnded(touches)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchesInNoteLabelsContainer = event!.touches(for: noteLabelsContainer!)
        if touchesInNoteLabelsContainer != nil {
            padHandler!.processTouchesEnded(touches)
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
