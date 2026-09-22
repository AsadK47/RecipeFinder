import TipKit

/// Shown on the cooking mode button in the recipe detail toolbar.
struct CookingModeTip: Tip {
    var title: Text { Text("Cooking Mode") }
    var message: Text? { Text("Step-by-step guidance with the screen always on — perfect for hands-free cooking.") }
    var image: Image? { Image(systemName: "frying.pan.fill") }
    var options: [any TipOption] { [Tips.MaxDisplayCount(1)] }
}
