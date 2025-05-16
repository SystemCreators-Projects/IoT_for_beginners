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

#NetworkManagerの接続ファイルを削除
sudo rm /etc/NetworkManager/system-connections/*.nmconnection

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

    sudo nmcli connection add type wifi \
        con-name "$SSID" \
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
