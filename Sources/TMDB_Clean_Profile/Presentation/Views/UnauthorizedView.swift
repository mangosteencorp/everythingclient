import UIKit
import TMDB_Shared_Backend

class UnauthorizedView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign in to access your profile"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In with TMDB", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
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
        // Setup layout constraints here
    }
    
    func setSignInAction(_ action: @escaping () -> Void) {
        signInButton.addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
} 
@available(iOS 17, *)
#Preview {
    UnauthorizedView()
}
