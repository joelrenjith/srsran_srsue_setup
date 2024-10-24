# srsran_srsue_setup

Enable IP Forwarding so that UE traffic sent to internet:

```
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o <IFNAME> -j MASQUERADE
```

Dependencies:

```
apt install cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev libzmq3-dev
```

## Building:
Clone and build srsRAN_Project with ZeroMQ:

```
cd ~
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build
cd build
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j $(nproc)
make test -j $(nproc)
```

Clone and build srsRAN_4G with ZeroMQ:

```
cd ~
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project/
mkdir build
cd build/
cmake ../ -DENABLE_EXPORT=ON -DENABLE_ZEROMQ=ON
make -j $(nproc)
make test -j $(nproc)
```

## Running the Network

The following order should be used when running the network:
1. 5GC
2. gNB
3. UE

Open5GS Core:

 - We will be running the dockerized version of the Open5GS given in srsRAN_Project:
   
```
cd ./srsRAN_Project/docker
sudo docker compose up --build 5gc
```

gNB:

First we will download the configuration file of the gNB with ZeroMQ and then run it:

```
cd srsRAN_Project/build/apps/gnb/
wget https://docs.srsran.com/projects/project/en/latest/_downloads/a7c34dbfee2b765503a81edd2f02ec22/gnb_zmq.yaml
sudo ./gnb -c ./gnb_zmq.yaml
```

srsUE:

First we will download the configuration file of the srsUE with ZeroMQ and then run it:

```
cd /srsRAN_4G/build/srsue/src/
wget https://docs.srsran.com/projects/project/en/latest/_downloads/fbb79b4ff222d1829649143ca4cf1446/ue_zmq.conf
sudo ./srsue ./ue_zmq.conf
```
## Routing Configuration

```
sudo ip ro add 10.45.0.0/16 via 10.53.1.2
sudo ip netns exec ue1 ip route add default via 10.45.1.1 dev tun_srsue
```

Do the testing provided in the docs.




