//
//  Item.swift
//  Legal Week Cite Checker
//
//  Created by Kevin Keller on 3/26/25.
//

import Foundation
import SwiftData

// A basic model class that represents a timestamped item
// This is a template class that can be used as a starting point
// for creating new data models in the app
@Model
final class Item {
    // The timestamp when the item was created
    var timestamp: Date
    
    // Creates a new Item with the given timestamp
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
