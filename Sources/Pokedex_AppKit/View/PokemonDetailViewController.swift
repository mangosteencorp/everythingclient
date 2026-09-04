#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import Kingfisher
import Pokedex_Shared_Backend
import Shared_UI_Support

/// A compact AppKit detail pane, presented as a sheet by `PokelistRouter`.
///
/// Reads `PokemonService.fetchPokemonDetail` — the same call the UIKit `Pokedex_Detail` module
/// makes — with no change to the backend.
public final class PokemonDetailViewController: NSViewController {
    private let pokemonID: Int
    private let pokemonService: PokemonService

    private let spriteView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = FontFamily.Pixelmix.regular.font(size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statsLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let spinner: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var loadTask: Task<Void, Never>?

    public init(pokemonID: Int, pokemonService: PokemonService) {
        self.pokemonID = pokemonID
        self.pokemonService = pokemonService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    override public func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 420))
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        load()
    }

    override public func viewWillDisappear() {
        super.viewWillDisappear()
        loadTask?.cancel()
    }

    private func configureLayout() {
        let dismissButton = NSButton(title: "Done", target: self, action: #selector(dismissSheet))
        dismissButton.keyEquivalent = "\r"
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        [spriteView, titleLabel, statsLabel, spinner, dismissButton].forEach(view.addSubview)

        NSLayoutConstraint.activate([
            spriteView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            spriteView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spriteView.widthAnchor.constraint(equalToConstant: 160),
            spriteView.heightAnchor.constraint(equalToConstant: 160),

            titleLabel.topAnchor.constraint(equalTo: spriteView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    @objc private func dismissSheet() {
        dismiss(nil)
    }

    private func load() {
        spinner.startAnimation(nil)
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await pokemonService.fetchPokemonDetail(id: pokemonID)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.apply(detail) }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.applyFailure(error) }
            }
        }
    }

    @MainActor
    private func apply(_ detail: PokemonDetail?) {
        spinner.stopAnimation(nil)
        guard let detail else {
            titleLabel.stringValue = "Not found"
            return
        }
        titleLabel.stringValue = "\(detail.name)  #\(detail.id)"
        statsLabel.stringValue = detail.stats
            .map { "\($0.name.padding(toLength: 18, withPad: " ", startingAt: 0)) \($0.baseStat)" }
            .joined(separator: "\n")
        if let url = URL(string: detail.imageURL) {
            spriteView.kf.setImage(with: url)
        }
    }

    @MainActor
    private func applyFailure(_ error: Error) {
        spinner.stopAnimation(nil)
        titleLabel.stringValue = "Could not load"
        statsLabel.stringValue = error.localizedDescription
    }
}
#endif
