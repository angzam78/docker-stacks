#!/bin/sh
export CLUSTER_NODES=3
export MYSQL_ROOT_PASSWORD=piggyback123

export IP_ADDRESS=`getent hosts | grep $HOSTNAME | awk '{print $1}'`
       
echo Service: $SERVICE_NAME
echo Hostname: $HOSTNAME

echo Cluster peers:
echo `getent hosts tasks.$SERVICE_NAME`

CLUSTER_MEMBERS=`getent hosts tasks.$SERVICE_NAME | grep -v $IP_ADDRESS | awk '{print $$1}'`
                          
# Check we can see enough peers to form a Primary Component
if [ `getent hosts tasks.$SERVICE_NAME | wc -l` -lt $(((${CLUSTER_NODES}+1)/2)) ]; then
  echo Cannot see enough peers to form a cluster - restarting.
  exit 1
fi

# If we are the first node then assume responsability
if [ `getent hosts tasks.$SERVICE_NAME | sort -V | head -n 1 | awk '{print $$1}'` = $IP_ADDRESS ]; then
  echo Looks like we are the first member. Testing for an established cluster between other nodes...
                                                                                            
  # Check to see if the other nodes have an established cluster
  for MEMBER in $CLUSTER_MEMBERS
  do
    echo Testing $MEMBER...
    if echo SHOW STATUS LIKE 'wsrep_local_state_comment'; | mysql -u root -p$MYSQL_ROOT_PASSWORD -h $MEMBER | grep 'Synced'; then
                                
      # Connect to existing cluster
      echo Success!                     
      break
    else
      echo Failed!
    fi
  done

fi

