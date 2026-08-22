# 🚀 Faz 9: Flutter Web, IIS / RunASP WebDeploy ve Sorun Giderme Rehberi

Bu rehber; Flutter Web uygulamalarını IIS (Internet Information Services) ve RunASP gibi Windows/IIS tabanlı barındırma ortamlarına GitHub Actions ve WebDeploy (MSDeploy) ile yayınlarken karşılaşılan kilitlenme, sonsuz yükleme (infinite loading) ve yönlendirme sorunlarını önlemek amacıyla hazırlanmış mimari ve operasyonel kılavuzdur.

---

## 🛑 1. Problem Tanımı: "Deploy Başarılı Ama Sayfa Sonsuz Yükleniyor"

### Belirtiler:
1. GitHub Actions WebDeploy adımı yeşil tik alır ve `msdeploy.exe` senkronizasyonu hatasız tamamlanır.
2. Tarayıcıda site açıldığında sekme başlığı **"New Tab"** olarak kalır, favicon yüklenmez ve yükleme çarkı sürekli döner.
3. Tarayıcı veya terminal (`curl`) sunucuya TCP/TLS ile başarıyla bağlanır ancak sunucudan **ilk yanıt baytı (TTFB - Time To First Byte)** hiç gelmez (0 byte zaman aşımı).

---

## 🔬 2. Kök Neden Analizi (Neden Kilitlenir?)

| Neden | Açıklama |
|---|---|
| **1. Canlı Dosya Kilitlenmesi (File Lock)** | IIS `w3wp.exe` worker process'i aktif ziyaretçilere veya arka plan önbelleğine `index.html`, `flutter.js`, `.wasm` gibi dosyaları sunarken dosya tanıtıcılarını (file handles) açık tutar. Canlı üzerine yazma sırasında I/O deadlock oluşur. |
| **2. Zamansız Havuz Yenileme (Race Condition)** | IIS, dizindeki `web.config` değiştiği an Application Pool'u yeniden başlatır. Dosya transferi devam ederken havuz tetiklenirse yarım kopyalanmış dosyalar nedeniyle yeni process donar. |
| **3. SPA Rewrite Döngüsü** | `web.config` içinde `<defaultDocument>` açıkça verilmediğinde ve rewrite hedefi `url="/"` olduğunda, IIS dahili bir çözümleme çıkmazına girebilir. Doğru hedef her zaman `url="index.html"` olmalıdır. |
| **4. `HTTP.sys` vs `w3wp.exe` İletişim Kopması** | Windows çekirdek seviyesindeki `HTTP.sys` gelen HTTP isteklerini kabul eder (bağlantı kuruldu görünür), ancak istekleri yönlendirdiği `w3wp.exe` donduğu için yanıt dönülmez. |

---

## 🛡️ 3. Altın Standartlar ve Çözümler

### A. WebDeploy'da `AppOffline` Kuralı (Zorunlu)
Deploy sırasında worker process'in güvenle boşa çıkarılması için `msdeploy.exe` komutuna `-enableRule:AppOffline` parametresi eklenmelidir.

```text
┌────────────────────────┐              ┌────────────────────────┐              ┌────────────────────────┐
│  GitHub Actions Runner │              │    IIS Web Sunucusu    │              │  Worker Process (w3wp) │
└───────────┬────────────┘              └───────────┬────────────┘              └───────────┬────────────┘
            │                                       │                                       │
            │ ── 1. app_offline.htm Bırak ────────> │                                       │
            │                                       │ ── 2. Dosya Kilitlerini Bırak / Kapat>│
            │                                       │ <─── 3. Temizce Kapandı (Idle) ───────│
            │ ── 4. Build Dosyalarını Senkronize Et>│                                       │
            │ ── 5. app_offline.htm Dosyasını Sil ─>│                                       │
            │                                       │ ── 6. Yeni w3wp.exe Başlat ─────────> │
            │                                       │ <─── 7. Site Sorunsuz Yayında! ───────│
```


#### GitHub Actions Workflow Örneği (`deploy_web.yml`):
```powershell
& $msdeployPath -verb:sync `
  "-source:contentPath=$sourcePath" `
  "-dest:contentPath=$site,computerName=$destUrl,userName=$username,password=$password,authType=Basic" `
  -enableRule:AppOffline `
  -allowUntrusted
```

---

### B. Kusursuz `web.config` Şablonu

Flutter Web için IIS'te bulunması gereken 3 temel bileşen:
1. **`<defaultDocument>`:** Varsayılan doküman listesini temizleyip doğrudan `index.html` atar.
2. **`<staticContent>`:** Modern Flutter Web için gerekli `.wasm`, `.json`, `.mjs`, `.symbols` ve font MIME tiplerini tanımlar.
3. **`<rewrite>`:** Sayfa yenilendiğinde veya doğrudan alt rotalara gidildiğinde 404 almamak için tüm rota isteklerini `index.html`'e yönlendirir.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <!-- 1. Varsayılan Doküman -->
    <defaultDocument enabled="true">
      <files>
        <clear />
        <add value="index.html" />
      </files>
    </defaultDocument>

    <!-- 2. MIME Tipleri -->
    <staticContent>
      <remove fileExtension=".json" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <remove fileExtension=".wasm" />
      <mimeMap fileExtension=".wasm" mimeType="application/wasm" />
      <remove fileExtension=".otf" />
      <mimeMap fileExtension=".otf" mimeType="font/otf" />
      <remove fileExtension=".ttf" />
      <mimeMap fileExtension=".ttf" mimeType="font/ttf" />
      <remove fileExtension=".woff" />
      <mimeMap fileExtension=".woff" mimeType="font/woff" />
      <remove fileExtension=".woff2" />
      <mimeMap fileExtension=".woff2" mimeType="font/woff2" />
      <remove fileExtension=".js" />
      <mimeMap fileExtension=".js" mimeType="text/javascript" />
      <remove fileExtension=".mjs" />
      <mimeMap fileExtension=".mjs" mimeType="text/javascript" />
      <remove fileExtension=".symbols" />
      <mimeMap fileExtension=".symbols" mimeType="application/octet-stream" />
    </staticContent>

    <!-- 3. Flutter SPA Yönlendirmesi -->
    <rewrite>
      <rules>
        <rule name="Flutter Web SPA" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.html" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

---

## 📋 4. Hızlı Sorun Giderme Kontrol Listesi (Troubleshooting Checklist)

Benzer bir durumda izlenecek acil müdahale adımları:

1. **Sunucu Yanıt Testi (Terminal / PowerShell):**
   ```bash
   curl.exe -I -v --max-time 5 https://wordstation.runasp.net
   ```
   * *Sonuç zaman aşımı (timeout) ise:* IIS AppPool askıda kalmıştır.
   * *Sonuç 200 OK ise:* Sunucu sağlıklıdır, tarayıcı önbelleği (Ctrl+F5) temizlenmelidir.
   * *Sonuç 500.19 ise:* `web.config` dosyasında XML sözdizimi veya çakışan MIME tanımı vardır.

2. **RunASP Panelinden Yeniden Başlatma:**
   * RunASP Kontrol Paneli -> **Web Sites** -> **wordstation**
   * **"Stop"** butonuna basıp 5 saniye bekleyin, ardından **"Start"** butonuna basın (veya **"Restart Site"** / **"Recycle App Pool"** yapın).

3. **Site Runtime Ayarı:**
   * Flutter Web saf statik dosyalardan oluşur. Panelde sitenin .NET Core uygulaması gibi backend bekleyecek şekilde değil, saf web/statik modda çalıştığından emin olun.
