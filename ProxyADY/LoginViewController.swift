import UIKit

final class LoginViewController: UIViewController, UITextFieldDelegate {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let backgroundImageView = RemoteImageView()
    private let onlineLogoImageView = RemoteImageView()
    private let logoView = ProxyLogoView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let keyField = UITextField()
    private let pasteButton = UIButton(type: .system)
    private let connectButton = GradientButton()
    private let statusLabel = UILabel()
    private let securityCard = UIView()
    private let securityTitle = UILabel()
    private let securitySubtitle = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let particlesView = ParticleBackgroundView()
    private var dynamicButtonViews: [UIButton] = []

    private var primaryColor = UIColor.systemPink
    private var primaryDarkColor = UIColor.systemPurple
    private var textColor = UIColor.white
    private var mutedTextColor = UIColor(white: 0.75, alpha: 1)
    private var inputColor = UIColor(white: 0.08, alpha: 1)
    private var cardColor = UIColor(white: 0.05, alpha: 1)

    private var topConstraint: NSLayoutConstraint?
    private var onlineLogoHeightConstraint: NSLayoutConstraint?
    private var logoHeightConstraint: NSLayoutConstraint?
    private var keyHeightConstraint: NSLayoutConstraint?
    private var connectHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        APIClient.loadOnlineConfig { [weak self] _ in
            self?.applyTheme()
            self?.trySavedKey()
        }
    }

    private func setupUI() {
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .black

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.alpha = 0.95
        backgroundImageView.isHidden = true
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        particlesView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(particlesView)
        NSLayoutConstraint.activate([
            particlesView.topAnchor.constraint(equalTo: view.topAnchor),
            particlesView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            particlesView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            particlesView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        onlineLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        onlineLogoImageView.contentMode = .scaleAspectFit
        onlineLogoImageView.clipsToBounds = true
        onlineLogoImageView.isHidden = true
        onlineLogoHeightConstraint = onlineLogoImageView.heightAnchor.constraint(equalToConstant: 116)
        onlineLogoHeightConstraint?.isActive = true

        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoHeightConstraint = logoView.heightAnchor.constraint(equalToConstant: 116)
        logoHeightConstraint?.isActive = true

        titleLabel.text = "PROXY"
        titleLabel.font = .systemFont(ofSize: 54, weight: .heavy)
        titleLabel.textAlignment = .center

        subtitleLabel.text = ""
        subtitleLabel.font = .systemFont(ofSize: 22, weight: .medium)
        subtitleLabel.textAlignment = .center

        instructionLabel.text = "INSIRA SUA KEY PARA CONTINUAR"
        instructionLabel.font = .systemFont(ofSize: 14, weight: .bold)
        instructionLabel.textAlignment = .center

        keyField.placeholder = "Insira sua key"
        keyField.autocapitalizationType = .allCharacters
        keyField.autocorrectionType = .no
        keyField.returnKeyType = .done
        keyField.delegate = self
        keyField.clearButtonMode = .never
        keyField.font = .systemFont(ofSize: 20, weight: .semibold)
        keyField.isUserInteractionEnabled = false // só aceita key pelo botão COLAR KEY
        keyField.leftView = iconContainer(systemName: "key.fill")
        keyField.leftViewMode = .always
        keyField.rightView = nil
        keyField.rightViewMode = .never
        keyHeightConstraint = keyField.heightAnchor.constraint(equalToConstant: 74)
        keyHeightConstraint?.isActive = true
        keyField.layer.cornerRadius = 18
        keyField.layer.borderWidth = 1.2
        keyField.clipsToBounds = true

        pasteButton.setTitle("COLAR KEY", for: .normal)
        pasteButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .heavy)
        pasteButton.layer.cornerRadius = 16
        pasteButton.layer.borderWidth = 1
        pasteButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        connectButton.setTitle("CONECTAR  →", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .heavy)
        connectButton.setTitleColor(.white, for: .normal)
        connectHeightConstraint = connectButton.heightAnchor.constraint(equalToConstant: 76)
        connectHeightConstraint?.isActive = true
        connectButton.layer.cornerRadius = 20
        connectButton.clipsToBounds = true
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        statusLabel.text = ""
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        securityCard.layer.cornerRadius = 22
        securityCard.layer.borderWidth = 1
        securityCard.translatesAutoresizingMaskIntoConstraints = false
        securityCard.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let shield = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        shield.tintColor = primaryColor
        shield.contentMode = .scaleAspectFit
        shield.translatesAutoresizingMaskIntoConstraints = false
        securityCard.addSubview(shield)

        securityTitle.text = "Conexão segura"
        securityTitle.font = .systemFont(ofSize: 19, weight: .bold)
        securityTitle.translatesAutoresizingMaskIntoConstraints = false
        securityCard.addSubview(securityTitle)

        securitySubtitle.text = "Acesso liberado pela VPS por 10 minutos."
        securitySubtitle.font = .systemFont(ofSize: 14, weight: .medium)
        securitySubtitle.numberOfLines = 2
        securitySubtitle.translatesAutoresizingMaskIntoConstraints = false
        securityCard.addSubview(securitySubtitle)

        NSLayoutConstraint.activate([
            shield.leadingAnchor.constraint(equalTo: securityCard.leadingAnchor, constant: 22),
            shield.centerYAnchor.constraint(equalTo: securityCard.centerYAnchor),
            shield.widthAnchor.constraint(equalToConstant: 42),
            shield.heightAnchor.constraint(equalToConstant: 42),
            securityTitle.leadingAnchor.constraint(equalTo: shield.trailingAnchor, constant: 18),
            securityTitle.trailingAnchor.constraint(equalTo: securityCard.trailingAnchor, constant: -18),
            securityTitle.topAnchor.constraint(equalTo: securityCard.topAnchor, constant: 20),
            securitySubtitle.leadingAnchor.constraint(equalTo: securityTitle.leadingAnchor),
            securitySubtitle.trailingAnchor.constraint(equalTo: securityTitle.trailingAnchor),
            securitySubtitle.topAnchor.constraint(equalTo: securityTitle.bottomAnchor, constant: 6)
        ])

        spinner.hidesWhenStopped = true
        spinner.color = .white

        [onlineLogoImageView, logoView, titleLabel, subtitleLabel, instructionLabel, keyField, pasteButton, connectButton, statusLabel, securityCard, spinner].forEach { stack.addArrangedSubview($0) }
        stack.setCustomSpacing(8, after: titleLabel)
        stack.setCustomSpacing(34, after: connectButton)

        topConstraint = stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 70)
        topConstraint?.isActive = true
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -30),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30)
        ])
    }

    private func applyTheme() {
        let cfg = APIClient.config
        primaryColor = UIColor.fromHex(cfg.primaryColorHex, fallback: .systemPink)
        primaryDarkColor = UIColor.fromHex(cfg.primaryDarkColorHex, fallback: .systemPurple)
        textColor = UIColor.fromHex(cfg.textColorHex, fallback: .white)
        mutedTextColor = UIColor.fromHex(cfg.mutedTextColorHex, fallback: UIColor(white: 0.75, alpha: 1))
        inputColor = UIColor.fromHex(cfg.inputColorHex, fallback: UIColor(white: 0.08, alpha: 1))
        cardColor = UIColor.fromHex(cfg.cardColorHex, fallback: UIColor(white: 0.05, alpha: 1))
        view.backgroundColor = UIColor.fromHex(cfg.backgroundColorHex, fallback: .black)
        backgroundImageView.load(urlString: cfg.backgroundURL)
        backgroundImageView.isHidden = cfg.backgroundURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        particlesView.isHidden = !cfg.particlesEnabled
        particlesView.configure(
            color: UIColor.fromHex(cfg.particleColorHex, fallback: primaryColor),
            mode: cfg.particleMode,
            imageURL: cfg.particleImageURL,
            birthRate: CGFloat(max(1, cfg.particleBirthRate))
        )

        onlineLogoImageView.load(urlString: cfg.logoURL)
        onlineLogoImageView.isHidden = cfg.logoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !cfg.showLogo
        logoView.tint = primaryColor
        logoView.isHidden = !cfg.showLogo || !cfg.logoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        titleLabel.isHidden = !cfg.showTitle
        subtitleLabel.isHidden = !cfg.showSubtitle
        securityCard.isHidden = !cfg.showSecurityCard
        pasteButton.isHidden = !cfg.showPasteButton

        titleLabel.text = cfg.appName.uppercased()
        subtitleLabel.text = cfg.subtitle
        instructionLabel.text = cfg.instructionText
        keyField.placeholder = cfg.inputPlaceholder
        pasteButton.setTitle(cfg.pasteButtonTitle, for: .normal)
        connectButton.setTitle(cfg.connectButtonTitle, for: .normal)

        topConstraint?.constant = CGFloat(max(10, cfg.topPadding))
        onlineLogoHeightConstraint?.constant = CGFloat(max(40, cfg.logoHeight))
        logoHeightConstraint?.constant = CGFloat(max(40, cfg.logoHeight))
        keyHeightConstraint?.constant = CGFloat(max(50, cfg.fieldHeight))
        connectHeightConstraint?.constant = CGFloat(max(52, cfg.buttonHeight))

        [titleLabel, securityTitle].forEach { $0.textColor = textColor }
        [subtitleLabel, securitySubtitle].forEach { $0.textColor = mutedTextColor }
        instructionLabel.textColor = primaryColor
        keyField.textColor = textColor
        keyField.attributedPlaceholder = NSAttributedString(string: cfg.inputPlaceholder, attributes: [.foregroundColor: mutedTextColor.withAlphaComponent(0.65)])
        keyField.backgroundColor = inputColor.withAlphaComponent(0.7)
        keyField.layer.borderColor = primaryColor.withAlphaComponent(0.75).cgColor
        pasteButton.setTitleColor(primaryColor, for: .normal)
        pasteButton.backgroundColor = inputColor.withAlphaComponent(0.5)
        pasteButton.layer.borderColor = primaryColor.withAlphaComponent(0.7).cgColor
        connectButton.applyGradient(colors: [primaryDarkColor, primaryColor], cornerRadius: 20)
        securityCard.backgroundColor = cardColor.withAlphaComponent(0.65)
        securityCard.layer.borderColor = primaryColor.withAlphaComponent(0.35).cgColor
        addSoftGlow(to: connectButton, color: primaryColor)
        rebuildDynamicButtons(cfg.dynamicButtons)
    }

    private func rebuildDynamicButtons(_ configs: [DynamicButtonConfig]) {
        dynamicButtonViews.forEach { button in
            stack.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        dynamicButtonViews.removeAll()

        guard !configs.isEmpty else { return }

        for item in configs {
            let button = LinkButton(type: .system)
            button.urlString = item.url
            button.setTitle(item.title.uppercased(), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .heavy)
            button.setTitleColor(UIColor.fromHex(item.textColorHex, fallback: .white), for: .normal)
            let bg = UIColor.fromHex(item.colorHex, fallback: inputColor.withAlphaComponent(0.65))
            button.backgroundColor = bg.withAlphaComponent(0.82)
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 1
            button.layer.borderColor = primaryColor.withAlphaComponent(0.6).cgColor
            button.heightAnchor.constraint(equalToConstant: 52).isActive = true
            button.addTarget(self, action: #selector(dynamicButtonTapped(_:)), for: .touchUpInside)
            stack.insertArrangedSubview(button, at: max(0, stack.arrangedSubviews.firstIndex(of: statusLabel) ?? stack.arrangedSubviews.count))
            dynamicButtonViews.append(button)
        }
    }

    @objc private func dynamicButtonTapped(_ sender: LinkButton) {
        guard let raw = sender.urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
              let url = URL(string: raw) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @objc private func pasteTapped() {
        if let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            keyField.text = text.uppercased()
            keyField.resignFirstResponder()
        } else {
            showStatus("Nada copiado para colar.", color: .systemYellow)
        }
    }

    private func trySavedKey() {
        guard let saved = APIClient.savedKey else { return }
        keyField.text = saved
        connectButton.isEnabled = false
        spinner.startAnimating()
        showStatus("Validando key salva...", color: mutedTextColor)
        APIClient.validateKey(saved) { [weak self] response in
            guard let self = self else { return }
            self.spinner.stopAnimating()
            self.connectButton.isEnabled = true
            if response.success {
                let home = HomeViewController(response: response)
                self.navigationController?.setViewControllers([home], animated: false)
            } else {
                APIClient.clearSavedKey()
                self.keyField.text = ""
                self.showStatus("Key vencida ou apagada. Cole uma nova key.", color: .systemYellow)
            }
        }
    }

    @objc private func connectTapped() {
        let key = keyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty else {
            showStatus("Digite ou cole sua key.", color: .systemYellow)
            return
        }
        keyField.resignFirstResponder()
        connectButton.isEnabled = false
        spinner.startAnimating()
        showStatus("Validando key na VPS...", color: mutedTextColor)

        APIClient.validateKey(key) { [weak self] response in
            guard let self = self else { return }
            self.spinner.stopAnimating()
            self.connectButton.isEnabled = true
            if response.success {
                self.showStatus("✅ Key aprovada. IP liberado por \(APIClient.config.sessionTimeoutSeconds / 60) minutos.", color: .systemGreen)
                let home = HomeViewController(response: response)
                self.navigationController?.setViewControllers([home], animated: true)
            } else {
                self.showStatus("❌ \(response.message)", color: .systemRed)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        connectTapped()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false // não abre teclado; cliente usa somente COLAR KEY
    }

    private func showStatus(_ text: String, color: UIColor) {
        statusLabel.text = text
        statusLabel.textColor = color
    }

    private func iconContainer(systemName: String) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 58, height: 58))
        let imageView = UIImageView(image: UIImage(systemName: systemName))
        imageView.tintColor = primaryColor
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 18, y: 16, width: 26, height: 26)
        container.addSubview(imageView)
        return container
    }

    private func addSoftGlow(to view: UIView, color: UIColor) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowOpacity = 0.65
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = .zero
    }
}



final class RemoteImageView: UIImageView {
    private static let cache = NSCache<NSString, UIImage>()
    private var currentURLString = ""

    func load(urlString: String) {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        currentURLString = clean
        guard !clean.isEmpty, let url = URL(string: clean) else {
            image = nil
            return
        }
        if let cached = RemoteImageView.cache.object(forKey: clean as NSString) {
            image = cached
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  self.currentURLString == clean,
                  let data = data,
                  let img = UIImage(data: data) else { return }
            RemoteImageView.cache.setObject(img, forKey: clean as NSString)
            DispatchQueue.main.async { self.image = img }
        }.resume()
    }
}

final class LinkButton: UIButton {
    var urlString: String?
}

final class ParticleBackgroundView: UIView {
    private var particleColor: UIColor = .systemGreen
    private var particleMode: String = "dot"
    private var particleImageURL: String = ""
    private var particleBirthRate: CGFloat = 42
    private var remoteParticleImage: UIImage?
    private let emitter = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(emitter)
        recreateParticles()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        layer.addSublayer(emitter)
        recreateParticles()
    }

    func configure(color: UIColor, mode: String, imageURL: String, birthRate: CGFloat) {
        let cleanMode = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanURL = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        particleColor = color
        particleMode = cleanMode.isEmpty ? "dot" : cleanMode
        particleBirthRate = birthRate

        if cleanURL != particleImageURL {
            particleImageURL = cleanURL
            remoteParticleImage = nil
            loadRemoteParticleImage(cleanURL)
        }
        recreateParticles()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterShape = .line
    }

    private func loadRemoteParticleImage(_ urlString: String) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  self.particleImageURL == urlString,
                  let data = data,
                  let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.remoteParticleImage = img
                self.recreateParticles()
            }
        }.resume()
    }

    private func particleCGImage() -> CGImage? {
        if let remote = remoteParticleImage?.cgImage { return remote }
        if particleMode == "money", let img = UIImage(named: "MoneyDrop")?.cgImage { return img }
        if particleMode == "image", let img = remoteParticleImage?.cgImage { return img }
        if particleMode == "heart" { return textImage("♥", color: particleColor) }
        if particleMode == "star" { return textImage("★", color: particleColor) }
        if particleMode == "snow" { return textImage("❄", color: particleColor) }
        if particleMode == "money" { return textImage("$", color: particleColor) }
        return dotImage(color: particleColor.withAlphaComponent(0.95))
    }

    private func textImage(_ text: String, color: UIColor) -> CGImage? {
        let size = CGSize(width: 34, height: 34)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: color
        ]
        let rect = CGRect(origin: .zero, size: size)
        (text as NSString).draw(in: rect, withAttributes: attrs)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.cgImage
    }

    private func dotImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 8, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(color.cgColor)
        ctx?.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.cgImage
    }

    private func recreateParticles() {
        let cell = CAEmitterCell()
        cell.contents = particleCGImage()
        cell.birthRate = Float(particleBirthRate)
        cell.lifetime = 9
        cell.lifetimeRange = 4
        cell.velocity = 120
        cell.velocityRange = 70
        cell.yAcceleration = 25
        cell.xAcceleration = 0
        cell.scale = particleMode == "dot" ? 0.28 : 0.45
        cell.scaleRange = particleMode == "dot" ? 0.35 : 0.25
        cell.alphaSpeed = -0.04
        cell.spin = 1.2
        cell.spinRange = 2.4
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = .pi / 7
        emitter.emitterCells = [cell]
    }
}

final class ProxyLogoView: UIView {
    var tint: UIColor = .systemPink { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setLineWidth(8)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(tint.cgColor)
        ctx.setShadow(offset: .zero, blur: 18, color: tint.cgColor)

        let w = rect.width
        let cx = w / 2
        let top = rect.minY + 10
        let size: CGFloat = 92
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cx, y: top))
        path.addLine(to: CGPoint(x: cx + size / 2, y: top + size * 0.28))
        path.addLine(to: CGPoint(x: cx + size / 2, y: top + size * 0.72))
        path.addLine(to: CGPoint(x: cx, y: top + size))
        path.addLine(to: CGPoint(x: cx - size / 2, y: top + size * 0.72))
        path.addLine(to: CGPoint(x: cx - size / 2, y: top + size * 0.28))
        path.close()
        path.stroke()

        let p = UIBezierPath()
        p.move(to: CGPoint(x: cx - 18, y: top + 68))
        p.addLine(to: CGPoint(x: cx + 22, y: top + 28))
        p.addQuadCurve(to: CGPoint(x: cx + 30, y: top + 60), controlPoint: CGPoint(x: cx + 52, y: top + 42))
        p.addLine(to: CGPoint(x: cx - 4, y: top + 92))
        p.stroke()
    }
}

final class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    func applyGradient(colors: [UIColor], cornerRadius: CGFloat) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.cornerRadius = cornerRadius
        layer.cornerRadius = cornerRadius
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
