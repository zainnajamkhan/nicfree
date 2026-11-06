//
//  SproutHaptics.swift
//  NicFree
//

import CoreHaptics
import os

/// What the sprout feels like in the hand.
///
/// - **Pet (tap):** a giggle, or one of a few other styles.
/// - **Purr (press and hold):** a low rumble that breathes until you let go.
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

    // MARK: - Petting

    /// The ways a tap on the sprout can feel. All of them are short, so a few quick taps in
    /// a row stay playful instead of turning into a buzz.
    enum PetStyle: String, CaseIterable, Identifiable {
        /// A soft thump, then a quick little laugh climbing in pitch. The default.
        case giggle
        /// One firm thump that bounces to rest, slower each time, like a spring.
        case boing
        /// Light taps getting crisper, like bubbles popping up.
        case bubbles
        /// A swish of leaves that swells and fades.
        case rustle
        /// Two soft double beats, a heartbeat.
        case heartbeat

        var id: String { rawValue }

        var title: String {
            switch self {
            case .giggle: "Giggle"
            case .boing: "Boing"
            case .bubbles: "Bubbles"
            case .rustle: "Rustle"
            case .heartbeat: "Heartbeat"
            }
        }
    }

    /// Debug builds can pick a style in Settings to compare them on a device. Everyone else
    /// gets the default.
    static var petStyle: PetStyle {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "debugPetStyle"), let style = PetStyle(rawValue: raw) {
            return style
        }
        #endif
        return .giggle
    }

    static func pet(_ style: PetStyle? = nil) {
        switch style ?? petStyle {
        case .giggle:
            play([
                // A dull thump underneath, then laughing taps that rise and trade strong for soft.
                continuous(0, duration: 0.07, intensity: 0.45, sharpness: 0.05),
                tap(0.02, intensity: 0.7, sharpness: 0.25),
                tap(0.10, intensity: 0.55, sharpness: 0.45),
                tap(0.17, intensity: 0.85, sharpness: 0.6),
                tap(0.23, intensity: 0.6, sharpness: 0.7),
                tap(0.30, intensity: 0.9, sharpness: 0.8),
                tap(0.37, intensity: 0.45, sharpness: 0.85),
                tap(0.45, intensity: 0.25, sharpness: 0.9),
            ])
        case .boing:
            play([
                continuous(0, duration: 0.09, intensity: 0.8, sharpness: 0.1),
                tap(0, intensity: 1, sharpness: 0.2),
                tap(0.13, intensity: 0.65, sharpness: 0.35),
                tap(0.30, intensity: 0.42, sharpness: 0.5),
                tap(0.52, intensity: 0.25, sharpness: 0.6),
                tap(0.80, intensity: 0.12, sharpness: 0.7),
            ])
        case .bubbles:
            play((0..<7).map { index in
                let t = Double(index)
                return tap(t * 0.065 + (index.isMultiple(of: 2) ? 0 : 0.012),
                           intensity: Float(0.35 + 0.08 * t),
                           sharpness: Float(0.3 + 0.1 * t))
            })
        case .rustle:
            let hum = continuous(0, duration: 0.45, intensity: 1, sharpness: 0.35)
            let swell = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.1),
                    .init(relativeTime: 0.12, value: 0.55),
                    .init(relativeTime: 0.22, value: 0.3),
                    .init(relativeTime: 0.32, value: 0.5),
                    .init(relativeTime: 0.45, value: 0),
                ],
                relativeTime: 0
            )
            play([hum] + (0..<5).map { tap(Double($0) * 0.09, intensity: 0.3, sharpness: 0.7) }, curves: [swell])
        case .heartbeat:
            play([
                tap(0, intensity: 0.85, sharpness: 0.15), tap(0.11, intensity: 0.55, sharpness: 0.2),
                tap(0.60, intensity: 0.85, sharpness: 0.15), tap(0.71, intensity: 0.55, sharpness: 0.2),
            ])
        }
    }

    /// A tired, gentle bump.
    static func thirstyPet() {
        play([
            continuous(0, duration: 0.25, intensity: 0.3, sharpness: 0.05),
        ])
    }

    // MARK: - Purring (press and hold)

    private static var purrPlayer: CHHapticAdvancedPatternPlayer?

    /// A low rumble that breathes in and out, for as long as the sprout is held. A second of
    /// rapid soft taps, wobbling in strength, looped until `stopPurr`.
    static func startPurr() {
        guard purrPlayer == nil, let engine = ready() else { return }
        let step = 0.045
        let count = Int(1.0 / step)
        let events = (0..<count).map { index -> CHHapticEvent in
            let t = Double(index) * step
            // Two slow swells a second, so it feels like breathing under a purr.
            let swell = 0.5 + 0.5 * sin(t * 2 * .pi * 1.0 - .pi / 2)
            return tap(t, intensity: Float(0.22 + 0.3 * swell), sharpness: 0.08)
        }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            player.loopEnd = 1.0
            try player.start(atTime: CHHapticTimeImmediate)
            purrPlayer = player
        } catch {
            logger.error("Purr did not start: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Stops the purr, and ends on a happy little double tap.
    static func stopPurr() {
        guard let player = purrPlayer else { return }
        try? player.stop(atTime: CHHapticTimeImmediate)
        purrPlayer = nil
        play([tap(0.02, intensity: 0.7, sharpness: 0.5), tap(0.11, intensity: 0.45, sharpness: 0.6)])
    }

    private static func continuous(_ time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time,
            duration: duration
        )
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
