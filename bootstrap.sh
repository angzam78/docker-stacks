#!/bin/bash

read -s -p "Master Password: " password
printf "$password" | docker secret create adminpass -

# floating ip address stack
docker stack deploy -c ucarp.yml ucarp

# HA persistent database stack
docker stack deploy -c cockroachdb.yml cockroachdb
docker run --rm -it --volume $(pwd)/cockroachdb/certs:/certs cockroachdb/cockroach init --certs-dir=/certs --host=172.17.0.1:26257
docker run --rm -it --volume $(pwd)/cockroachdb/certs:/certs cockroachdb/cockroach sql --certs-dir=/certs --host=172.17.0.1:26257 --execute="CREATE USER dbadmin WITH PASSWORD '$password';grant admin to dbadmin;"

# service to ensure custom seaweedfs plugin is installed on all nodes
docker service create --name=seaweedfs_plugin --mode=global-job --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock docker plugin install --alias seaweedfs --grant-all-permissions angzam78/seaweedfs-volume-plugin:latest-`uname -m | sed -e s/x86_64/amd64/ -e s/aarch64$/arm64/`

# service to ensure custom juicefs plugin is installed on all nodes
docker service create --name=juicefs_plugin_installer --mode=global --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock --health-cmd="/bin/sh -c 'docker plugin inspect juicefs > /dev/null 2>&1'" --constraint=node.platform.os==linux docker /bin/sh -c 'docker plugin inspect juicefs --format "{{.PluginReference}}" 2> /dev/null; if [ $? -eq 1 ]; then docker plugin install --alias juicefs --grant-all-permissions registry.viraqua.net/juicefs-volume-plugin:1.0.0-`uname -m | sed -e s/x86_64/amd64/ -e s/aarch64$/arm64/`; fi; sleep infinity'

# persistent and fast data storage service
docker run --rm -it --volume $(pwd)/cockroachdb/certs:/certs cockroachdb/cockroach sql --certs-dir=/certs --host=172.17.0.1:26257 --execute="CREATE USER weed WITH PASSWORD '$password';CREATE DATABASE seaweedfs;ALTER DATABASE seaweedfs OWNER TO weed;"
docker stack deploy -c seaweedfs.yml seaweedfs

sleep 30

############################################################################
# at this point we can start launching stacks which require persistence... #
############################################################################

# take over the home network (IMPORTANT: copy and adapt the next line on all hosts)
docker network create --config-only --subnet="192.168.1.0/24" --ip-range="192.168.1.250/32" --gateway="192.168.1.254" -o parent="`route | grep '^default' | grep -o '[^ ]*$'`" "dhcpdns_config"
docker network create -d macvlan --scope swarm --config-from "dhcpdns_config" "dhcpdns"
docker stack deploy -c technitium.yml technitium

# some UIs to view the state of our containers
docker stack deploy -c portainer.yml portainer
docker stack deploy -c swarmpit.yml swarmpit  # TODO script to create folders

# monitoring and logging
docker run --rm -it --volume $(pwd)/cockroachdb/certs:/certs cockroachdb/cockroach sql --certs-dir=/certs --host=172.17.0.1:26257 --execute="CREATE USER zabbix WITH PASSWORD '$password';CREATE DATABASE zabbix;ALTER DATABASE zabbix OWNER TO zabbix;"


############################################################################
# here we configure front facing services with externally exposed ports    #
############################################################################


#docker network create -d overlay frontend_network
#docker stack deploy -c traefik.yml traefik

#docker stack deploy -c powerdns.yml powerdns
