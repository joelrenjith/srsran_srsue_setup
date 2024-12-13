# srsran_srsue_setup

Enable IP Forwarding so that UE traffic sent to internet:
 - Here `IFNAME` is the interface in the host that connects to the internet.

```
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o <IFNAME> -j MASQUERADE
```

Dependencies:

```
apt install cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev libzmq3-dev
```

## Building:
 - Clone and build srsRAN_Project with ZeroMQ:

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

- Clone and build srsRAN_4G with ZeroMQ:

```
cd ~
git clone https://github.com/srsran/srsRAN_4G.git
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

**Open5GS Core**:

 - We will be running the dockerized version of the Open5GS given in srsRAN_Project:
   
```
cd ./srsRAN_Project/docker
sudo docker compose up --build 5gc
```

**gNB**:

- First we will download the configuration file of the gNB with ZeroMQ and then run it:

```
cd srsRAN_Project/build/apps/gnb/
wget https://docs.srsran.com/projects/project/en/latest/_downloads/a7c34dbfee2b765503a81edd2f02ec22/gnb_zmq.yaml
sudo ./gnb -c ./gnb_zmq.yaml
```

**srsUE**:
- First we add a network space for our UE.
   ```
   sudo ip netns add ue1
   ```
- Then we will download the configuration file of the srsUE with ZeroMQ and then run it:

   ```
   cd /srsRAN_4G/build/srsue/src/
   wget https://docs.srsran.com/projects/project/en/latest/_downloads/fbb79b4ff222d1829649143ca4cf1446/ue_zmq.conf
   sudo ./srsue ./ue_zmq.conf
   ```
## Routing Configuration:

```
sudo ip ro add 10.45.0.0/16 via 10.53.1.2
sudo ip netns exec ue1 ip route add default via 10.45.1.1 dev tun_srsue
```

## Testing:
1. **Check the host routing table:**

```
route -n
```

Output: 

2. **Check the UE routing table:**

```
sudo ip netns exec ue1 route -n
```

3. **Ping:**
 - Uplink:
   
   ```
   sudo ip netns exec ue1 ping 10.45.1.1
   ```
   
 - Downlink:
   
   ```
   ping 10.45.1.2
   ```
   
4. **iPerf3:**
   - Server:
      - Open a shell of the core container and run this:
        
        ```
        iperf3 -s -i 1
        ```
        
   - Client:
     - In the host run this through the ue network space:

          ```
          # TCP
          sudo ip netns exec ue1 iperf3 -c 10.45.1.1 -i 1 -t 60
          # or UDP
          sudo ip netns exec ue1 iperf3 -c 10.45.1.1 -i 1 -t 60 -u -b 10M
          ```
          
## Sending user traffic to core:
 - **UE DNS Config:**
   - Create a directory for the UE network space if not done already:
    
    ```
    sudo mkdir -p /etc/netns/ue1
    ```
    
   - Copy your current resolv.conf into the ue1 namespace:
     
     ```
     sudo cp /etc/resolv.conf /etc/netns/ue1/resolv.conf
     ```
     
   - Open `/etc/netns/ue1/resolv.conf` and add these 2 lines:
     
     ```
     nameserver 8.8.8.8
     nameserver 1.1.1.1
     ```
   
  - Now we can send user traffic to the core and get responses:
   
    ```
    sudo ip netns exec ue1 ping www.google.com    
    sudo ip netns exec ue1 curl www.example.com
    ```

## Multi-UE:
 - Follow the instructions here: [Multi UE Emulation with srsRAN](https://docs.srsran.com/projects/project/en/latest/tutorials/source/srsUE/source/index.html#multi-ue-emulation) for making changes and running ṭhe core, gNB and UEs.
 - For GNU Companion, run the following command. (Note that only after running this will the UEs connect to the core).

   ```
   cd /usr/bin/
   QT_QPA_PLATFORM=offscreen python3 multi_ue_scenario.py
   ```
  
 - Do the UE DNS Config for the UEs as we did in the [previous section](https://github.com/joelrenjith/srsran_srsue_setup/blob/main/README.md#sending-user-traffic-to-core).

## LFE Injection and HLDE Connection:
- Download the docker_compose.yml provided here into your host and run the following command:
  
  ```
  docker compose up
  ```
  
- This will setup the LFE and HLDE as two containers and the connections to the existing architecture will also be done here.
   - `docker_ran` (subnet : `10.53.1.0`) is the docker network for srsRAN and Open5Gs. The LFE is connected to this network. 
   - `packetHighway` (subnet : `10.53.2.0`) is the docker network connecting the LFE and HLDE. Both LFE and HLDE are connected to this network.
- Now run `gateways.sh` given here in the host to setup the routing for the overall architetcure. All traffic going from RAN to CORE will pass through LFE. (This also conatins the normal gateway commands for the srsRAN setup.)
- Test the UE connections once more.(Incase it inst wokring, just open another terminal and open a shell into the LFE container).
   
## PulledPork:
 - The below setup has been already implemented in the LFE container. This is just for your reference.
 - Refer [PulledPork3 Setup](https://github.com/shirkdog/pulledpork3) to setup Pulled Pork.
 - In the HLDE container, start a webserver in the same directory where you are storing the updated ruleset.
 - Open `pulledpork.py` in the LFE conatiner and do the following change:

   ```
   RULESET_URL_SNORT_COMMUNITY = 'http://<ip of hlde webserver>:<port of hlde webserver>/<name of the tar file with the updated ruleset.>'
   ```

 - In the HLDE, the directory format of the ruleset should look like this:

   ```
   tar -tzf snort3-community-rules.tar.gz :
   ./
   ./snort3-community-rules/
   ./snort3-community-rules/snort3-community.rules
   ```
  
 - Run pulled pork and snort as specified in [PulledPork3 Setup](https://github.com/shirkdog/pulledpork3)

## Runnig the entire setup:
 - Open a new terminal and open a shell into the LFE container.
   - Run the following commands command to setup the server for pulledpork to pull rules

     ```
     cd Data/Rules
     ./serve.sh
     ```

   - Run the following command to start the SSH server for Rsync.

     ```
     cd /app
     ./sshStartup.sh
     ```
     
   - Run the following command to have the HLDE runnig to parse and evaluate traffic

     ```
     ./run_hlde.sh
     ```
     
 - Open two terminals and open a shell into the LFE container in both of them as root and run this command in both.

   ```
   cd tdir
   ```

   - Now in one terminal run the following to run snort:

     ```
     ./snortStartup.sh
     ```
     
   - In the other terminal run the following script that runs pulledpork, rsync and tshark.

     ```
     ./run.sh
     ```
     
     - You might see a warnning from pulledpork with error code 404 telling it couldnt find the ruleset file. This is fine because initially the HLDE wouldn't have made a ruleset as it didnt get any malicious traffic yet.
 - Now in the host you can run:

    ```
    sudo ip netns exec <ue name> <command you want to run>
    ```
    - You can try sending just benign traffic or simulate mailcious traffic using tools such as `hping`.
   

