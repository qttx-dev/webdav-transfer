# WebDAV Transfer

Eine elegante Lösung zum Übertragen zwischen zwei Cloudservern mit WebDAV-Zugang.

## Übersicht

Dieses Projekt überbrückt die Lücke zwischen der FTP-Upload-Funktionalität von Reolink-Kameras und Cloud-Servern, die nur über WebDAV erreichbar sind. So wird sichergestellt, dass Ihre Überwachungsaufnahmen sicher gespeichert und leicht zugänglich sind.

## Funktionen

- 📂 **Intelligente Dateiübertragung**: Prüft das Alter der Dateien vor der Übertragung
- ⏳ **Anpassbare Verzögerung**: Legen Sie Ihre bevorzugte Übertragungsverzögerung fest
- 📱 **Fehlerbenachrichtigungen**: Optionale Telegram-Integration für Benachrichtigungen
- 📊 **Monitoring-Integration**: Kompatibel mit Tools wie Uptime Kuma
- ✅ **Überprüfungen**: Bestätigt erfolgreiche Dateiübertragungen
- 📁 **Dateifokus**: Überträgt einzelne Dateien, keine Verzeichnisse

## Anforderungen

- 🌐 Zugriff auf einen Server mit Internetverbindung (z.B. vServer, Homelab, Raspberry Pi)
- 🖥️ Shell-Zugriff
- 🔑 Zwei WebDAV-Konten
- 🤖 Telegram Bot Token (optional)
- 📈 Monitoring-Tool (z.B. Uptime Kuma, optional)

## Schnellstart

1. Überprüfen Sie, ob cURL installiert ist:
   ```bash
   curl --version
   ```

2. Falls nötig, installieren Sie cURL:
   ```bash
   sudo apt update && sudo apt upgrade
   sudo apt install curl
   ```

3. Erstellen und bearbeiten Sie das Script:
   ```bash
   nano transfer.sh
   ```

4. Fügen Sie den Inhalt des Scripts ein und konfigurieren Sie Ihre Einstellungen (siehe unten).

5. Machen Sie das Script ausführbar:
   ```bash
   chmod +x transfer.sh
   ```

6. Führen Sie das Script aus:
   ```bash
   ./transfer.sh
   ```

## Konfiguration

Bearbeiten Sie die folgenden Variablen in `transfer.sh`:

### WebDAV Verbindung 1
- `SOURCE_BASE_URL`  WebDAV URL (https://webdav.beispiel1.tld)
- `SOURCE_SUBDIR` ggfs. Unterverzeichnis
- `SOURCE_USE_SUBDIR` true/false (wenn Unterverzeichnisse verwendet werden)
- `SOURCE_USER` Benutzer
- `SOURCE_PASS` Kennwort

### WebDAV Verbindung 2
- `DEST_BASE_URL` WebDAV URL (https://webdav.beispiel2.tld)
- `DEST_SUBDIR` ggfs. Unterverzeichnis
- `DEST_USE_SUBDIR` true/false (wenn Unterverzeichnisse verwendet werden)
- `DEST_USER` Benutzer
- `DEST_PASS` Kennwort

### weitere Einstellungen
- `TRANSFER_TIME` Alter einer Datei bis zum Transfer
- `CASE_SENSITIV` true/false (Klein- und Großschreibung relevant)
- `TELEGRAM_BOT_TOKEN` Telegram Bot Token
- `TELEGRAM_CHAT_IDS` Telegram Chat ID
- `UPTIME_KUMA_URL` Uptime Kuma Push URL
- `TZ` Zeitzone

## Automatische Ausführung
Sie können das Script automatisch ausführen. Für eine Ausführung alle 5 Minuten verwenden Sie zum Beispiel folgenden Cron-Tab Eintrag.
*Es empfielt sich, die selbe Zeit wie im Script zu nutzen*

   ```bash
   crontab -e
   ```

   ```bash
   */5 * * * * /pfad/zum/script/transfer.sh
   ```

## Vorsicht

Testen Sie das Script immer mit gesicherten Dateien, bevor Sie es mit wichtigen Daten ausführen.

## Unterstützung

Bei Problemen, Fragen oder Beiträgen öffnen Sie bitte ein Issue in diesem GitHub-Repository.

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz - siehe die [LICENSE](LICENSE) Datei für Details.

---

Hergestellt mit ❤️ von qttx-dev
