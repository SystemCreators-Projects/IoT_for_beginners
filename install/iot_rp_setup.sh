#!/bin/bash

SECRET_ENV_FILE="/tmp/secret.env"

# .env ファイルの存在確認
if [ ! -f "$SECRET_ENV_FILE" ]; then
  echo "Error: .env file not found at $SECRET_ENV_FILE"
  exit 1
fi

# 改行コードをLFに置換（CRを削除）
sed -i 's/\r$//' "$SECRET_ENV_FILE"

# .env 読み込み
source "$SECRET_ENV_FILE"

# Swapをオフ
sudo dphys-swapfile swapoff

# swapサイズ設定を変更
sudo sed -i 's|^CONF_SWAPSIZE=[0-9]*$|CONF_SWAPSIZE=1024|' /etc/dphys-swapfile

# Swapファイルを再作成
sudo dphys-swapfile setup

# Swapをオン
sudo dphys-swapfile swapon

#dhcpcd の停止
sudo systemctl stop dhcpcd.service
sudo systemctl disable dhcpcd.service

#NetworkManager の起動
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service

#NetworkManagerの接続ファイルを削除
sudo rm /etc/NetworkManager/system-connections/*.nmconnection
sudo nmcli connection reload

# ネットワークの数を取得
NUM_NETWORKS=$(grep -o 'SSID_' "$SECRET_ENV_FILE" | wc -l)

# 各ネットワーク設定を順番に処理
for i in $(seq 1 $NUM_NETWORKS); do
    CON_NAME="wifi_$i"
    SSID_VAR="SSID_$i"
    PASSWORD_VAR="PASSWORD_$i"
    PRIORITY_VAR="PRIORITY_$i"
    
    SSID="${!SSID_VAR}"
    PASSWORD="${!PASSWORD_VAR}"
    PRIORITY="${!PRIORITY_VAR}"
    
    echo "Setting up $CON_NAME with SSID $SSID"

    nmcli connection add type wifi \
        con-name "$CON_NAME" \
        ifname wlan0 \
        ssid "$SSID" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$PASSWORD" \
        connection.autoconnect yes \
        connection.autoconnect-priority "$PRIORITY" \
        802-11-wireless.hidden false
done

# secret.env を削除
rm -f "$SECRET_ENV_FILE"

# 終了
sudo reboot
