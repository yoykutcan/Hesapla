# Hesapla

Hepsi bir arada hesaplama uygulaması (Flutter).

## APK alma
1. Bu klasörün içindekileri yeni bir GitHub deposuna yükle (tercihen private).
2. Actions sekmesinde "APK olustur" çalışır (yüklemede otomatik başlar).
3. Çalışma bitince sayfanın altındaki Artifacts bölümünden `hesapla-apk` dosyasını indir, zip'ten çıkan `app-release.apk` dosyasını telefona kur.

## Güncelleme
Kodu değiştirip yükle, yeni APK'yı eskisinin üstüne kur. `signing/debug.keystore` dosyası sabit olduğu ve sürüm numarası her çalışmada arttığı için eski uygulamayı silmen gerekmez.
`signing/debug.keystore` dosyasını silme veya değiştirme.

## Play Store
Yayın için ayrı bir yükleme (upload) anahtarı ve imzalı AAB üretimi eklenecek. Bu test anahtarı Play Store için kullanılmamalı.

## Yasal parametreler
Brüt-net maaş ve kıdem tazminatı hesapları `lib/params.dart` dosyasındaki 2026 değerlerini kullanır (asgari ücret, SGK tavanı, vergi dilimleri, kıdem tavanı). Yıl veya dönem değişince sadece bu dosyayı güncelle.
