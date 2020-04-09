#!/bin/bash

exe() { echo "\$ $@" ; "$@" ; }

EXE_FILE="./radio_simulator/ue_in_host.sh"

HOST=10.200.200.100
PORT=9999
SUPI=imsi-2089300007487
ID=(2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17)
TIME=(40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40)
ServiceIp=60.60.2.1
ServicePort=5001
BANDWIDTH=50m


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

mkdir iper_log

# iperf -s -u -B ${ServiceIp} -p $ServicePort -i 1 -x M -l 14000 > ./iper_log/iperf_server.txt &
# SERVER_PID=$!
SERVER_PID=()

sleep 1

PID_LIST=()

for index in ${!ID[@]}; do
    port=500$index
    iperf -s -u -B ${ServiceIp} -p $port -i 1 -x M -l 14000 > ./iper_log/iperf_server_${ID[$index]}.txt &
    # iperf -s -u -B ${ServiceIp} -p $port -i 1 -x M > iperf_server_${ID[$index]}.txt &
    SERVER_PID+=($!)
    exe $EXE_FILE $HOST $PORT $SUPI ${ID[$index]} ${TIME[$index]} $ServiceIp $port -k -b=$BANDWIDTH &
    PID_LIST+=($!)
    sleep 1.5
done

wait ${PID_LIST[@]}
 
echo "Send deregistration"


sleep 1
# Register
send_msg "dereg" 4
read -r msg_in <&4
echo ${msg_in}

exec 4<&-

kill -9 ${SERVER_PID[@]}
# kill -9 $SERVER_PID

echo exited