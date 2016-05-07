#!/bin/bash
# Note, this script has a dependency on bridge-utils

# Ensure the script fails at the first non-zero return code
set -e 

COMMAND="$1"
DEVICE1="$2"
DEVICE2="$3" 

if [ "$COMMAND" != "list" -a "$COMMAND" != "start" -a "$COMMAND" != "stop" ]
then
  echo "Invalid command type"
  echo "Syntax:"
  echo "$ ./bridge.sh start <interface1> <interface2>"
  echo "$ ./bridge.sh stop"
  echo "$ ./bridge.sh list"
  exit 1
fi

BRIDGE="ethbridge"

if [ $COMMAND == "list" ]
then
  echo "List of available interfaces:"
  ifconfig | grep flags | cut -f 1 -d ":"
elif [ $COMMAND == "stop" ]
then
  echo "Attempting to stop $BRIDGE"
  sudo ifconfig $BRIDGE down
  sudo brctl delbr $BRIDGE
elif [ $COMMAND == "start" ]
then
  if [ -z "$DEVICE1" -o -z "$DEVICE2" ]
  then
    echo "Syntax:"
    echo "$ ./bridge.sh start <interface1> <interface2>"
    exit 1
  else
    for intf in `ifconfig | grep flags | cut -f 1 -d ":" | grep "$BRIDGE"`
    do
      echo "Bridge $BRIDGE already exists... please run ./bridge.sh stop"
      exit 1
    done 
  fi

  sudo ip addr flush dev "$DEVICE1"
  sudo ip addr flush dev "$DEVICE2"

  sudo brctl addbr $BRIDGE
  sudo brctl addif $BRIDGE $DEVICE1 $DEVICE2

  sudo ip link set dev $BRIDGE up

  # Now, restart the networking subsystem. This assumes Systemd.
  #sudo /etc/init.d/networking restart
  sudo systemctl restart systemd-networkd
fi

exit 0

