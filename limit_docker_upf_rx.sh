#!/usr/bin/env bash

exe() { echo "\$ $@" ; "$@" ; }

UPF_RX_LIST=(100)

function remove_tc {
    if [[ $(tc qdisc |grep 'tbf 1:') ]]; then
	echo "Unlimit Rx traffic on UPFs" 
        for index in ${!UPF_RX_LIST[@]}; do
            num=$(docker exec -it upf$(($index+1)) cat /sys/class/net/eth0/iflink)
            num=${num:0:$(( ${#num} - 1 ))}
            INTERFACE=$( ip a | grep $num | grep -Po '(?<=(: )).*(?=@)' )
            exe sudo tc qdisc del root dev ${INTERFACE}
        done
    fi
}

function add_tc {
    for index in ${!UPF_RX_LIST[@]}; do
        num=$(docker exec -it upf$(($index+1)) cat /sys/class/net/eth0/iflink)
        num=${num:0:$(( ${#num} - 1 ))}
        INTERFACE=$( ip a | grep $num | grep -Po '(?<=(: )).*(?=@)' )
        exe sudo tc qdisc add dev ${INTERFACE} root handle 1: tbf rate ${UPF_RX_LIST[$index]}mbit burst 1540 limit 3000
    done
}

for i in "$@"
do
case $i in
    --remove|-r)
    REMOVE=true
    shift # past argument with no value
    ;;
esac
done

# [ -n $1 ] && ADDRESS=$1
remove_tc

if [ -z $REMOVE ]; then
     echo "Limit Rx traffic on UPFs" 
     add_tc
fi

