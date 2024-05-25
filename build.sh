commitHashLong=$(git rev-parse HEAD)
commitHash=${commitHashLong:0:7}
read -p "wallet: " WALLET
PROCS=$(nproc)
THREADS=$(($PROCS/2))

apt install -y ufw bzip2 plocate logrotate vim tree jq git build-essential cmake automake libtool autoconf libhugetlbfs-bin numactl jsonlint vim syslinux-utils lm-sensors neofetch jq msr-tools xclip
modprobe msr

snap install btop

apt update && apt upgrade -y

git config --global user.email "stephenjonpeters@icloud.com"
git config --global user.name "Steve Peters"


cat <<EOF> ~/.bash_aliases
alias start="systemctl daemon-reload;systemctl restart xmr;systemctl status xmr"
alias stop="systemctl stop xmr"
alias stat="systemctl status xmr"
alias tsl="tail -f /var/log/syslog"
alias j="journalctl -u xmr.service -r"
alias updxmr="vi /opt/xmrig/xmr.json"
alias updsvc="vi /etc/systemd/system/xmr.service"
alias z="source ~/.bashrc"
alias donate="grep -i donate /var/log/syslog"
alias v="journalctl --vacuum-size=10M"
alias b1="/opt/xmrig/xmrig --bench=1M --submit --config /opt/xmrig/xmr.json -t 16" 
alias b10="/opt/xmrig/xmrig --bench=10M --submit --config /opt/xmrig/xmr.json -t 16" 
alias xmrig="/opt/xmrig/xmrig"
EOF

source .bashrc

echo vm.nr_hugepages=1024 > /etc/sysctl.conf 

cd /root/ 
rm -rf xxxmrig
rm -f /opt/xmrig/xmrig
rm -f /opt/xmrig/xmr.json
rm -f /opt/xmrig/config.json
mkdir -p /opt/xmrig /var/lib/xmrig

cp xxxmrig/src/config.json /opt/xmrig
mkdir xxxmrig/build && cd xxxmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps -DWITH_CN_LITE=OFF -DWITH_CN_HEAVY=OFF -DWITH_CN_PICO=OFF -DWITH_CN_FEMTO=OFF -DWITH_GHOSTRIDER=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_NVML=OFF -DHWLOC_DEBUG=ON 
make -j$(nproc)
cp xmrig /opt/xmrig

cat <<EOF> /opt/xmrig/config.json
{
    "autosave": false,
    "randomx": {
        "init": -1,
        "init-avx2": 1,
        "mode": "fast",
        "1gb-pages": true,
        "numa": true
    },
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "priority": 5,
        "max-threads-hint": 100,
        "asm": "ryzen",
        "yield": false,
        "rdmsr": true,
        "wrmsr": true,
        "memory-pool": true
    },
    "opencl": false,
    "cuda": false,
    "donate-level": 0,
    "log-file": null,
    "syslog": true,
    "pools": [
        {
            "algo": "rx/0",
            "coin": "monero",
            "url": "xmr.kryptex.network:8888",
            "user": "$WALLET/$(hostname)-$THREADSthreads-$commitHash",
            "keepalive": true,
            "enabled": true,
            "tls": true
        }
    ],
    "pause-on-battery": false,
    "pause-on-active": false
}
EOF

cat <<EOF> /etc/systemd/system/xmr.service
[Unit]
Description=xmr
After=network.target
[Service]
Type=simple
PIDFile=/var/lib/xmrig/xmr.pid
ExecStart=/opt/xmrig/xmrig -t $(nproc)
User=root
Group=root
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable xmr
systemctl restart xmr
systemctl status xmr


echo “done!”

