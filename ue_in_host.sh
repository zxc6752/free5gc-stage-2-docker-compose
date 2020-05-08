#!/bin/bash

CONTAINER_NAME="simulator"

# test_string="[SESSION] ID=10,DNN=internet,SST=1,SD=010203,UEIP=60.60.0.1,ULAddr=10.200.200.102,ULTEID=2,DLAddr=10.200.200.1,DLTEID=1"
SESS_FORMAT=$'\[SESSION\] ID=([0-9]+),DNN=([^,]+),SST=([0-9]+),SD=([0-9]+),UEIP=([^,]+),ULAddr=([^,]+),ULTEID=([0-9]+),DLAddr=([^,]+),DLTEID=([0-9]+)'
# if [[ $test_string =~ $SESS_FORMAT ]]; then echo "DNN=${BASH_REMATCH[1]},UEIP=${BASH_REMATCH[4]}"; fi

# TUN="uetun"
# TUN_ADDR="60.60.0.1"

function show_usage {
    echo
    echo "Ue Simulator"
    echo "Usage: $0 <ip> <port> <supi> <id> <time> <servicIp> <servicePort> [-k|--keep-alive] [-b|--bandwidth=] [-s|--slice=]"
    echo
    echo "Arguments:"
    echo "  id                 : pdu session id"
    echo "  time               : pdu session would exist n[seconds]"
    echo "  -k|--keep-alive    : do not deregsiter"
    echo "  -b|--bandwidth=    : iperf3 client send data bandwidth(default is 20mbps)"
    echo "  -s|--slice=        : specific pdu session slice info, format: \"dnn=%s,sst=%d,sd=%s\""
}

if [ -z "$5" ]
then
    show_usage
    exit 1
fi


HOST=$1
PORT=$2
SUPI=$3
ID=$4
TIME=$5
ServiceIp=$6
ServicePort=$7
BANDWIDTH=20m
ALIVE=false

shift 6

for i in "$@"
do
case $i in
    -b=*|--bandwidth=)
    BANDWIDTH=${i#*=}
    shift
    ;;
    -k|--keep-alive)
    ALIVE=true
    shift
    ;;
    -s=*|--slice=)
    SLICE="${i#*=}"
    shift
    ;;
    -p=*)
    prefix="${i#*=}"
    shift
    ;;
esac
done


function check_error() {
    if [[ "$1" == *"[ERROR]"* ]] && [[ "$1" == *"FAIL"* ]]; then
        exit 1
    fi
}
send_msg() { 
    echo "\$ $1" 
    echo "$1" >&$2
}
read_msg() {
    read -r msg_in <&$1
    check_error "$msg_in"
    echo "$msg_in"
}
get_ueip(){
    if [[ $1 =~ $SESS_FORMAT ]]
    then 
        echo "${BASH_REMATCH[5]}"
    fi 
}

exec 3<>/dev/tcp/${HOST}/${PORT}

read -r msg_in <&3
echo $msg_in
# send SUPI

send_msg "$SUPI" 3
read_msg 3

# Register
send_msg "reg" 3
read_msg 3

# ADD Session
msg_out="sess $ID add"
[ -n "$SLICE" ] && msg_out="$msg_out"" ${SLICE}"
send_msg "$msg_out" 3
msg_in=$(read_msg 3)

# Add Ip in tun dev
UEIP=$(get_ueip "$msg_in")

if [ -n "${UEIP}" ] 
then
    echo "UE_IP: ${UEIP}"
    docker exec $CONTAINER_NAME /bin/bash -c "ping ${ServiceIp} -I ${UEIP} -i1 -c $TIME > /ping_log/ping${prefix}_${ID}.txt &
    iperf -c ${ServiceIp} -p ${ServicePort} -B ${UEIP} -t $TIME -i 1 -u -b ${BANDWIDTH} -l 14000" > /dev/null
else 
    echo "$msg_in"
fi

if $ALIVE;
then
    # send rel pdu sess
    send_msg "sess $ID del" 3
    read_msg 3
else 
    # send del reg
    send_msg "dereg" 3
    read_msg 3
fi

exec 3<&-