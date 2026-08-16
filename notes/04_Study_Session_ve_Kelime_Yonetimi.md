# 📚 Faz 4: Kelimeler, CRUD ve 3D Çalışma Seansı

WordStation Flutter kelime yönetimi ve çalışma seansı modülü tamamlandı.

## 1. Modeller & Servisler
- **`WordModel`:** `id`, `en`, `tr`, `example`, `listName`, `userId`, `toJson()`, `fromJson()`, `copyWith()`.
- **`SynonymGroupModel`:** Aynı Türkçe anlama (`tr`) sahip İngilizce kelimeleri gruplama.
- **`WordService`:** Kelime listeleme, arama (backend/lokal), CRUD işlemleri ve eş anlamlı grupları yönetme.

## 2. 3D Flip Card Çalışma Seansı (`StudySessionPage` & `StudyController`)
- **3D Matrix4 Flip:**
  - Ön Yüz: Turkuaz Gradient (`#12C6B2`), Türkçe Anlam (`tr`), dokunma ipucu.
  - Arka Yüz: Pembe Gradient (`#E3719D`), İngilizce Kelime (`en`), dokunma ipucu.
  - `Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateY(angle)` ile derinlikli 3D rotasyon.
  - `HapticFeedback.lightImpact()` ile dokunsal geri bildirim.
- **Synonym Badges:** Kelimenin Türkçe anlamına karşılık gelen diğer eş anlamlıları rozetler halinde listeleme ve tıklayınca doğrudan o kelimeye odaklanma.
- **Örnek Cümle Kutusu:** `example` cümlesini şık bir alıntı kartı içinde gösterme.
- **Sesli Okuma (TTS):** `flutter_tts` ile doğal Amerikan İngilizcesi (`en-US`) telaffuzu (Mavi hoparlör `#007AFF`).
- **Kontroller & Slider:**
  - Sayaç: `908 / 2455` formatında başlık altında gösterim.
  - Hızlı Slider: Kelimeler arasında kaydırarak geçiş.
  - `[← Önceki]`, `[🔀 Rastgele (Turuncu)]`, `[🔊 Telaffuz (Mavi)]`, `[Sonraki →]`.

## 3. Kelime Yönetimi ve Arama (`WordsListPage`, `AddEditWordPage`)
- Dinamik liste filtreleme çipleri (Tümü, A1, B2 vb.).
- 350ms debounce ile anlık arama çubuğu.
- Kelime ekleme / düzenleme / silme formu ve liste önerileri.

## 4. Eş Anlamlılar Modu (`SynonymsPage`)
- Türkçe anlama göre gruplanmış kelime kartları.
- Her kartta telaffuz butonlu rozetler ve o gruba özel çalışma seansı başlatma butonu.
