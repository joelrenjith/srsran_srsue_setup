#!/bin/bash

# Add route for 10.45.0.0/16 via 10.53.1.2
sudo ip route add 10.45.0.0/16 via 10.53.1.2

# Add default route in network namespace 'ue1' via 10.45.1.1 on interface 'tun_srsue'
sudo ip netns exec ue1 ip route add default via 10.45.1.1 dev tun_srsue
sudo ip netns exec ue2 ip route add default via 10.45.1.1 dev tun_srsue
sudo ip netns exec ue3 ip route add default via 10.45.1.1 dev tun_srsue

sudo ip route add 10.53.1.2 via 10.53.1.3
