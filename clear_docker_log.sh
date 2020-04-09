#!/usr/bin/env bash



Containers="amf smf udr pcf udm nssf ausf simulator balancer upf1 upf2 upf3 upf4 upf5 upf6 upf7 upf8 upf9 upf10"


for con in ${Containers}; do
  if [[ "$(docker ps -aq -f name=^/${con}$ 2> /dev/null)" == "" ]]; then
    echo "Container \"$con\" does not exist, exiting."
    continue
  fi
  echo "" > $(docker inspect -f '{{.LogPath}}' ${con})
done
