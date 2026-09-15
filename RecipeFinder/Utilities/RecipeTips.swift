import TipKit

/// Shown on the filter button in the recipe search screen.
struct CanMakeNowTip: Tip {
    var title: Text { Text("Filter by What You Have") }
    var message: Text? { Text("Tap here to see only recipes you can cook with ingredients already in your pantry.") }
    var image: Image? { Image(systemName: "house.fill") }
}

/// Shown on the cooking mode button in the recipe detail toolbar.
struct CookingModeTip: Tip {
    var title: Text { Text("Cooking Mode") }
    var message: Text? { Text("Step-by-step guidance with the screen always on — perfect for hands-free cooking.") }
    var image: Image? { Image(systemName: "frying.pan.fill") }
}
