import AppIntents
import UIKit

/// Acción de Atajos y de Siri: «Guardar enlace copiado». Abre SaveReel por
/// `savetic://clipboard`; la app lee el portapapeles, busca el video y muestra
/// los formatos, igual que al compartir desde TikTok o Instagram.
@available(iOS 16.0, *)
struct SaveCopiedLinkIntent: AppIntent {
  static var title: LocalizedStringResource = "Guardar enlace copiado"
  static var description = IntentDescription(
    "Abre SaveReel con el enlace de TikTok o Instagram que tengas copiado."
  )

  /// La app tiene que verse para leer el portapapeles.
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    if let url = URL(string: "savetic://clipboard") {
      await UIApplication.shared.open(url)
    }
    return .result()
  }
}

/// Deja la acción lista en la app Atajos y disponible por voz, sin que el
/// usuario tenga que configurar nada.
@available(iOS 16.0, *)
struct SaveReelShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: SaveCopiedLinkIntent(),
      phrases: [
        "Guardar enlace copiado en \(.applicationName)",
        "Guarda el enlace copiado con \(.applicationName)",
        "Descargar el video copiado con \(.applicationName)",
      ],
      shortTitle: "Guardar enlace copiado",
      systemImageName: "arrow.down.to.line"
    )
  }
}
