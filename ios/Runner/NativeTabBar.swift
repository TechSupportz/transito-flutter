import Flutter
import UIKit

// MARK: - 1. Factory
class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
	private var messenger: FlutterBinaryMessenger
	
	init(messenger: FlutterBinaryMessenger) {
		self.messenger = messenger
		super.init()
	}
	
	func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
		return NativeTabBarPlatformView(frame: frame, viewId: viewId, args: args, messenger: messenger)
	}
	
	func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
		return FlutterStandardMessageCodec.sharedInstance()
	}
}

// MARK: - 2. Platform View Wrapper
class NativeTabBarPlatformView: NSObject, FlutterPlatformView {
	private let controller: LiquidGlassTabBarController
	
	init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
		self.controller = LiquidGlassTabBarController(
			viewId: viewId,
			messenger: messenger,
			args: args
		)
		super.init()
	}
	
	func view() -> UIView {
		return controller.view
	}
}

// MARK: - 3. Data Model
struct TabBarConfig: Equatable {
	var labels: [String] = []
	var symbols: [String] = []
	var hasActionButton: Bool = false
	var tintColor: UIColor = .systemBlue
	var selectedIndex: Int = 0
	
	init(from dict: [String: Any]?) {
		guard let dict = dict else { return }
		if let l = dict["labels"] as? [String] { self.labels = l }
		if let s = dict["symbols"] as? [String] { self.symbols = s }
		if let action = dict["actionButtonSymbol"] as? String, !action.isEmpty {
			self.hasActionButton = true
		}
		if let colorInt = dict["tintColor"] as? NSNumber {
			self.tintColor = TabBarConfig.uiColorFromARGB(colorInt.intValue)
		}
		if let idx = dict["selectedIndex"] as? Int {
			self.selectedIndex = idx
		}
	}
	
	// Helper to check if we need to destroy/recreate tabs
	func structuralChange(from other: TabBarConfig) -> Bool {
		return labels != other.labels ||
		symbols != other.symbols ||
		hasActionButton != other.hasActionButton
	}
	
	private static func uiColorFromARGB(_ argb: Int) -> UIColor {
		let a = CGFloat((argb >> 24) & 0xFF) / 255.0
		let r = CGFloat((argb >> 16) & 0xFF) / 255.0
		let g = CGFloat((argb >> 8) & 0xFF) / 255.0
		let b = CGFloat(argb & 0xFF) / 255.0
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

// MARK: - 4. Optimized Controller
class LiquidGlassTabBarController: UITabBarController, UITabBarControllerDelegate {
	private let channel: FlutterMethodChannel
	private var config: TabBarConfig
	
	init(viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
		self.channel = FlutterMethodChannel(name: "NativeTabBar_\(viewId)", binaryMessenger: messenger)
		self.config = TabBarConfig(from: args as? [String: Any])
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// 1. Base Transparency
		self.view.backgroundColor = .clear
		self.view.isOpaque = false
		
		self.delegate = self
		
		// 2. Initial Setup
		configureAppearance()
		performFullRebuild() // Only called once on load
		
		// 3. Listen for Updates
		channel.setMethodCallHandler { [weak self] call, result in
			self?.handle(call, result: result)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// Aggressively maintain transparency to prevent "White Flash" during rotation/resize
		self.view.backgroundColor = .clear
	}
	
	// MARK: - Appearance
	private func configureAppearance() {
		let appearance = UITabBarAppearance()
		appearance.configureWithDefaultBackground() // Uses System Liquid/Glass Material
		appearance.backgroundColor = .clear
		appearance.shadowColor = .clear
		
		let itemAppearance = UITabBarItemAppearance()
		itemAppearance.normal.iconColor = .systemGray
		itemAppearance.selected.iconColor = config.tintColor
		
		appearance.stackedLayoutAppearance = itemAppearance
		appearance.inlineLayoutAppearance = itemAppearance
		appearance.compactInlineLayoutAppearance = itemAppearance
		
		tabBar.standardAppearance = appearance
		if #available(iOS 15.0, *) {
			tabBar.scrollEdgeAppearance = appearance
		}
		
		tabBar.isTranslucent = true
		tabBar.tintColor = config.tintColor
	}
	
	// MARK: - Logic
	private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		if call.method == "update", let dict = call.arguments as? [String: Any] {
			let newConfig = TabBarConfig(from: dict)
			
			// 1. Check for Structural Changes (Labels/Icons changed)
			// Only rebuild if absolutely necessary to prevent animation resets
			if newConfig.structuralChange(from: self.config) {
				self.config = newConfig
				performFullRebuild()
			} else {
				// 2. Light Update (Color/Selection only)
				self.config = newConfig
				updateSelectionAndColors()
			}
			
			result(nil)
		} else {
			result(FlutterMethodNotImplemented)
		}
	}
	
	// Heavy Operation: Destroys and recreates all tabs
	private func performFullRebuild() {
		var controllers: [UIViewController] = []
		let count = max(config.labels.count, config.symbols.count)
		
		for i in 0..<count {
			let dummyVC = UIViewController()
			dummyVC.view.backgroundColor = .clear
			
			let symbolName = i < config.symbols.count ? config.symbols[i] : "questionmark"
			let label = i < config.labels.count ? config.labels[i] : ""
			
			dummyVC.tabBarItem = UITabBarItem(
				title: label,
				image: UIImage(systemName: symbolName),
				tag: i
			)
			controllers.append(dummyVC)
		}
		
		if config.hasActionButton {
			let actionVC = UIViewController()
			actionVC.view.backgroundColor = .clear
			// Use System Search Item
			let item = UITabBarItem(tabBarSystemItem: .search, tag: 99)
			actionVC.tabBarItem = item
			controllers.append(actionVC)
		}
		
		// Set controllers without animation to prevent visual jumping during init
		self.setViewControllers(controllers, animated: false)
		
		// Restore selection
		updateSelectionAndColors()
	}
	
	// Light Operation: Just changes properties
	private func updateSelectionAndColors() {
		// Update Tint
		if tabBar.tintColor != config.tintColor {
			tabBar.tintColor = config.tintColor
			// We must update the appearance object too for unselected states if needed
			configureAppearance()
		}
		
		// Update Selection
		// Only update if different to avoid interrupting native transitions
		if self.selectedIndex != config.selectedIndex {
			// Ensure we don't select the action button
			if let vcs = self.viewControllers,
			   config.selectedIndex < vcs.count,
			   vcs[config.selectedIndex].tabBarItem.tag != 99 {
				self.selectedIndex = config.selectedIndex
			}
		}
	}
	
	// MARK: - Delegate
	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		let tag = viewController.tabBarItem.tag
		
		if tag == 99 {
			channel.invokeMethod("actionButtonPressed", arguments: nil)
			return false
		}
		return true
	}
	
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		let tag = viewController.tabBarItem.tag
		if tag != 99 {
			// Update our local config immediately so incoming Flutter updates don't revert it momentarily
			config.selectedIndex = tag
			channel.invokeMethod("valueChanged", arguments: ["index": tag])
		}
	}
}
