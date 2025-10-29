// swiftlint:disable file_length
import PDFKit
import SwiftUI

// swiftlint:disable:next type_body_length

/// High-performance utility for sharing and exporting recipes
class RecipeShareUtility {
    
    // MARK: - Text Format Export (Blazing Fast)
    
    /// Generate a clean text version of the recipe (optimized)
    static func generateTextFormat(recipe: RecipeModel, measurementSystem: MeasurementSystem = .metric) -> String {
        var text = ""
        text.reserveCapacity(2000) // Pre-allocate for performance
        
        // Title
        text += "\(recipe.name)\n"
        text += String(repeating: "=", count: recipe.name.count) + "\n\n"
        
        // Recipe info
        text += "RECIPE INFORMATION\n"
        text += "Category: \(recipe.category)\n"
        text += "Difficulty: \(recipe.difficulty)\n"
        text += "Prep Time: \(recipe.prepTime)\n"
        text += "Cook Time: \(recipe.cookingTime)\n"
        text += "Servings: \(recipe.baseServings)\n\n"
        
        // Ingredients
        text += "INGREDIENTS\n"
        text += String(repeating: "-", count: 11) + "\n"
        for ingredient in recipe.ingredients {
            let formatted = ingredient.formattedWithUnit(for: 1.0, system: measurementSystem)
            text += "- \(formatted) \(ingredient.name)\n"
        }
        text += "\n"
        
        // Pre-prep instructions
        if !recipe.prePrepInstructions.isEmpty {
            text += "PREPARATION\n"
            text += String(repeating: "-", count: 11) + "\n"
            for (index, instruction) in recipe.prePrepInstructions.enumerated() {
                text += "\(index + 1). \(instruction)\n"
            }
            text += "\n"
        }
        
        // Instructions
        text += "INSTRUCTIONS\n"
        text += String(repeating: "-", count: 12) + "\n"
        for (index, instruction) in recipe.instructions.enumerated() {
            text += "\(index + 1). \(instruction)\n\n"
        }
        
        // Notes
        if !recipe.notes.isEmpty {
            text += "NOTES\n"
            text += String(repeating: "-", count: 5) + "\n"
            text += recipe.notes + "\n\n"
        }
        
        // Footer
        text += "\n" + String(repeating: "=", count: 40) + "\n"
        text += "Shared from RecipeFinder\n"
        
        return text
    }
    
    // MARK: - PDF Export (App-Style Screenshot)
    
    // swiftlint:disable:next function_body_length
    
    /// Generate a beautiful iPhone-width PDF that looks exactly like the app
    /// - Parameters:
    ///   - recipe: The recipe to export
    ///   - measurementSystem: The measurement system to use
    ///   - theme: The app theme to apply
    /// - Returns: PDF data or nil if generation fails
    static func generatePDF(recipe: RecipeModel, measurementSystem: MeasurementSystem = .metric, theme: AppTheme.ThemeType = .purple) -> Data? {
        
        // iPhone 14/15 Pro width
        let pageWidth: CGFloat = 390
        
        // Calculate dynamic height based on all content
        let estimatedHeight = calculateContentHeight(recipe: recipe, measurementSystem: measurementSystem)
        let pageHeight = estimatedHeight + 60 // Bottom padding
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "RecipeFinder",
            kCGPDFContextTitle as String: recipe.name
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Theme gradient colors (exactly like app)
        let gradientColors: [UIColor] = theme == .purple ?
            [UIColor(red: 131/255, green: 58/255, blue: 180/255, alpha: 1.0),
             UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1.0),
             UIColor(red: 64/255, green: 224/255, blue: 208/255, alpha: 1.0)] :
            [UIColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0),
             UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0),
             UIColor(red: 96/255, green: 165/255, blue: 250/255, alpha: 1.0)]
        
        let accentColor = gradientColors[0]
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext
            
            // MARK: - FULL GRADIENT BACKGROUND (exactly like app)
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors.map { $0.cgColor } as CFArray,
                locations: [0.0, 0.5, 1.0]
            ) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: pageWidth, y: pageHeight),
                    options: []
                )
            }
            
            var yPos: CGFloat = 20
            let margin: CGFloat = 20
            let contentWidth = pageWidth - (margin * 2)
            
            // MARK: - TITLE (White, centered - exactly like app)
            let titleParagraph = NSMutableParagraphStyle()
            titleParagraph.alignment = .center
            titleParagraph.lineBreakMode = .byWordWrapping
            
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: titleParagraph
            ]
            
            let titleText = recipe.name as NSString
            let titleRect = CGRect(x: margin, y: yPos, width: contentWidth, height: 100)
            let titleBounds = titleText.boundingRect(
                with: CGSize(width: contentWidth, height: 100),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: titleAttrs,
                context: nil
            )
            titleText.draw(in: titleRect, withAttributes: titleAttrs)
            yPos += titleBounds.height + 20
            
            // MARK: - INFO CARDS (Glass morphism - exactly like app)
            let cardSpacing: CGFloat = 16
            let cardWidth = (contentWidth - cardSpacing) / 2
            let cardHeight: CGFloat = 90
            
            // Card 1: Time Info
            let cardY = yPos
            drawGlassCardExact(context: cgContext, rect: CGRect(x: margin, y: cardY, width: cardWidth, height: cardHeight))
            
            // Icon and text for time card
            let timeIcon = "⏱" as NSString
            timeIcon.draw(at: CGPoint(x: margin + 15, y: cardY + 15), withAttributes: [
                .font: UIFont.systemFont(ofSize: 22)
            ])
            
            let timeLabel = "Prep time" as NSString
            timeLabel.draw(at: CGPoint(x: margin + 50, y: cardY + 15), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ])
            
            let prepValue = recipe.prepTime as NSString
            prepValue.draw(at: CGPoint(x: margin + 50, y: cardY + 30), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
            
            let cookLabel = "Cook time" as NSString
            cookLabel.draw(at: CGPoint(x: margin + 15, y: cardY + 52), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ])
            
            let cookValue = recipe.cookingTime as NSString
            cookValue.draw(at: CGPoint(x: margin + 15, y: cardY + 67), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
            
            // Card 2: Difficulty & Category
            let rightCardX = margin + cardWidth + cardSpacing
            drawGlassCardExact(context: cgContext, rect: CGRect(x: rightCardX, y: cardY, width: cardWidth, height: cardHeight))
            
            let diffIcon = "📊" as NSString
            diffIcon.draw(at: CGPoint(x: rightCardX + 15, y: cardY + 15), withAttributes: [
                .font: UIFont.systemFont(ofSize: 22)
            ])
            
            let diffLabel = "Difficulty" as NSString
            diffLabel.draw(at: CGPoint(x: rightCardX + 50, y: cardY + 15), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ])
            
            let diffValue = recipe.difficulty as NSString
            diffValue.draw(at: CGPoint(x: rightCardX + 50, y: cardY + 30), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
            
            let catLabel = "Category" as NSString
            catLabel.draw(at: CGPoint(x: rightCardX + 15, y: cardY + 52), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ])
            
            let catValue = "\(recipe.category) • \(recipe.baseServings) servings" as NSString
            catValue.draw(at: CGPoint(x: rightCardX + 15, y: cardY + 67), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
            
            yPos += cardHeight + 24
            
            // MARK: - INGREDIENTS SECTION (exactly like app)
            yPos = drawSectionWithCard(
                context: cgContext,
                title: "🥘 Ingredients",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            ) {
                var itemY: CGFloat = 20
                
                for ingredient in recipe.ingredients {
                    let formatted = ingredient.formattedWithUnit(for: 1.0, system: measurementSystem)
                    let text = "• \(formatted) \(ingredient.name)" as NSString
                    
                    let textRect = CGRect(x: 15, y: itemY, width: contentWidth - 30, height: 100)
                    let boundingRect = text.boundingRect(
                        with: textRect.size,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: [.font: UIFont.systemFont(ofSize: 14)],
                        context: nil
                    )
                    
                    text.draw(in: textRect, withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.black
                    ])
                    
                    itemY += max(boundingRect.height, 24)
                }
                
                return itemY + 10
            }
            
            yPos += 20
            
            // MARK: - PRE-PREP SECTION (if exists)
            if !recipe.prePrepInstructions.isEmpty {
                yPos = drawSectionWithCard(
                    context: cgContext,
                    title: "📋 Preparation",
                    yPos: yPos,
                    margin: margin,
                    width: contentWidth,
                    accentColor: accentColor
                ) {
                    var itemY: CGFloat = 20
                    
                    for (index, instruction) in recipe.prePrepInstructions.enumerated() {
                        // Circle number
                        let circleRect = CGRect(x: 15, y: itemY, width: 28, height: 28)
                        cgContext.setFillColor(accentColor.cgColor)
                        cgContext.fillEllipse(in: circleRect)
                        
                        let numText = "\(index + 1)" as NSString
                        let numSize = numText.size(withAttributes: [
                            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
                        ])
                        numText.draw(
                            at: CGPoint(
                                x: circleRect.midX - numSize.width / 2,
                                y: circleRect.midY - numSize.height / 2
                            ),
                            withAttributes: [
                                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                                .foregroundColor: UIColor.white
                            ]
                        )
                        
                        // Instruction text
                        let textRect = CGRect(x: 55, y: itemY, width: contentWidth - 70, height: 200)
                        let boundingRect = (instruction as NSString).boundingRect(
                            with: textRect.size,
                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                            attributes: [.font: UIFont.systemFont(ofSize: 14)],
                            context: nil
                        )
                        
                        (instruction as NSString).draw(in: textRect, withAttributes: [
                            .font: UIFont.systemFont(ofSize: 14),
                            .foregroundColor: UIColor.black
                        ])
                        
                        itemY += max(boundingRect.height + 15, 40)
                    }
                    
                    return itemY + 10
                }
                yPos += 20
            }
            
            // MARK: - INSTRUCTIONS SECTION (exactly like app)
            yPos = drawSectionWithCard(
                context: cgContext,
                title: "👨‍🍳 Instructions",
                yPos: yPos,
                margin: margin,
                width: contentWidth,
                accentColor: accentColor
            ) {
                var itemY: CGFloat = 20
                
                for (index, instruction) in recipe.instructions.enumerated() {
                    // Circle number (larger for instructions)
                    let circleRect = CGRect(x: 15, y: itemY, width: 32, height: 32)
                    cgContext.setFillColor(accentColor.cgColor)
                    cgContext.fillEllipse(in: circleRect)
                    
                    let numText = "\(index + 1)" as NSString
                    let numSize = numText.size(withAttributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .bold)
                    ])
                    numText.draw(
                        at: CGPoint(
                            x: circleRect.midX - numSize.width / 2,
                            y: circleRect.midY - numSize.height / 2
                        ),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                            .foregroundColor: UIColor.white
                        ]
                    )
                    
                    // Instruction text
                    let textRect = CGRect(x: 60, y: itemY, width: contentWidth - 75, height: 300)
                    let boundingRect = (instruction as NSString).boundingRect(
                        with: textRect.size,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: [.font: UIFont.systemFont(ofSize: 14)],
                        context: nil
                    )
                    
                    (instruction as NSString).draw(in: textRect, withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.black
                    ])
                    
                    itemY += max(boundingRect.height + 20, 45)
                }
                
                return itemY + 10
            }
            
            yPos += 20
            
            // MARK: - NOTES SECTION (if exists)
            if !recipe.notes.isEmpty {
                yPos = drawSectionWithCard(
                    context: cgContext,
                    title: "📝 Notes",
                    yPos: yPos,
                    margin: margin,
                    width: contentWidth,
                    accentColor: accentColor
                ) {
                    let textRect = CGRect(x: 15, y: 20, width: contentWidth - 30, height: 300)
                    let boundingRect = (recipe.notes as NSString).boundingRect(
                        with: textRect.size,
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: [.font: UIFont.systemFont(ofSize: 14)],
                        context: nil
                    )
                    
                    (recipe.notes as NSString).draw(in: textRect, withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.black
                    ])
                    
                    return boundingRect.height + 30
                }
            }
            
            // MARK: - FOOTER
            yPos = pageHeight - 30
            let footerText = "Created with RecipeFinder" as NSString
            let footerSize = footerText.size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ])
            footerText.draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yPos),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.8)
                ]
            )
        }
        
        return data
    }
    // swiftlint:enable function_body_length
    
    // MARK: - Helper Functions (Optimized for App-Like Look)
    
    /// Draw glass card exactly like the app (with material blur effect simulation)
    private static func drawGlassCardExact(context: CGContext, rect: CGRect) {
        context.saveGState()
        
        let path = CGPath(roundedRect: rect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        
        // White background with transparency (glass effect)
        context.addPath(path)
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.fillPath()
        
        // Subtle border (optional, makes it pop)
        context.addPath(path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
        
        // Subtle shadow
        context.setShadow(offset: CGSize(width: 0, height: 4), blur: 8, color: UIColor.black.withAlphaComponent(0.1).cgColor)
        
        context.restoreGState()
    }
    
    // swiftlint:disable:next function_parameter_count
    
    /// Draw section with white header and glass card content (exactly like app)
    private static func drawSectionWithCard(
        context: CGContext,
        title: String,
        yPos: CGFloat,
        margin: CGFloat,
        width: CGFloat,
        accentColor: UIColor,
        contentBlock: @escaping () -> CGFloat
    ) -> CGFloat {
        // White section title (exactly like app)
        (title as NSString).draw(
            at: CGPoint(x: margin, y: yPos),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        
        let cardY = yPos + 32
        
        // Calculate content height (content draws to measure itself)
        context.saveGState()
        context.translateBy(x: margin, y: cardY)
        
        // TEMP: Enable transparency to "hide" the measurement draw
        context.setAlpha(0)
        let contentHeight = contentBlock()
        context.setAlpha(1)
        
        context.restoreGState()
        
        // NOW draw the glass card background
        let cardRect = CGRect(x: margin, y: cardY, width: width, height: contentHeight)
        let path = CGPath(roundedRect: cardRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
        context.addPath(path)
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.fillPath()
        
        context.addPath(path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
        
        // NOW draw the actual visible content
        context.saveGState()
        context.translateBy(x: margin, y: cardY)
        _ = contentBlock()
        context.restoreGState()
        
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
