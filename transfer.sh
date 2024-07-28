#!/bin/bash

# Konfiguration
SOURCE_BASE_URL="https://webdav.starturl.de" # Eingabe der WebDav Adresse 1
SOURCE_SUBDIR="data/files"  # Wenn die Dateien in einem Unterverzeichnis liegen, dann ist hier der komplette Pfad anzugeben, ansonsten leer lassen.
SOURCE_USE_SUBDIR=true  # true, wenn ein Unterverzeichnis verwendet wird, sonst false
SOURCE_USER="user" # WebDav Benutzer
SOURCE_PASS="password" # WebDav Passwort

DEST_BASE_URL="https://webdav.zielurl.de"
DEST_SUBDIR=""  # Wenn die Dateien in einem Unterverzeichnis liegen, dann ist hier der komplette Pfad anzugeben, ansonsten leer lassen.
DEST_USE_SUBDIR=false  # true, wenn ein Unterverzeichnis verwendet wird, sonst false
DEST_USER="user"
DEST_PASS="password"

# Zeitdifferenz in Min. die eine Datei auf dem WebDav Server "SOURCE" nach Dateinamenbenennung liegen soll
# Die Dateien haben das Muster "TEXT_00_20240728145000.jpg". Relevant ist die Ziffernfolge, Dateiendung und vorstehender Text nicht.
# Aus der Ziffernfolge wird das Datum der Erstellung und die Uhrzeit ausgelesen (28.07.2024, 14:50:00)
TRANSFER_TIME=5

# Groß- und Kleinschreibung beachten (true) oder ignorieren (false)
CASE_SENSITIVE=true

# Wenn Sie im Falle eines Fehlers per Telegram informiert werden möchten, tragen Sie hier Ihre Daten ein und heben die Kommentierung weiter unten auf
TELEGRAM_BOT_TOKEN="" # Fügen Sie hier den Bot-Token ein
TELEGRAM_CHAT_IDS=("chat_id_1" "chat_id_2")  # Fügen Sie hier Ihre Chat-IDs hinzu ohne Komma und mit Leerzeichen also ("chat_id_1" "chat_id_2" "chat_id_3")

# Sie können einem Monitoring-Tool wie Uptime Kuma nutzen um zu überprüfen ob das Script ordnungsgemäß durchgeführt worden ist!
# Legen Sie einen Push Monitor an und fügen Sie die URL hier ein.
UPTIME_KUMA_URL="https://uptime.monitoring-url.de"

# Setze die Zeitzone auf Europe/Berlin
export TZ='Europe/Berlin'

########################################################################################################################################

# Funktion zum Senden einer Telegram-Nachricht an mehrere Chat-IDs
send_telegram_message() {
    local message=$1
    for chat_id in "${TELEGRAM_CHAT_IDS[@]}"; do
        response=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$chat_id" \
            -d text="$message")
        if [[ $(echo $response | grep -o '"ok":true') ]]; then
            echo "Telegram-Nachricht erfolgreich an Chat-ID $chat_id gesendet."
        else
            echo "Fehler beim Senden der Telegram-Nachricht an Chat-ID $chat_id: $response"
        fi
    done
}

# Die Dateien haben zum Beispiel das Muster "TEXT_00_20240728145000.jpg". Relevant ist die Ziffernfolge,
# Dateiendung und vorstehender Text nicht.
# Aus der Ziffernfolge wird das Datum der Erstellung und die Uhrzeit ausgelesen (28.07.2024, 14:50:00) 
# Funktion zum überprüfen des Dateialters basierend auf dem Dateinamen
check_file_age() {
    local filename=$1
    local current_time=$(date +%Y%m%d%H%M)
    
    # Extrahiere Datum und Zeit aus dem Dateinamen
    local file_datetime=$(echo $filename | grep -oP '\d{12}')
    
    if [ -z "$file_datetime" ]; then
        echo "Konnte kein Datum/Zeit aus dem Dateinamen extrahieren: $filename"
        return 1
    fi
    
    # Berechne die Differenz in Minuten
    local time_diff=$(( ($(date -d "${current_time:0:8} ${current_time:8:4}" +%s) - $(date -d "${file_datetime:0:8} ${file_datetime:8:4}" +%s)) / 60 ))
    
    echo "Datei: $filename"
    echo "Extrahierte Zeit: ${file_datetime:0:8} ${file_datetime:8:4}"
    echo "Aktuelle Zeit: ${current_time:0:8} ${current_time:8:4}"
    echo "Zeitdifferenz in Minuten: $time_diff"
    
    if [ $time_diff -ge $TRANSFER_TIME ]; then
        echo "Datei ist alt genug für die Übertragung."
        return 0
    else
        echo "Datei ist zu neu fürr die Übertragung."
        return 1
    fi
}

# Funktion zum rekursiven Kopieren von Ordnern und Dateien
copy_recursive() {
    local source_path=$1
    local dest_path=$2
    local relative_path=$3

    local response=$(curl -s -u $SOURCE_USER:$SOURCE_PASS -X PROPFIND --header "Depth: 1" --data '<?xml version="1.0"?><D:propfind xmlns:D="DAV:"><D:prop><D:resourcetype/></D:prop></D:propfind>' "${source_path}${relative_path}")

    echo "$response" | grep -oP '(?<=<D:href>).*?(?=</D:href>)' | while read -r item; do
        item=${item#/}
        if [ "$SOURCE_USE_SUBDIR" = true ]; then
            item=${item#$SOURCE_SUBDIR/}
        fi
        
        if [ -z "$item" ] || [ "$item" = "${relative_path%/}" ]; then
            continue
        fi

        local item_path="${relative_path}${item}"
        local is_directory=$(echo "$response" | grep -A1 "<D:href>.*$item</D:href>" | grep -q "<D:collection/>"; echo $?)

        if [ $is_directory -eq 0 ]; then
            curl -s -u $DEST_USER:$DEST_PASS -X MKCOL "${dest_path}${item_path}"
            copy_recursive "$source_path" "$dest_path" "${item_path}/"
        else
            local source_file="${source_path}${item_path}"
            local dest_file="${dest_path}${item_path}"
            
            if check_file_age "$item"; then
                echo "Kopiere Datei: $item_path"
                echo "Quelle: $source_file"
                echo "Ziel: $dest_file"
                
                curl -s -u $SOURCE_USER:$SOURCE_PASS -L "$source_file" | curl -s -u $DEST_USER:$DEST_PASS -T - "$dest_file"
                
                if [ $? -eq 0 ]; then
                    if curl -s -u $DEST_USER:$DEST_PASS --head "$dest_file" | grep -q "HTTP/1.1 200"; then
                        curl -s -u $SOURCE_USER:$SOURCE_PASS -X DELETE "$source_file"
                        echo "Datei $item_path erfolgreich übertragen und gelöscht"
                    else
                        send_telegram_message "Fehler: Datei ${item_path} konnte nicht auf dem Ziel verifiziert werden"
                        return 1
                    fi
                else
                    send_telegram_message "Fehler beim Kopieren der Datei ${item_path}"
                    return 1
                fi
            else
                echo "Datei ${item_path} ist weniger als $($TRANSFER_TIME) Minuten alt. Überspringe..."
            fi
        fi
    done
}

# Hauptprogramm
echo "Starte Dateiübertragung..."

SOURCE_URL="${SOURCE_BASE_URL}"
DEST_URL="${DEST_BASE_URL}"

if [ "$SOURCE_USE_SUBDIR" = true ] && [ -n "$SOURCE_SUBDIR" ]; then
    SOURCE_URL="${SOURCE_URL}/${SOURCE_SUBDIR}"
fi

if [ "$DEST_USE_SUBDIR" = true ] && [ -n "$DEST_SUBDIR" ]; then
    DEST_URL="${DEST_URL}/${DEST_SUBDIR}"
fi

echo "SOURCE_URL: $SOURCE_URL"
echo "DEST_URL: $DEST_URL"
echo "SOURCE_USER: $SOURCE_USER"
echo "DEST_USER: $DEST_USER"

echo "Überprüfe Verbindung zum Quellserver..."
if ! curl -s -u $SOURCE_USER:$SOURCE_PASS -X PROPFIND "$SOURCE_URL" > /dev/null; then
    echo "Fehler: Konnte keine Verbindung zum Quellserver herstellen. Bitte überprüfen Sie die URL und Zugangsdaten."
    exit 1
fi

echo "Überprüfe Verbindung zum Zielserver..."
if ! curl -s -u $DEST_USER:$DEST_PASS -X PROPFIND "$DEST_URL" > /dev/null; then
    echo "Fehler: Konnte keine Verbindung zum Zielserver herstellen. Bitte überprüfen Sie die URL und Zugangsdaten."
    exit 1
fi

# überprüfen, ob Dateien auf der Quelle vorhanden sind
files=$(curl -s -u $SOURCE_USER:$SOURCE_PASS -X PROPFIND --header "Depth: 1" "$SOURCE_URL" | grep -oP '(?<=<D:href>).*?(?=</D:href>)')
if [ -z "$files" ]; then
    echo "Keine Dateien auf der Quelle gefunden"
    curl -s $UPTIME_KUMA_URL > /dev/null
    exit 0
fi

if copy_recursive "$SOURCE_URL" "$DEST_URL" "/"; then
    echo "Alle Übertragungen erfolgreich abgeschlossen."
else
    echo "Es gab Fehler bei der Übertragung."
    send_telegram_message "Warnung: Es gab Probleme bei der Dateiübertragung."
fi

curl -s $UPTIME_KUMA_URL > /dev/null
