#!/bin/bash
set -e
TAP_DEV="tap0"
TAP_IP="172.16.0.1"
MASK_SHORT="/30"
FC_MAC="06:00:AC:10:00:02"
API_SOCKET=/tmp/firecracker.socket 
KERNEL=/home/david/git/lk/vmlinuxwasworking
KERNEL=/home/david/git/lk/vmlinux-5.10.204
KERNEL=/home/david/git/lk/vmlinux-no-smp
KERNEL=/home/david/git/lk/vmlinux-smp
ROOTFS=$PWD/rootfs.ext4

LOGFILE=/tmp/firecracker.log
IP_CONFIG=""
IP_CONFIG="ip=192.168.2.15::192.168.2.1:255.255.255.0:hostname:eth0:off"
IP_CONFIG="ip=172.16.0.2::172.16.0.1:255.255.255.0:hostname:eth0:off"
SERIAL_CONFIG="earlyprintk=serial,ttyS0 console=ttyS0,115200"
#SERIAL_CONFIG="console=ttyS0,2000000"
QUIET="quiet"
QUIET=""
INIT="init=/busybox -- sh /init.sh"
INIT="init=/goinit"
INIT="init=/initc"
OPT=""
OPT="no_timer_check printk.time=1  cryptomgr.notests tsc=reliable 8250.nr_uarts=1 iommu=off pci=off"
OPT="${OPT} ip.dev_wait_ms=0"
OTHER=""
KERNEL_BOOT_ARGS="$SERIAL_CONFIG panic=-1 reboot=t $OPT root=/dev/vda $OTHER $IP_CONFIG $QUIET $INIT"
#  

#sudo ip link del "$TAP_DEV" 2> /dev/null || true
#sudo ip tuntap add dev "$TAP_DEV" mode tap
#sudo sysctl -w net.ipv4.conf.${TAP_DEV}.proxy_arp=1 > /dev/null
#sudo sysctl -w net.ipv6.conf.${TAP_DEV}.disable_ipv6=1 > /dev/null
#sudo ip addr add "${TAP_IP}${MASK_SHORT}" dev "$TAP_DEV"
#sudo ip link set dev "$TAP_DEV" up

if [ ! -f $ROOTFS ]; then
	dd if=/dev/zero of=$ROOTFS.ext4 bs=1M count=50
	mkfs.ext4 $ROOTFS
fi
sudo chmod 666 $API_SOCKET
curl -X PUT --unix-socket "${API_SOCKET}"     --data "{
    \"log_path\": \"${LOGFILE}\",
    \"level\": \"Debug\",
    \"show_level\": true,
    \"show_log_origin\": true
}"     "http://localhost/logger"

curl -X PUT --unix-socket "${API_SOCKET}"     --data "{
    \"kernel_image_path\": \"${KERNEL}\",
    \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
}"     "http://localhost/boot-source"

curl -X PUT --unix-socket "${API_SOCKET}"     --data "{
    \"vcpu_count\": 1,
    \"mem_size_mib\": 128
}"     "http://localhost/machine-config"


curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }" \
    "http://localhost/drives/rootfs"


curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"iface_id\": \"net1\",
        \"guest_mac\": \"$FC_MAC\",
        \"host_dev_name\": \"$TAP_DEV\"
    }" \
    "http://localhost/network-interfaces/net1"


sleep 0.015s

curl -X PUT --unix-socket "${API_SOCKET}" \
    --data "{
        \"action_type\": \"InstanceStart\"
    }" \
    "http://localhost/actions"
