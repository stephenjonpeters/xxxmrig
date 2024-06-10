apk update 

apk add  build-essential cmake pkg-config libssl-dev libzmq3-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev libexpat1-dev libpgm-dev qttools5-dev-tools libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev python3 ccache doxygen graphviz

apt update && apt upgrade -y



cat << EOF > ~/.profile
alias startd="rc-service monerod start"
alias stopd="rc-service monerod stop"
alias startx="rc-service xmrig start"
alias stopx="rc-service xmrig stop"
EOF

source .profile

git config --global user.email 
git config --global user.name 

sudo adduser --system --no-create-home --group monero # creates system user account for monero service
sudo mkdir -p /var/log/monero # logfile goes here
sudo mkdir -p /var/lib/monero # blockchain database goes here

wget https://downloads.getmonero.org/cli/linux64
wget https://www.getmonero.org/downloads/hashes.txt #download latest hashes.txt file
grep $(sha256sum monero-linux-x64-*.tar.bz2) hashes.txt #search hashes.txt file for the computed sha256sum

tar -xvf monero-linux-x64-*.tar.bz2
sudo mv monero-x86_64-linux-gnu-*/* /usr/local/bin
sudo chown -R monero:monero /usr/local/bin/monero*

cat<<EOF>/var/lib/monero/monerod.conf 
#blockchain data / log locations
data-dir=/var/lib/monero
log-file=/var/log/monero/monero.log

#log options
log-level=0
max-log-file-size=0 # Prevent monerod from managing the log files; we want logrotate to take care of that

# P2P full node
p2p-bind-ip=0.0.0.0 # Bind to all interfaces (the default)
p2p-bind-port=18080 # Bind to default port
public-node=true # Advertises the RPC-restricted port over p2p peer lists

# rpc settings
rpc-restricted-bind-ip=0.0.0.0
rpc-restricted-bind-port=18089

# i2p settings
tx-proxy=i2p,127.0.0.1:8060

# node settings
prune-blockchain=false
db-sync-mode=safe # Slow but reliable db writes
enforce-dns-checkpointing=true
enable-dns-blocklist=true # Block known-malicious nodes
no-igd=true # Disable UPnP port mapping
no-zmq=true # ZMQ configuration

# bandwidth settings
out-peers=32 # This will enable much faster sync and tx awareness; the default 8 is suboptimal nowadays
in-peers=32 # The default is unlimited; we prefer to put a cap on this
limit-rate-up=1048576 # 1048576 kB/s == 1GB/s; a raise from default 2048 kB/s; contribute more to p2p network
limit-rate-down=1048576 # 1048576 kB/s == 1GB/s; a raise from default 8192 kB/s; allow for faster initial sync
EOF

sudo chown -R monero:monero /var/lib/monero 
sudo chown -R monero:monero /var/log/monero

cat<<EOF>/etc/systemd/system/monerod.service
[Unit]
Description=monerod
After=network.target
[Service]
Type=forking
PIDFile=/var/lib/monero/monerod.pid
ExecStart=/usr/local/bin/monerod --config-file /var/lib/monero/monerod.conf --pidfile /var/lib/monero/monerod.pid --detach
User=monero
Group=monero
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable monerod
sudo systemctl restart monerod
sudo systemctl status monerod

cat<<EOF>/etc/systemd/system/monero.service
[Unit]
Description=monero
After=network.target
[Service]
Type=simple
PIDFile=/var/lib/monero/monero.pid
ExecStart=/usr/local/bin/monerod start_mining 42mULgdD5UoZ3uQbVkc5d7My2v4z453ccPFJaf9RVdZ71oAyRspuhurFaC5kwqUDjw6rTJ2b4yDFxiqN3PbpATsS1Hyekr 16 
User=monero
Group=monero
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable monero
sudo systemctl restart monero
sudo systemctl status monero

echo "done!"
