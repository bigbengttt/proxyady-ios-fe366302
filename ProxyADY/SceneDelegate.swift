import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: LoginViewController())
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        APIClient.sendHeartbeat()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        APIClient.startHeartbeat()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        APIClient.deactivate()
    }
}
