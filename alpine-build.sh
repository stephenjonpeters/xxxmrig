commitHashLong=$(git rev-parse HEAD)
commitHash=${commitHashLong:0:7}
read -p "wallet: " WALLET
PROCS=$(nproc)
THREADS=$(($PROCS/2))

#https://xmrig.com/docs/miner/build/alpine

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
    "pause-on-active": false,
    "verbose": 2,
    "print-time": 60
}
EOF

