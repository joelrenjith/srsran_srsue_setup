#!/bin/bash
tshark -i eth0 -f "udp port 2152" -a filesize:1024 -b files:10 -w captures/capture.pcap
