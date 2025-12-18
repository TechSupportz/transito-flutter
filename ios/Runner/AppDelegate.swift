import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let registrar = self.registrar(forPlugin: "GlassButton")!
    let glassButtonFactory = GlassButtonFactory(messenger: registrar.messenger())
    registrar.register(glassButtonFactory, withId: "GlassButton")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
