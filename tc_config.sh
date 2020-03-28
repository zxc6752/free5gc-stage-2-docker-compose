#!/usr/bin/env bash


UPF_TX_LIST=(100 200)
UPF_RX_LIST=(100 200)
UPF_DELAY_LIST=(1ms 3ms) 
UPF_LOSS_LIST=(5% 10%)

echo "Modify limit_docker_upf_traffic.sh for tc rule"

sed -i "5s/.*/$(sed -n '4p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "6s/.*/$(sed -n '5p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "7s/.*/$(sed -n '6p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "8s/.*/$(sed -n '7p' tc_config.sh)/" limit_docker_upf_traffic.sh

line_num=($(grep -n "/dynamicpath/bin/monitor -h" docker-compose.yaml | head -n ${#UPF_TX_LIST} | cut -d: -f1))

echo "Modify docker-compose.yaml for tc rule"
for index in ${!UPF_TX_LIST[@]}; do
    replace="        \/dynamicpath\/bin\/monitor -h upf$(($index+1)):8888 -eth1 rx=${UPF_RX_LIST[$index]},tx=${UPF_TX_LIST[$index]} \&"
    sed -i "${line_num[$index]}s/.*/$replace/" docker-compose.yaml
done
