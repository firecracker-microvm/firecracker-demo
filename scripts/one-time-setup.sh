# Load kernel module
sudo modprobe kvm_intel

# Configure packet forwarding
sudo sysctl -w net.ipv4.conf.all.forwarding=1

# Avoid "neighbour: arp_cache: neighbor table overflow!"
sudo sysctl -w net.ipv4.neigh.default.gc_thresh1=1024
sudo sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
sudo sysctl -w net.ipv4.neigh.default.gc_thresh3=4096
