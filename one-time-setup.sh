# Load kernel module
sudo modprobe kvm_intel

# Configure packet forwarding
sudo sysctl -w net.ipv4.conf.all.forwarding=1

# Avoid "nf_conntrack: table full, dropping packet"
sudo sysctl -w net.ipv4.netfilter.ip_conntrack_max=99999999

# Avoid "neighbour: arp_cache: neighbor table overflow!"
sudo sysctl -w net.ipv4.neigh.default.gc_thresh1=1024
sudo sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
sudo sysctl -w net.ipv4.neigh.default.gc_thresh3=4096

# Add CAP_NET_ADMIN to firecracker (for TUNSETIFF ioctl)
sudo setcap cap_net_admin=eip firecracker
