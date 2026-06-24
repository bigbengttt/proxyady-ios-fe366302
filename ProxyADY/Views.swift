import SwiftUI
import UIKit
import Foundation

func hexColor(_ hex: String, fallback: Color = .purple) -> Color {
    var value = hex.replacingOccurrences(of: "#", with: "")
    if value.count == 6 { value = "FF" + value }
    guard let int = UInt64(value, radix: 16) else { return fallback }
    let a = Double((int >> 24) & 255) / 255
    let r = Double((int >> 16) & 255) / 255
    let g = Double((int >> 8) & 255) / 255
    let b = Double(int & 255) / 255
    return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
}

struct Field: View {
    var title: String
    @Binding var text: String
    var secure: Bool = false
    var body: some View {
        Group {
            if secure { SecureField(title, text: $text) }
            else { TextField(title, text: $text).textInputAutocapitalization(.never).autocorrectionDisabled(true) }
        }
        .padding()
        .foregroundColor(.white)
        .background(Color.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MainButton: View {
    @EnvironmentObject var app: AppState
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).fontWeight(.bold).frame(maxWidth: .infinity).padding()
                .background(LinearGradient(colors: [hexColor(app.config.primary).opacity(0.98), hexColor(app.config.secondary, fallback: hexColor(app.config.primary)).opacity(0.95)], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct Screen<Content: View>: View {
    @EnvironmentObject var app: AppState
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            hexColor(app.config.background, fallback: Color.black).ignoresSafeArea()
            content.padding()
        }
    }
}

@MainActor final class AppState: ObservableObject {
    @Published var user: AppUser? = nil
    @Published var config = AppRemoteConfig()
    @Published var message = ""

    var isLogged: Bool { user != nil }

    init() {
        if let data = UserDefaults.standard.data(forKey: "saved_user"), let saved = try? JSONDecoder().decode(AppUser.self, from: data) {
            self.user = saved
        }
    }

    func save(_ u: AppUser, token: String? = nil) {
        user = u
        if let data = try? JSONEncoder().encode(u) { UserDefaults.standard.set(data, forKey: "saved_user") }
        if let token = token, !token.isEmpty { UserDefaults.standard.set(token, forKey: "auth_token") }
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: "saved_user")
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }

    func refreshConfig() async {
        config = await APIClient.shared.config()
    }

    func refreshUser() async {
        guard let current = user else { return }
        let login = current.email.isEmpty ? current.username : current.email
        if let updated = try? await APIClient.shared.me(login: login) { save(updated) }
    }
}

struct RootView: View {
    @StateObject var app = AppState()
    var body: some View {
        Group { app.isLogged ? AnyView(MainTabs()) : AnyView(AuthView()) }
            .environmentObject(app)
            .task { await app.refreshConfig(); await app.refreshUser() }
    }
}

struct AuthView: View {
    @EnvironmentObject var app: AppState
    @State var register = false
    @State var username = ""
    @State var login = ""
    @State var password = ""
    var body: some View {
        Screen {
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "bolt.shield.fill").font(.system(size: 76)).foregroundColor(hexColor(app.config.primary))
                Text(app.config.appName).font(.largeTitle.bold()).foregroundColor(.white)
                Text("Sistema online pelo servidor").foregroundColor(.white.opacity(0.7))
                Text(register ? "Criar conta" : "Entrar").font(.title2.bold()).foregroundColor(.white).padding(.top)
                if register { Field(title: "Nome de usuário", text: $username) }
                Field(title: "E-mail ou usuário", text: $login)
                Field(title: "Senha", text: $password, secure: true)
                MainButton(title: register ? "Criar conta grátis" : "Entrar") { Task { await submit() } }
                Button(register ? "Já tenho conta" : "Criar conta") { register.toggle(); app.message = "" }.foregroundColor(hexColor(app.config.primary))
                if !app.message.isEmpty { Text(app.message).foregroundColor(.red).multilineTextAlignment(.center) }
                Spacer()
            }
        }
    }

    func submit() async {
        do {
            let reply = register ? try await APIClient.shared.register(username: username.isEmpty ? login : username, email: login, password: password) : try await APIClient.shared.login(login: login, password: password)
            if reply.success, let u = (reply.user ?? reply.data) {
                app.save(u, token: reply.token)
                await app.refreshUser()
            } else { app.message = reply.message ?? "Erro" }
        } catch { app.message = error.localizedDescription }
    }
}

struct MainTabs: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Início", systemImage: "house") }
            GenerateView().tabItem { Label("Gerar", systemImage: "key") }
            KeysView().tabItem { Label("Keys", systemImage: "list.bullet") }
            DevicesView().tabItem { Label("Dispositivos", systemImage: "iphone") }
            ProfileView().tabItem { Label("Perfil", systemImage: "person") }
        }.tint(hexColor(app.config.primary))
    }
}

struct Card<Content: View>: View {
    @EnvironmentObject var app: AppState
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hexColor(app.config.cardBG).opacity(0.92))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(hexColor(app.config.cardBorder).opacity(0.75), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State var adminUser = ""
    @State var adminCredits = "50"
    @State var adminRole = "seller"
    @State var adminMessage = ""
    @State var superSellers: [SuperSellerItem] = []
    @State var superLoading = false
    @State var superMessage = ""
    var body: some View {
        Screen {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text(app.config.appName).foregroundColor(.white.opacity(0.85)).font(.headline); Spacer(); Button("Atualizar") { Task { await app.refreshUser(); await app.refreshConfig() } }.foregroundColor(hexColor(app.config.primary)) }
                    Text(app.config.homeUI.welcomeText.isEmpty ? "Olá, \(app.user?.username ?? "usuário")!" : app.config.homeUI.welcomeText).font(.largeTitle.bold()).foregroundColor(hexColor(app.config.textPrimary))
                    Card { VStack(alignment: .leading, spacing: 12) { Text(app.config.homeUI.balanceTitle).foregroundColor(hexColor(app.config.textSecondary)); Text("R$ " + String(format: "%.2f", app.user?.credits ?? 0)).font(.system(size: 42, weight: .bold)).foregroundColor(hexColor(app.config.textPrimary)); if app.config.homeUI.showPlan { Text(app.config.homeUI.planText.isEmpty ? "Plano: \(app.user?.plan ?? "free")" : app.config.homeUI.planText).foregroundColor(hexColor(app.config.primary)) } } }
                    if app.config.homeUI.showOnlineButtonsTitle && !app.config.homeUI.onlineButtonsTitle.isEmpty {
                        Text(app.config.homeUI.onlineButtonsTitle)
                            .font(.headline)
                            .foregroundColor(hexColor(app.config.textPrimary))
                    }
                    ForEach(app.config.buttons.filter { $0.enabled }) { b in Card { Text(b.title).foregroundColor(hexColor(app.config.textPrimary)).font(.headline) } }
                    if app.config.homeUI.showAdminPanel && ["admin","supremo"].contains(app.user?.role.lowercased() ?? "") {
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(app.config.homeUI.adminPanelTitle).font(.headline).foregroundColor(hexColor(app.config.textPrimary))
                                Text(app.config.homeUI.adminPanelSubtitle).font(.caption).foregroundColor(hexColor(app.config.textSecondary))
                                Field(title: "Usuário ou email", text: $adminUser)
                                Field(title: "Créditos", text: $adminCredits)
                                Picker("Cargo", selection: $adminRole) { Text("free").tag("free"); Text("seller").tag("seller"); Text("admin").tag("admin"); Text("supremo").tag("supremo") }.pickerStyle(.segmented)
                                MainButton(title: app.config.homeUI.loginButtonText.isEmpty ? "Atualizar usuário" : app.config.homeUI.loginButtonText) { Task { await updateUser() } }
                                if !adminMessage.isEmpty { Text(adminMessage).foregroundColor(.green).font(.caption) }
                            }
                        }
                    }
                    if app.user?.role.lowercased() == "supremo" {
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("ADM Supremo")
                                        .font(.headline)
                                        .foregroundColor(hexColor(app.config.textPrimary))
                                    Spacer()
                                    Button(superLoading ? "Carregando..." : "Ver vendedores") { Task { await loadSuperOverview() } }
                                        .foregroundColor(hexColor(app.config.primary))
                                }
                                Text("Mostra todos os vendedores e as keys de cada um.")
                                    .font(.caption)
                                    .foregroundColor(hexColor(app.config.textSecondary))
                                if !superMessage.isEmpty {
                                    Text(superMessage)
                                        .font(.caption)
                                        .foregroundColor(superMessage.lowercased().contains("erro") ? .red : .green)
                                }
                                ForEach(superSellers) { seller in
                                    DisclosureGroup {
                                        VStack(alignment: .leading, spacing: 8) {
                                            if seller.keys.isEmpty {
                                                Text("Nenhuma key desse vendedor")
                                                    .foregroundColor(.white.opacity(0.55))
                                                    .font(.caption)
                                            } else {
                                                ForEach(seller.keys) { k in
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        HStack {
                                                            Text(k.key)
                                                                .foregroundColor(.white)
                                                                .font(.caption.bold())
                                                                .lineLimit(1)
                                                            Spacer()
                                                            Button("Copiar") { UIPasteboard.general.string = k.key }
                                                                .font(.caption)
                                                                .foregroundColor(hexColor(app.config.primary))
                                                        }
                                                        Text("\(k.status.uppercased()) • \(k.type) • \(k.duration) \(k.durationType)")
                                                            .foregroundColor(.white.opacity(0.55))
                                                            .font(.caption2)
                                                        if !k.expiresAt.isEmpty {
                                                            Text("Expira: \(k.expiresAt)")
                                                                .foregroundColor(k.expired ? .red : .white.opacity(0.55))
                                                                .font(.caption2)
                                                        }
                                                        if !k.device.isEmpty {
                                                            Text("Celular/token: \(k.device)")
                                                                .foregroundColor(.white.opacity(0.45))
                                                                .font(.caption2)
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.06))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                }
                                            }
                                        }
                                        .padding(.top, 8)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(seller.username)
                                                .foregroundColor(.white)
                                                .font(.subheadline.bold())
                                            Text("Créditos: \(String(format: "%.0f", seller.credits)) • Keys: \(seller.keysCount) • \(seller.status)")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if app.user?.role.lowercased() == "supremo" {
                await loadSuperOverview()
            }
        }
    }
    func updateUser() async {
        do {
            adminMessage = try await APIClient.shared.updateUser(username: adminUser, role: adminRole, credits: Double(adminCredits) ?? 0, actor: app.user?.username ?? "")
            await loadSuperOverview()
        }
        catch { adminMessage = error.localizedDescription }
    }

    func loadSuperOverview() async {
        guard app.user?.role.lowercased() == "supremo" else { return }
        superLoading = true
        defer { superLoading = false }
        do {
            superSellers = try await APIClient.shared.superOverview()
            superMessage = "\(superSellers.count) vendedor(es) carregado(s)"
        } catch {
            superMessage = "Erro: \(error.localizedDescription)"
        }
    }
}

struct GenerateView: View {
    @EnvironmentObject var app: AppState
    @State var quantity = "1"
    @State var duration = "1"
    @State var unit = "Hora"
    @State var package = "Painel rage"
    @State var alias = "Admin"
    @State var generated: [String] = []
    @State var message = ""
    @State var showResult = false
    @State var loading = false

    var normalizedUnit: String {
        switch unit.lowercased() {
        case "hora", "hour": return "hour"
        case "dia", "day": return "day"
        case "semana", "week": return "week"
        case "mês", "mes", "month": return "month"
        case "ano", "year": return "year"
        default: return unit.lowercased()
        }
    }

    var body: some View {
        let ui = app.config.keyUI
        Screen {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(ui.titleCreate)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Button("Criar") { Task { await create() } }
                            .foregroundColor(hexColor(app.config.secondary))
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            if ui.showQuantity {
                                Text("Quantidade").foregroundColor(.white.opacity(0.85)).font(.headline)
                                Field(title: "1", text: $quantity)
                                    .keyboardType(.numberPad)
                            }

                            if ui.showDuration {
                                Text("Duração").foregroundColor(.white.opacity(0.85)).font(.headline)
                                HStack(spacing: 12) {
                                    Field(title: "1", text: $duration)
                                        .keyboardType(.numberPad)
                                    Menu {
                                        ForEach(ui.durationOptions, id: \.self) { option in
                                            Button(option) { unit = option }
                                        }
                                    } label: {
                                        HStack {
                                            Text(unit.isEmpty ? ui.defaultDurationType : unit)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.09))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .foregroundColor(.white)
                                    }
                                }
                            }

                            if ui.showAlias {
                                Text("Alias").foregroundColor(.white.opacity(0.85)).font(.headline)
                                Field(title: ui.defaultAlias, text: $alias)
                            }

                            if ui.showPackage {
                                Text("Pacote").foregroundColor(.white.opacity(0.85)).font(.headline)
                                Field(title: "Painel rage", text: $package)
                            }

                            if ui.showPreview {
                                Text("Prévia da key").foregroundColor(.white.opacity(0.75))
                                Text("\(alias.isEmpty ? ui.defaultAlias : alias)-\(normalizedUnit)-xxxxxxxx")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white.opacity(0.8))
                                    .background(Color.white.opacity(0.09))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            MainButton(title: loading ? "Gerando..." : ui.createButtonText) {
                                Task { await create() }
                            }
                        }
                    }

                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(generated.isEmpty ? .red : .green)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }

                    if !generated.isEmpty {
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Últimas keys geradas")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                ForEach(generated, id: \.self) { key in
                                    HStack {
                                        Text(key)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        Button(ui.copyButtonText) {
                                            UIPasteboard.general.string = key
                                        }
                                        .foregroundColor(hexColor(app.config.secondary))
                                    }
                                }
                                MainButton(title: "Copiar todas") {
                                    UIPasteboard.general.string = generated.joined(separator: "\n")
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                let ui = app.config.keyUI
                if alias.isEmpty { alias = ui.defaultAlias }
                if unit.isEmpty { unit = ui.defaultDurationType }
            }
            .alert("Result", isPresented: $showResult) {
                Button("Fechar", role: .cancel) {}
                Button(ui.copyButtonText) { UIPasteboard.general.string = generated.joined(separator: "\n") }
            } message: {
                Text(generated.joined(separator: "\n"))
            }
        }
    }

    func create() async {
        loading = true
        defer { loading = false }
        do {
            let ui = app.config.keyUI
            let owner = app.user?.username ?? "admin"
            let qty = max(1, Int(quantity) ?? 1)
            let dur = max(1, Int(duration) ?? 1)
            let useAlias = alias.isEmpty ? ui.defaultAlias : alias
            let codes = try await APIClient.shared.generateKeys(
                owner: owner,
                quantity: qty,
                duration: dur,
                unit: normalizedUnit,
                package: package.isEmpty ? "PADRAO" : package,
                alias: useAlias,
                autoClean: false,
                multipleActivate: false
            )
            generated = codes
            await app.refreshUser()
            UIPasteboard.general.string = codes.joined(separator: "\n")
            message = codes.count == 1 ? "Key gerada e copiada" : "\(codes.count) keys geradas e copiadas"
            showResult = true
        } catch {
            generated = []
            message = error.localizedDescription
        }
    }
}

struct KeysView: View {
    @EnvironmentObject var app: AppState
    @State var keys: [KeyItem] = []
    @State var selectedKeys: Set<String> = []
    @State var message = ""
    @State var filter = "Todas"
    @State var searchText = ""
    @State var deleting = false
    @State var resetting = false
    let filters = ["Todas", "Active", "Used", "Expired"]

    var visible: [KeyItem] {
        let byFilter: [KeyItem]
        if filter == "Todas" { byFilter = keys }
        else {
            byFilter = keys.filter {
                (filter == "Expired" && $0.isExpired) ||
                (filter == "Used" && $0.used && !$0.isExpired) ||
                ($0.status.lowercased() == filter.lowercased())
            }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return byFilter }
        return byFilter.filter { item in
            item.key.localizedCaseInsensitiveContains(q) ||
            item.type.localizedCaseInsensitiveContains(q) ||
            item.owner.localizedCaseInsensitiveContains(q)
        }
    }

    var allVisibleSelected: Bool {
        !visible.isEmpty && visible.allSatisfy { selectedKeys.contains($0.key) }
    }

    var body: some View {
        let ui = app.config.keyUI
        Screen {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(ui.titleList)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button("Atualizar") { Task { await load() } }
                        .foregroundColor(hexColor(app.config.secondary))
                }

                Picker("Filtro", selection: $filter) {
                    ForEach(filters, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)

                Field(title: "Pesquisar key", text: $searchText)

                if !selectedKeys.isEmpty {
                    HStack(spacing: 10) {
                        Text("\(selectedKeys.count) selecionada(s)")
                            .foregroundColor(.white)
                            .font(.headline)
                        Spacer()
                        Button(allVisibleSelected ? ui.deselectText : ui.selectAllText) {
                            toggleSelectAll()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)

                        Button(action: { copySelected() }) {
                            Image(systemName: "doc.on.doc")
                                .padding(10)
                                .background(hexColor(app.config.primary).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                        }

                        Button(action: { Task { await resetSelected() } }) {
                            Image(systemName: "arrow.counterclockwise")
                                .padding(10)
                                .background(Color.orange.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                        }
                        .disabled(resetting)

                        Button(action: { Task { await deleteSelected() } }) {
                            Image(systemName: "trash.fill")
                                .padding(10)
                                .background(Color.red.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                        }
                        .disabled(deleting)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if visible.isEmpty {
                    Card { Text("Nenhuma key encontrada").foregroundColor(.white.opacity(0.7)) }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(visible) { item in
                            KeyRow(
                                item: item,
                                selected: selectedKeys.contains(item.key),
                                onToggle: { toggle(item.key) }
                            )
                        }
                    }
                }

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(message.lowercased().contains("erro") ? .red : .green)
                        .font(.caption)
                }
            }
            .task { await load() }
        }
    }

    func toggle(_ key: String) {
        if selectedKeys.contains(key) { selectedKeys.remove(key) }
        else { selectedKeys.insert(key) }
    }

    func toggleSelectAll() {
        if allVisibleSelected {
            visible.forEach { selectedKeys.remove($0.key) }
        } else {
            visible.forEach { selectedKeys.insert($0.key) }
        }
    }

    func copySelected() {
        let selectedList = keys.filter { selectedKeys.contains($0.key) }.map { $0.key }
        UIPasteboard.general.string = selectedList.joined(separator: "\n")
        message = "Keys copiadas"
    }

    func load() async {
        do {
            let owner = app.user?.username ?? ""
            keys = try await APIClient.shared.listKeys(owner: owner)
            selectedKeys = selectedKeys.filter { key in keys.contains { $0.key == key } }
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }

    func resetSelected() async {
        guard !selectedKeys.isEmpty else { return }
        resetting = true
        defer { resetting = false }
        do {
            let count = selectedKeys.count
            try await APIClient.shared.resetKeys(Array(selectedKeys))
            selectedKeys.removeAll()
            await load()
            message = "\(count) key(s) resetada(s). Dias mantidos."
        } catch {
            message = "Erro ao resetar: \(error.localizedDescription)"
        }
    }

    func deleteSelected() async {
        guard !selectedKeys.isEmpty else { return }
        deleting = true
        defer { deleting = false }
        do {
            let count = selectedKeys.count
            try await APIClient.shared.deleteKeys(Array(selectedKeys))
            selectedKeys.removeAll()
            await load()
            message = "\(count) key(s) apagada(s)"
        } catch {
            message = "Erro ao apagar: \(error.localizedDescription)"
        }
    }
}

struct KeyRow: View {
    @EnvironmentObject var app: AppState
    let item: KeyItem
    let selected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(hexColor(app.config.primary).opacity(0.8), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    if selected {
                        Circle()
                            .fill(hexColor(app.config.primary))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.key)
                    .foregroundColor(.white)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(item.durationText) • \(item.type)")
                    .foregroundColor(.white.opacity(0.65))
                    .font(.caption)
                if item.used || !item.activatedAt.isEmpty {
                    Text("Dispositivo: \(item.deviceText)")
                        .foregroundColor(.white.opacity(0.62))
                        .font(.caption2)
                        .lineLimit(1)
                }
                if !item.expiresAt.isEmpty {
                    Text("Expira: \(item.expiresAt)")
                        .foregroundColor(item.isExpired ? Color.red.opacity(0.9) : Color.white.opacity(0.45))
                        .font(.caption2)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                Text(statusText)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor)
                    .clipShape(Capsule())
                Button("Copiar") { UIPasteboard.general.string = item.key }
                    .foregroundColor(hexColor(app.config.primary))
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(item.isExpired ? Color.red.opacity(0.22) : (selected ? hexColor(app.config.primary).opacity(0.24) : hexColor(app.config.cardBG).opacity(0.96)))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var statusText: String {
        if item.isExpired { return "Expired" }
        return item.used ? "Used" : (item.status.isEmpty ? "Active" : item.status.capitalized)
    }

    var statusColor: Color {
        let s = statusText.lowercased()
        if s.contains("expired") { return .red.opacity(0.85) }
        if s.contains("used") { return .gray.opacity(0.85) }
        if s.contains("pending") { return .yellow.opacity(0.85) }
        return .green.opacity(0.85)
    }
}

struct DevicesView: View {
    @EnvironmentObject var app: AppState
    @State private var keys: [KeyItem] = []
    @State private var message = ""

    var usedKeys: [KeyItem] {
        keys.filter { $0.used || !$0.activatedAt.isEmpty || !$0.ipBound.isEmpty || !$0.ip.isEmpty }
    }

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Dispositivos")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button("Atualizar") { Task { await load() } }
                        .foregroundColor(hexColor(app.config.primary))
                }

                if usedKeys.isEmpty {
                    Card {
                        Text("Nenhum dispositivo usando key ainda")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(usedKeys) { item in
                            Card {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(item.key)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(item.isExpired ? "Vencida" : "Usando")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(item.isExpired ? Color.red.opacity(0.85) : Color.green.opacity(0.85))
                                            .clipShape(Capsule())
                                    }
                                    Text("Dispositivo: \(item.deviceText)")
                                        .foregroundColor(hexColor(app.config.textSecondary))
                                        .font(.subheadline)
                                    Text("Duração: \(item.durationText)")
                                        .foregroundColor(.white.opacity(0.65))
                                        .font(.caption)
                                    if !item.activatedAt.isEmpty {
                                        Text("Ativada: \(item.activatedAt)")
                                            .foregroundColor(.white.opacity(0.55))
                                            .font(.caption2)
                                    }
                                    if !item.expiresAt.isEmpty {
                                        Text("Expira: \(item.expiresAt)")
                                            .foregroundColor(item.isExpired ? .red : .white.opacity(0.55))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                    }
                }

                if !message.isEmpty {
                    Text(message).foregroundColor(.red).font(.caption)
                }
            }
            .task { await load() }
        }
    }

    func load() async {
        do {
            keys = try await APIClient.shared.listKeys(owner: app.user?.username ?? "")
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Screen { VStack(spacing: 16) { Text("Meu Perfil").font(.title.bold()).foregroundColor(.white); Card { VStack(alignment: .leading, spacing: 12) { Text(app.user?.username ?? "").foregroundColor(.white).font(.headline); Text(app.user?.email ?? "").foregroundColor(.white.opacity(0.7)); Text("Plano: \(app.user?.plan ?? "free")").foregroundColor(hexColor(app.config.primary)); Text("Cargo liberado pelo servidor: \(app.user?.role ?? "free")").foregroundColor(.white.opacity(0.7)) } }; MainButton(title: "Sair") { app.logout() }; Spacer() } }
    }
}
