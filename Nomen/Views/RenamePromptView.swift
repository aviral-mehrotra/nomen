import SwiftUI

struct RenamePromptView: View {
    @Bindable var viewModel: RenamePromptViewModel

    private enum Field: Hashable {
        case name, tags
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ThumbnailView(url: viewModel.screenshot.url)

            TextField("What is this?", text: $viewModel.name)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .focused($focusedField, equals: .name)
                .onSubmit { viewModel.save() }

            TextField("Add tags (comma separated)…", text: $viewModel.tagsInput)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .focused($focusedField, equals: .tags)
                .onSubmit { viewModel.save() }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            HStack(spacing: 0) {
                Spacer()
                Text(viewModel.didCopy
                     ? "✓ Copied to clipboard"
                     : "↵ Save  ·  esc Skip  ·  ⌘O Open  ·  ⌘C Copy")
                    .font(.system(size: 11))
                    .foregroundStyle(viewModel.didCopy ? Color.green : .secondary)
                    .animation(.easeInOut(duration: 0.18), value: viewModel.didCopy)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.separator, lineWidth: 0.5)
        )
        .overlay {
            if viewModel.didSave {
                ZStack {
                    Color.black.opacity(0.35)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white, .green)
                        .symbolEffect(.bounce, value: viewModel.didSave)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.didSave)
        .onExitCommand { viewModel.cancel() }
        .background {
            Button("") { viewModel.openInPreview() }
                .keyboardShortcut("o", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
            Button("") { viewModel.copyToClipboard() }
                .keyboardShortcut("c", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .onAppear {
            DispatchQueue.main.async { focusedField = .name }
            viewModel.startAutoDismissTimer()
        }
    }
}
