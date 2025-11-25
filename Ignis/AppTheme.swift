import SwiftUI

extension Color {

    static let appBackground = Color(red: 28/255, green: 25/255, blue: 23/255)
    static let appSurface = Color(red: 38/255, green: 35/255, blue: 33/255)
    static let appCard = Color(red: 48/255, green: 44/255, blue: 41/255)

    static let appPrimary = Color(red: 255/255, green: 138/255, blue: 76/255)
    static let appSecondary = Color(red: 255/255, green: 183/255, blue: 107/255)
    static let appAccent = Color(red: 255/255, green: 206/255, blue: 146/255)

    static let appTextPrimary = Color(red: 250/255, green: 248/255, blue: 246/255)
    static let appTextSecondary = Color(red: 190/255, green: 185/255, blue: 180/255)
    static let appTextTertiary = Color(red: 140/255, green: 135/255, blue: 130/255)

    static let appSuccess = Color(red: 134/255, green: 239/255, blue: 172/255)
    static let appWarning = Color(red: 251/255, green: 191/255, blue: 36/255)
    static let appError = Color(red: 248/255, green: 113/255, blue: 113/255)
    static let appInfo = Color(red: 96/255, green: 165/255, blue: 250/255)

    static let appButtonPrimary = Color(red: 255/255, green: 138/255, blue: 76/255)
    static let appButtonSecondary = Color(red: 68/255, green: 64/255, blue: 61/255)
    static let appBorder = Color(red: 68/255, green: 64/255, blue: 61/255)

    static let appGradientPrimary = LinearGradient(
        colors: [appPrimary, appSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appGradientBackground = LinearGradient(
        colors: [
            Color(red: 28/255, green: 25/255, blue: 23/255),
            Color(red: 33/255, green: 30/255, blue: 28/255),
            Color(red: 38/255, green: 35/255, blue: 33/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appGradientCard = LinearGradient(
        colors: [
            Color(red: 48/255, green: 44/255, blue: 41/255),
            Color(red: 53/255, green: 49/255, blue: 46/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let wsOrange = appPrimary
    static let wsYellow = appSecondary
    static let wsRed = appError
    static let wsDark = appBackground

    static let lightOrange = appPrimary
    static let softOrange = appSecondary
    static let cream = appCard
    static let warmGray = appTextSecondary
    static let lightGray = appBorder
    static let darkText = appTextPrimary
}

extension View {

    func appCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appGradientCard)
                    .shadow(color: Color.appPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
            )
    }

    func appButtonPrimary() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appGradientPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
            )
    }

    func appButtonSecondary() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appButtonSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
    }

    func appInputStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
    }
}

extension Font {

    static let appTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let appHeadline = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let appSubheadline = Font.system(size: 18, weight: .medium, design: .default)
    static let appBody = Font.system(size: 16, weight: .regular, design: .default)
    static let appCaption = Font.system(size: 14, weight: .medium, design: .default)
    static let appSmall = Font.system(size: 12, weight: .regular, design: .default)
}

extension Animation {
    static let appSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let appEaseOut = Animation.easeOut(duration: 0.3)
    static let appEaseIn = Animation.easeIn(duration: 0.2)
}
