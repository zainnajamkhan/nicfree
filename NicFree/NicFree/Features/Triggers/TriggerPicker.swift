//
//  TriggerPicker.swift
//  NicFree
//

import SwiftUI
import SwiftData

/// The "What set it off?" chips, shared by the craving and slip screens.
///
/// The selection is the stored string: a `CravingTrigger` raw value, or the person's own
/// words for anything the list misses. Words typed before come back as chips, so they're
/// one tap the next time. Tapping the selected chip again clears it.
struct TriggerPicker: View {
    @Binding var selection: String?

    @Query(sort: \CravingEvent.occurredAt, order: .reverse) private var cravings: [CravingEvent]
    @State private var writing = false
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    private static let maxLength = 40

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            FlowLayout {
                ForEach(CravingTrigger.allCases, id: \.self) { value in
                    chip(String(localized: value.title), raw: value.rawValue)
                }
                ForEach(ownWords, id: \.self) { words in
                    chip(words, raw: words)
                }
                Chip(String(localized: "+ Something else"), isOn: writing) {
                    writing.toggle()
                    fieldFocused = writing
                }
            }

            if writing {
                HStack(spacing: Space.s) {
                    TextField("What was it?", text: $draft)
                        .font(Typeface.row)
                        .focused($fieldFocused)
                        .submitLabel(.done)
                        .onSubmit(add)
                        .onChange(of: draft) { _, new in
                            if new.count > Self.maxLength { draft = String(new.prefix(Self.maxLength)) }
                        }
                        .padding(Space.m)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button))
                    Button("Add", action: add)
                        .font(Typeface.row)
                        .disabled(trimmedDraft.isEmpty)
                }
            }
        }
    }

    private func chip(_ title: String, raw: String) -> some View {
        Chip(title, isOn: selection == raw) {
            selection = selection == raw ? nil : raw
        }
    }

    /// Everything typed before, newest first, plus a selection typed just now.
    private var ownWords: [String] {
        var seen = Set<String>()
        var words: [String] = []
        let stored = cravings.compactMap(\.triggerRaw)
        for raw in [selection].compactMap({ $0 }) + stored
        where CravingTrigger(rawValue: raw) == nil && seen.insert(raw.lowercased()).inserted {
            words.append(raw)
        }
        return words
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reuses a matching chip when there is one, so "work" and "Work" don't become two.
    private func add() {
        let text = trimmedDraft
        guard !text.isEmpty else { return }
        if let builtIn = CravingTrigger.allCases.first(where: {
            String(localized: $0.title).caseInsensitiveCompare(text) == .orderedSame
        }) {
            selection = builtIn.rawValue
        } else {
            selection = ownWords.first { $0.caseInsensitiveCompare(text) == .orderedSame } ?? text
        }
        draft = ""
        writing = false
        fieldFocused = false
    }
}
