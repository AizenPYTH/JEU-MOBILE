import Foundation

/// Dialogue text with the player in it: {player.firstName}, {player.lastName}, {player.LASTNAME},
/// {player.fullName}, {player.rank} (« Inspectrice »…), {player.service} (« BEN-04821 »), and
/// gendered words {g:affecté|affectée|affecté·e} chosen from the player's agreement (masculine,
/// feminine, neutral; the neutral form is optional and falls back to the masculine one).
public enum StoryText {
    public static func resolve(_ text: String, player: StoryPlayer, rank: StoryRank) -> String {
        var out = text
        let form = GrammaticalForm(player.agreement)
        let replacements: [String: String] = [
            "{player.firstName}": player.firstName,
            "{player.lastName}": player.lastName,
            "{player.LASTNAME}": player.lastName.uppercased(),
            "{player.fullName}": "\(player.firstName) \(player.lastName)",
            "{player.rank}": rankTitle(rank, form: form),
            "{player.service}": player.serviceNumber,
        ]
        for (key, value) in replacements { out = out.replacingOccurrences(of: key, with: value) }
        // {g:masc|fem|neutral}
        while let start = out.range(of: "{g:"), let end = out.range(of: "}", range: start.upperBound..<out.endIndex) {
            let forms = out[start.upperBound..<end.lowerBound].split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            let chosen: String
            switch form {
            case .masculine: chosen = forms.first ?? ""
            case .feminine: chosen = forms.count > 1 ? forms[1] : (forms.first ?? "")
            case .neutral: chosen = forms.count > 2 ? forms[2] : (forms.first ?? "")
            }
            out.replaceSubrange(start.lowerBound..<end.upperBound, with: chosen)
        }
        return out
    }

    public enum GrammaticalForm: Sendable {
        case masculine, feminine, neutral

        public init(_ agreement: Agreement) {
            switch agreement {
            case .feminine: self = .feminine
            case .masculine: self = .masculine
            case .neutral: self = .neutral
            }
        }
    }

    /// « Enquêtrice », « Inspecteur senior »… (neutral: « Agent »).
    public static func rankTitle(_ rank: StoryRank, form: GrammaticalForm) -> String {
        let fem = form == .feminine
        if form == .neutral {
            switch rank {
            case .enqueteur: return "Agent"
            case .inspecteur: return "Agent inspecteur"
            case .senior: return "Agent senior"
            case .experimente: return "Agent expérimenté"
            }
        }
        switch rank {
        case .enqueteur: return fem ? "Enquêtrice" : "Enquêteur"
        case .inspecteur: return fem ? "Inspectrice" : "Inspecteur"
        case .senior: return fem ? "Inspectrice senior" : "Inspecteur senior"
        case .experimente: return fem ? "Enquêtrice expérimentée" : "Enquêteur expérimenté"
        }
    }

    /// Placeholders a text may use (the validator rejects any other « {…} »).
    public static let knownPlaceholders = ["{player.firstName}", "{player.lastName}", "{player.LASTNAME}", "{player.fullName}",
                                           "{player.rank}", "{player.service}"]
}
