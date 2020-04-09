#!/usr/bin/env bash

sudo -v
if [ $? == 1 ]
then
    echo "Without root permission, you cannot run the test due to our test is using namespace"
    exit 1
fi

./tc_config.sh

docker-compose up &
PID=$!
sleep 2
sudo ./limit_docker_upf_traffic.sh

function terminate()
{
    # kill amf first
    sudo kill -SIGINT ${PID}
    sleep 2
}

trap terminate SIGINT
wait ${PID}
