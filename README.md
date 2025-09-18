# Redactly

**Redactly** ist eine lokale Desktop-App (macOS & Windows), um Texte schnell und sicher zu anonymisieren.  
Platzhalter ersetzen sensible Daten wie Namen, E-Mail-Adressen oder Orte, und können bei Bedarf wieder zurückverwandelt werden.  
Die App arbeitet komplett offline – keine Daten verlassen deinen Rechner.

---

## ✨ Features

- 📝 Texteditor mit Highlighting für Platzhalter
- 🔄 Automatische Ersetzung & Rückumwandlung
- 📂 Session-Management (mehrere Projekte parallel)
- 💾 Speicherung in Hive (lokal, offline)
- 📋 Copy-to-Clipboard & Export als JSON oder Text
- 🎨 Modernes, schlankes UI für macOS & Windows

---

## 🚀 Installation

### macOS
1. Lade die aktuelle `.dmg` oder `.zip` aus den Releases herunter.
2. Entpacke und verschiebe **Redactly.app** in den Programme-Ordner.
3. Falls macOS beim ersten Start blockiert: Rechtsklick → *Öffnen*.

### Windows
1. Lade die aktuelle `.msix` oder `.zip` aus den Releases herunter.
2. Für `.msix`: Doppelklick → Installation folgen.
3. Für `.zip`: Entpacken und `Redactly.exe` starten.

---

## 🛠️ Entwicklung

Voraussetzungen:
- Flutter (>=3.22, channel *stable*)
- Dart SDK
- macOS 12+ oder Windows 10+ für Desktop-Builds

Setup:
```bash
flutter pub get
flutter run -d macos    # oder windows
