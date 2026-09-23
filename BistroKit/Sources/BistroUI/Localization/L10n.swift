import Foundation
import GameCore

/// Localized strings from the package String Catalog (`Resources/Localizable.xcstrings`).
/// English is the development language; French is shipped from day one.
public enum L10n {
    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }

    public static func ingredientName(_ id: IngredientID) -> String { string(LocalizationKey.ingredientName(id)) }
    public static func dishName(_ id: RecipeID) -> String { string(LocalizationKey.dishName(id)) }
    public static func stationName(_ id: StationID) -> String { string(LocalizationKey.stationName(id)) }
    public static func regularName(_ id: RegularID) -> String { string(LocalizationKey.regularName(id)) }
    public static func zoneName(_ id: ZoneID) -> String { string(LocalizationKey.zoneName(id)) }
}
