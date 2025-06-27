//
//  BreakManager.swift
//  remeetner
//
//  Created by Alberto Diaz on 25-06-25.
//

import Foundation
import AppKit

/// Manages breaks and overlay
class BreakManager: ObservableObject, BreakManaging {
    private var overlayTimer: Timer?
    private var secondsRemaining: Int = 0
    
    private let settingsModel: SettingsModel
    private let windowManager: WindowManager
    private let audioManager: AudioManager
    
    var isBreakActive: Bool {
        return overlayTimer != nil
    }
    
    init(settingsModel: SettingsModel, windowManager: WindowManager, audioManager: AudioManager) {
        self.settingsModel = settingsModel
        self.windowManager = windowManager
        self.audioManager = audioManager
    }
    
    func startBreak() {
        guard !isBreakActive else { return }
        
        secondsRemaining = Int(settingsModel.breakDuration)
        audioManager.playStartSound()
        
        windowManager.showOverlay(duration: settingsModel.breakDuration) { [weak self] in
            self?.endBreak()
        }
        
        startTimer()
    }
    
    func endBreak() {
        guard isBreakActive else { return }
        
        overlayTimer?.invalidate()
        overlayTimer = nil
        
        audioManager.playEndSound()
        windowManager.hideOverlay()
    }
    
    private func startTimer() {
        overlayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.secondsRemaining > 1 {
                self.secondsRemaining -= 1
                self.updateOverlayView()
            } else {
                self.endBreak()
            }
        }
    }
    
    private func updateOverlayView() {
        windowManager.updateOverlayView(
            secondsRemaining: secondsRemaining,
            totalDuration: Int(settingsModel.breakDuration)
        ) { [weak self] in
            self?.endBreak()
        }
    }
}

/// Manages application sounds
class AudioManager: AudioPlaying {
    func playStartSound() {
        NSSound(named: AppConfiguration.startSoundName)?.play()
    }
    
    func playEndSound() {
        NSSound(named: AppConfiguration.endSoundName)?.play()
    }
}
