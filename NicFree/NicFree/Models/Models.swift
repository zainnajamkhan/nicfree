import Foundation
import SwiftData

// MARK: - Vocabulary

/// Enums are persisted as raw strings rather than as Codable properties. SwiftData
/// stores Codable values as opaque blobs, which makes them unusable inside
/// `#Predicate` and awkward to mirror through CloudKit. The typed accessors on each
/// model keep call sites clean.

enum NicotineForm: String, CaseIterable, Sendable {
    case vape
    case cigarette
    case pouch
    case shisha
}

/// What one unit of consumption is, which differs per form. Vaping is continuous
/// rather than discrete, so its units are containers of liquid, never puffs.
enum ConsumptionUnit: String, CaseIterable, Sendable {
    case disposable
    case pod
    case millilitre
    case cigarette
    case pouch
    case session

    var title: LocalizedStringResource {
        switch self {
        case .disposable: "disposable"
        case .pod: "pod"
        case .millilitre: "ml of liquid"
        case .cigarette: "cigarette"
        case .pouch: "pouch"
        case .session: "session"
        }
    }
}

/// How much was used on a slip day. Deliberately coarse: a vaper cannot answer
/// "how many puffs" honestly, so asking guarantees either a blank field or an
/// invented number. Intensity never affects the hero number.
enum UsageIntensity: String, CaseIterable, Sendable {
    case fewPuffs
    case several
    case usual
    case moreThanUsual

    var title: LocalizedStringResource {
        switch self {
        case .fewPuffs: "Just a little"
        case .several: "Several times"
        case .usual: "My usual amount"
        case .moreThanUsual: "More than usual"
        }
    }
}

/// Drawn from NCI and NSW Health vaping cessation material rather than invented.
enum CravingTrigger: String, CaseIterable, Sendable {
    case stress
    case phone
    case afterMeal
    case coffee
    case alcohol
    case social
    case sawSomeoneVape
    case driving
    case waiting
    case boredom
    case loneliness
    case routine

    var title: LocalizedStringResource {
        switch self {
        case .stress: "Stress"
        case .phone: "On my phone"
        case .afterMeal: "After a meal"
        case .coffee: "Coffee"
        case .alcohol: "Drinking"
        case .social: "Around other people"
        case .sawSomeoneVape: "Saw someone vape"
        case .driving: "Driving"
        case .waiting: "Waiting around"
        case .boredom: "Bored"
        case .loneliness: "Lonely"
        case .routine: "Just habit"
        }
    }

    var symbolName: String {
        switch self {
        case .stress: "bolt.fill"
        case .phone: "iphone"
        case .afterMeal: "fork.knife"
        case .coffee: "cup.and.saucer.fill"
        case .alcohol: "wineglass.fill"
        case .social: "person.2.fill"
        case .sawSomeoneVape: "eye.fill"
        case .driving: "car.fill"
        case .waiting: "clock.fill"
        case .boredom: "zzz"
        case .loneliness: "person.fill"
        case .routine: "arrow.trianglehead.2.clockwise"
        }
    }
}

// MARK: - Habit

/// The thing being quit, plus the baseline used to estimate what abstaining saved.
///
/// Baseline is per week because that is how vapers actually describe their use.
/// Daily figures are derived, never entered.
@Model
final class Habit {
    var formRaw: String = NicotineForm.vape.rawValue
    var unitRaw: String = ConsumptionUnit.disposable.rawValue

    var baselineUnitsPerWeek: Double = 0
    var costPerUnit: Double = 0
    var nicotineMgPerUnit: Double = 0
    var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    var quitStartedAt: Date = Date()

    /// Written by the user during onboarding, in their own words, and shown back to
    /// them at the moment of a craving. The strongest single intervention available.
    var reasons: [String] = []

    /// The last day the app was opened, so a return after time away can ask about the days
    /// it did not see. Optional and additive: older stores simply start without it.
    var lastCheckedThrough: Date?

    /// The opt-in evening reminder, as minutes after midnight. Nil means off, the default.
    var eveningReminderMinute: Int?

    init(
        form: NicotineForm = .vape,
        unit: ConsumptionUnit = .disposable,
        baselineUnitsPerWeek: Double = 0,
        costPerUnit: Double = 0,
        nicotineMgPerUnit: Double = 0,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        quitStartedAt: Date = Date(),
        reasons: [String] = []
    ) {
        self.formRaw = form.rawValue
        self.unitRaw = unit.rawValue
        self.baselineUnitsPerWeek = baselineUnitsPerWeek
        self.costPerUnit = costPerUnit
        self.nicotineMgPerUnit = nicotineMgPerUnit
        self.currencyCode = currencyCode
        self.quitStartedAt = quitStartedAt
        self.reasons = reasons
    }

    var form: NicotineForm {
        get { NicotineForm(rawValue: formRaw) ?? .vape }
        set { formRaw = newValue.rawValue }
    }

    var unit: ConsumptionUnit {
        get { ConsumptionUnit(rawValue: unitRaw) ?? .disposable }
        set { unitRaw = newValue.rawValue }
    }

    var baselineUnitsPerDay: Double { baselineUnitsPerWeek / 7 }
    var baselineDailyCost: Double { baselineUnitsPerDay * costPerUnit }
    var baselineDailyNicotineMg: Double { baselineUnitsPerDay * nicotineMgPerUnit }
}

// MARK: - Day record

/// A record exists **only** for a day on which nicotine was used.
///
/// The absence of a record is what makes a day free, which is why the app never
/// asks for a daily check in: a free day costs the user zero interactions, and
/// there is no blank state to feel guilty about.
@Model
final class DayRecord {
    /// Always normalised with `Calendar.startOfDay(for:)`.
    var day: Date = Date()
    var intensityRaw: String?
    var note: String?

    init(day: Date, intensity: UsageIntensity? = nil, note: String? = nil) {
        self.day = day
        self.intensityRaw = intensity?.rawValue
        self.note = note
    }

    var intensity: UsageIntensity? {
        get { intensityRaw.flatMap(UsageIntensity.init(rawValue:)) }
        set { intensityRaw = newValue?.rawValue }
    }
}

// MARK: - Craving

/// Logged whether or not it was resisted. A craving that ended in use is data, not
/// a confession, and the copy around it has to read that way.
@Model
final class CravingEvent {
    var occurredAt: Date = Date()
    var heldOutSeconds: Int = 0
    var resisted: Bool = true
    var triggerRaw: String?
    var note: String?

    init(
        occurredAt: Date = Date(),
        heldOutSeconds: Int = 0,
        resisted: Bool = true,
        trigger: CravingTrigger? = nil,
        note: String? = nil
    ) {
        self.occurredAt = occurredAt
        self.heldOutSeconds = heldOutSeconds
        self.resisted = resisted
        self.triggerRaw = trigger?.rawValue
        self.note = note
    }

    var trigger: CravingTrigger? {
        get { triggerRaw.flatMap(CravingTrigger.init(rawValue:)) }
        set { triggerRaw = newValue?.rawValue }
    }
}
