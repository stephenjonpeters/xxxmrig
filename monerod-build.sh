apk update 

apk add monero

apk -U upgrade



cat << EOF > ~/.profile
VISUAL="vim" ; export VISUAL
EDITOR="$VISUAL" ; export EDITOR
alias h="history"
alias t="tail -f /var/log/messages"
alias x="cd /opt/xmrig; ls -ltr"
alias s="grep speed /var/log/messages"
alias startd="rc-service monerod start"
alias stopd="rc-service monerod stop"
alias startx="rc-service xmrig start"
alias stopx="rc-service xmrig stop"
EOF

source .profile

cat <<EOF> /etc/init.d/monerod
#!/sbin/openrc-run
name="monerod"
command="/usr/bin/monerod"
command_args="--detach" 
supervisor="supervise-daemon"
pidfile="/run/monerod.pid"
EOF

rc-update add monerod

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

