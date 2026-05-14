import SwiftUI

struct MenuBarLockView: View {
    @ObservedObject var viewModel: CleaningLockViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isLocked ? "lock.fill" : "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .glassEffect()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Squeeky Clean Mac")
                        .font(.headline)
                    Text(viewModel.statusTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isLocked {
                ProgressView(value: viewModel.unlockProgress)
                    .progressViewStyle(.linear)

                Text("Hold both Command keys for 3 seconds.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    viewModel.primaryAction()
                } label: {
                    Label(viewModel.primaryActionTitle, systemImage: viewModel.permissionState.canLock ? "wand.and.sparkles" : "hand.raised.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)

                if viewModel.permissionState.needsAttention {
                    Button {
                        viewModel.openSystemSettings()
                    } label: {
                        Label(viewModel.permissionState.canLock ? "Review Permissions" : "Open Privacy Settings", systemImage: "switch.2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding(18)
        .frame(width: 310)
    }
}
