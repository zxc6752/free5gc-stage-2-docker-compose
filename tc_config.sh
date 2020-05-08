#!/usr/bin/env bash


UPF_TX_LIST=(200 600 400 600 400 500 300 500 400 100)
UPF_RX_LIST=(200 600 400 600 400 500 300 500 400 100)
UPF_DELAY_LIST=(1ms 3ms 4ms 2ms 5ms 1ms 2ms 3ms 4ms 2ms) 
UPF_LOSS_LIST=(0.01% 0.05% 0% 0.01% 0.03% 0.06% 0.02% 0.04% 0.07% 0.04%)
UPF_Anchor=( false false false false false false false true true true )

echo "Modify limit_docker_upf_traffic.sh for tc rule"

sed -i "5s/.*/$(sed -n '4p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "6s/.*/$(sed -n '5p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "7s/.*/$(sed -n '6p' tc_config.sh)/" limit_docker_upf_traffic.sh
sed -i "8s/.*/$(sed -n '7p' tc_config.sh)/" limit_docker_upf_traffic.sh

line_num=($(grep -n "/dynamicpath/bin/monitor -h" docker-compose.yaml | head -n ${#UPF_TX_LIST[@]} | cut -d: -f1))
echo "Modify line ${line_num[@]} docker-compose.yaml for tc rule"
for index in ${!UPF_TX_LIST[@]}; do
    tx=$(( ${UPF_TX_LIST[$index]} - 30))
    rx=$(( ${UPF_RX_LIST[$index]} - 30))
    replace="        \/dynamicpath\/bin\/monitor -h upf$(($index+1)):8888 -eth1 rx=$rx,tx=$tx "
    if ${UPF_Anchor[$index]}; then 
        replace+="-eth2 rx=${UPF_RX_LIST[$index]},tx=${UPF_TX_LIST[$index]} " 
    fi
    sed -i "${line_num[$index]}s/.*/$replace/" docker-compose.yaml
done
