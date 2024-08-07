commitHashLong=$(git rev-parse HEAD)
commitHash=${commitHashLong:0:7}
read -p "wallet: " WALLET
read -p "git token: " GITTOKEN
PROCS=$(nproc)
THREADS=$(($PROCS/2))
export TS=$(date +"%Y%m%d-%H%M")

cd

cat <<EOF> /etc/apk/repositories
#/media/sda/apks
http://mirror.leaseweb.com/alpine/v3.20/main
http://mirror.leaseweb.com/alpine/v3.20/community
EOF

apk add git make cmake libstdc++ gcc g++ libuv-dev openssl-dev hwloc-dev sudo python3 vim wget logrotate findutils-locate  linux-firmware-radeon linux-firmware-amdgpu automake libtool autoconf linux-headers

cat <<EOF> ~/.profile
VISUAL="vim" ; export VISUAL
EDITOR="\$VISUAL" ; export EDITOR
alias h="history"
alias t="tail -f /var/log/messages"
alias x="cd /opt/xmrig; ls -ltr"
alias z="source ~/.profile"
alias s="grep speed /var/log/messages"
alias start="rc-service xmrig start"
alias stop="rc-service xmrig stop"
alias status="rc-service xmrig status"
EOF

cat <<EOF> ~/.vimrc
set mouse=v
set number
EOF

source /root/.profile

#apk -U upgrade

cat <<EOF>> /etc/logrotate.conf
/var/log/messages {
    rotate 2
    daily 
}
EOF

cat <<EOF>> /etc/default/grub
GRUB_CMDLINE_LINUX="msr.allow_writes=on"
EOF

update-grub

cat <<EOF>> /etc/hosts
192.168.0.10 xmrig1
192.168.0.20 xmrig2
192.168.0.30 xmrig3
192.168.0.40 xmrig4
192.168.0.50 xmrig5
192.168.0.60 xmrig6
192.168.0.70 xmrig7
192.168.0.80 xmrig8
192.168.0.90 xmrig9
192.168.0.101 oldmac
EOF

reboot

rm -rf xxxmrig
rm -f /opt/xmrig/xmrig
rm -f /opt/xmrig/config.json

cd /root/ 
mkdir -p /opt/xmrig /var/lib/xmrig 


#git clone https://$GITTOKEN@github.com/stephenjonpeters/xxxmrig.git

mkdir xxxmrig/build && cd xxxmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps -DWITH_CN_LITE=OFF -DWITH_CN_HEAVY=OFF -DWITH_CN_PICO=OFF -DWITH_CN_FEMTO=OFF -DWITH_GHOSTRIDER=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_NVML=OFF -DHWLOC_DEBUG=ON 
make -j$(nproc)
cp xmrig /opt/xmrig/xmrig

cat <<EOF> /opt/xmrig/config.json
{
    "autosave": false,
    "background": false,
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
        "priority": null,
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
            "url": "chicago01.hashvault.pro:3333",
            "user": "42mULgdD5UoZ3uQbVkc5d7My2v4z453ccPFJaf9RVdZ71oAyRspuhurFaC5kwqUDjw6rTJ2b4yDFxiqN3PbpATsS1Hyekry",
            "pass": "xmrig9",
            "keepalive": true,
            "enabled": true,
             "tls-fingerprint": "420c7850e09b7c0bdcf748a7da9eb3647daf8515718f36d9ccfdd6b9ff834b14",
            "tls": true
        }
    ],
    "pause-on-battery": false,
    "pause-on-active": false,
    "verbose": 2,
    "print-time": 60
}
EOF



cat <<EOF>/etc/init.d/xmrig
#!/sbin/openrc-run
name="xmrig"
command="/opt/xmrig/xmrig"
command_args="--foreground"
supervisor="supervise-daemon"
pidfile="/run/xmrig.pid"
EOF


chmod +xxx /etc/init.d/xmrig

rc-update add xmrig

start
status

