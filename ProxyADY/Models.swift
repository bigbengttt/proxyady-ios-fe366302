import Foundation

struct AppUser: Codable {
    var id: String
    var username: String
    var email: String
    var role: String
    var plan: String
    var credits: Double
    var status: String

    enum CodingKeys: String, CodingKey {
        case id, username, email, role, plan, credits, credit, status
    }

    init(id: String = "", username: String = "", email: String = "", role: String = "free", plan: String = "free", credits: Double = 0, status: String = "active") {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.plan = plan
        self.credits = credits
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decodeIfPresent(String.self, forKey: .username) ?? "usuario"
        self.username = name
        self.id = try c.decodeIfPresent(String.self, forKey: .id) ?? name
        self.email = try c.decodeIfPresent(String.self, forKey: .email) ?? name
        self.role = try c.decodeIfPresent(String.self, forKey: .role) ?? "free"
        self.plan = try c.decodeIfPresent(String.self, forKey: .plan) ?? self.role
        self.status = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        if let v = try c.decodeIfPresent(Double.self, forKey: .credits) {
            self.credits = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .credits) {
            self.credits = Double(v)
        } else if let v = try c.decodeIfPresent(Double.self, forKey: .credit) {
            self.credits = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .credit) {
            self.credits = Double(v)
        } else {
            self.credits = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encode(email, forKey: .email)
        try c.encode(role, forKey: .role)
        try c.encode(plan, forKey: .plan)
        try c.encode(credits, forKey: .credits)
        try c.encode(status, forKey: .status)
    }
}


struct SuperKeyItem: Decodable, Identifiable {
    var id: String { key }
    var key: String
    var status: String
    var used: Bool
    var expired: Bool
    var type: String
    var duration: Int
    var durationType: String
    var createdAt: String
    var activatedAt: String
    var expiresAt: String
    var device: String

    enum CodingKeys: String, CodingKey {
        case key, status, used, expired, type, duration, duration_type, created_at, activated_at, expires_at, device
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try c.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.status = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        self.used = try c.decodeIfPresent(Bool.self, forKey: .used) ?? false
        self.expired = try c.decodeIfPresent(Bool.self, forKey: .expired) ?? false
        self.type = try c.decodeIfPresent(String.self, forKey: .type) ?? "PADRAO"
        self.duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 1
        self.durationType = try c.decodeIfPresent(String.self, forKey: .durationType) ?? c.decodeIfPresent(String.self, forKey: .duration_type) ?? "day"
        self.createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) ?? c.decodeIfPresent(String.self, forKey: .created_at) ?? ""
        self.activatedAt = try c.decodeIfPresent(String.self, forKey: .activatedAt) ?? c.decodeIfPresent(String.self, forKey: .activated_at) ?? ""
        self.expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt) ?? c.decodeIfPresent(String.self, forKey: .expires_at) ?? ""
        self.device = try c.decodeIfPresent(String.self, forKey: .device) ?? ""
    }
}

struct SuperSellerItem: Decodable, Identifiable {
    var id: String { username }
    var username: String
    var email: String
    var credits: Double
    var status: String
    var keysCount: Int
    var keys: [SuperKeyItem]

    enum CodingKeys: String, CodingKey {
        case username, email, credits, credit, status, keys_count, keys
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""
        self.email = try c.decodeIfPresent(String.self, forKey: .email) ?? username
        if let d = try c.decodeIfPresent(Double.self, forKey: .credits) {
            self.credits = d
        } else if let i = try c.decodeIfPresent(Int.self, forKey: .credits) {
            self.credits = Double(i)
        } else if let d = try c.decodeIfPresent(Double.self, forKey: .credit) {
            self.credits = d
        } else {
            self.credits = 0
        }
        self.status = try c.decodeIfPresent(String.self, forKey: .status) ?? "active"
        self.keysCount = try c.decodeIfPresent(Int.self, forKey: .keys_count) ?? 0
        self.keys = try c.decodeIfPresent([SuperKeyItem].self, forKey: .keys) ?? []
    }
}

struct SuperOverviewReply: Decodable {
    var success: Bool?
    var data: [SuperSellerItem]?
    var sellers: [SuperSellerItem]?
}

struct KeyItem: Decodable, Identifiable {
    var id: String { key }
    var key: String
    var owner: String
    var type: String
    var days: Int
    var durationType: String
    var durationLabel: String
    var status: String
    var createdAt: String
    var activatedAt: String
    var expiresAt: String
    var used: Bool
    var expired: Bool
    var ip: String
    var ipBound: String
    var device: String
    var deviceInfo: String
    var sessionExpiresAt: String

    enum CodingKeys: String, CodingKey {
        case key, key_code, owner, username, created_by, type, package, days, duration_days, duration, duration_type, duration_label, unit, unit_label, status, created_at, activated_at, expires_at, used, expired, ip, ip_bound, device, device_info, session_expires_at
    }

    init(key: String = "", owner: String = "admin", type: String = "PADRAO", days: Int = 1, durationType: String = "day", durationLabel: String = "dia", status: String = "active", createdAt: String = "", activatedAt: String = "", expiresAt: String = "", used: Bool = false, expired: Bool = false, ip: String = "", ipBound: String = "", device: String = "", deviceInfo: String = "", sessionExpiresAt: String = "") {
        self.key = key
        self.owner = owner
        self.type = type
        self.days = days
        self.durationType = durationType
        self.durationLabel = durationLabel
        self.status = status
        self.createdAt = createdAt
        self.activatedAt = activatedAt
        self.expiresAt = expiresAt
        self.used = used
        self.expired = expired
        self.ip = ip
        self.ipBound = ipBound
        self.device = device
        self.deviceInfo = deviceInfo
        self.sessionExpiresAt = sessionExpiresAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try c.decodeIfPresent(String.self, forKey: .key) ?? c.decodeIfPresent(String.self, forKey: .key_code) ?? ""
        self.owner = try c.decodeIfPresent(String.self, forKey: .owner) ?? c.decodeIfPresent(String.self, forKey: .username) ?? c.decodeIfPresent(String.self, forKey: .created_by) ?? "admin"
        self.type = try c.decodeIfPresent(String.self, forKey: .type) ?? c.decodeIfPresent(String.self, forKey: .package) ?? "PADRAO"
        func intValue(_ key: CodingKeys) -> Int? {
            if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
            if let s = try? c.decodeIfPresent(String.self, forKey: key) {
                let digits = s.filter { $0.isNumber }
                return Int(digits)
            }
            return nil
        }
        self.days = intValue(.days) ?? intValue(.duration_days) ?? intValue(.duration) ?? 1
        let rawUnit = (try? c.decodeIfPresent(String.self, forKey: .duration_type)) ?? (try? c.decodeIfPresent(String.self, forKey: .unit)) ?? "day"
        self.durationType = KeyItem.normalizeUnit(rawUnit)
        self.durationLabel = (try? c.decodeIfPresent(String.self, forKey: .duration_label)) ?? (try? c.decodeIfPresent(String.self, forKey: .unit_label)) ?? KeyItem.label(for: self.durationType, amount: self.days)
        self.status = (try? c.decodeIfPresent(String.self, forKey: .status)) ?? "active"
        self.createdAt = (try? c.decodeIfPresent(String.self, forKey: .created_at)) ?? ""
        self.activatedAt = (try? c.decodeIfPresent(String.self, forKey: .activated_at)) ?? ""
        self.expiresAt = (try? c.decodeIfPresent(String.self, forKey: .expires_at)) ?? ""
        if let b = try? c.decodeIfPresent(Bool.self, forKey: .used) { self.used = b }
        else if let s = try? c.decodeIfPresent(String.self, forKey: .used) { self.used = ["1","true","yes","used"].contains(s.lowercased()) }
        else { self.used = !self.activatedAt.isEmpty || self.status.lowercased().contains("used") }
        if let b = try? c.decodeIfPresent(Bool.self, forKey: .expired) { self.expired = b }
        else { self.expired = self.status.lowercased().contains("expired") }
        self.ip = (try? c.decodeIfPresent(String.self, forKey: .ip)) ?? ""
        self.ipBound = (try? c.decodeIfPresent(String.self, forKey: .ip_bound)) ?? self.ip
        self.device = (try? c.decodeIfPresent(String.self, forKey: .device)) ?? ""
        self.deviceInfo = (try? c.decodeIfPresent(String.self, forKey: .device_info)) ?? ""
        self.sessionExpiresAt = (try? c.decodeIfPresent(String.self, forKey: .session_expires_at)) ?? ""
    }

    static func normalizeUnit(_ value: String) -> String {
        let v = value.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        if ["h","hr","hrs","hora","horas","hour","hours"].contains(v) { return "hour" }
        if ["d","dia","dias","day","days"].contains(v) { return "day" }
        if ["s","semana","semanas","week","weeks"].contains(v) { return "week" }
        if ["mes","meses","month","months"].contains(v) { return "month" }
        if ["ano","anos","year","years"].contains(v) { return "year" }
        return v.isEmpty ? "day" : v
    }

    static func label(for unit: String, amount: Int) -> String {
        switch normalizeUnit(unit) {
        case "hour": return amount == 1 ? "hora" : "horas"
        case "day": return amount == 1 ? "dia" : "dias"
        case "week": return amount == 1 ? "semana" : "semanas"
        case "month": return amount == 1 ? "mês" : "meses"
        case "year": return amount == 1 ? "ano" : "anos"
        default: return unit
        }
    }

    var durationText: String { "\(days) \(durationLabel)" }
    var deviceText: String {
        if !deviceInfo.isEmpty { return deviceInfo }
        if !device.isEmpty { return device }
        if !ipBound.isEmpty { return "IP: \(ipBound)" }
        if !ip.isEmpty { return "IP: \(ip)" }
        if !activatedAt.isEmpty { return "Ativada" }
        return "Sem dispositivo"
    }
    var isExpired: Bool { expired || status.lowercased().contains("expired") }
}

struct RemoteButton: Decodable, Identifiable {
    var id: String
    var title: String
    var url: String
    var enabled: Bool
    var roles: [String]

    enum CodingKeys: String, CodingKey { case id, title, url, enabled, roles }

    init(id: String = UUID().uuidString, title: String = "Botão", url: String = "", enabled: Bool = true, roles: [String] = ["all"]) {
        self.id = id
        self.title = title
        self.url = url
        self.enabled = enabled
        self.roles = roles
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Botão"
        self.url = try c.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.roles = try c.decodeIfPresent([String].self, forKey: .roles) ?? ["all"]
    }
}

struct HomeUIConfig: Decodable {
    var welcomeText: String
    var subtitleText: String
    var onlineButtonsTitle: String
    var showOnlineButtonsTitle: Bool
    var showBalance: Bool
    var showPlan: Bool
    var showAdminPanel: Bool
    var balanceTitle: String
    var planText: String
    var adminPanelTitle: String
    var adminPanelSubtitle: String
    var loginButtonText: String
    var roles: [String]

    enum CodingKeys: String, CodingKey {
        case welcomeText = "welcome_text", subtitleText = "subtitle_text", onlineButtonsTitle = "online_buttons_title", showOnlineButtonsTitle = "show_online_buttons_title", showBalance = "show_balance", showPlan = "show_plan", showAdminPanel = "show_admin_panel", balanceTitle = "balance_title", planText = "plan_text", adminPanelTitle = "admin_panel_title", adminPanelSubtitle = "admin_panel_subtitle", loginButtonText = "login_button_text", roles
    }

    init(welcomeText: String = "", subtitleText: String = "", onlineButtonsTitle: String = "", showOnlineButtonsTitle: Bool = false, showBalance: Bool = true, showPlan: Bool = true, showAdminPanel: Bool = true, balanceTitle: String = "Crédito disponível", planText: String = "", adminPanelTitle: String = "Painel ADM rápido", adminPanelSubtitle: String = "Criar vendedor/admin online pelo servidor", loginButtonText: String = "Atualizar usuário", roles: [String] = ["free", "seller", "admin"]) {
        self.welcomeText = welcomeText
        self.subtitleText = subtitleText
        self.onlineButtonsTitle = onlineButtonsTitle
        self.showOnlineButtonsTitle = showOnlineButtonsTitle
        self.showBalance = showBalance
        self.showPlan = showPlan
        self.showAdminPanel = showAdminPanel
        self.balanceTitle = balanceTitle
        self.planText = planText
        self.adminPanelTitle = adminPanelTitle
        self.adminPanelSubtitle = adminPanelSubtitle
        self.loginButtonText = loginButtonText
        self.roles = roles
    }


    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.welcomeText = try c.decodeIfPresent(String.self, forKey: .welcomeText) ?? ""
        self.subtitleText = try c.decodeIfPresent(String.self, forKey: .subtitleText) ?? ""
        self.onlineButtonsTitle = try c.decodeIfPresent(String.self, forKey: .onlineButtonsTitle) ?? ""
        self.showOnlineButtonsTitle = try c.decodeIfPresent(Bool.self, forKey: .showOnlineButtonsTitle) ?? false
        self.showBalance = try c.decodeIfPresent(Bool.self, forKey: .showBalance) ?? true
        self.showPlan = try c.decodeIfPresent(Bool.self, forKey: .showPlan) ?? true
        self.showAdminPanel = try c.decodeIfPresent(Bool.self, forKey: .showAdminPanel) ?? true
        self.balanceTitle = try c.decodeIfPresent(String.self, forKey: .balanceTitle) ?? "Crédito disponível"
        self.planText = try c.decodeIfPresent(String.self, forKey: .planText) ?? ""
        self.adminPanelTitle = try c.decodeIfPresent(String.self, forKey: .adminPanelTitle) ?? "Painel ADM rápido"
        self.adminPanelSubtitle = try c.decodeIfPresent(String.self, forKey: .adminPanelSubtitle) ?? "Criar vendedor/admin online pelo servidor"
        self.loginButtonText = try c.decodeIfPresent(String.self, forKey: .loginButtonText) ?? "Atualizar usuário"
        self.roles = try c.decodeIfPresent([String].self, forKey: .roles) ?? ["free", "seller", "admin"]
    }
}

struct AppRemoteConfig: Decodable {
    var appName: String
    var themeName: String
    var primary: String
    var secondary: String
    var primaryDark: String
    var background: String
    var cardBG: String
    var cardBorder: String
    var textPrimary: String
    var textSecondary: String
    var success: String
    var danger: String
    var buttonGradient1: String
    var buttonGradient2: String
    var buttons: [RemoteButton]
    var keyUI: KeyUIConfig
    var homeUI: HomeUIConfig

    enum CodingKeys: String, CodingKey { case app_name, appName, app, colors, primary, secondary, buttons, theme, key_ui, keyUI, keys_ui, home_ui, homeUI }
    enum AppKeys: String, CodingKey { case name, theme }
    enum ColorKeys: String, CodingKey { case primary, secondary, primary_dark, background, card_bg, card_border, text_primary, text_secondary, success, danger, button_gradient_1, button_gradient_2 }
    enum ThemeKeys: String, CodingKey { case primary, secondary, background }

    init(appName: String = "Gerador", themeName: String = "purple", primary: String = "#00ff66", secondary: String = "#00ff66", primaryDark: String = "#008f38", background: String = "#0b0b12", cardBG: String = "#1b1b26", cardBorder: String = "#2c2c3a", textPrimary: String = "#ffffff", textSecondary: String = "#b3b3c7", success: String = "#22c55e", danger: String = "#ef4444", buttonGradient1: String = "#00ff66", buttonGradient2: String = "#00ff66", buttons: [RemoteButton] = [], keyUI: KeyUIConfig = KeyUIConfig(), homeUI: HomeUIConfig = HomeUIConfig()) {
        self.appName = appName
        self.themeName = themeName
        self.primary = primary
        self.secondary = secondary
        self.primaryDark = primaryDark
        self.background = background
        self.cardBG = cardBG
        self.cardBorder = cardBorder
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.success = success
        self.danger = danger
        self.buttonGradient1 = buttonGradient1
        self.buttonGradient2 = buttonGradient2
        self.buttons = buttons
        self.keyUI = keyUI
        self.homeUI = homeUI
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var appNameValue = try c.decodeIfPresent(String.self, forKey: .app_name) ?? c.decodeIfPresent(String.self, forKey: .appName) ?? "Gerador"
        var themeValue = try c.decodeIfPresent(String.self, forKey: .theme) ?? "purple"
        if let app = try? c.nestedContainer(keyedBy: AppKeys.self, forKey: .app) {
            appNameValue = try app.decodeIfPresent(String.self, forKey: .name) ?? appNameValue
            themeValue = try app.decodeIfPresent(String.self, forKey: .theme) ?? themeValue
        }
        self.appName = appNameValue
        self.themeName = themeValue
        self.buttons = try c.decodeIfPresent([RemoteButton].self, forKey: .buttons) ?? []
        self.keyUI = try c.decodeIfPresent(KeyUIConfig.self, forKey: .key_ui) ?? c.decodeIfPresent(KeyUIConfig.self, forKey: .keyUI) ?? c.decodeIfPresent(KeyUIConfig.self, forKey: .keys_ui) ?? KeyUIConfig()
        self.homeUI = try c.decodeIfPresent(HomeUIConfig.self, forKey: .home_ui) ?? c.decodeIfPresent(HomeUIConfig.self, forKey: .homeUI) ?? HomeUIConfig()

        var p = "#9d4edd", s = "#A970FF", pd = "#7b2cbf", bg = "#0b0b12", cbg = "#1b1b26", cbr = "#2c2c3a", tp = "#ffffff", ts = "#b3b3c7", ok = "#22c55e", bad = "#ef4444", g1 = "#9d4edd", g2 = "#7b2cbf"

        if let theme = try? c.nestedContainer(keyedBy: ThemeKeys.self, forKey: .theme) {
            p = try theme.decodeIfPresent(String.self, forKey: .primary) ?? p
            s = try theme.decodeIfPresent(String.self, forKey: .secondary) ?? s
            bg = try theme.decodeIfPresent(String.self, forKey: .background) ?? bg
        } else {
            p = try c.decodeIfPresent(String.self, forKey: .primary) ?? p
            s = try c.decodeIfPresent(String.self, forKey: .secondary) ?? s
        }

        if let colors = try? c.nestedContainer(keyedBy: ColorKeys.self, forKey: .colors) {
            p = try colors.decodeIfPresent(String.self, forKey: .primary) ?? p
            s = try colors.decodeIfPresent(String.self, forKey: .secondary) ?? s
            pd = try colors.decodeIfPresent(String.self, forKey: .primary_dark) ?? pd
            bg = try colors.decodeIfPresent(String.self, forKey: .background) ?? bg
            cbg = try colors.decodeIfPresent(String.self, forKey: .card_bg) ?? cbg
            cbr = try colors.decodeIfPresent(String.self, forKey: .card_border) ?? cbr
            tp = try colors.decodeIfPresent(String.self, forKey: .text_primary) ?? tp
            ts = try colors.decodeIfPresent(String.self, forKey: .text_secondary) ?? ts
            ok = try colors.decodeIfPresent(String.self, forKey: .success) ?? ok
            bad = try colors.decodeIfPresent(String.self, forKey: .danger) ?? bad
            g1 = p
            g2 = s
        } else {
            g1 = p
            g2 = s
        }

        self.primary = p
        self.secondary = s
        self.primaryDark = pd
        self.background = bg
        self.cardBG = cbg
        self.cardBorder = cbr
        self.textPrimary = tp
        self.textSecondary = ts
        self.success = ok
        self.danger = bad
        self.buttonGradient1 = g1
        self.buttonGradient2 = g2
    }
}

struct KeyUIConfig: Decodable {
    var titleCreate: String
    var titleList: String
    var showQuantity: Bool
    var showDuration: Bool
    var showAlias: Bool
    var showPackage: Bool
    var showPreview: Bool
    var showAutoClean: Bool
    var showMultipleActivate: Bool
    var createButtonText: String
    var copyButtonText: String
    var deleteButtonText: String
    var selectAllText: String
    var deselectText: String
    var durationOptions: [String]
    var defaultDurationType: String
    var defaultAlias: String

    enum CodingKeys: String, CodingKey {
        case titleCreate = "title_create", titleList = "title_list", showQuantity = "show_quantity", showDuration = "show_duration", showAlias = "show_alias", showPackage = "show_package", showPreview = "show_preview", showAutoClean = "show_auto_clean", showMultipleActivate = "show_multiple_activate", createButtonText = "create_button_text", copyButtonText = "copy_button_text", deleteButtonText = "delete_button_text", selectAllText = "select_all_text", deselectText = "deselect_text", durationOptions = "duration_options", durationTypes = "duration_types", defaultDurationType = "default_duration_type", defaultAlias = "default_alias"
    }

    init(titleCreate: String = "Criar Key", titleList: String = "Keys", showQuantity: Bool = true, showDuration: Bool = true, showAlias: Bool = true, showPackage: Bool = false, showPreview: Bool = false, showAutoClean: Bool = false, showMultipleActivate: Bool = false, createButtonText: String = "Gerar Key", copyButtonText: String = "Copiar", deleteButtonText: String = "Apagar marcadas", selectAllText: String = "Marcar todas", deselectText: String = "Limpar", durationOptions: [String] = ["Hora", "Dia", "Semana", "Mês", "Ano"], defaultDurationType: String = "Hora", defaultAlias: String = "Admin") {
        self.titleCreate = titleCreate
        self.titleList = titleList
        self.showQuantity = showQuantity
        self.showDuration = showDuration
        self.showAlias = showAlias
        self.showPackage = showPackage
        self.showPreview = showPreview
        self.showAutoClean = showAutoClean
        self.showMultipleActivate = showMultipleActivate
        self.createButtonText = createButtonText
        self.copyButtonText = copyButtonText
        self.deleteButtonText = deleteButtonText
        self.selectAllText = selectAllText
        self.deselectText = deselectText
        self.durationOptions = durationOptions
        self.defaultDurationType = defaultDurationType
        self.defaultAlias = defaultAlias
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.titleCreate = try c.decodeIfPresent(String.self, forKey: .titleCreate) ?? "Criar Key"
        self.titleList = try c.decodeIfPresent(String.self, forKey: .titleList) ?? "Keys"
        self.showQuantity = try c.decodeIfPresent(Bool.self, forKey: .showQuantity) ?? true
        self.showDuration = try c.decodeIfPresent(Bool.self, forKey: .showDuration) ?? true
        self.showAlias = try c.decodeIfPresent(Bool.self, forKey: .showAlias) ?? true
        self.showPackage = try c.decodeIfPresent(Bool.self, forKey: .showPackage) ?? false
        self.showPreview = try c.decodeIfPresent(Bool.self, forKey: .showPreview) ?? false
        self.showAutoClean = try c.decodeIfPresent(Bool.self, forKey: .showAutoClean) ?? false
        self.showMultipleActivate = try c.decodeIfPresent(Bool.self, forKey: .showMultipleActivate) ?? false
        self.createButtonText = try c.decodeIfPresent(String.self, forKey: .createButtonText) ?? "Gerar Key"
        self.copyButtonText = try c.decodeIfPresent(String.self, forKey: .copyButtonText) ?? "Copiar"
        self.deleteButtonText = try c.decodeIfPresent(String.self, forKey: .deleteButtonText) ?? "Apagar marcadas"
        self.selectAllText = try c.decodeIfPresent(String.self, forKey: .selectAllText) ?? "Marcar todas"
        self.deselectText = try c.decodeIfPresent(String.self, forKey: .deselectText) ?? "Limpar"
        let rawOptions = try c.decodeIfPresent([String].self, forKey: .durationOptions) ?? c.decodeIfPresent([String].self, forKey: .durationTypes) ?? ["Hora", "Dia", "Semana", "Mês", "Ano"]
        self.durationOptions = rawOptions.map { opt in
            switch opt.lowercased() {
            case "hour": return "Hora"
            case "day": return "Dia"
            case "week": return "Semana"
            case "month": return "Mês"
            case "year": return "Ano"
            default: return opt
            }
        }
        self.defaultDurationType = try c.decodeIfPresent(String.self, forKey: .defaultDurationType) ?? self.durationOptions.first ?? "Hora"
        self.defaultAlias = try c.decodeIfPresent(String.self, forKey: .defaultAlias) ?? "Admin"
    }
}

struct AuthReply: Decodable {
    var success: Bool
    var message: String?
    var token: String?
    var user: AppUser?
    var data: AppUser?
}

struct UserReply: Decodable {
    var success: Bool
    var message: String?
    var user: AppUser?
    var data: AppUser?
}

struct KeyGenerateReply: Decodable {
    var success: Bool
    var message: String?
    var key: String?
    var keys: [String]?
    var data: KeyItem?
}

struct KeysReply: Decodable {
    var success: Bool
    var message: String?
    var data: [KeyItem]?
    var keys: [KeyItem]?
}
