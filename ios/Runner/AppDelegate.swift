import Flutter
import Network
import UIKit
import UserNotifications

/// Vigila el tipo de red: `isExpensive` es cierto con datos móviles o con un
/// punto de acceso del teléfono, y `isConstrained` con el modo de datos reducidos.
final class NetworkMonitor {
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "savetic.network")
  private var metered = false

  var isMetered: Bool { queue.sync { metered } }

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      self?.metered = path.isExpensive || path.isConstrained
    }
    monitor.start(queue: queue)
  }
}

/// Pide tiempo extra a iOS mientras hay descargas y avisa al terminar. iOS
/// suspende la app a los ~30 s de pasar a segundo plano y no deja seguir
/// ejecutando código: la descarga se pausa y se retoma sola al volver.
final class BackgroundDownloads {
  private var task: UIBackgroundTaskIdentifier = .invalid
  private var askedForNotifications = false

  func sync(count: Int) {
    if count == 0 {
      end()
      return
    }
    askForNotificationsOnce()
    guard task == .invalid else { return }
    task = UIApplication.shared.beginBackgroundTask(withName: "savetic.download") { [weak self] in
      self?.end()
    }
  }

  func finished(heading: String, detail: String) {
    // En primer plano la app ya lo muestra por su cuenta.
    guard UIApplication.shared.applicationState != .active else { return }
    let content = UNMutableNotificationContent()
    content.title = heading
    content.body = detail
    content.sound = .default
    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }

  private func end() {
    guard task != .invalid else { return }
    UIApplication.shared.endBackgroundTask(task)
    task = .invalid
  }

  private func askForNotificationsOnce() {
    guard !askedForNotifications else { return }
    askedForNotifications = true
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let networkMonitor = NetworkMonitor()
  private let backgroundDownloads = BackgroundDownloads()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FlutterMethodChannel(
      name: "savetic/network",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { [weak self] call, result in
      if call.method == "isMetered" {
        result(self?.networkMonitor.isMetered ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterMethodChannel(
      name: "savetic/background",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { [weak self] call, result in
      let arguments = call.arguments as? [String: Any]
      switch call.method {
      case "sync":
        self?.backgroundDownloads.sync(count: arguments?["count"] as? Int ?? 0)
        result(nil)
      case "finished":
        self?.backgroundDownloads.finished(
          heading: arguments?["heading"] as? String ?? "",
          detail: arguments?["detail"] as? String ?? "")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
