import UIKit

class ErrorView: UIView {
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Something went wrong"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Try Again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        [imageView, titleLabel, messageLabel, retryButton].forEach {
            containerStackView.addArrangedSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            
            imageView.heightAnchor.constraint(equalToConstant: 50),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    func configure(with error: Error, retryAction: @escaping () -> Void) {
        messageLabel.text = error.localizedDescription
        retryButton.addAction(UIAction { _ in retryAction() }, for: .touchUpInside)
    }
}
@available(iOS 17, *)
#Preview {
    ErrorView()
}
