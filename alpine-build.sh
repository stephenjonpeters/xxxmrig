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

cat <<EOF> ~/.profile
VISUAL="vim" ; export VISUAL
EDITOR="\$VISUAL" ; export EDITOR
alias h="history"
alias t="tail -f /var/log/messages"
alias x="cd /opt/xmrig; ls -ltr"
alias z="source ~/.bashrc"
EOF

apk -U upgrade

apk add util-linux pciutils hwdata-pci usbutils hwdata-usb coreutils binutils findutils grep iproute2 vim wget findutils-locate linux-firmware-radeon linux-firmware-amdgpu git make cmake libstdc++ gcc g++ automake libtool autoconf linux-headers ufw

apk -U upgrade

rc-update add iptables 
rc-update add ip6tables
rc-update add ufw

cat <<EOF>> /etc/default/grub
GRUB_CMDLINE_LINUX="msr.allow_writes=on"
EOF
update-grub

git config --global user.email "stephenjonpeters@icloud.com"
git config --global user.name "Steve Peters"

cp /etc/hosts /etc/hosts.$TS
cat <<EOF>> /etc/hosts
192.168.0.10 xmrig1
192.168.0.20 xmrig2
192.168.0.30 xmrig3
192.168.0.40 xmrig4
192.168.0.50 xmrig5
192.168.0.60 xmrig6
EOF


cat <<EOF> ~/.vimrc
set mouse=v
set number
EOF

source /root/.bashrc

cp /etc/security/limits.conf /etc/security/limits.conf.$TS
cat <<EOF>>  /etc/security/limits.conf
echo root hard nofile 1048576
echo root soft nofile 1048576
EOF

cd /root/ 
rm -rf xxxmrig
rm -f /opt/xmrig/xmrig
rm -f /opt/xmrig/config.json
mkdir -p /opt/xmrig /var/lib/xmrig

#https://xmrig.com/docs/miner/build/alpine

git clone https://$GITTOKEN@github.com/stephenjonpeters/xxxmrig.git
mkdir xxxmrig/build && cd xxxmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps -DWITH_CN_LITE=OFF -DWITH_CN_HEAVY=OFF -DWITH_CN_PICO=OFF -DWITH_CN_FEMTO=OFF -DWITH_GHOSTRIDER=OFF -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_NVML=OFF -DHWLOC_DEBUG=ON 
make -j$(nproc)
cp xmrig /opt/xmrig/xmrig

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
            "url": "monerohash.com:9999",
            "user": "42mULgdD5UoZ3uQbVkc5d7My2v4z453ccPFJaf9RVdZ71oAyRspuhurFaC5kwqUDjw6rTJ2b4yDFxiqN3PbpATsS1Hyekry",
            "pass": $(hostname)
            "keepalive": true,
            "enabled": true,
            "tls": true
        }
    ],
    "pause-on-battery": false,
    "pause-on-active": false,
    "verbose": 2,
    "print-time": 60
}
EOF

nohup /opt/xmrig/xmrig &


/etc/init.d/
#!/sbin/openrc-run

name="busybox watchdog"
command="/sbin/watchdog"
command_args="${WATCHDOG_OPTS} -F ${WATCHDOG_DEV}"
pidfile="/run/watchdog.pid"
command_background=true

depend() {
	need dev
	after hwdrivers
}

start_pre() {
	if ! [ -n "$WATCHDOG_DEV" ]; then
		eerror "WATCHDOG_DEV is not set"
		return 1
	fi
}

