import SwiftUI

enum HealthMeasure: String, CaseIterable {
    case prematureDeath = "Premature death"
    case poorHealth = "Poor or fair health"
    case poorPhysicalHealth = "Poor physical health days"
    case poorMentalHealth = "Poor mental health days"
    case lowBirthWeight = "Low birthweight"
    case adultSmoking = "Adult smoking"
    case adultObesity = "Adult obesity"
    case physicalInactivity = "Physical inactivity"
    case excessiveDrinking = "Excessive drinking"
    // Add other measures as needed
    
    var color: Color {
        switch self {
        case .prematureDeath: return .red
        case .poorHealth: return .orange
        case .poorPhysicalHealth: return .yellow
        case .poorMentalHealth: return .green
        case .lowBirthWeight: return .blue
        case .adultSmoking: return .purple
        case .adultObesity: return .pink
        case .physicalInactivity: return .brown
        case .excessiveDrinking: return .cyan
        }
    }
} 