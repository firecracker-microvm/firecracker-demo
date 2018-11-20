# firecracker-demo

For simplicity run everything as root.
Demo was developed to be run on a EC2 i3.metal instance.

## initial setup

```bash
./0.initial-setup.sh
```

## Single microVM, ssh then iperf

```bash
./start-firecracker.sh
ssh -i xenial.rootfs.id_rsa root@169.254.0.1
iperf3 -c 169.254.0.2
reboot      # this is the nice poweroff, alternatively could CTRL+D then `killall firecracker`
```

## 4000 VMs

```bash
./parallel-start-many.sh 0 4000 10     # will start a total of 4k uVMs from 10 parallel threads
# ... wait for it ... should take around 37 seconds
./extract-times.sh &        # process uVMs logs to get boot-times. Will write "data.log".

```

To plot the boot times, on your local machine or any non-headless setup:
```bash
scp -i <identity-key> ec2-user@<i3.metal-ip>:firecracker-demo/{data.log,gnuplot.script} .
gnuplot gnuplot.script
xdg-open boot-time.png  # on Ubuntu. For other distros just use your default .png viewer.
```
