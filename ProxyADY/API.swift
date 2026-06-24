import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private func request(path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: AppConfig.apiBaseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 25
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = UserDefaults.standard.string(forKey: "auth_token"), !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }

    func config() async -> AppRemoteConfig {
        for path in ["/app_design.php", "/app_config.php", "/config.php"] {
            do {
                let data = try await request(path: path)
                if let cfg = try? JSONDecoder().decode(AppRemoteConfig.self, from: data) { return cfg }
                struct Wrapped: Decodable { var success: Bool; var data: AppRemoteConfig? }
                if let w = try? JSONDecoder().decode(Wrapped.self, from: data), let cfg = w.data { return cfg }
            } catch { }
        }
        return AppRemoteConfig()
    }

    func register(username: String, email: String, password: String) async throws -> AuthReply {
        let data = try await request(path: "/register.php", method: "POST", body: ["username": username, "email": email, "password": password])
        return try JSONDecoder().decode(AuthReply.self, from: data)
    }

    func login(login: String, password: String) async throws -> AuthReply {
        let data = try await request(path: "/login.php", method: "POST", body: ["email": login, "username": login, "login": login, "password": password])
        return try JSONDecoder().decode(AuthReply.self, from: data)
    }

    func me(login: String) async throws -> AppUser? {
        let data = try await request(path: "/me.php", method: "POST", body: ["email": login, "username": login])
        let r = try JSONDecoder().decode(UserReply.self, from: data)
        return r.user ?? r.data
    }

    func generateKeys(owner: String, quantity: Int, duration: Int, unit: String, package: String, alias: String, autoClean: Bool, multipleActivate: Bool) async throws -> [String] {
        let body: [String: Any] = [
            "owner": owner,
            "username": owner,
            "quantity": quantity,
            "days": duration,
            "duration": duration,
            "duration_days": duration,
            "duration_type": unit.lowercased(),
            "unit": unit.lowercased(),
            "type": package,
            "package": package,
            "alias": alias,
            "prefix": alias,
            "auto_clean": autoClean,
            "multiple_activate": multipleActivate
        ]
        let data = try await request(path: "/generate_key.php", method: "POST", body: body)
        var result: [String] = []

        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let success = obj["success"] as? Bool, success == false {
                let msg = obj["message"] as? String ?? "Não foi possível gerar key"
                throw NSError(domain: "ProxyADY", code: 400, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            if let keys = obj["keys"] as? [String] { result.append(contentsOf: keys) }
            if let key = obj["key"] as? String { result.append(key) }
            if let dataArray = obj["data"] as? [[String: Any]] {
                result.append(contentsOf: dataArray.compactMap { $0["key"] as? String })
            }
            if let dataObj = obj["data"] as? [String: Any], let key = dataObj["key"] as? String {
                result.append(key)
            }
            result = Array(NSOrderedSet(array: result)) as? [String] ?? result
            if result.isEmpty, let success = obj["success"] as? Bool, success {
                result.append(obj["message"] as? String ?? "Key gerada")
            }
            return result
        }

        let r = try JSONDecoder().decode(KeyGenerateReply.self, from: data)
        if let arr = r.keys { result.append(contentsOf: arr) }
        if let one = r.key { result.append(one) }
        if let item = r.data, !item.key.isEmpty { result.append(item.key) }
        result = Array(NSOrderedSet(array: result)) as? [String] ?? result
        if result.isEmpty && r.success { result.append(r.message ?? "Key gerada") }
        return result
    }

    func listKeys(owner: String, search: String = "") async throws -> [KeyItem] {
        let encoded = owner.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? owner
        let encodedSearch = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search
        let suffix = encodedSearch.isEmpty ? "" : "&q=\(encodedSearch)"
        let data = try await request(path: "/keys.php?username=\(encoded)\(suffix)")
        let decoder = JSONDecoder()
        if let direct = try? decoder.decode([KeyItem].self, from: data) {
            return direct
        }
        let r = try decoder.decode(KeysReply.self, from: data)
        return r.data ?? r.keys ?? []
    }

    func resetKeys(_ keys: [String]) async throws {
        guard !keys.isEmpty else { return }
        let body: [String: Any] = ["keys": keys, "key": keys.first ?? ""]
        do {
            _ = try await request(path: "/reset_keys.php", method: "POST", body: body)
        } catch {
            _ = try await request(path: "/reset_key.php", method: "POST", body: body)
        }
    }



    func deleteKeys(_ keys: [String]) async throws {
        guard !keys.isEmpty else { return }
        let body: [String: Any] = ["keys": keys, "key": keys.first ?? ""]
        do {
            _ = try await request(path: "/delete_keys.php", method: "POST", body: body)
        } catch {
            _ = try await request(path: "/delete_key.php", method: "POST", body: body)
        }
    }

    func updateUser(username: String, role: String, credits: Double, actor: String) async throws -> String {
        let body: [String: Any] = ["email": username, "username": username, "role": role, "credits": credits, "credit": credits, "plan": role, "status": "active", "actor": actor, "admin": actor, "created_by": actor]
        do {
            let data = try await request(path: "/admin/update_user.php", method: "POST", body: body)
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = obj["message"] as? String { return msg }
        } catch {
            let data = try await request(path: "/admin_set_user.php", method: "POST", body: body)
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let msg = obj["message"] as? String { return msg }
        }
        return "Usuário atualizado"
    }
    func superOverview() async throws -> [SuperSellerItem] {
        let data = try await request(path: "/super_overview.php", method: "POST", body: [:])
        let r = try JSONDecoder().decode(SuperOverviewReply.self, from: data)
        return r.sellers ?? r.data ?? []
    }

}
