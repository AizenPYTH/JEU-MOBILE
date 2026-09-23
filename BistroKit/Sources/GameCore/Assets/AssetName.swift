/// Asset naming convention shared with the design team (see HANDOFF_INTEGRATION.md).
///
/// The UI must build every asset name through this type, never by hand, so that a
/// convention change is a one-line fix and missing assets can be listed automatically.
public enum AssetName {
    public enum CharacterPose: String, CaseIterable, Sendable {
        case idle, happy, sad, eating, portrait
    }

    public enum StaffPose: String, CaseIterable, Sendable {
        case idle, walking, carrying, cooking
    }

    public enum Currency: String, CaseIterable, Sendable {
        case coins, gems
    }

    public static func ingredient(_ id: IngredientID) -> String { "ing_\(id)" }
    public static func dish(_ id: RecipeID) -> String { "dish_\(id)" }
    public static func character(_ id: RegularID, _ pose: CharacterPose) -> String { "char_\(id)_\(pose.rawValue)" }
    public static func staff(_ role: String, _ pose: StaffPose) -> String { "staff_\(role)_\(pose.rawValue)" }
    public static func station(_ id: StationID, level: Int) -> String { "station_\(id)_lv\(level)" }
    public static func decoration(_ id: DecorationID) -> String { "deco_\(id)" }
    public static func background(_ zone: ZoneID) -> String { "bg_\(zone)" }
    public static func uiIcon(_ name: String) -> String { "ui_icon_\(name)" }
    public static func currency(_ currency: Currency) -> String { "currency_\(currency.rawValue)" }
}

/// String Catalog keys derived from content ids. Content JSON never contains display text.
public enum LocalizationKey {
    public static func ingredientName(_ id: IngredientID) -> String { "ingredient.\(id).name" }
    public static func dishName(_ id: RecipeID) -> String { "dish.\(id).name" }
    public static func dishDescription(_ id: RecipeID) -> String { "dish.\(id).description" }
    public static func stationName(_ id: StationID) -> String { "station.\(id).name" }
    public static func regularName(_ id: RegularID) -> String { "regular.\(id).name" }
    public static func regularBio(_ id: RegularID) -> String { "regular.\(id).bio" }
    public static func regularStory(_ id: RegularID, tier: Int) -> String { "regular.\(id).story.\(tier)" }
    public static func zoneName(_ id: ZoneID) -> String { "zone.\(id).name" }
    public static func decorationName(_ id: DecorationID) -> String { "decoration.\(id).name" }
    public static func category(_ category: DishCategory) -> String { "category.\(category.rawValue)" }
}
