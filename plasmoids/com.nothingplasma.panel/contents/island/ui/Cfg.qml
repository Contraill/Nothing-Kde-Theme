pragma Singleton

import QtQuick
QtObject {
    id: cfg
    property string lang: "auto"
    // UI language can differ from the number/date formatting locale.
    readonly property string systemLanguage: Qt.uiLanguage || Qt.locale().uiLanguages[0] || Qt.locale().name

    readonly property string localeName: {
        if (cfg.lang === "tr")
            return "tr_TR";
        if (cfg.lang === "en")
            return "en_US";
        return Qt.locale().name;
    }

    readonly property var locale: Qt.locale(cfg.localeName)
    readonly property bool turkish: cfg.lang === "tr" || (cfg.lang === "auto" && cfg.systemLanguage.toLowerCase().startsWith("tr"))
    property bool clock24: true

    readonly property string fmtHora: cfg.clock24 ? "HH:mm" : "h:mm AP"
    readonly property string fmtHoraCorta: cfg.clock24 ? "HH:mm" : "h:mm"
    property bool ramUsage: false
    property bool showWorkspaces: true
    property bool showWeather: true
    property bool showClock: true
    property bool showNetwork: true
    property bool showVolume: true
    property bool showBattery: true
    property bool showMini: true
    property string weatherCity: ""
    property color colorFondo: "#000000"
    property color colorTarjeta: "#0B0B0B"
    property color colorInvertida: "#FFFFFF"
    property color colorAlerta: "#D71921"
    property color colorTexto: "#FFFFFF"
    property string fuenteUi: ""
    property string fuenteNumeros: ""
    readonly property var textos: ({
        "SHOW SYSTEM TRAY": ["Sistem tepsisini göster", "Show system tray"],
        "CONFIGURE TRAY ITEMS": ["Tepsi simgelerini yapılandır…", "Configure tray icons…"],
        "ACCENT LINKS": ["İsteğe bağlı renk bağlantıları · kapatınca eski görünüm geri gelir. Yeni terminalde etkinleşir.", "Optional accent links · disable to restore. Takes effect in a new terminal."],
        "LINKED": ["Bağlı", "Linked"],
        "UNLINKED": ["Bağlı değil", "Unlinked"],
        "LINK FAILED": ["Renk bağlantısı uygulanamadı.", "Could not apply accent link."],
        "ISLAND SETTINGS": ["Ada ayarları", "Island settings"],
        "CONFIRM POWER ACTIONS": ["Güç işlemlerini onayla", "Confirm power actions"],
        "LIGHT THEME": ["Aydınlık", "Light"],
        "DARK THEME": ["Karanlık", "Dark"],
        "THEME FAILED": ["Tema değiştirilemedi. Lütfen tekrar deneyin.", "Could not change the theme. Please try again."],
        "ACCENT COLOR": ["Vurgu rengi", "Accent color"],
        "ACCENT DESCRIPTION": ["KDE ve Nothing panellerinin vurgu rengini değiştirir.", "Changes the accent color of KDE and Nothing panels."],
        "COLOR SATURATION VALUE": ["Renk doygunluğu ve parlaklığı", "Color saturation and brightness"],
        "COLOR ARROW HELP": ["Sol/sağ doygunluğu, yukarı/aşağı parlaklığı değiştirir.", "Left/right adjusts saturation; up/down adjusts brightness."],
        "COLOR HUE": ["Renk tonu", "Hue"],
        "SELECTED COLOR": ["Seçilen renk", "Selected color"],
        "HEX COLOR": ["Manuel renk kodu (HEX)", "Manual color code (HEX)"],
        "APPLY COLOR": ["Uygula", "Apply"],
        "ACCENT FAILED": ["Renk uygulanamadı. Tekrar deneyin.", "Could not apply the color. Please try again."],
        "NETWORK": [
                "AĞ",
                "NETWORK"
        ],
        "DEVICES": [
                "CİHAZLAR",
                "DEVICES"
        ],
        "CONNECTED": [
                "BAĞLI",
                "CONNECTED"
        ],
        "SAVED NETWORKS": [
                "KAYITLI AĞLAR",
                "SAVED NETWORKS"
        ],
        "KNOWN DEVICES": [
                "BİLİNEN CİHAZLAR",
                "KNOWN DEVICES"
        ],
        "NEARBY NETWORKS": [
                "YAKINDAKİ AĞLAR",
                "NEARBY NETWORKS"
        ],
        "NEARBY DEVICES": [
                "YAKINDAKİ CİHAZLAR",
                "NEARBY DEVICES"
        ],
        "Connected": [
                "Bağlı",
                "Connected"
        ],
        "Saved": [
                "Kayıtlı",
                "Saved"
        ],
        "Available": [
                "Kullanılabilir",
                "Available"
        ],
        "Connecting…": [
                "Bağlanıyor…",
                "Connecting…"
        ],
        "Pairing…": [
                "Eşleştiriliyor…",
                "Pairing…"
        ],
        "Couldn't connect": [
                "Bağlanılamadı",
                "Couldn't connect"
        ],
        "Enter the password": [
                "Parolayı girin",
                "Enter the password"
        ],
        "Password": [
                "Parola",
                "Password"
        ],
        "Searching…": [
                "Aranıyor…",
                "Searching…"
        ],
        "Unknown": [
                "Bilinmiyor",
                "Unknown"
        ],
        "Wi-Fi off": [
                "Wi-Fi kapalı",
                "Wi-Fi off"
        ],
        "Bluetooth off": [
                "Bluetooth kapalı",
                "Bluetooth off"
        ],
        "CALENDAR": [
                "TAKVİM",
                "CALENDAR"
        ],
        "TODAY": [
                "BUGÜN",
                "TODAY"
        ],
        "Week": [
                "Hafta",
                "Week"
        ],
        "RECORDING": [
                "SES KAYDI",
                "RECORDING"
        ],
        "Nothing playing": [
                "Çalan bir şey yok",
                "Nothing playing"
        ],
        "APPS": [
                "UYGULAMALAR",
                "APPS"
        ],
        "Search apps…": [
                "Uygulama ara…",
                "Search apps…"
        ],
        "No results": [
                "Sonuç yok",
                "No results"
        ],
        "Signal": [
                "Sinyal",
                "Signal"
        ],
        "Secured": [
                "Korumalı",
                "Secured"
        ],
        "Open": [
                "Açık",
                "Open"
        ],
        "CONNECT": [
                "BAĞLAN",
                "CONNECT"
        ],
        "DISCONNECT": [
                "BAĞLANTIYI KES",
                "DISCONNECT"
        ],
        "FORGET": [
                "UNUT",
                "FORGET"
        ],
        "No network": [
                "Bağlantı yok",
                "No network"
        ],
        "NO NETWORK": [
                "BAĞLANTI YOK",
                "NO NETWORK"
        ],
        "OFF": [
                "KAPALI",
                "OFF"
        ],
        "ON": [
                "AÇIK",
                "ON"
        ],
        "SOUND": [
                "SES",
                "SOUND"
        ],
        "COFFEE MODE": [
                "KAHVE MODU",
                "COFFEE MODE"
        ],
        "OUTPUT": [
                "ÇIKIŞ",
                "OUTPUT"
        ],
        "INPUT": [
                "GİRİŞ",
                "INPUT"
        ],
        "No outputs": [
                "Çıkış bulunamadı",
                "No outputs"
        ],
        "No inputs": [
                "Giriş bulunamadı",
                "No inputs"
        ],
        "NOTIFICATIONS": [
                "BİLDİRİMLER",
                "NOTIFICATIONS"
        ],
        "MUTE": [
                "SESSİZE AL",
                "MUTE"
        ],
        "MUTED": [
                "SESSİZ",
                "MUTED"
        ],
        "CLEAR": [
                "TEMİZLE",
                "CLEAR"
        ],
        "NO NOTIFICATIONS": [
                "BİLDİRİM YOK",
                "NO NOTIFICATIONS"
        ],
        "POWER": [
                "GÜÇ",
                "POWER"
        ],
        "LOCK": [
                "KİLİTLE",
                "LOCK"
        ],
        "Asks for the password on return": [
                "Döndüğünüzde parola ister",
                "Asks for the password on return"
        ],
        "LOG OUT": [
                "OTURUMU KAPAT",
                "LOG OUT"
        ],
        "Closes the open programs": [
                "Açık uygulamaları kapatır",
                "Closes the open programs"
        ],
        "SLEEP": [
                "UYKU",
                "SLEEP"
        ],
        "Screen off, everything stays as it is": [
                "Ekran kapanır, oturumunuz korunur",
                "Screen off, everything stays as it is"
        ],
        "HIBERNATE": [
                "HAZIRDA BEKLET",
                "HIBERNATE"
        ],
        "Saves everything to disk and powers off": [
                "Oturumu diske kaydeder ve kapatır",
                "Saves everything to disk and powers off"
        ],
        "RESTART": [
                "YENİDEN BAŞLAT",
                "RESTART"
        ],
        "Powers off and starts again": [
                "Bilgisayarı yeniden başlatır",
                "Powers off and starts again"
        ],
        "SHUT DOWN": [
                "KAPAT",
                "SHUT DOWN"
        ],
        "Powers off the computer": [
                "Bilgisayarı kapatır",
                "Powers off the computer"
        ],
        "YES": [
                "EVET",
                "YES"
        ],
        "CANCEL": [
                "VAZGEÇ",
                "CANCEL"
        ],
        "POWER SAVER": ["Güç tasarrufu", "Power saver"],
        "CHECKING…": ["Kontrol ediliyor…", "CHECKING…"],
        "META KEY ENABLED": ["Meta tuşu etkin", "META KEY ENABLED"],
        "META KEY DISABLED": ["Meta tuşu kapalı", "META KEY DISABLED"],
        "META STATUS UNAVAILABLE": ["Meta durumu alınamadı", "META STATUS UNAVAILABLE"],
        "ENABLING META…": ["Meta etkinleştiriliyor…", "ENABLING META…"],
        "DISABLING META…": ["Meta kapatılıyor…", "DISABLING META…"],
        "META UPDATE FAILED": ["Meta güncellenemedi", "META UPDATE FAILED"],
        "‹ BACK": ["‹ Geri", "‹ BACK"],
        "LAUNCHER / SETTINGS": ["Başlatıcı ayarları", "LAUNCHER / SETTINGS"],
        "OPEN APP LAUNCHER": ["UYGULAMA BAŞLATICI", "OPEN APP LAUNCHER"],
        "META / START KEY": ["META / BAŞLAT TUŞU", "META / START KEY"],
        "CAN BE ENABLED OR REMOVED": ["İstediğinde açıp kapatabilirsin", "CAN BE ENABLED OR REMOVED"],
        "OPTIONAL ALTERNATE SHORTCUT": ["ALTERNATİF KISAYOL", "OPTIONAL ALTERNATE SHORTCUT"],
        "CLEAR REMOVES THE ALTERNATE COMBINATION": ["Temizle düğmesi alternatif kısayolu kaldırır", "CLEAR REMOVES THE ALTERNATE COMBINATION"],
        "APPLICATIONS": ["Uygulamalar", "Applications"],
        "SHOW DESKTOP": ["Masaüstünü göster", "Show desktop"],
        "LAUNCHER SETTINGS": ["Başlatıcı ayarları", "Launcher settings"],
        "SEARCH APPS": ["Uygulama ara…", "Search applications…"],
        "SEARCH RESULTS": ["ARAMA SONUÇLARI", "SEARCH RESULTS"],
        "ALL APPS": ["TÜM UYGULAMALAR", "ALL APPLICATIONS"],
        "PIN DOCK": ["Alt bara sabitle", "Pin to dock"],
        "UNPIN DOCK": ["Sabitlemeyi kaldır", "Unpin from dock"],
        "NEW WINDOW": ["Yeni pencere aç", "Open new window"],
        "CHOOSE WINDOW": ["Pencere seç", "Choose window"],
        "RESTORE WINDOW": ["Geri yükle", "Restore"],
        "MINIMIZE WINDOW": ["Küçült", "Minimize"],
        "MAXIMIZE WINDOW": ["Büyüt", "Maximize"],
        "CLOSE ALL WINDOWS": ["Tüm pencereleri kapat", "Close all windows"],
        "CLOSE WINDOW": ["Pencereyi kapat", "Close window"],
        "WINDOWS": ["pencere", "windows"],
        "OPEN APP": ["Aç", "Open"],
        "NO APPS FOUND": ["Uygulama bulunamadı", "No applications found"],
        "LOADING APPS": ["Uygulamalar yükleniyor…", "Loading applications…"],
        "DOCK PIN HINT": ["Sabitlemek için sağ tık · Sıralamak için alt barda sürükle", "Right-click to pin · Drag on the dock to reorder"],
        "BRIGHTNESS": ["PARLAKLIK", "BRIGHTNESS"],
        "KEYBOARD BRIGHTNESS": ["KLAVYE PARLAKLIĞI", "KEYBOARD BRIGHTNESS"],
        "KEYBOARD LIGHTING": ["KLAVYE AYDINLATMASI", "KEYBOARD LIGHTING"],
        "KEYBOARD RIGHT CLICK": ["Klavye aydınlatması için sağ tıklayın", "Right-click for keyboard lighting"],
        "CLOSE": ["Kapat", "Close"],
        "BRIGHTNESS HELP": ["Dahili ekran parlaklığı", "Built-in display brightness"],
        "BATTERY": ["Batarya", "Battery"],
        "CHARGING": ["Şarj oluyor", "Charging"],
        "BALANCED": ["Dengeli", "Balanced"],
        "PERFORMANCE": ["Performans", "Performance"],
        "CAMERA": ["Kamera", "Camera"],
        "MICROPHONE": ["Mikrofon", "Microphone"],
        "CAMERA HELP": ["Bağlı USB kameralarını aç/kapat. Yönetici onayı gerekir; yeniden takılınca veya başlatılınca sıfırlanabilir.", "Enable/block connected USB cameras. Administrator approval required; reconnecting or rebooting may reset this."],
        "MIC HELP": ["Yerel ALSA mikrofonlarına sistem erişimini engeller/açar. Yönetici onayı gerekir; ses hizmeti kısa süre yeniden başlar. Bluetooth ve sanal kaynaklar desteklenmez.", "Block/allow system access to local ALSA microphones. Requires administrator approval and briefly restarts audio. Bluetooth and virtual sources are not supported."],
        "MIC BUSY": ["Başka bir uygulama mikrofonu doğrudan kullanıyor. Kaydı kapatıp tekrar deneyin; değişiklik geri alındı.", "Another application is using the microphone directly. Stop recording and retry; the change was rolled back."],
        "PARTIAL": ["Tam engelleme doğrulanamadı", "Full blocking could not be verified"],
        "PRIVACY ON": ["Erişim açık", "Access allowed"],
        "PRIVACY OFF": ["Erişim engelli", "Access blocked"],
        "UNAVAILABLE": ["Kullanılamıyor", "Unavailable"],
        "ACTION FAILED": ["İşlem uygulanamadı", "Could not apply the change"],
        "AUTH CANCELLED": ["Yönetici onayı verilmedi", "Administrator approval was not granted"],
        "WORKING": ["Uygulanıyor…", "Applying…"],
        "APP VISIBILITY": ["Başlatıcıda gösterilen uygulamalar", "Apps shown in the launcher"],
        "APP SHOWN": ["Görünür", "Visible"],
        "APP HIDDEN": ["Gizli", "Hidden"],
        "WEATHER SETTINGS": ["Hava durumu", "Weather"],
        "WEATHER CHOOSE CITY": ["Şehir seçmek için tıklayın", "Click to choose a city"],
        "WEATHER CITY SEARCH": ["Şehir ara…", "Search for a city…"],
        "SEARCH CITY": ["Şehir ara", "Search city"],
        "WEATHER NO CITY": ["Şehir bulunamadı", "City not found"],
        "REFRESH WEATHER": ["Hava durumunu yenile", "Refresh weather"],
        "WEATHER LAST VALUE": ["Son alınan değer:", "Last received value:"],
        "WEATHER CLEAR": ["Açık", "Clear"],
        "WEATHER CLOUDY": ["Bulutlu", "Cloudy"],
        "WEATHER FOG": ["Sisli", "Foggy"],
        "WEATHER RAIN": ["Yağmurlu", "Rainy"],
        "WEATHER SNOW": ["Karlı", "Snowy"],
        "WEATHER STORM": ["Gök gürültülü", "Thunderstorm"],
        "WEATHER LOADING": ["Hava durumu alınıyor…", "Loading weather…"],
        "WEATHER ERROR": ["Hava durumu alınamadı. Yeniden deneyin.", "Weather unavailable. Try again."],
        "SYSTEM LANGUAGE": ["Sistem dili", "System language"],
        "ISLAND LANGUAGE": ["Ada dili:", "Island language:"],
        "WEATHER CITY": ["Hava durumu şehri:", "Weather city:"],
        "AUTO CITY": ["Şehir adı girin", "Enter a city name"],
        "UNMUTE": ["Sesi aç", "Unmute"],
        "MUTE MICROPHONE": ["Mikrofonu sessize al", "Mute microphone"],
        "UNMUTE MICROPHONE": ["Mikrofonu aç", "Unmute microphone"],
        "MICROPHONE MUTED": ["Mikrofon sessizde", "Microphone muted"],
        "DISPLAYS AND KEYBOARD": ["EKRANLAR VE KLAVYE", "DISPLAYS AND KEYBOARD"],
        "BRIGHTNESS RIGHT CLICK": ["Tüm ekranlar ve klavye ışığı için sağ tıklayın", "Right-click for every display and keyboard lighting"],
        "HOTSPOT": ["Erişim noktası (hotspot)", "Hotspot"],
        "AIRPLANE MODE": ["Uçak modu", "Airplane mode"],
        "NETWORK SETTINGS": ["Ağ ayarları (gizli ve kurumsal ağlar)", "Network settings (hidden and enterprise networks)"],
        "BLUETOOTH SETTINGS": ["Bluetooth ayarları", "Bluetooth settings"],
        "SHARE": ["PAYLAŞ", "SHARE"],
        "SHOW PASSWORD": ["Şifreyi göster", "Show password"],
        "HIDE PASSWORD": ["Şifreyi gizle", "Hide password"],
        "SCAN TO JOIN": ["Bağlanmak için okutun", "Scan to join"],
        "WIFI HARDWARE OFF": ["Wi-Fi donanım anahtarıyla kapalı", "Wi-Fi is off by its hardware switch"],
        "NOT CONNECTED": ["BAĞLI DEĞİL", "NOT CONNECTED"],
        "NO OTHER NETWORKS": ["Başka ağ bulunamadı", "No other networks found"],
        "NO NEARBY DEVICES": ["Yakında cihaz bulunamadı", "No nearby devices found"],
        "GPU ASLEEP": ["UYKUDA", "ASLEEP"],
        "DO NOT DISTURB": ["RAHATSIZ ETME", "DO NOT DISTURB"],
        "REPLY": ["Yanıtla", "Reply"],
        "NOW": ["şimdi", "now"],
        "MIN": ["dk", "min"]
})

    function t(clave) {
        const par = cfg.textos[clave];
        if (!par)
            return clave;
        return cfg.turkish ? par[0] : par[1];
    }
}
