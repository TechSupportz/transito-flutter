import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let registrar = self.registrar(forPlugin: "NativeTabBar")!
    let factory = NativeTabBarFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "NativeTabBar")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
