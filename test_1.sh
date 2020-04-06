#!/bin/bash

exe() { echo "\$ $@" ; "$@" ; }

EXE_FILE="./radio_simulator/ue_in_host.sh"

HOST=10.200.200.100
PORT=9999
SUPI=imsi-2089300007487
ID=(3 4 5 6 7)
TIME=(4 6 6 10 8)
ServiceIp=60.60.2.1
ServicePort=5001
BANDWIDTH=20m

send_msg() { 
    echo "\$ $1" 
    echo "$1" >&$2
}

exec 4<>/dev/tcp/${HOST}/${PORT}
read <&4

echo "Send Registration"
send_msg "$SUPI" 4
read <&4

send_msg "reg" 4
read -r msg_in <&4
echo "$msg_in"

sleep 1

PID_LIST=()
for index in ${!ID[@]}; do
    exe $EXE_FILE $HOST $PORT $SUPI ${ID[$index]} ${TIME[$index]} $ServiceIp $ServicePort -k -b=$BANDWIDTH &
    PID_LIST+=($!)
    sleep 1
done

wait 
 
echo "Send deregistration"



# Register
send_msg "dereg" 4
read -r msg_in <&4
echo ${msg_in}

exec 4<&-

echo exited