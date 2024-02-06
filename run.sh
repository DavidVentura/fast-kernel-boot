API_SOCKET="/tmp/firecracker.socket"
while true; do
	sudo rm -f $API_SOCKET
	sudo ./firecracker-hugepages --api-sock "${API_SOCKET}" | ts -s '%.S' | ts -i '%.S' | tee tmp
	mv tmp latest
	grep -E 'Linux version|vim-go' latest | awk '{print $2}' | xargs | while read a b; do echo "$b-$a" | bc; done | tee -a boottimes

	sleep 0.01
done
