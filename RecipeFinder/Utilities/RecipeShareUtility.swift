import PDFKit
import SwiftUI

/// High-performance utility for sharing and exporting recipes
class RecipeShareUtility {
    
    // Drawing Configuration
    
    /// Configuration for drawing PDF sections
    private struct SectionDrawConfig {
        let context: CGContext
        let title: String
        let yPos: CGFloat
        let margin: CGFloat
        let width: CGFloat
        let accentColor: UIColor
    }
    
    // Text Format Export (Blazing Fast)
    
    /// Generate a beautiful, well-formatted text version of the recipe
    static func generateTextFormat(recipe: RecipeModel, measurementSystem: MeasurementSystem = .metric) -> String {
        var text = ""
        text.reserveCapacity(2500) // Pre-allocate for performance
        
        let divider = String(repeating: "━", count: 50)
        let sectionDivider = String(repeating: "─", count: 50)
        
        // Title with decorative border
        text += divider + "\n"
        text += "🍽️  \(recipe.name.uppercased())\n"
        text += divider + "\n\n"
        
        // Recipe info in a clean box format
        text += "📋 RECIPE INFORMATION\n"
        text += sectionDivider + "\n"
        text += "📁 Category    : \(recipe.category)\n"
        text += "⭐ Difficulty  : \(recipe.difficulty)\n"
        text += "⏱️  Prep Time   : \(recipe.prepTime)\n"
        text += "🔥 Cook Time   : \(recipe.cookingTime)\n"
        text += "👥 Servings    : \(recipe.baseServings)\n"
        text += "\n"
        
        // Ingredients with prettier formatting
        text += "🥘 INGREDIENTS\n"
        text += sectionDivider + "\n"
        for ingredient in recipe.ingredients {
            let formatted = ingredient.formattedWithUnit(for: 1.0, system: measurementSystem)
            text += "  ✓ \(formatted) \(ingredient.name)\n"
        }
        text += "\n"
        
        // Pre-prep instructions
        if !recipe.prePrepInstructions.isEmpty {
            text += "🔪 PREPARATION STEPS\n"
            text += sectionDivider + "\n"
            for (index, instruction) in recipe.prePrepInstructions.enumerated() {
                text += "  \(index + 1). \(instruction)\n\n"
            }
        }
        
        // Instructions with clear numbering
        text += "👨‍🍳 COOKING INSTRUCTIONS\n"
        text += sectionDivider + "\n"
        for (index, instruction) in recipe.instructions.enumerated() {
            text += "Step \(index + 1):\n"
            text += "\(instruction)\n\n"
        }
        
        // Notes in a highlighted section
        if !recipe.notes.isEmpty {
            text += "📝 CHEF'S NOTES\n"
            text += sectionDivider + "\n"
            text += recipe.notes + "\n\n"
        }
        
        // Footer with branding
        text += divider + "\n"
        text += "Created with ❤️ using RecipeFinder\n"
        text += divider + "\n"
        
        return text
    }
    
    // MARK: - PDF Export
    
    /// Generate a beautiful iPhone-width PDF that looks exactly like the app
    static func generatePDF(
        recipe: RecipeModel,
        measurementSystem: MeasurementSystem = .metric,
        theme: AppTheme.ThemeType = .purple
    ) -> Data? {
        let pageWidth: CGFloat = 390
        let estimatedHeight = calculateContentHeight(recipe: recipe, measurementSystem: measurementSystem)
        let pageHeight = estimatedHeight + 60
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let format = createPDFFormat(for: recipe)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let gradientColors = getGradientColors(for: theme)
        
        return renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext
            
            drawBackground(context: cgContext, pageWidth: pageWidth, pageHeight: pageHeight, colors: gradientColors)
            
            var yPos: CGFloat = 20
            let margin: CGFloat = 20
            let contentWidth = pageWidth - (margin * 2)
            
            yPos = drawTitle(recipe: recipe, context: cgContext, yPos: yPos, margin: margin, contentWidth: contentWidth)
            yPos = drawInfoCards(
                recipe: recipe, context: cgContext, yPos: yPos, 
                margin: margin, contentWidth: contentWidth
            )
            yPos = drawIngredients(
                recipe: recipe, measurementSystem: measurementSystem, 
                context: cgContext, yPos: yPos, margin: margin, 
                contentWidth: contentWidth, accentColor: gradientColors[0]
            )
            
            if !recipe.prePrepInstructions.isEmpty {
                yPos = drawPreparation(
                    recipe: recipe, context: cgContext, yPos: yPos, 
                    margin: margin, contentWidth: contentWidth, accentColor: gradientColors[0]
                )
            }
            
            yPos = drawInstructions(recipe: recipe, context: cgContext, yPos: yPos, margin: margin, contentWidth: contentWidth, accentColor: gradientColors[0])
            
            if !recipe.notes.isEmpty {
                yPos = drawNotes(recipe: recipe, context: cgContext, yPos: yPos, margin: margin, contentWidth: contentWidth, accentColor: gradientColors[0])
            }
            
            drawFooter(context: cgContext, yPos: yPos, pageWidth: pageWidth)
        }
    }
    
    // MARK: - PDF Configuration
    
    private static func createPDFFormat(for recipe: RecipeModel) -> UIGraphicsPDFRendererFormat {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "RecipeFinder",
            kCGPDFContextTitle as String: recipe.name
        ]
        return format
    }
    
    private static func getGradientColors(for theme: AppTheme.ThemeType) -> [UIColor] {
        switch theme {
        case .purple:
            return [
                UIColor(red: 131/255, green: 58/255, blue: 180/255, alpha: 1.0),
                UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1.0),
                UIColor(red: 64/255, green: 224/255, blue: 208/255, alpha: 1.0)
            ]
        default:
            return [
                UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0),
                UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0),
                UIColor(red: 96/255, green: 165/255, blue: 250/255, alpha: 1.0)
            ]
        }
    }
    
    // MARK: - Drawing Functions
    
    private static func drawBackground(context: CGContext, pageWidth: CGFloat, pageHeight: CGFloat, colors: [UIColor]) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: [0.0, 0.5, 1.0]
        ) else { return }
        
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: pageWidth, y: pageHeight),
            options: []
        )
    }
    
    private static func drawTitle(recipe: RecipeModel, context: CGContext, yPos: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        let titleText = recipe.name as NSString
        let titleRect = CGRect(x: margin, y: yPos, width: contentWidth, height: 100)
        let bounds = titleText.boundingRect(
            with: CGSize(width: contentWidth, height: 100),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        
        titleText.draw(in: titleRect, withAttributes: attributes)
        return yPos + bounds.height + 20
    }
    
    private static func drawInfoCards(recipe: RecipeModel, context: CGContext, yPos: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let cardSpacing: CGFloat = 16
        let cardWidth = (contentWidth - cardSpacing) / 2
        let cardHeight: CGFloat = 90
        
        // Time card
        drawGlassCardExact(context: context, rect: CGRect(x: margin, y: yPos, width: cardWidth, height: cardHeight))
        drawTimeCardContent(recipe: recipe, context: context, x: margin, y: yPos)
        
        // Difficulty card
        let rightCardX = margin + cardWidth + cardSpacing
        drawGlassCardExact(context: context, rect: CGRect(x: rightCardX, y: yPos, width: cardWidth, height: cardHeight))
        drawDifficultyCardContent(recipe: recipe, context: context, x: rightCardX, y: yPos)
        
        return yPos + cardHeight + 30
    }
    
    private static func drawTimeCardContent(recipe: RecipeModel, context: CGContext, x: CGFloat, y: CGFloat) {
        ("⏱" as NSString).draw(at: CGPoint(x: x + 15, y: y + 15), withAttributes: [
            .font: UIFont.systemFont(ofSize: 22)
        ])
        
        ("Prep time" as NSString).draw(at: CGPoint(x: x + 50, y: y + 15), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ])
        
        (recipe.prepTime as NSString).draw(at: CGPoint(x: x + 50, y: y + 30), withAttributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ])
        
        ("Cook time" as NSString).draw(at: CGPoint(x: x + 15, y: y + 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ])
        
        (recipe.cookingTime as NSString).draw(at: CGPoint(x: x + 15, y: y + 67), withAttributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ])
    }
    
    private static func drawDifficultyCardContent(recipe: RecipeModel, context: CGContext, x: CGFloat, y: CGFloat) {
        ("📊" as NSString).draw(at: CGPoint(x: x + 15, y: y + 15), withAttributes: [
            .font: UIFont.systemFont(ofSize: 22)
        ])
        
        ("Difficulty" as NSString).draw(at: CGPoint(x: x + 50, y: y + 15), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ])
        
        (recipe.difficulty as NSString).draw(at: CGPoint(x: x + 50, y: y + 30), withAttributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ])
        
        ("Category" as NSString).draw(at: CGPoint(x: x + 15, y: y + 52), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ])
        
        let categoryValue = "\(recipe.category) • \(recipe.baseServings) servings" as NSString
        categoryValue.draw(at: CGPoint(x: x + 15, y: y + 67), withAttributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ])
    }
    
    private static func drawIngredients(
        recipe: RecipeModel,
        measurementSystem: MeasurementSystem,
        context: CGContext,
        yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        accentColor: UIColor
    ) -> CGFloat {
        drawSectionWithCard(
            config: SectionDrawConfig(
                context: context,
                title: "🥘 Ingredients",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            )
        ) {
            var itemY: CGFloat = 20
            for ingredient in recipe.ingredients {
                let formatted = ingredient.formattedWithUnit(for: 1.0, system: measurementSystem)
                let text = "• \(formatted) \(ingredient.name)" as NSString
                let textRect = CGRect(x: 15, y: itemY, width: contentWidth - 30, height: 100)
                let bounds = text.boundingRect(
                    with: textRect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: UIFont.systemFont(ofSize: 14)],
                    context: nil
                )
                text.draw(in: textRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ])
                itemY += max(bounds.height, 24)
            }
            return itemY + 10
        } + 20
    }
    
    private static func drawPreparation(
        recipe: RecipeModel,
        context: CGContext,
        yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        accentColor: UIColor
    ) -> CGFloat {
        drawSectionWithCard(
            config: SectionDrawConfig(
                context: context,
                title: "🔪 Preparation",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            )
        ) {
            var itemY: CGFloat = 20
            for (index, instruction) in recipe.prePrepInstructions.enumerated() {
                let circleRect = CGRect(x: 15, y: itemY, width: 24, height: 24)
                context.setFillColor(accentColor.cgColor)
                context.fillEllipse(in: circleRect)
                
                let numText = "\(index + 1)" as NSString
                let numSize = numText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold)])
                numText.draw(
                    at: CGPoint(x: circleRect.midX - numSize.width / 2, y: circleRect.midY - numSize.height / 2),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white]
                )
                
                let textRect = CGRect(x: 50, y: itemY, width: contentWidth - 65, height: 300)
                let bounds = (instruction as NSString).boundingRect(
                    with: textRect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: UIFont.systemFont(ofSize: 14)],
                    context: nil
                )
                (instruction as NSString).draw(in: textRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ])
                itemY += max(bounds.height + 15, 40)
            }
            return itemY + 10
        } + 20
    }
    
    private static func drawInstructions(
        recipe: RecipeModel,
        context: CGContext,
        yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        accentColor: UIColor
    ) -> CGFloat {
        drawSectionWithCard(
            config: SectionDrawConfig(
                context: context,
                title: "👨‍🍳 Instructions",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            )
        ) {
            var itemY: CGFloat = 20
            for (index, instruction) in recipe.instructions.enumerated() {
                let circleRect = CGRect(x: 15, y: itemY, width: 32, height: 32)
                context.setFillColor(accentColor.cgColor)
                context.fillEllipse(in: circleRect)
                
                let numText = "\(index + 1)" as NSString
                let numSize = numText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold)])
                numText.draw(
                    at: CGPoint(x: circleRect.midX - numSize.width / 2, y: circleRect.midY - numSize.height / 2),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold), .foregroundColor: UIColor.white]
                )
                
                let textRect = CGRect(x: 60, y: itemY, width: contentWidth - 75, height: 300)
                let bounds = (instruction as NSString).boundingRect(
                    with: textRect.size,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: UIFont.systemFont(ofSize: 14)],
                    context: nil
                )
                (instruction as NSString).draw(in: textRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ])
                itemY += max(bounds.height + 20, 45)
            }
            return itemY + 10
        } + 20
    }
    
    private static func drawNotes(
        recipe: RecipeModel,
        context: CGContext,
        yPos: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        accentColor: UIColor
    ) -> CGFloat {
        drawSectionWithCard(
            config: SectionDrawConfig(
                context: context,
                title: "📝 Notes",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            )
        ) {
            let textRect = CGRect(x: 15, y: 20, width: contentWidth - 30, height: 300)
            let bounds = (recipe.notes as NSString).boundingRect(
                with: textRect.size,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: UIFont.systemFont(ofSize: 14)],
                context: nil
            )
            (recipe.notes as NSString).draw(in: textRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ])
            return bounds.height + 30
        }
    }
    
    private static func drawFooter(context: CGContext, yPos: CGFloat, pageWidth: CGFloat) {
        let footerText = "Created with RecipeFinder" as NSString
        let footerSize = footerText.size(withAttributes: [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ])
        footerText.draw(
            at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yPos - 30),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
        )
    }
    
    // MARK: - Helper Functions
    
    private static func drawGlassCardExact(context: CGContext, rect: CGRect) {
        context.saveGState()
        let path = CGPath(roundedRect: rect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        context.addPath(path)
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.fillPath()
        context.addPath(path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
        context.setShadow(offset: CGSize(width: 0, height: 4), blur: 8, color: UIColor.black.withAlphaComponent(0.1).cgColor)
        context.restoreGState()
    }
    
    private static func drawSectionWithCard(
        config: SectionDrawConfig,
        contentBlock: @escaping () -> CGFloat
    ) -> CGFloat {
        // White section title (exactly like app)
        (config.title as NSString).draw(
            at: CGPoint(x: config.margin, y: config.yPos),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        
        let cardY = config.yPos + 32
        
        // Calculate content height (content draws to measure itself)
        config.context.saveGState()
        config.context.translateBy(x: config.margin, y: cardY)
        
        // TEMP: Enable transparency to "hide" the measurement draw
        config.context.setAlpha(0)
        let contentHeight = contentBlock()
        config.context.setAlpha(1)
        
        config.context.restoreGState()
        
        // NOW draw the glass card background
        let cardRect = CGRect(x: config.margin, y: cardY, width: config.width, height: contentHeight)
        let path = CGPath(roundedRect: cardRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        config.context.addPath(path)
        config.context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        config.context.fillPath()
        
        config.context.addPath(path)
        config.context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        config.context.setLineWidth(0.5)
        config.context.strokePath()
        
        // NOW draw the actual visible content
        config.context.saveGState()
        config.context.translateBy(x: config.margin, y: cardY)
        _ = contentBlock()
        config.context.restoreGState()
        
        return cardY + contentHeight
    }
    
    /// Calculate total height needed for content
    private static func calculateContentHeight(recipe: RecipeModel, measurementSystem: MeasurementSystem) -> CGFloat {
        var height: CGFloat = 150 // Title + top padding
        
        // Info cards
        height += 90 + 24
        
        // Ingredients
        height += 32 + 60 + (CGFloat(recipe.ingredients.count) * 24) + 20
        
        // Pre-prep
        if !recipe.prePrepInstructions.isEmpty {
            height += 32 + 60 + (CGFloat(recipe.prePrepInstructions.count) * 45) + 20
        }
        
        // Instructions
        height += 32 + 60 + (CGFloat(recipe.instructions.count) * 60) + 20
        
        // Notes
        if !recipe.notes.isEmpty {
            height += 32 + 100 + 20
        }
        
        return height
    }
}
