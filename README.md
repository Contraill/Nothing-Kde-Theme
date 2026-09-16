# Nothing KDE

Nothing OS esintili Plasma teması: üst ada, alt dock, sekiz masaüstü gereci ve
isteğe bağlı uygulama vurguları. Türkçe/İngilizce; özel daemon yoktur.
Nothing-inspired Plasma theme with two panels, eight desktop widgets and
optional application accents. Turkish/English; no custom daemon.

## Kurulum / Install

Plasma 6.7, Qt 6.10+, Bash, Python 3, `kpackagetool6`, `qdbus6` ve KDE yapılandırma araçları gerekir.
Requires Plasma 6.7, Qt 6.10+, Bash, Python 3 and KDE package/configuration tools.
İlgili kontroller / optional backends: NetworkManager (`nmcli`), PipeWire (`wpctl`,
`pactl`), BlueZ, PowerDevil, `brightnessctl`, `upower`, `powerprofilesctl`.

```sh
./install.sh                  # Kur / güncelle — install / upgrade
./install.sh --apply-layout   # İki paneli kur/onar; Plasma yenilenir — create/repair panels
./install.sh --widgets-only   # Yalnızca masaüstü gereçleri — widgets only
```

Tema: Sistem Ayarları → Nothing KDE Dark/Light. Gereçler: masaüstü → Gereç Ekle.
Choose Nothing KDE Dark/Light in System Settings; use Add Widgets for desktop widgets.

Desktop widgets share a palette-driven Glassy surface; images/artwork keep their
own content. Normal desktop applets share the wallpaper's window, so this uses
translucency without fake blur or an external effect ([KDE desktop view](https://invent.kde.org/plasma/plasma-workspace/-/blob/master/shell/desktopview.cpp)).
Ortak Glassy gereç yüzeyi KDE paletini izler; gerçek pencere-arkası blur yerine
hafif saydamlık kullanılır. Görseller ve gereç işlevleri korunur.
Mevcut paneller korunur; `--apply-layout` önce yedekler, yalnızca eski Nothing yan panellerini kaldırır.
Existing panels are retained; layout repair backs up first and removes only retired Nothing side panels.

## Glassy

Paket, yeniden kullanılabilir **Glassy** Kvantum temasını ve **Glassy** native
Aurorae pencere dekorasyonunu içerir. İkisi de KDE renklerini izler; Nothing'a
özgü bir renk paleti kullanmaz. KDE'nin uygulama biçemi listesinde altyapı adı
`Kvantum`, Kvantum Manager'da tema adı `Glassy` olarak görünür.
The bundle includes the reusable **Glassy** Kvantum theme and native Aurorae
decoration. Both follow KDE colors, independently of Nothing's palette.
Select `Kvantum` as the application style and `Glassy` in Kvantum Manager;
the window decoration is also named `Glassy`.

**Glassy Settings / Glassy Ayarları** uygulama menüsünde bulunur. Application,
Glass, Window Decoration ve Controls sekmeleri tek `auroraerc` / `[org.glassy.decoration]`
kaydını kullanır. **Reset to Glassy defaults** yalnız bu formu sıfırlar; Apply kaydeder.
Aynı form Sistem Ayarları → Pencere Dekorasyonları → Glassy → Yapılandır içindedir.
Open **Glassy Settings** from the launcher, or configure Glassy in Window Decorations.
Settings persist in the native Aurorae group; Reset only affects Glassy and is staged until Apply.
The small native settings utility needs CMake/C++ at source-build time; it is not a style engine.

```sh
./install.sh --appearance install     # Yalnız Glassy / Glassy only
./install.sh --appearance sync        # Palette değişiminden sonra / after palette changes
./install.sh --appearance disable     # Önceki seçimleri geri al / restore previous selections
```

Kurulu bağımlılıklar tekrar kurulmaz; kaldırma paket silmez. Sahiplik ve önceki
ayarlar `~/.config/nothing-kde/appearance/state.json` içinde tutulur.
Existing dependencies are reused; uninstall never removes packages. Previous
settings and ownership are recorded in that state file.
Üst ada palette eşlemesini tetikler; başka bir tema/panel kullanırken `sync`
çağrısını o temanın renk değişimine bağlayın. Ayrı daemon yoktur.
The island triggers palette synchronization; other themes should invoke `sync`
after changing colors. There is no separate daemon.
Cam görünüm Qt Widgets içindir: System Settings'in Qt Quick sayfaları, GTK ve
Electron içerikleri Kvantum kapsamı dışındadır ve opak kalabilir.
Glass targets Qt Widgets; System Settings' Qt Quick pages, GTK and Electron
content are outside Kvantum's scope and may remain opaque.

**Önemli:** Qt paleti açık uygulamalarda güncellenir; Kvantum'un cached yüzeyleri
ve SVG kontrol renkleri henüz tamamen canlı değişmez. 11 gereksiz renk override'ı
kaldırıldı; yeniden başlatma final çözüm olarak kabul edilmiyor.
[Canlı geçiş ölçümleri](assets/kvantum/LIVE-PALETTE.md). Dekorasyon ve engine sınırları:
[Glassy notları](assets/kvantum/README.md).
**Important:** Qt palettes update live, but cached Kvantum surfaces/SVG controls
do not all follow yet. Eleven unnecessary color overrides were removed; restarting
applications is not considered a final solution. See the live-palette audit above.
Gerçek açık/koyu geçişinde çalışan Kvantum uygulamaları varsa tek yerel bildirim
gösterilir; başlangıç/vurgu güncellemeleri bildirim üretmez. Uygulamalar kapatılmaz.
Actual light/dark transitions with running Kvantum apps show a deduplicated native
notification; startup/accent updates do not. No application is restarted.

## İsteğe bağlı / Optional

```sh
./install.sh --dolphin apply
./install.sh --dolphin restore
./install.sh --accent-links enable fastfetch   # starship | spaceship | fastfetch
./install.sh --accent-links disable all
```

Vurgu bağlantıları üst adanın dişli menüsünden de yönetilir. Starship/Fish ve
Spaceship/Zsh ilk etkinleştirmede yeni terminal ister; Fastfetch sonraki çalıştırmada güncellenir.
Accent links also appear in island settings. Open a new terminal after enabling a prompt link.
Starship segment yazıları arka plan kontrastından, normal yazılar KDE paletinden
türetilir; etkin bağlantı renk değişimini sonraki prompt çiziminde alır.
Starship uses contrast-aware segment ink and KDE palette text; the original
prompt layout/config is preserved and linked colors update on the next prompt.

Üst adayı açın: dişliye sol tık ada ayarları, sağ tık KDE Sistem Ayarları.
Ada ayarlarında Aydınlık/Karanlık geçişi; vurgu için renk seçici veya manuel HEX
girişi ve Uygula vardır. Kalıcı vurgu kaynağı KDE `General/AccentColor` tercihidir;
başlangıç ve açık/koyu geçişi bunu sıfırlamaz. Kapat, uygulanmamış renk taslağını iptal eder.
Expand the island: left-click the gear for island settings, right-click for KDE
System Settings. Choose Light/Dark, or pick an accent visually/by HEX and Apply.
The persistent accent source is KDE `General/AccentColor`; startup and mode switching
preserve it. Closing the picker discards unapplied changes.

Kitty kuruluysa resmi `light-theme.auto.conf`, `dark-theme.auto.conf` ve
`no-preference-theme.auto.conf` yönetilir; `kitty.conf`, opacity/blur ve ANSI renkleri
korunur. Açık/koyu geçişini Kitty yerel OS bildirimiyle canlı uygular; değişen
dosyalar için resmi SIGUSR1 reload kullanılır. Özel `--config` süreçlerine sinyal gönderilmez.
Kitty uses its official automatic OS themes; the main config, opacity/blur and ANSI
colors remain untouched. Mode changes are live; managed file changes use SIGUSR1.
Geri al / restore: `./install.sh --kitty-theme disable`; önceki otomatik tema
dosyaları saklanır, sonradan kullanıcı tarafından düzenlenen dosyalar korunur.
Removing auto themes may need a manually reopened Kitty to discard its cached theme;
the integration never restarts a process. [Official automatic themes](https://sw.kovidgoyal.net/kitty/kittens/themes/#change-color-themes-automatically-when-the-os-switches-between-light-and-dark).

Simge teması zorunlu değildir; kurulum ve tema geçişi mevcut seçiminizi değiştirmez.
Modern görünümü, Glassy uyumu ve KDE renk paletini izleyebilen klasörleri nedeniyle
[Colloid](https://github.com/vinceliuice/Colloid-icon-theme) isteğe bağlı önerilir;
otomatik kurulmaz/seçilmez. KDE tint desteği Colloid'in `--notint` seçeneğiyle kapanabilir.
No icon theme is required or selected automatically. Colloid is an optional
recommendation for its modern appearance and KDE palette-aware folder tinting.

Ada ayarlarında **Güç işlemlerini onayla / Confirm power actions** varsayılan açıktır.
Kapatmak yalnız panelin onayını kaldırır; KDE/Polkit kuralları değişmez. Tercih
panel yapılandırmasında saklanır; uyku dahil güç işlemlerine uygulanır.

Manuel kalıcılık kontrolü / Manual persistence check: farklı bir accent ve açık/koyu
mod seçin; Glassy'de yarıçap/alt köşe tercihini ve panelde güç onayını değiştirin.
Önce logout/login, ardından kendi seçiminizle reboot yapıp aynı değerlerin kaldığını
kontrol edin. Güç onayı kapalıyken eylemler anında çalışabilir: yalnız kaydedilmiş
işlerle deneyin. Otomatik testler gerçek shutdown/logout/suspend çalıştırmaz.

Dolphin profili KDE renklerini izler; Qt stilini yüklemek için dock/menüden açın.
Doğrudan terminal/D-Bus ile ilk başlatma stili atlayabilir. Kişisel klasör ayarları korunur.
Dolphin uses a scoped Qt stylesheet, not a global style; launch from the dock/menu.
Backups for reversible application links live in `~/.config/nothing-kde/`; do not delete while enabled.
Etkin bağlantıların geri alma yedeklerini silmeyin. `--dolphin status` / `--accent-links status` durum gösterir.

Limine 12 yalnızca inceleme dosyası üretir; önyükleme dosyaları değiştirilmez.
Limine 12 is export-only; boot files are never modified:
`./install.sh --accent-links export limine --source /path/limine.conf --output /tmp/limine-preview.conf`.

## Bildirimler ve gizlilik / Notifications and privacy

Glyph kurulumu patch sürümünü değil, kurulu KDE bildirim QML/API yapısını denetler.
Uyumluluk doğrulanamazsa KDE görünümü korunur. Kaynak şablonları doğrulanmış ve sabittir.
The optional Glyph adapter checks installed notification resources, model callbacks
and popup APIs, not patch-version equality. Unknown contracts retain native KDE
appearance. Inspection uses a temporary Qt 6 probe (C++ compiler, pkg-config,
Qt Core/Qml/Gui headers); missing tools also safely skip the optional skin.
Install: `./install.sh --notifications-only --restart-plasma`.
Explicit override: `./install.sh --notifications-only --force-notifications --restart-plasma`.
Force yalnız uyumluluk kapısını atlar; QML doğrulaması, yerel servis kontrolü ve
hata halinde geri alma korunur. Force bypasses compatibility only, never validation
or rollback. No notification daemon or system KDE resources are replaced.
Restore: `./notification-skin/rollback-native.sh`.

Mikrofon kilidi sessize alma değildir: yönetici onayıyla yerel ALSA kayıt erişimini
engeller ve yeniden başlatmada sürer. Ses hizmetleri kısa süre yeniden başlar.
Bluetooth/sanal/ağ/OSS mikrofonlarını veya root erişimini kapsamaz. Kamera kilidi
USB Video arayüzleri içindir; yeniden takma/başlatmada sıfırlanabilir.
Microphone blocking requires admin approval, denies local ALSA capture and persists
across reboot; audio services briefly restart. Bluetooth/virtual/network/OSS capture
and root are outside its scope. USB camera blocking may reset on reconnect/reboot.
Requires Polkit, ACL tools, udev, systemd and PipeWire/WirePlumber.

**Kaldırmadan önce mikrofonu açın / Unblock the microphone before uninstalling:**

```sh
pkexec /usr/bin/python3 -I "$PWD/runtime/privacy.py" microphone on
./uninstall.sh
```

Store-only recovery helper: `~/.local/share/plasma/plasmoids/com.nothingplasma.panel/contents/tools/privacy.py`.
Üst panelde hava durumuna tıklayarak şehir seçebilir ve veriyi yenileyebilirsiniz.
Open-Meteo şehir araması ve hava durumu için internet kullanır; seçilen konum panelde saklanır.
Click the island weather to select a city or refresh. Open-Meteo receives the city search/coordinates
and your IP; no API key is needed. [Weather data](https://open-meteo.com/) uses CC BY 4.0.
Launcher settings list installed applications; visibility choices apply to this launcher and its search.

## Test ve paketleme / Test and package

```sh
./validate.sh
./package.sh                           # Üretilen dosyalar / artifacts: dist/
./package.sh --output /tmp/nothing-kde-dist
NOTHING_PACKAGE_DIR=/tmp/nothing-kde-dist ./validate.sh
```

Qt QML tools enable lint/interaction tests; `msgfmt` rebuilds Turkish catalogs.
Pinned KDE sources and compiled translations are retained for offline packaging.
Store dependencies: `./package.sh --store-ids packaging/store-ids.json`, using the
structure in `packaging/store-ids.example.json` and real published component IDs.

**Store yayını henüz hazır değil / Store publication is not yet cleared:** widget
font/görsel izinleri, duvar kâğıdı dağıtım hakları ve gerçek Store kimlikleri tamamlanmalıdır.
Widget font/artwork permissions, wallpaper redistribution rights and Store IDs must be resolved first.

Lisans / license: [GPL](LICENSE), [Island attribution](plasmoids/com.nothingplasma.panel/contents/island/NOTICE.md),
[widget sources](widgets/UPSTREAM.json) and each widget's `UPSTREAM-NOTICE.md`.
Existing `com.nothingplasma.*` IDs remain stable to preserve panels and pinned applications.
