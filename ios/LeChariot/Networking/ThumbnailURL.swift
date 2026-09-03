import Foundation

/// Bilder in der Größe holen, in der sie gezeichnet werden.
///
/// Die Angebotszeile zeichnet ein 48-pt-Bildchen — auf einem 3×-Gerät 144 px.
/// Geladen wurde bis zum 2026-09-03 die Originaldatei des Händlers, und die
/// ist um Größenordnungen zu groß. Gemessen an je einer Datei pro CDN
/// (Vierfilialen-Woche vom 03.09., 1678 verschiedene Bilder):
///
/// | CDN | Anteil | Original | mit Größenwunsch |
/// |---|---:|---:|---|
/// | `cdn.penny.de` | 1032 | 178 kB @ 600 px | **15 kB** @ 150 px |
/// | `s7g10.scene7.com` (ALDI) | 519 | 146 kB @ 1280 px | **3,1 kB** @ 144 px |
/// | `kaufland.media.schwarz` | 473 | 71 kB @ 1440 px | unverändert |
/// | `www.norma-online.de` | 212 | 18 kB @ 213 px | schon klein |
/// | `www.lidl.de` | 142 | 3 kB @ 380 px | schon klein |
///
/// **Nur zwei Hosts kennen einen Größenparameter, und sie tragen 92 % der
/// Bilder.** Kaufland ignoriert jede Schreibweise, die am 03.09. versucht
/// wurde (`wid`, `hei`, `imwidth`, `width`, `fit=constrain`) — dort bleibt nur
/// der Spiegel im Backend, und bis dahin die Verkleinerung im Gerät.
///
/// **Warum im Gerät und nicht beim Push?** Nur die App weiß, wie groß sie
/// zeichnet, und dieselbe Zeile steht auf einem 2×- und einem 3×-Gerät. Und
/// eine Regel hier greift auch für Zeilen, die längst im Cache liegen, ohne
/// dass ein Prospekt neu gepusht werden muss.
enum ThumbnailURL {
    /// Die Adresse, unter der dieses Bild höchstens `px` Pixel breit ist.
    /// Kennt der Host keinen Größenparameter, kommt die Adresse unverändert
    /// zurück — dann verkleinert der Lader beim Dekodieren.
    static func sized(_ url: URL, px: Int) -> URL {
        guard px > 0, var parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = parts.host?.lowercased()
        else { return url }

        if host.hasSuffix(".scene7.com") {
            // Scene7 nimmt den Wunsch als Abfrage entgegen; `fmt=webp` spart
            // gegenüber dem PNG noch einmal die Hälfte (5,5 → 3,1 kB).
            parts.queryItems = [
                URLQueryItem(name: "wid", value: String(px)),
                URLQueryItem(name: "fmt", value: "webp"),
            ]
        } else if host == "cdn.penny.de" {
            // Penny schickt die Adresse selbst schon mit `impolicy` und
            // `imwidth`; nur die Breite wird ersetzt, die Richtlinie bleibt —
            // ohne sie liefert der Host das unbeschnittene Original.
            var items = parts.queryItems ?? []
            items.removeAll { $0.name == "imwidth" }
            items.append(URLQueryItem(name: "imwidth", value: String(px)))
            parts.queryItems = items
        } else {
            return url
        }
        return parts.url ?? url
    }
}
