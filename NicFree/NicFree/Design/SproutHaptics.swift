//
//  SproutHaptics.swift
//  NicFree
//

import CoreHaptics
import os

/// What the sprout feels like in the hand.
///
/// - **Pet:** a soft rustle of leaves, a few light taps that fade out.
/// - **Thirsty pet:** one slow, low, dull bump. Never an error buzz.
/// - **Grow:** a rising hum that ends in a pop as the new leaf, bud or flower opens.
///
/// Silent on devices without a haptic engine and whenever the system turns haptics off.
@MainActor
enum SproutHaptics {

    private static var engine: CHHapticEngine?
    private static let logger = Logger(subsystem: "NicFree", category: "haptics")

    private static func ready() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        if let engine { return engine }
        do {
            let made = try CHHapticEngine()
            made.isAutoShutdownEnabled = true
            // The engine stops when the app goes to the background; start it again on demand.
            made.resetHandler = { [weak made] in try? made?.start() }
            try made.start()
            engine = made
            return made
        } catch {
            logger.error("Haptic engine unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private static func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard let engine = ready() else { return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            logger.error("Haptic pattern did not play: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func tap(_ time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    /// Leaves rustling: four soft taps, each lighter than the last.
    static func pet() {
        play([
            tap(0.00, intensity: 0.55, sharpness: 0.35),
            tap(0.07, intensity: 0.40, sharpness: 0.45),
            tap(0.15, intensity: 0.28, sharpness: 0.50),
            tap(0.25, intensity: 0.16, sharpness: 0.55),
        ])
    }

    /// A tired, gentle bump.
    static func thirstyPet() {
        play([
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05),
                ],
                relativeTime: 0,
                duration: 0.25
            ),
        ])
    }

    /// A hum that swells over `duration`, then a bright pop as the new part opens.
    static func grow(duration: TimeInterval = 0.9) {
        let hum = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ],
            relativeTime: 0,
            duration: duration
        )
        let swell = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.05),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.8, value: 0.45),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.6),
            ],
            relativeTime: 0
        )
        play([hum, tap(duration, intensity: 1, sharpness: 0.7), tap(duration + 0.09, intensity: 0.4, sharpness: 0.8)], curves: [swell])
    }

    /// A single light pop, for each stage passing by in a replay.
    static func pop() {
        play([tap(0, intensity: 0.7, sharpness: 0.6)])
    }
}
