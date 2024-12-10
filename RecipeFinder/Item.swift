//
//  Item.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
