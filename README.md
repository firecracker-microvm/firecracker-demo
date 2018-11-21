# firecracker-demo

## general info

For simplicity run everything as root. If we set `CAP_NET_ADMIN` on the **firecracker** binary, we don't need to run as root anymore.
Demo was developed to be run on a EC2 i3.metal instance.

## step-by-step

Get this repo on a EC2 i3.metal instance.
Open two terminals/ssh-connections to the instance.

### Terminal window 1

will show a heatmap of network traffic done by each microVM.

```bash
python3 microvm-tiles.py
```

### Terminal window 2

will control the rest of the demo.

```bash
# switch to root
sudo su
```

Create 4000 TAPs, configure networking for them and start 4k `iperf3` servers each bound to their respective TAP.

```bash
./0.initial-setup.sh 4000
```

#### Start 4000 Firecracker microVMs

Use 6 parallel threads to configure and start **4000** microVMs. Each thread will get an equal slice of the 4k total and sequentially configure and issue the start command for each microVM.

The script will report **total duration** as well as **mutation rate**.

```bash
# start a total of 4k uVMs from 10 parallel threads
./parallel-start-many.sh 0 4000 6
# ... wait for it ... should take around 60 seconds ... watch the heatmap

# process uVMs logs to get boot-times. Will write "data.log".
./extract-times.sh &
```

Each microVM has a workload (iperf client) and will run it in a loop with a random `sleep` between iterations.

Looking at the heatmap you should see **six** 'snakes' advancing which are the microVMs that have just been powered up and are doing their first iteration of the workload. Once that's done, the random sleep will lead to random lighting of the heatmap.

#### Pick a microVM and play with it

Pick a number `0 <= ID < 4000`. For this example `42` was chosen.

```bash
ID="42"
# get the IP for that microVM
ifconfig fc-$ID-tap0 | grep "inet "
       inet 169.254.0.170  netmask 255.255.255.252  broadcast 0.0.0.0

# IP of microVM on other side is *one less*
ssh -i xenial.rootfs.id_rsa 169.254.0.169
```

You're now inside the microVM. Do as you please.

Let's make it stand out in the heatmap.

```bash
# stop the workload service
localhost:~# rc-service demo-workload stop
 * Stopping demo-workload ...                                    [ ok ]
# manually run iperf with a higher bandwidth than the rest
localhost:~# iperf3 -c $(./gateway-ip.sh) -b 104857600
# check out the heatmap
```

This microVM should now shine brighter in the heatmap.

Demonstrate the network throughput of this microVM:
```bash
localhost:~# iperf3 -c $(./gateway-ip.sh)
Connecting to host 169.254.0.170, port 5201
[  5] local 169.254.0.169 port 53392 connected to 169.254.0.170 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.72 GBytes  14.8 Gbits/sec    0    952 KBytes       
[  5]   1.00-2.00   sec  1.67 GBytes  14.4 Gbits/sec    0    952 KBytes       
[  5]   2.00-3.00   sec  1.76 GBytes  15.1 Gbits/sec    0    952 KBytes       
[  5]   3.00-4.00   sec  1.69 GBytes  14.5 Gbits/sec    0    952 KBytes       
[  5]   4.00-5.00   sec  1.69 GBytes  14.5 Gbits/sec    0    952 KBytes       
[  5]   5.00-6.00   sec  1.66 GBytes  14.3 Gbits/sec    0    952 KBytes       
[  5]   6.00-7.00   sec  1.67 GBytes  14.4 Gbits/sec    0    952 KBytes       
[  5]   7.00-8.00   sec  1.77 GBytes  15.2 Gbits/sec    0    952 KBytes       
[  5]   8.00-9.00   sec  1.76 GBytes  15.1 Gbits/sec    0    952 KBytes       
[  5]   9.00-10.00  sec  1.42 GBytes  12.2 Gbits/sec    0    952 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  16.8 GBytes  14.4 Gbits/sec    0             sender
[  5]   0.00-10.00  sec  16.8 GBytes  14.4 Gbits/sec                  receiver

iperf Done.
```

#### Plot the 4000 Firecracker microVMs boot times

To plot the boot times, on your local machine or any non-headless setup:

```bash
scp -i <identity-key> ec2-user@<i3.metal-ip>:firecracker-demo/{data.log,gnuplot.script} .
gnuplot gnuplot.script
xdg-open boot-time.png  # on Ubuntu. For other distros just use your default .png viewer.
```
