#!/bin/sh -e

# https://xmrig.com/docs/miner/hugepages#onegb-huge-pages

sysctl -w vm.nr_hugepages=2048

for i in $(find /sys/devices/system/node/node* -maxdepth 0 -type d);
do
    echo 2 > "$i/hugepages/hugepages-1048576kB/nr_hugepages";
done

echo "1GB pages successfully enabled"
