#!/usr/bin/env bash

exe() { echo "\$ $@" ; "$@" ; }

UPF_TX_LIST=(100)
UPF_RX_LIST=(100)
UPF_DELAY_LIST=(1ms) 
UPF_LOSS_LIST=(5%)
UPF_VETH_LIST=()
UPF_NAME_LIST=()

function remove_tc {
    if [[ $(tc qdisc |grep 'tbf 1:') ]]; then
	echo "Unlimit traffic on UPFs" 
        for index in ${!UPF_RX_LIST[@]}; do
            # Unlimit TX
            exe docker exec -it ${UPF_NAME_LIST[$index]} tc qdisc del root dev eth0
            # Unlimit RX
            exe sudo tc qdisc del root dev ${UPF_VETH_LIST[$index]}
        done
    fi
}

function add_tc {
    for index in ${!UPF_RX_LIST[@]}; do
        # Limit TX
        exe docker exec -it ${UPF_NAME_LIST[$index]} /bin/bash -c "
        tc qdisc add dev eth0 root handle 1: tbf rate ${UPF_TX_LIST[$index]}mbit burst 1540 limit 3000 
        tc qdisc add dev eth0 parent 1:1 handle 10: netem delay ${UPF_DELAY_LIST[$index]} loss ${UPF_LOSS_LIST[$index]}
        "
        # Limit RX
        exe sudo tc qdisc add dev ${UPF_VETH_LIST[$index]} root handle 1: tbf rate ${UPF_RX_LIST[$index]}mbit burst 1540 limit 3000
    done
}
function init_upf {
    for index in ${!UPF_RX_LIST[@]}; do
        container_name="upf$(($index+1))"
        UPF_NAME_LIST+=($container_name)
        num=$(docker exec -it $container_name cat /sys/class/net/eth0/iflink)
        num=${num:0:$(( ${#num} - 1 ))}
        INTERFACE=$( ip a | grep $num | grep -Po '(?<=(: )).*(?=@)' )
        UPF_VETH_LIST+=($INTERFACE)
    done
}

sudo -v
if [ $? == 1 ]
then
    echo "Without root permission, you cannot run the test due to our test is using namespace"
    exit 1
fi

for i in "$@"
do
case $i in
    --remove|-r)
    REMOVE=true
    shift # past argument with no value
    ;;
esac
done

init_upf
# [ -n $1 ] && ADDRESS=$1
remove_tc

if [ -z $REMOVE ]; then
     echo "Limit traffic on UPFs" 
     add_tc
fi
