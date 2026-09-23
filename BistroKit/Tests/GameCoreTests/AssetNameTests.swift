import Testing
@testable import GameCore

@Suite("AssetName convention")
struct AssetNameTests {
    @Test func followsHandoffConvention() {
        #expect(AssetName.ingredient("tomato") == "ing_tomato")
        #expect(AssetName.dish("bruschetta") == "dish_bruschetta")
        #expect(AssetName.character("margot", .portrait) == "char_margot_portrait")
        #expect(AssetName.staff(.waiter, .idle) == "staff_waiter_idle")
        #expect(AssetName.staff(.chef, .working) == "staff_chef_working")
        #expect(AssetName.story("margot", number: 2) == "bg_story_margot_2")
        #expect(AssetName.station("stove", level: 2) == "station_stove_lv2")
        #expect(AssetName.decoration("plant") == "deco_plant")
        #expect(AssetName.background("main_room") == "bg_main_room")
        #expect(AssetName.uiIcon("settings") == "ui_icon_settings")
        #expect(AssetName.ui("lab_pot") == "ui_lab_pot")
        #expect(AssetName.currency(.gems) == "currency_gems")
    }
}
