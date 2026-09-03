import XCTest
@testable import LeChariot

/// Je ein echtes Beispiel pro CDN aus der Angebotstabelle vom 03.09.2026.
/// Die Zahlen hinter den Regeln stehen bei `ThumbnailURL`.
final class ThumbnailURLTests: XCTestCase {
    func testScene7GetsWidthAndFormat() {
        let url = URL(string: "https://s7g10.scene7.com/is/image/aldinord/1044914_37_2026_hohes_c_1l_on_comp")!
        let klein = ThumbnailURL.sized(url, px: 144).absoluteString
        XCTAssertTrue(klein.contains("wid=144"), klein)
        XCTAssertTrue(klein.contains("fmt=webp"), klein)
    }

    /// Pennys Adressen bringen `impolicy` schon mit. Ohne die Richtlinie
    /// liefert der Host das unbeschnittene Original — also darf nur die
    /// Breite getauscht werden.
    func testPennyKeepsItsPolicyAndOnlySwapsTheWidth() {
        let url = URL(string: "https://cdn.penny.de/dam/jcr:80487a66-20e7-4268-8dc2-fd998133844a/50488192.png?impolicy=penny&imwidth=600")!
        let klein = ThumbnailURL.sized(url, px: 144).absoluteString
        XCTAssertTrue(klein.contains("impolicy=penny"), klein)
        XCTAssertTrue(klein.contains("imwidth=144"), klein)
        XCTAssertFalse(klein.contains("imwidth=600"), klein)
    }

    /// Kaufland, NORMA und Lidl kennen keinen Größenparameter (am 03.09. mit
    /// `wid`, `hei`, `imwidth`, `width` und `fit=constrain` durchprobiert).
    /// Ihre Adressen bleiben unangetastet; für sie verkleinert der Lader.
    func testHostsWithoutASizeParameterStayUntouched() {
        for adresse in [
            "https://kaufland.media.schwarz/is/image/schwarz/4035900465006_DE_P-1",
            "https://www.norma-online.de/ext/img/product/angebote/26_09_09/200_vodka_wo.png",
            "https://www.lidl.de/assets/gcp4885578e518a4e11bb510fd818d9e60b.jpg",
            "https://media.kaufland.com/images/PPIM/Lago/c44709042_1.jpg",
        ] {
            let url = URL(string: adresse)!
            XCTAssertEqual(ThumbnailURL.sized(url, px: 144), url)
        }
    }

    /// Ohne Größe bleibt die Adresse, wie sie ist — sonst bekäme das
    /// Detailblatt ein Vorschaubild.
    func testNoSizeNoChange() {
        let url = URL(string: "https://s7g10.scene7.com/is/image/aldinord/x")!
        XCTAssertEqual(ThumbnailURL.sized(url, px: 0), url)
    }
}
