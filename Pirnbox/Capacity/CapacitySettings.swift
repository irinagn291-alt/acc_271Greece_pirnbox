import SwiftUI

/// Role: Capacity. Settings sheet. Integer Capacity, contact, onboarding, reset. ReviewScreen goals.
@MainActor
struct CapacitySettings: View {
    @Bindable var watch: BobbinWatch
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var confirmReset = false
    @State private var resetBusy = false

    private var isEmpty: Bool { watch.document.writes.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            BobbinSheetBar(title: "Settings", closeLabel: "Close settings") {
                dismiss()
            }
            if watch.persistFailed {
                BobbinVacancy(
                    image: BobbinArt.emptyList,
                    headline: "Settings could not be saved.",
                    line: "Retry the last write, or reset if the bobbin stays torn.",
                    actionTitle: "Retry",
                    usesAccent: false
                ) {
                    Task { await watch.retryFlush() }
                }
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BobbinPaint.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .confirmationDialog(
            "Erase every stitch, bare mark, and reload?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: BobbinSpace.step(2)) {
            VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                Text(BobbinType.figure(watch.capacity))
                    .font(BobbinType.font(.display))
                    .foregroundStyle(BobbinPaint.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Capacity on this bobbin")
                    .font(BobbinType.font(.body))
                    .foregroundStyle(BobbinPaint.ink)
                Text("Remaining \(BobbinType.figure(watch.remaining)). Only Reload fills the spool.")
                    .font(BobbinType.font(.quiet))
                    .foregroundStyle(BobbinPaint.muted)
            }
            .padding(BobbinSpace.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .bobbinCardSurface()
            .padding(.horizontal, BobbinSpace.step(2))
            .padding(.top, BobbinSpace.step(1))
            Form {
                if isEmpty {
                    Section {
                        Text("No stitches yet. Capacity is ready on the glass.")
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.muted)
                            .listRowBackground(BobbinPaint.surface)
                    }
                }
                Section {
                    Stepper(value: capacityBinding, in: 1 ... 48) {
                        VStack(alignment: .leading, spacing: BobbinSpace.step(1)) {
                            Text("Capacity")
                                .font(BobbinType.font(.body))
                                .foregroundStyle(BobbinPaint.ink)
                            Text(BobbinType.figure(watch.capacity))
                                .font(BobbinType.font(.figure))
                                .foregroundStyle(BobbinPaint.ink)
                        }
                        .frame(minHeight: BobbinSpace.tap)
                    }
                    .listRowBackground(BobbinPaint.surface)
                    if let fault = watch.capacityFault {
                        Text(fault)
                            .font(BobbinType.font(.quiet))
                            .foregroundStyle(BobbinPaint.ink)
                            .listRowBackground(BobbinPaint.surface)
                    }
                    Text("Editing capacity clamps remaining. Only Reload fills the spool.")
                        .font(BobbinType.font(.quiet))
                        .foregroundStyle(BobbinPaint.muted)
                        .listRowBackground(BobbinPaint.surface)
                }
                Section {
                    Button {
                        openURL(BobbinSite.contactURL)
                    } label: {
                        Text("Contact Pirnbox")
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.ink)
                            .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(BobbinPaint.surface)
                    Button {
                        watch.reopenOnboarding()
                    } label: {
                        Text("Re-run onboarding")
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.ink)
                            .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(BobbinPaint.surface)
                    Button {
                        confirmReset = true
                    } label: {
                        Text("Reset all data")
                            .font(BobbinType.font(.body))
                            .foregroundStyle(BobbinPaint.ink)
                            .frame(maxWidth: .infinity, minHeight: BobbinSpace.tap, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .disabled(resetBusy)
                    .listRowBackground(BobbinPaint.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, BobbinSpace.step(4), for: .scrollContent)
            .background(BobbinPaint.background)
        }
    }

    private var capacityBinding: Binding<Int> {
        Binding(
            get: { watch.capacity },
            set: { watch.setCapacity($0) }
        )
    }

    private func resetAll() async {
        resetBusy = true
        await watch.resetAllData()
        resetBusy = false
        dismiss()
    }
}
