#!/bin/bash

# Source and destination directories
SOURCE_DIR="/home/snorty/tdir/captures/"
DESTINATION_DIR="root@10.53.1.4:/home/ubuntu/hlde/"

# Loop through each file in the source directory
for FILE in "$SOURCE_DIR"*; do
    if [ -f "$FILE" ]; then
        # Send file using rsync and remove source files upon successful transfer
        rsync -avz -e "ssh -i /home/snorty/.ssh/id_rsa" --ignore-existing --remove-source-files "$FILE" "$DESTINATION_DIR"

        # Check if rsync was successful
        if [ $? -eq 0 ]; then
            echo "Successfully transferred and deleted: $FILE"
        else
            echo "Failed to transfer: $FILE"
        fi
    fi
done
