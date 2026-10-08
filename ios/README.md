# Panduan Build File IPA untuk LiveContainer (iOS)

Dokumen ini memandu Anda meng-compile dan mengunduh berkas `.ipa` **Line Walker PLN UPT Semarang** secara gratis menggunakan GitHub Actions untuk dipasang di **LiveContainer** pada iPhone/iPad.

---

## 🚀 Langkah 1: Masukkan URL Web App Anda
1. Buka berkas `ios/LineWalkerApp/AppConfig.swift`.
2. Ganti nilai `webAppUrl` dengan URL deployment Google Apps Script Anda (yang berakhiran `/exec`):
   ```swift
   static let webAppUrl: String = "https://script.google.com/macros/s/AKfycbx_PASTE_URL_WEB_APP_ANDA_DISINI/exec"
   ```
3. Simpan berkas tersebut.

---

## ☁️ Langkah 2: Upload / Push ke Repositori GitHub
1. Upload folder proyek ini ke repositori GitHub pribadi Anda.

---

## ⚡ Langkah 3: Jalankan Build Otomatis di GitHub Actions
1. Buka halaman repositori Anda di GitHub melalui browser.
2. Klik tab **Actions** di bagian atas menu repositori.
3. Pada daftar workflow di sebelah kiri, pilih **"Build iOS IPA (LiveContainer)"**.
4. Klik tombol dropdown **"Run workflow"** di sisi kanan, lalu klik tombol hijau **"Run workflow"**.
5. Tunggu proses build selesai (~1-2 menit hingga muncul ikon centang hijau ✅).

---

## 📥 Langkah 4: Download File .IPA
1. Klik pada riwayat build yang baru saja selesai tersebut.
2. Gulir ke bagian paling bawah ke bagian **Artifacts**.
3. Klik **`LineWalker-PLN-UPT-Semarang-IPA`** untuk mengunduh filenya.
4. Ekstrak zip jika diunduh dalam bentuk zip untuk mendapatkan berkas **`LineWalker-PLN-UPT-Semarang.ipa`**.

---

## 📱 Langkah 5: Pasang ke LiveContainer di iPhone
1. Kirim file `.ipa` tersebut ke iPhone Anda (via AirDrop, Google Drive, iCloud Files, atau Telegram).
2. Buka aplikasi **LiveContainer** di iPhone Anda.
3. Ketuk ikon tambah **(+)** di LiveContainer, lalu pilih file `LineWalker-PLN-UPT-Semarang.ipa`.
4. Aplikasi **Line Walker** siap dijalankan langsung di dalam LiveContainer!
