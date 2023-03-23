# WIFI

## iwctl

```
iwctl device list
iwctl station <stationname> scan
iwctl station <stationname> get-networks
iwctl station <stationname> connect <ssid> -P <password>
```

where <stationname> = wlan0 most of the time.

# Connect to the internet

We need to make sure that we are connected to the internet to be able to install Arch Linux `base` and `linux` packages. Let’s see the names of our interfaces.

```
# ip link
```

You should see something like this:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
		link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
		link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DORMANT group default qlen 1000
		link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff permaddr 00:00:00:00:00:00
```

+ `enp0s0` is the wired interface  
+ `wlan0` is the wireless interface  

# Wired Connection

If you are on a wired connection, you can enable your wired interface by systemctl start `dhcpcd@<interface>`.  

```
# systemctl start dhcpcd@enp0s0
```

# Wireless Connection

If you are on a laptop, you can connect to a wireless access point using `iwctl` command from `iwd`. Note that it's already enabled by default. Also make sure the wireless card is not blocked with `rfkill`.

## Scan for network.

```
# iwctl station wlan0 scan
```

## Get the list of scanned networks by:

```
# iwctl station wlan0 get-networks
```

## Connect to your network.

```
# iwctl -P "PASSPHRASE" station wlan0 connect "NETWORKNAME"
```

## Internet Check:

```sh
ip a
```

or

```
ping google.com
```

If you receive Unknown host or Destination host unreachable response, means you are not online yet. Review your network configuration and redo the steps above.

If connection successful press CTRL-C to end ping

## Connect to Wi-Fi at install:

```sh
iwctl
iwctl device list
iwctl station stationname scan
iwctl station stationname get-networks
iwctl station stationname connect networkname
```
