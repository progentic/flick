#if os(iOS)
import SwiftUI
import FlickDomain

public struct TextFlickView: View {
    @Bindable private var model: CaptureScreenModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var writing: Bool
    @State private var deleting: CaptureFeedItem?

    public init(model: CaptureScreenModel) { self.model = model }
    private var palette: FlickPalette { FlickPalette(dark: scheme == .dark, highContrast: contrast == .increased) }

    public var body: some View {
        NavigationStack {
            List {
                composer
                feedback
                feed
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(palette.canvas).foregroundStyle(palette.ink)
            .navigationTitle("Flick")
            .navigationBarTitleDisplayMode(typeSize.isAccessibilitySize ? .inline : .automatic)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !typeSize.isAccessibilitySize {
                    saveButton.padding(16).background(palette.canvas)
                }
            }
            .toolbar {
                if writing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { writing = false }.frame(minHeight: 44)
                    }
                }
            }
            .refreshable { await model.activate() }
            .task { await model.activate() }
            .task { await model.observe() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await model.activate() } }
            }
            .onChange(of: model.saveMessage) { _, message in
                if let message { AccessibilityNotification.Announcement(message).post() }
            }
            .confirmationDialog("Delete note?", isPresented: deletingBinding) {
                Button("Delete note", role: .destructive) {
                    if let item = deleting { Task { await model.delete(item.id) } }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: {
                Text("This removes the note and original text.")
            }
        }.tint(palette.ember)
    }

    private var composer: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                if !typeSize.isAccessibilitySize {
                    Text("A thought worth keeping.").font(.title2.weight(.semibold)).accessibilityAddTraits(.isHeader)
                }
                TextField("Your note", text: $model.draft,
                          prompt: Text("What's on your mind?").foregroundColor(palette.secondary), axis: .vertical)
                    .lineLimit(typeSize.isAccessibilitySize ? 3...12 : 3...8)
                    .font(.body).padding(16)
                    .background(model.saveFailed ? palette.errorSurface : palette.canvas)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(editorBorder, lineWidth: writing || model.saveFailed || contrast == .increased ? 2 : 1))
                    .focused($writing).disabled(model.isSaving || model.captureUnavailable)
                    .accessibilityLabel("Your note").accessibilityIdentifier("thoughtInput")
                if typeSize.isAccessibilitySize { saveButton }
            }.padding(.vertical, typeSize.isAccessibilitySize ? 8 : 16)
        }.listRowBackground(palette.canvas).listRowSeparator(.hidden)
    }

    private var editorBorder: Color {
        if model.saveFailed { return palette.error }
        if writing && model.saveState != .saved { return palette.ember }
        return palette.outline
    }

    private var buttonTitle: String {
        switch model.saveState {
        case .saving: "Saving…"
        case .saved: "Saved"
        case .failed: "Try again"
        case .idle: typeSize.isAccessibilitySize ? "Save" : "Save Note"
        }
    }

    private var buttonFill: Color {
        if model.saveFailed { return palette.errorSurface }
        return model.canSave || model.isSaving ? palette.ember : palette.canvas
    }

    private var buttonInk: Color {
        if model.saveFailed { return palette.error }
        return model.canSave || model.isSaving ? palette.onEmber : palette.secondary
    }

    private var saveButton: some View {
        Button { Task { await model.save() } } label: {
            HStack(spacing: 8) {
                if model.isSaving { ProgressView().tint(buttonInk).accessibilityHidden(true) }
                else if model.saveState == .saved { Image(systemName: "checkmark").accessibilityHidden(true) }
                else if model.saveFailed { Image(systemName: "exclamationmark.circle.fill").accessibilityHidden(true) }
                Text(buttonTitle).fontWeight(.semibold).lineLimit(1).fixedSize()
                    .foregroundColor(buttonInk)
            }
            .frame(maxWidth: .infinity, minHeight: 52).padding(.horizontal, 12)
            .foregroundStyle(buttonInk)
            .background(buttonFill, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(model.saveFailed ? palette.error : palette.outline, lineWidth: 1))
        }
        .buttonStyle(CaptureButtonStyle()).disabled(!model.canSave)
        .accessibilityIdentifier("saveThought")
        .accessibilityLabel(buttonTitle)
        .accessibilityHint("Saves the note on this device.")
    }

    @ViewBuilder private var feedback: some View {
        if model.saveFailed, let message = model.saveMessage {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill").accessibilityHidden(true)
                Text(message).fixedSize(horizontal: false, vertical: true)
            }.font(.callout).foregroundStyle(palette.error)
                .accessibilityElement(children: .combine).accessibilityIdentifier("saveFailure")
                .listRowBackground(palette.errorSurface)
        }
        if let error = model.operationError {
            Text(error).foregroundStyle(palette.error).fixedSize(horizontal: false, vertical: true)
                .listRowBackground(palette.errorSurface)
        }
    }

    @ViewBuilder private var feed: some View {
        Section {
            if model.isLoading {
                ProgressView("Opening notes…").frame(minHeight: 44)
            } else if let error = model.loadError {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                    Text(error).fixedSize(horizontal: false, vertical: true)
                    Button("Try again") { Task { await model.activate() } }.frame(minHeight: 44)
                }.foregroundStyle(palette.error).listRowBackground(palette.errorSurface)
                    .accessibilityIdentifier("loadFailure")
            } else if model.items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No notes yet.").font(.headline)
                    Text("Write a note above.").foregroundStyle(palette.secondary)
                }.padding(.vertical, 8).accessibilityIdentifier("emptyFeed")
                    .listRowBackground(palette.canvas)
            } else {
                ForEach(model.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink {
                            CaptureDetail(model: model, id: item.id, palette: palette)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.note?.summary ?? item.text).font(.body).fixedSize(horizontal: false, vertical: true)
                                Text(item.capture.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption).foregroundStyle(palette.secondary).fixedSize(horizontal: false, vertical: true)
                                if !model.needsRetry(item) { rowStatus(item) }
                            }.padding(.vertical, 8).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle()).accessibilityElement(children: .combine)
                        }.buttonStyle(.plain).accessibilityIdentifier("captureRow")
                        if model.needsRetry(item) { rowStatus(item) }
                    }
                    .listRowBackground(model.needsRetry(item) ? palette.errorSurface : palette.canvas)
                    .swipeActions { Button("Delete", role: .destructive) { deleting = item } }
                    .contextMenu { Button("Delete note", role: .destructive) { deleting = item } }
                }
            }
        } header: {
            Text("Notes").font(typeSize.isAccessibilitySize ? .body.weight(.semibold) : .headline)
                .foregroundStyle(palette.secondary).textCase(nil).accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder private func rowStatus(_ item: CaptureFeedItem) -> some View {
        if model.needsRetry(item) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                    Text("Saved · Note not ready").fixedSize(horizontal: false, vertical: true)
                }.foregroundStyle(palette.error)
                Button("Retry") { Task { await model.retry(item.id) } }
                    .buttonStyle(.borderless)
                    .frame(minHeight: 44).disabled(model.retrying.contains(item.id))
                    .accessibilityIdentifier("retryNote-" + item.id.uuidString)
            }.font(.callout)
        } else if item.note == nil {
            HStack(alignment: .top, spacing: 8) {
                ProgressView().tint(palette.secondary).accessibilityLabel("Finishing note")
                Text("Saved · Finishing note…").fixedSize(horizontal: false, vertical: true)
            }.font(.callout).foregroundStyle(palette.secondary)
        } else {
            Text("Note ready").font(.caption).foregroundStyle(palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var deletingBinding: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }
}

private struct CaptureButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.98)
    }
}

private struct CaptureDetail: View {
    @Bindable var model: CaptureScreenModel
    let id: UUID
    let palette: FlickPalette
    var body: some View {
        List {
            if let item = model.items.first(where: { $0.id == id }) {
                Section(item.note == nil ? "Saved text" : "Note") {
                    Text(item.note?.fullText ?? item.text).textSelection(.enabled)
                }
                if model.needsRetry(item) {
                    Section {
                        Text("Saved · Note not ready").foregroundStyle(palette.error)
                        Button("Retry") { Task { await model.retry(id) } }.frame(minHeight: 44)
                    }
                }
                Section("Original capture") {
                    Text(item.text).textSelection(.enabled)
                    Text(item.capture.createdAt, format: .dateTime).foregroundStyle(palette.secondary)
                }
            }
        }
        .navigationTitle("Note").navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden).background(palette.canvas).foregroundStyle(palette.ink)
    }
}
#endif
