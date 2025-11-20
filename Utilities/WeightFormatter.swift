//
//  WeightFormatter.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct WeightFormatter {
    static func format(_ weight: Double, unit: WeightUnit = .pounds) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        
        let formattedWeight = formatter.string(from: NSNumber(value: weight)) ?? "\(weight)"
        return "\(formattedWeight) \(unit.abbreviation)"
    }
}

enum WeightUnit: String, CaseIterable {
    case pounds = "lbs"
    case kilograms = "kg"
    
    var abbreviation: String {
        return self.rawValue
    }
}

