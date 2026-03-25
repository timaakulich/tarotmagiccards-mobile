import SwiftUI

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Theme.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Theme.glassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

struct GradientBackground: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Theme.backgroundGradient.ignoresSafeArea()
            VStack {
                Spacer()
                Ellipse()
                    .fill(Theme.accentRed.opacity(0.3))
                    .frame(width: 300, height: 200)
                    .blur(radius: 80)
                    .offset(y: 60)
            }
            .ignoresSafeArea()
        }
    }
}

enum PillButtonStyle {
    case primary
    case secondary
}

struct PillButton: View {
    let title: String
    var style: PillButtonStyle = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(backgroundView)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Capsule().fill(Theme.backgroundGradient)
        case .secondary:
            Capsule().fill(Theme.glassBackground)
        }
    }
}

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("step \(currentStep)/\(totalSteps)")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 2)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 2)
                }
            }
            .frame(height: 2)
        }
    }

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }
}
