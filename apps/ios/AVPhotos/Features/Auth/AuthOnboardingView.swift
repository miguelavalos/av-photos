import SwiftUI

struct AuthOnboardingView: View {
    @Binding var authOptionsArePresented: Bool
    let accountIsAvailable: Bool
    let onContinueWithApple: () async throws -> Void
    let onContinueWithGoogle: () async throws -> Void
    let onSkip: () -> Void

    @State private var activeProvider: AuthProvider?
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var isShowingSelfHostedSetup = false
    @GestureState private var authOptionsDragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AVPhotosTheme.onboardingBackground.ignoresSafeArea()

                OnboardingBackdrop()
                    .overlay {
                        LinearGradient(
                            colors: [
                                AVPhotosTheme.brandBlack.opacity(0.04),
                                AVPhotosTheme.brandBlack.opacity(authOptionsArePresented ? 0.4 : 0.22),
                                AVPhotosTheme.brandBlack.opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .blur(radius: authOptionsArePresented ? 6 : 0)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: max(proxy.safeAreaInsets.top + 96, authOptionsArePresented ? 128 : 148))

                    FeatureCallout(compact: authOptionsArePresented)

                    Spacer(minLength: authOptionsArePresented ? 24 : 94)

                    if authOptionsArePresented {
                        AuthOptionsPanel(
                            accountIsAvailable: accountIsAvailable,
                            activeProvider: activeProvider,
                            onAppleTap: startAppleSignIn,
                            onGoogleTap: startGoogleSignIn,
                            onSelfHostedTap: { isShowingSelfHostedSetup = true },
                            onSkip: onSkip
                        )
                        .padding(.horizontal, 14)
                        .padding(.bottom, max(12, proxy.safeAreaInsets.bottom))
                        .offset(y: authOptionsDragOffset)
                        .gesture(authOptionsDismissGesture)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        CallToActionSection(
                            accountIsAvailable: accountIsAvailable,
                            action: {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                    authOptionsArePresented = true
                                }
                            },
                            skipAction: onSkip
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .overlay(alignment: .top) {
                    BrandHeaderBadge()
                        .padding(.top, proxy.safeAreaInsets.top + 8)
                }
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.88), value: authOptionsArePresented)
        .alert(L10n.string("auth.alert.continueFailed.title"), isPresented: $isShowingError) {
            Button(L10n.string("auth.alert.close"), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $isShowingSelfHostedSetup) {
            SelfHostedSetupSheet(onContinue: onSkip)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func startAppleSignIn() {
        guard accountIsAvailable else {
            errorMessage = L10n.string("auth.error.unavailable")
            isShowingError = true
            return
        }
        guard activeProvider == nil else { return }
        activeProvider = .apple

        Task {
            do {
                try await onContinueWithApple()
                await MainActor.run {
                    authOptionsArePresented = false
                    activeProvider = nil
                }
            } catch {
                await MainActor.run {
                    activeProvider = nil
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }

    private func startGoogleSignIn() {
        guard accountIsAvailable else {
            errorMessage = L10n.string("auth.error.unavailable")
            isShowingError = true
            return
        }
        guard activeProvider == nil else { return }
        activeProvider = .google

        Task {
            do {
                try await onContinueWithGoogle()
                await MainActor.run {
                    authOptionsArePresented = false
                    activeProvider = nil
                }
            } catch {
                await MainActor.run {
                    activeProvider = nil
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }

    private var authOptionsDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($authOptionsDragOffset) { value, state, _ in
                state = max(0, value.translation.height)
            }
            .onEnded { value in
                let shouldDismiss =
                    value.translation.height > 120 ||
                    value.predictedEndTranslation.height > 180

                guard shouldDismiss else { return }

                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                    authOptionsArePresented = false
                }
            }
    }
}

private enum AuthProvider {
    case apple
    case google
}

private struct FeatureCallout: View {
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 14 : 18) {
            HeroBadge(size: compact ? 104 : 124)

            VStack(spacing: compact ? 10 : 12) {
                Text(L10n.string("auth.feature.title"))
                    .font(.system(size: compact ? 26 : 30, weight: .bold))
                    .foregroundStyle(AVPhotosTheme.textInverse)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.string("auth.feature.subtitle"))
                    .font(.system(size: compact ? 15 : 16, weight: .medium))
                    .foregroundStyle(AVPhotosTheme.textInverse.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, compact ? 18 : 14)
                    .frame(maxWidth: 320)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, compact ? 16 : 18)
            .frame(maxWidth: 350)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AVPhotosTheme.brandBlack.opacity(0.82))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct BrandHeaderBadge: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AVPhotosTheme.highlight)

            Text("AV Photos")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AVPhotosTheme.brandBlack)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(AVPhotosTheme.brandWhite, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 26, y: 10)
    }
}

private struct HeroBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AVPhotosTheme.brandBlack.opacity(0.8))
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.44), radius: 34, y: 22)

            Circle()
                .stroke(AVPhotosTheme.highlight.opacity(0.22), lineWidth: 1)
                .frame(width: size + 18, height: size + 18)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AVPhotosTheme.highlight.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: size / 1.5
                    )
                )
                .frame(width: size * 0.86, height: size * 0.86)

            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: size * 0.58, height: size * 0.58)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }

            Image(systemName: "photo.stack.fill")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(AVPhotosTheme.highlight)
        }
    }
}

private struct CallToActionSection: View {
    let accountIsAvailable: Bool
    let action: () -> Void
    let skipAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button(action: action) {
                Text(accountIsAvailable ? L10n.string("auth.cta.continue") : L10n.string("auth.cta.localMode"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AVPhotosTheme.brandBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AVPhotosTheme.highlight, in: Capsule())
            }
            .disabled(!accountIsAvailable)

            Text(accountIsAvailable ? L10n.string("auth.cta.subtitle.available") : L10n.string("auth.cta.subtitle.unavailable"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AVPhotosTheme.textInverse.opacity(0.76))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button(L10n.string("auth.cta.skip"), action: skipAction)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AVPhotosTheme.textInverse.opacity(0.88))
        }
    }
}

private struct AuthOptionsPanel: View {
    let accountIsAvailable: Bool
    let activeProvider: AuthProvider?
    let onAppleTap: () -> Void
    let onGoogleTap: () -> Void
    let onSelfHostedTap: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 52, height: 5)
                .padding(.top, 2)

            Text(L10n.string("auth.options.title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AVPhotosTheme.textInverse)

            ProductLaneCard(
                title: L10n.string("auth.path.hosted.title"),
                detail: L10n.string("auth.path.hosted.detail"),
                buttonTitle: L10n.string("auth.path.hosted.cta"),
                action: {}
            )

            VStack(spacing: 12) {
                ProviderButton(
                    title: L10n.string("auth.option.apple"),
                    systemImage: "apple.logo",
                    isLoading: activeProvider == .apple,
                    action: onAppleTap
                )

                ProviderButton(
                    title: L10n.string("auth.option.google"),
                    systemImage: "globe",
                    isLoading: activeProvider == .google,
                    action: onGoogleTap
                )
            }
            .disabled(!accountIsAvailable)

            ProductLaneCard(
                title: L10n.string("auth.path.selfHosted.title"),
                detail: L10n.string("auth.path.selfHosted.detail"),
                buttonTitle: L10n.string("auth.path.selfHosted.cta"),
                action: onSelfHostedTap
            )

            ProductLaneCard(
                title: L10n.string("auth.path.local.title"),
                detail: L10n.string("auth.path.local.detail"),
                buttonTitle: L10n.string("auth.path.local.cta"),
                action: onSkip
            )

            Text(L10n.string("auth.options.detail"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AVPhotosTheme.textInverse.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        )
    }
}

private struct ProviderButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(AVPhotosTheme.brandBlack)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 16, weight: .bold))

                Spacer()
            }
            .foregroundStyle(AVPhotosTheme.brandBlack)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(AVPhotosTheme.highlight, in: Capsule())
        }
        .disabled(isLoading)
    }
}

private struct ProductLaneCard: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AVPhotosTheme.textInverse)

            Text(detail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AVPhotosTheme.textInverse.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AVPhotosTheme.brandBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AVPhotosTheme.highlight, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        )
    }
}

private struct SelfHostedSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.string("auth.selfHosted.title"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AVPhotosTheme.textPrimary)

                    Text(L10n.string("auth.selfHosted.subtitle"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AVPhotosTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                setupStep(
                    number: "1",
                    title: L10n.string("auth.selfHosted.step1.title"),
                    detail: L10n.string("auth.selfHosted.step1.detail")
                )
                setupStep(
                    number: "2",
                    title: L10n.string("auth.selfHosted.step2.title"),
                    detail: "AVPHOTOS_AVAPPS_API_BASE_URL"
                )
                setupStep(
                    number: "3",
                    title: L10n.string("auth.selfHosted.step3.title"),
                    detail: "AVPHOTOS_AUTH_TOKEN"
                )

                Text(L10n.string("auth.selfHosted.footer"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AVPhotosTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    dismiss()
                    onContinue()
                } label: {
                    Text(L10n.string("auth.selfHosted.continue"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AVPhotosTheme.brandBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AVPhotosTheme.highlight, in: Capsule())
                }
            }
            .padding(24)
        }
        .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
    }

    private func setupStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AVPhotosTheme.brandBlack)
                .frame(width: 28, height: 28)
                .background(AVPhotosTheme.highlight, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AVPhotosTheme.textPrimary)

                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AVPhotosTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AVPhotosTheme.cardSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AVPhotosTheme.borderSubtle, lineWidth: 1)
                }
        )
    }
}

private struct OnboardingBackdrop: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AVPhotosTheme.highlight.opacity(0.1))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
                .offset(x: -110, y: -220)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 220, height: 220)
                .blur(radius: 16)
                .offset(x: 130, y: -140)

            Circle()
                .fill(AVPhotosTheme.highlight.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 20)
                .offset(x: 140, y: 260)
        }
    }
}
