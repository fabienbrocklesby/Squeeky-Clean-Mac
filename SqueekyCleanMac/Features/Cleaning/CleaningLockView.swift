import SwiftUI

struct CleaningLockView: View {
    @ObservedObject var viewModel: CleaningLockViewModel
    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            AtmosphericBackdrop(isLocked: viewModel.isLocked)

            GlassEffectContainer(spacing: 24) {
                VStack(spacing: 24) {
                    header
                    lockOrb
                    statusPanel
                    footer
                }
                .padding(28)
            }
        }
        .preferredColorScheme(.dark)
        .alert(item: Binding(get: { viewModel.alert }, set: { _ in viewModel.dismissAlert() })) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshPermissionState()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .glassEffect()
                .glassEffectID("sparkles", in: glassNamespace)

            VStack(alignment: .leading, spacing: 2) {
                Text("Squeeky Clean Mac")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)

                Text("A tiny lock for spotless hardware")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
    }

    private var lockOrb: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.14), lineWidth: 1)
                .frame(width: 204, height: 204)
                .glassEffect()
                .glassEffectID("orb-outer", in: glassNamespace)

            Circle()
                .fill(.white.opacity(viewModel.isLocked ? 0.16 : 0.08))
                .frame(width: 190, height: 190)
                .blur(radius: 18)

            Circle()
                .trim(from: 0, to: viewModel.isLocked ? max(viewModel.unlockProgress, 0.035) : 1)
                .stroke(
                    AngularGradient(
                        colors: [.white.opacity(0.95), .cyan.opacity(0.85), .mint.opacity(0.78), .white.opacity(0.95)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 156, height: 156)
                .opacity(viewModel.isLocked ? 1 : 0.58)
                .animation(.smooth(duration: 0.25), value: viewModel.unlockProgress)

            Image(systemName: viewModel.isLocked ? "lock.fill" : "keyboard")
                .font(.system(size: 52, weight: .semibold, design: .rounded))
                .symbolEffect(.bounce, value: viewModel.isLocked)
                .foregroundStyle(.white)
                .frame(width: 128, height: 128)
                .glassEffect()
                .glassEffectID("lock-orb", in: glassNamespace)
                .shadow(color: .black.opacity(0.22), radius: 18, y: 14)

            if viewModel.isLocked && viewModel.unlockProgress > 0 {
                Text(viewModel.progressLabel)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect()
                    .offset(y: 86)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 212)
    }

    private var statusPanel: some View {
        VStack(spacing: 12) {
            Text(viewModel.statusTitle)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Text(viewModel.statusMessage)
                .font(.callout)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.isLocked && viewModel.permissionState.needsAttention {
                permissionStrip
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if !viewModel.isLocked && viewModel.permissionState.needsAttention {
                Button {
                    viewModel.openSystemSettings()
                } label: {
                    Label(viewModel.permissionState.canLock ? "Review Permissions" : "Open Privacy Settings", systemImage: "switch.2")
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .glassEffect()
        .glassEffectID("status-panel", in: glassNamespace)
    }

    private var permissionStrip: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.permissionRows) { row in
                PermissionPill(row: row)
            }
        }
        .padding(8)
        .glassEffect()
        .glassEffectID("permission-strip", in: glassNamespace)
    }

    private var footer: some View {
        Button {
            viewModel.primaryAction()
        } label: {
            Label(viewModel.primaryActionTitle, systemImage: viewModel.permissionState.canLock ? "wand.and.sparkles" : "hand.raised.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(viewModel.isLocked)
        .animation(.smooth(duration: 0.28), value: viewModel.isLocked)
    }
}

private struct PermissionPill: View {
    let row: PermissionRowState

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: row.isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(row.isGranted ? .mint : .white.opacity(0.48))

            Text(row.title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(row.isGranted ? 0.82 : 0.56))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.white.opacity(row.isGranted ? 0.10 : 0.055), in: Capsule())
    }
}

private struct AtmosphericBackdrop: View {
    let isLocked: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isLocked
                    ? [Color(red: 0.03, green: 0.08, blue: 0.11), Color(red: 0.12, green: 0.18, blue: 0.16), Color(red: 0.05, green: 0.05, blue: 0.07)]
                    : [Color(red: 0.07, green: 0.09, blue: 0.11), Color(red: 0.13, green: 0.17, blue: 0.15), Color(red: 0.06, green: 0.06, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    .white.opacity(isLocked ? 0.22 : 0.15),
                    .cyan.opacity(0.08),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            RadialGradient(
                colors: [.mint.opacity(0.19), .teal.opacity(0.06), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )

            RadialGradient(
                colors: [.white.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 280
            )

            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.54))
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.75), value: isLocked)
    }
}

#Preview {
    CleaningLockView(viewModel: CleaningLockViewModel())
        .frame(width: 420, height: 520)
}
