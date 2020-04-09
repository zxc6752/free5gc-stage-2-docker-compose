#!/usr/bin/env bash

echo "" > tmp.txt

UPF_Anchor=( false false false false false false false true true true )
for index in ${!UPF_Anchor[@]}; do
    upf_index=$(($index+1))
    replace="
  free5gc-upf${upf_index}:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: upf${upf_index}
    command: | 
        /bin/bash -c \""
    if ${UPF_Anchor[$index]}; then
        replace+="
        ip route change default via 60.60.1.254 dev eth2
        iptables -t nat -I POSTROUTING -o eth2 -j MASQUERADE"
    fi
        replace+="
        sysctl fs.mqueue.msg_default=5
        # cd /gofree5gc/src/upf && rm -rf ./build && mkdir -p build && cd build && cmake .. && make -j8
        /gofree5gc/src/upf/build/bin/free5gc-upfd -f /config/upf${upf_index}cfg.yaml &
        sleep 0.05
        ip link set dev upfgtp0 mtu 65535
        /dynamicpath/bin/monitor -h upf${upf_index}:8888 -eth1 rx=100,tx=100 
        \"
    privileged: true
    volumes:
      - \"./gofree5gc:/gofree5gc\"
      - \"./config:/config\"
      - \"./dynamicpath:/dynamicpath\"
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - \"/dev/net/tun:/dev/net/tun\"
    expose:
      - \"2152\"
      - \"8805\"
      - \"8888\""
    if [ $upf_index -le 9 ]; then
        upf_index=0${upf_index}
    fi
    replace+="
    networks:
      1_cpnet:
        ipv4_address: 10.200.200.1${upf_index}
      2_upnet:
        ipv4_address: 10.200.201.1${upf_index}"
    if ${UPF_Anchor[$index]}; then
        replace+="
      3_servicenet:
        ipv4_address: 60.60.1.1${upf_index}"
    fi
    echo "$replace" >> tmp.txt
done
