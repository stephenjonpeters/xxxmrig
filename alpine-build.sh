commitHashLong=$(git rev-parse HEAD)
commitHash=${commitHashLong:0:7}
read -p "wallet: " WALLET
PROCS=$(nproc)
THREADS=$(($PROCS/2))

#https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts#setup-sshd
setup-alpine

apk add util-linux pciutils hwdata-pci usbutils hwdata-usb coreutils binutils findutils grep iproute2 vim wget plocate git ufw 


#https://pkgs.alpinelinux.org/package/edge/main/x86_64/linux-firmware-radeon
apk install linux-firmware-radeon

#https://pkgs.alpinelinux.org/package/edge/main/x86_64/linux-firmware-amdgpu
#apk install linux-firmware-amdgpu

#https://xmrig.com/docs/miner/build/alpine

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="msr.allow_writes=on"/'  /etc/default/grub
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

cp ~/.bashrc ~/.bashrc.$TS
cat <<EOF>> ~/.bashrc
VISUAL="vim" ; export VISUAL
EDITOR="\$VISUAL" ; export EDITOR
EOF

cat <<EOF> ~/.vimrc
set mouse=v
set number
EOF

source .bashrc

cp /etc/security/limits.conf /etc/security/limits.conf.$TS
cat <<EOF>>  /etc/security/limits.conf
echo root hard nofile 1048576
echo root soft nofile 1048576
EOF

cp  /etc/sysctl.conf  /etc/sysctl.conf.$TS
cat <<EOF> /etc/sysctl.conf
vm.nr_hugepages=1024
kernel.shmmax = 3254779904
vm.hugetlb_shm_group = 0
vm.min_free_kbytes = 112640
EOF


cd /root/ 
rm -rf xxxmrig
rm -f /opt/xmrig/xmrig
rm -f /opt/xmrig/xmr.json
rm -f /opt/xmrig/config.json
mkdir -p /opt/xmrig /var/lib/xmrig

apk add git make cmake libstdc++ gcc g++ automake libtool autoconf linux-headers

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
    "pause-on-active": false,
    "verbose": 2,
    "print-time": 60
}
EOF

