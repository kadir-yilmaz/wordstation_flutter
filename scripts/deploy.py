#!/usr/bin/env python3
import os
import sys
import subprocess
import ftplib
import shutil

FTP_HOST = "site85583.siteasp.net"
FTP_USER = "site85583"
FTP_PASS = "8w_RgL9#2z@N"
BUILD_DIR = "build/web"
DOMAIN = "wordstation.runasp.net"

def build_flutter():
    print("🚀 [1/3] Flutter Web Release derleniyor...")
    res = subprocess.run(["flutter", "build", "web", "--release"], check=False)
    if res.returncode != 0:
        print("❌ HATA: Flutter build basarisiz oldu!")
        sys.exit(1)

    # web.config kopyala
    if os.path.exists("web/web.config"):
        shutil.copy("web/web.config", os.path.join(BUILD_DIR, "web.config"))
    print("✅ Build tamamlandi.")

def upload_dir(ftp, local_dir, remote_dir=""):
    for item in os.listdir(local_dir):
        if item.startswith("."):
            continue
        local_path = os.path.join(local_dir, item)
        remote_path = f"{remote_dir}/{item}" if remote_dir else item

        if os.path.isdir(local_path):
            try:
                ftp.mkd(remote_path)
            except ftplib.error_perm:
                pass  # Klasör zaten var
            upload_dir(ftp, local_path, remote_path)
        else:
            with open(local_path, "rb") as f:
                print(f"  📤 Yükleniyor: {remote_path}")
                ftp.storbinary(f"STOR {remote_path}", f)

def deploy_ftp():
    print(f"🌐 [2/3] RunASP FTP Sunucusuna bağlanılıyor ({FTP_HOST})...")
    try:
        ftp = ftplib.FTP(FTP_HOST, timeout=30)
        ftp.login(FTP_USER, FTP_PASS)
        print("✅ FTP Girişi başarılı.")
    except Exception as e:
        print(f"❌ FTP Bağlantı Hatası: {e}")
        sys.exit(1)

    print("📦 [3/3] Dosyalar sunucuya aktarılıyor...")
    upload_dir(ftp, BUILD_DIR)
    ftp.quit()
    print(f"\n🎉 TEBRİKLER! Uygulama başarıyla yayınlandı:")
    print(f"👉 https://{DOMAIN}\n")

if __name__ == "__main__":
    if not os.path.exists("pubspec.yaml"):
        print("❌ Lütfen scripti Flutter proje ana dizininde çalıştırın.")
        sys.exit(1)
    
    build_flutter()
    deploy_ftp()
