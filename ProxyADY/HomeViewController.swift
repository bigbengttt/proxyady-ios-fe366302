import UIKit

final class HomeViewController: UIViewController {
    private let response: LicenseResponse
    private let statusLabel = UILabel()
    private var keyCheckTimer: Timer?

    init(response: LicenseResponse) {
        self.response = response
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startKeyWatcher()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyCheckTimer?.invalidate()
        keyCheckTimer = nil
    }

    deinit {
        keyCheckTimer?.invalidate()
    }

    private func setupUI() {
        let cfg = APIClient.config
        let primary = UIColor.fromHex(cfg.primaryColorHex, fallback: .systemGreen)
        let text = UIColor.fromHex(cfg.textColorHex, fallback: .white)
        view.backgroundColor = UIColor.fromHex(cfg.backgroundColorHex, fallback: .black)
        navigationController?.navigationBar.isHidden = true

        let bgImage = UIImageView(image: cfg.successBackgroundImage.isEmpty ? nil : UIImage(named: cfg.successBackgroundImage))
        bgImage.contentMode = .scaleAspectFill
        bgImage.alpha = 0.92
        bgImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bgImage)
        if let url = URL(string: cfg.successBackgroundURL), !cfg.successBackgroundURL.isEmpty {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { bgImage.image = img }
            }.resume()
        }

        let darkOverlay = UIView()
        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.40)
        darkOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(darkOverlay)

        let particles = ParticleBackgroundView()
        particles.configure(
            color: UIColor.fromHex(cfg.particleColorHex, fallback: primary),
            mode: cfg.particleMode,
            imageURL: cfg.particleImageURL,
            birthRate: CGFloat(max(1, cfg.particleBirthRate))
        )
        particles.isHidden = !cfg.particlesEnabled
        particles.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(particles)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 16
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        let header = UIStackView()
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 10

        // Removido o ícone grande de aprovado e o texto "Key aprovada" do topo.
        // O status fica vazio e só aparece abaixo quando precisar mostrar algo, como "Servidor copiado".
        statusLabel.text = ""
        statusLabel.textColor = text
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        let host = response.data?.proxyHost ?? cfg.proxyHost
        let serverTitle = label("SERVIDOR", size: 13, weight: .heavy, color: text.withAlphaComponent(0.82), alignment: .center)
        let serverValue = label(host, size: 29, weight: .black, color: primary, alignment: .center)
        serverValue.adjustsFontSizeToFitWidth = true
        serverValue.minimumScaleFactor = 0.65

        let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        card.layer.cornerRadius = 26
        card.clipsToBounds = true
        card.layer.borderColor = primary.withAlphaComponent(0.35).cgColor
        card.layer.borderWidth = 1

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 11
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(cardStack)

        cardStack.addArrangedSubview(serverTitle)
        cardStack.addArrangedSubview(serverValue)

        if let validade = response.data?.expiresAt, !validade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cardStack.addArrangedSubview(separator(primary))
            cardStack.addArrangedSubview(label("VALIDADE DA KEY", size: 13, weight: .heavy, color: text.withAlphaComponent(0.82), alignment: .center))
            cardStack.addArrangedSubview(label(validade, size: 19, weight: .black, color: primary, alignment: .center))
        }

        cardStack.addArrangedSubview(separator(primary))
        cardStack.addArrangedSubview(label("PORTAS DISPONÍVEIS ONLINE", size: 16, weight: .black, color: text, alignment: .center))

        for item in cfg.ports {
            cardStack.addArrangedSubview(portRow(item, primary: primary, text: text))
        }

        let copyButton = makeButton(title: cfg.successCopyButtonTitle, color: primary)
        copyButton.addTarget(self, action: #selector(copyServer), for: .touchUpInside)

        let certButton = makeButton(title: cfg.successCertificateButtonTitle, color: primary)
        certButton.addTarget(self, action: #selector(openCertificate), for: .touchUpInside)
        certButton.isHidden = !cfg.showCertificateButton

        content.addArrangedSubview(card)
        content.addArrangedSubview(copyButton)
        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(certButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            darkOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            darkOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            darkOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            darkOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            particles.topAnchor.constraint(equalTo: view.topAnchor),
            particles.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            particles.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            particles.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 22),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -26),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 22),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -22),

            cardStack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 20),
            cardStack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -20),
            cardStack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -18)
        ])
    }

    private func label(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor, alignment: NSTextAlignment) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = color
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textAlignment = alignment
        l.numberOfLines = 0
        return l
    }

    private func separator(_ color: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = color.withAlphaComponent(0.42)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func portRow(_ item: String, primary: UIColor, text: UIColor) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        row.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        row.layer.cornerRadius = 12

        let parts = item.components(separatedBy: "=")
        let port = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? item
        let name = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)

        let portLabel = label(port, size: 18, weight: .black, color: primary, alignment: .left)
        portLabel.widthAnchor.constraint(equalToConstant: 54).isActive = true
        let nameLabel = label(name.isEmpty ? item : name, size: 15, weight: .bold, color: text, alignment: .left)
        let check = label("✓", size: 16, weight: .black, color: primary, alignment: .center)
        check.layer.borderWidth = 2
        check.layer.borderColor = primary.cgColor
        check.layer.cornerRadius = 12
        check.clipsToBounds = true
        check.widthAnchor.constraint(equalToConstant: 24).isActive = true
        check.heightAnchor.constraint(equalToConstant: 24).isActive = true

        row.addArrangedSubview(portLabel)
        row.addArrangedSubview(nameLabel)
        row.addArrangedSubview(check)
        return row
    }

    private func makeButton(title: String, color: UIColor) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .black)
        b.backgroundColor = color
        b.layer.cornerRadius = 18
        b.layer.shadowColor = color.cgColor
        b.layer.shadowOpacity = 0.45
        b.layer.shadowRadius = 14
        b.heightAnchor.constraint(equalToConstant: 58).isActive = true
        return b
    }

    @objc private func copyServer() {
        let host = response.data?.proxyHost ?? APIClient.config.proxyHost
        UIPasteboard.general.string = host
        statusLabel.text = "Servidor copiado"
    }

    @objc private func openCertificate() {
        guard let url = URL(string: APIClient.config.certificateURL) else { return }
        UIApplication.shared.open(url)
    }

    private func startKeyWatcher() {
        keyCheckTimer?.invalidate()
        keyCheckTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { _ in
            APIClient.closeAppIfSavedKeyInvalid()
        }
        APIClient.closeAppIfSavedKeyInvalid()
    }
}
