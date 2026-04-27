import SwiftUI

struct SelfHostedSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var selfHostedConfigController: SelfHostedConfigController
    @EnvironmentObject private var hostedSyncController: HostedSyncController

    let onContinue: (() -> Void)?

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

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.string("auth.selfHosted.step2.title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AVPhotosTheme.textPrimary)

                    TextField("https://photos.example.com", text: $selfHostedConfigController.baseURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AVPhotosTheme.cardSurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(AVPhotosTheme.borderSubtle, lineWidth: 1)
                                }
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.string("auth.selfHosted.step3.title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AVPhotosTheme.textPrimary)

                    TextField("AVPHOTOS_AUTH_TOKEN", text: $selfHostedConfigController.authToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AVPhotosTheme.cardSurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(AVPhotosTheme.borderSubtle, lineWidth: 1)
                                }
                        )
                }

                Text(L10n.string("auth.selfHosted.footer"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AVPhotosTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    Button {
                        selfHostedConfigController.save()
                        Task { await hostedSyncController.refresh() }
                        dismiss()
                        onContinue?()
                    } label: {
                        Text(L10n.string("auth.selfHosted.save"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AVPhotosTheme.brandBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AVPhotosTheme.highlight, in: Capsule())
                    }
                    .disabled(!selfHostedConfigController.hasValidBaseURL)

                    if selfHostedConfigController.isConfigured {
                        Button {
                            selfHostedConfigController.clear()
                            Task { await hostedSyncController.refresh() }
                        } label: {
                            Text(L10n.string("auth.selfHosted.clear"))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AVPhotosTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(AVPhotosTheme.mutedSurface)
                                        .overlay {
                                            Capsule()
                                                .stroke(AVPhotosTheme.borderSubtle, lineWidth: 1)
                                        }
                                )
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
        .onAppear {
            selfHostedConfigController.reload()
        }
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
