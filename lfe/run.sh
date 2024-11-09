#!/bin/bash

# Run packet_capture.sh in the background
./sharky.sh &

# Run sync.sh every 10 seconds in a loop
while true
do
  ./sync.sh
  sleep 10
done
