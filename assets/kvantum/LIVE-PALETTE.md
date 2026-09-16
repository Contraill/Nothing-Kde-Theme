# Glassy: canlı palette incelemesi / live palette audit

2026-09-14 · Plasma 6.7.5 / Wayland · Kvantum 1.1.8 / Qt 6.11.
Bu bir tam canlı geçiş başarı raporu değildir. / Full live switching is not solved.
Refactor doğrulaması: 94 Python testi ve 41 QML testi başarılı.

## Bizim uygulamamızdan kaynaklanan kısım

Önceki `appearance.py sync`, her renk geçişinde hem `Glassy.svg` hem
`Glassy.kvconfig` üretiyordu. `GeneralColors` içinde 13 KDE rolünün RGB karşılığı
vardı. Dolayısıyla önceki test yalnız palette değişimini ölçmüyordu.

Refactor ile 11 gereksiz override kaldırıldı: window, button, text, window text,
button text, highlight, highlighted text, tooltip text, disabled text, link ve
visited link. Kontrol başına metin renkleri de belirtilmiyor; Kvantum'un belgelenmiş
palette fallback'i kullanılıyor. Yerel KDE `PaletteChanged` bildirimi artık dosya
yazılmış olmasına bağlı değil. Yalnız metin/bağlantı rengi değişse de iletiliyor.

Yalnız `base.color` ve `alt.base.color` üretiliyor. Bunun nedeni tahmin değil:
Kvantum `standardPalette()` içinde eksik Base yerine açıkça beyaz atıyor ve eksik
AlternateBase'i bundan türetiyor. Tüm renklerin çıkarıldığı deneyde, ilk palette
bildiriminden önce Base `#ffffff` kaldı. Bu iki rolü tutmak koyu ilk açılıştaki
beyaz içerik/okunabilirlik regresyonunu önlüyor; renkler yine KDE'den geliyor.

## Sabit dosya deneyi

`tests/glassy-live.py`, kullanıcı ayarlarına dokunmadan ayrı `XDG_CONFIG_HOME`
altında gerçek Wayland Dolphin ve Kate süreçleri açar. SVG/config başlangıçta
bir kere oluşturulur, geçişler boyunca **hiç değiştirilmez**. Yalnız renk şeması
ve KDE'nin yerel palette bildirimi değişir. Test gözlemcisi palette/stil atamaz,
repolish yapmaz. PID ve QStyle adresi üç aşamada aynı kalır; iki asset'in SHA256
değerleri de aynı kalır. Kate'te gerçek bir metin dosyası açılır, düzenlenmez.
Yalnız testin oluşturduğu süreçler deney sonunda kapatılır; bu bir ürün çözümü değildir.

| Ölçüm, aynı Dolphin/Kate süreçlerinde | Light | Dark | Light |
| --- | --- | --- | --- |
| QApplication Window | `#f6f6f3` | `#090909` | `#f6f6f3` |
| QApplication WindowText | `#121212` | `#f5f5f5` | `#121212` |
| Kvantum standardPalette Window | açık | **açık kaldı** | açık |
| Çizilmiş cam yüzey | açık, alfa 127 | **açık kaldı**, alfa 127 | açık, alfa 127 |

Koyu başlangıçlı ters testte de yüzey üç aşamada koyu kaldı. Refactor edilmiş
iki-rol sürümü koyu ilk açılışta doğru Base `#111111` ile başladı.
Bu deney, ana yüzey probleminin yalnız SVG dosyası önbelleği olmadığını gösteriyor.

## Gerçekte canlı olan / olmayan parçalar

| Parça | Durum |
| --- | --- |
| Qt uygulama ve widget palette rolleri | Aynı süreçte güncelleniyor; Window/Text/Base/Button/Highlight rollerinde doğrulandı. |
| Qt paletini doğrudan kullanan içerik | Güncellenebiliyor; Dolphin Places/etiket paletleri ve Kate editör içeriği kontrol edildi. |
| Tüm metin ve ikonların çizimi | **Topluca başarılı değil.** Bazı Kvantum menü/toolbar çizimleri veya uygulamanın kendi sabitlediği renkler eski kalabiliyor. Palette değerinin değişmesi, her pikselin değiştiği anlamına gelmiyor. |
| Cam pencere/diyalog zemini | Kvantum'un önbellekli `standardPalette()` rengi; aynı stil nesnesiyle canlı değişmiyor. |
| SVG kontrol dolgusu, kenarı, ok/glyph, progress ve seçili item zemini | Statik SVG; Qt palette bildirimi SVG'yi yeniden renklendirmiyor. |
| KWin blur / alfa | Renkten ayrı; yüzey alfa 127, bütün pencere opaklığı 1 kaldı. Bu deney blur gücünü değiştirmedi. |
| Glassy Aurorae | Ayrı SystemPalette yolu kullanmaya devam ediyor; bu refactor dekorasyonu değiştirmiyor. |

## Dosya üretimi neden tamamen kaldırılamadı?

`Glassy.kvconfig`: artık yalnız Base/AlternateBase değişince içeriği değişir.
Window/metin/vurgu/link renkleri için dosya yazımı gerekmez. Ancak ilk açılış
Base regresyonu çözülmeden kalan iki rolü kaldırmak güvenli değil.

`Glassy.svg`: mevcut opak kontrol dolguları ve glyph'ler için halen yeniden
renklendirme gerekiyor. Kvantum `QSvgRenderer` kullanıyor, KSvg'nin Plasma
palette sınıflarını değil. Render çağrısına Qt palette'i aktarılmıyor.
SVG'nin tamamını şeffaf yapmak veya `interior=false` kullanmak genel bir Qt
palette dolgusunu garanti etmiyor; bazı kontroller hiç doldurulmuyor. Bu,
opak/okunaklı kontrol gereksinimini bozacağı için uygulanmadı.

Dolayısıyla üretim `sync` yolu, gerekli SVG/iki Base rolünü hâlâ güncelliyor;
**tek değişmez SVG/config ile tam canlı Glassy hedefine ulaşıldığı iddia edilmiyor.**
Yazımlar yalnız içerik farklıysa yapılır. Değişen asset'ler yeni açılan stil
nesnelerinde yüklenir; çalışan süreçlerde otomatik reload sağlamaz.

Native config/SVG ile güvenli refactor bu aşamada uygulanmış durumda. Tam çözüm,
aynı Kvantum backend'inin upstream'de palette değişiminde cached standardPalette'i
yenilemesi ve SVG yüzeyleri için desteklenen palette-aware bir çizim yoluna sahip
olmasını gerektiriyor. Harici motor, dependency fork'u, uygulama kapat/aç,
session restart veya geçici Breeze→Kvantum değişimi eklenmedi.

## Reproduce / kaynaklar

### Context menu follow-up — 2026-09-15

`tests/check-density.py` + `glassy-density` gerçek Kvantum/QMenu ile izole,
offscreen Light → Dark → Light palette olaylarını ölçer. Config yalnız üretimdeki
Base/AlternateBase override'larını içerir; Window/Text sabitlenmez. Aynı QStyle ve
sabit SVG ile QMenu Window paleti `#f6f6f3 → #16191f → #f6f6f3` olurken çizilmiş
menü yüzeyi üç aşamada da `#f6f6f3` kaldı. Her aşamada yeni oluşturulan QMenu da
aynı eski yüzeyi çizdi. Bu, uygulamanın tek bir eski QMenu nesnesini tutmasından
değil Kvantum'un stil/SVG cache yolundan kaynaklanıyor. Render kaynağı menü rengini
halen doğru `window` palet rolünden üretir; üretim renk/sync davranışı değiştirilmedi.
Bu test compositor blur doğrulaması değildir; stil değişimi, repolish veya çalışan
uygulamayı yeniden başlatma çözümü eklenmedi.

Boyut matrisi: 8/10/14 pt × 100/125/200% × üç density × light/dark = 54 durum.
10 pt Normal'de buton/input/combobox 32→28, sekme 34→30, menü satırı 34→28 mantıksal
piksel; font alt sınırı, yeniden boyutlandırmada sizeHint kararlılığı ve tema
paritesi geçti. `cmake --build <build> --target glassy-density` ardından
`python3 tests/check-density.py --probe <build>/glassy-density` ile tekrar ölçülebilir.

### Runtime/state follow-up — 2026-09-14

`tests/runtime-live.py` gerçek oturumda Dolphin, Kate, System Settings ve Kitty'yi
aynı süreçlerle Light → Dark → Light kontrol eder; sonunda eski accent/şemayı geri alır.
`#806EE7` seçimi panel servisi yeniden yüklenince, yeni başlangıç helper süreçlerinde
ve üç geçişte korundu. Gerçek logout/reboot yapılmadı. Picker Apply/Cancel/yeniden
açılma ve geç gelen backend yanıtı QML testlerinde doğrulandı.
Kitty PID sabit: gövde `#f6f6f3` → `#090909` → `#f6f6f3`; ana config SHA256 aynı,
16 ANSI rengi aynı, mevcut opacity 0.5 / blur 1 korundu. Qt uygulamalarında palette
rolleri canlı değişti; yukarıdaki cached Kvantum yüzey sınırı değişmedi.
Üretim yalnız gerçek açık/koyu geçişinde yüklenmiş Kvantum süreçleri varsa yerel
bildirim gösterir; tekrarlar birleştirilir, başlangıç/accent sync sessizdir.
Test süreçleri dışında uygulama kapatma/açma veya session restart eklenmedi.

```sh
cmake -S tests/glassy -B /tmp/glassy-checks
cmake --build /tmp/glassy-checks
python3 tests/glassy-live.py --variant refactored \
  --observer /tmp/glassy-checks/libglassy-live-capture.so \
  --output /tmp/glassy-live-new-run
# Tam omission: --variant omit-all; ters geçiş: --initial-mode dark
```

Yeni bir çıktı klasörü kullanın. JSON dosyaları hem uygulama/widget palette'lerini,
hem cached standardPalette'i, hem gerçek boyanmış yüzey örneğini içerir.

- [Theme-Config, color inheritance exception 2](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/doc/Theme-Config)
- [polishing.cpp: polish(QPalette), standardPalette ve Base fallback](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/polishing.cpp)
- [Kvantum.cpp: PE_Widget ve kontrol doldurma yolları](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/Kvantum.cpp)
- [rendering.cpp: QSvgRenderer ve metin fallback](https://github.com/tsujan/Kvantum/blob/V1.1.8/Kvantum/style/rendering.cpp)
