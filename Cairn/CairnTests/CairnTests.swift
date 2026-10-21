//
//  CairnTests.swift
//  CairnTests
//

import Foundation
import Testing
@testable import Cairn

/// "1 free days" is the kind of slip that makes an app feel unfinished.
@Suite("Inflection")
struct InflectionTests {

    @Test("One day is singular, other counts are plural")
    func dayCounts() {
        #expect(String(inflecting: "^[\(1) free day](inflect: true)") == "1 free day")
        #expect(String(inflecting: "^[\(2) free day](inflect: true)") == "2 free days")
        #expect(String(inflecting: "Next: ^[\(1) day](inflect: true)") == "Next: 1 day")
        #expect(String(inflecting: "^[\(90) day](inflect: true)") == "90 days")
    }
}
