import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  let flutterEngine = FlutterEngine(name: "main")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 13.0, *) {
      flutterEngine.run()
      GeneratedPluginRegistrant.register(with: flutterEngine)
    } else {
      GeneratedPluginRegistrant.register(with: self)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

@available(iOS 13.0, *)
@objc(SceneDelegate)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard
      let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
    else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    let viewController = FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
    viewController.loadDefaultSplashScreenView()
    window.rootViewController = viewController
    self.window = window
    appDelegate.window = window
    window.makeKeyAndVisible()

    connectionOptions.urlContexts.forEach {
      _ = appDelegate.application(UIApplication.shared, open: $0.url)
    }
    connectionOptions.userActivities.forEach {
      _ = appDelegate.application(UIApplication.shared, continue: $0) { _ in }
    }
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }

    URLContexts.forEach {
      _ = appDelegate.application(UIApplication.shared, open: $0.url)
    }
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    (UIApplication.shared.delegate as? AppDelegate)?
      .application(UIApplication.shared, continue: userActivity) { _ in }
  }
}
