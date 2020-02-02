#!/bin/bash

# Script for turning on a Supermicro server using Raspberry Pi GPIO
# Author: Juan Chong - 2020

# Note: You may need to add the current user to the gpio group to 
# allow for GPIO access without sudo.
# sudo usermod -a -G gpio <user name>

# Common path for all GPIO access
BASE_GPIO_PATH=/sys/class/gpio

# Assign names to GPIO pin numbers for each light
POWER=17
STATUS=27

# Assign names to states
ON="1"
OFF="0"

# Utility function to export a pin if not already exported
exportPin()
{
  if [ ! -e $BASE_GPIO_PATH/gpio$1 ]; then
    echo "$1" > $BASE_GPIO_PATH/export
  fi
}

# Utility function to set a pin as an output
setOutput()
{
  echo "out" > $BASE_GPIO_PATH/gpio$1/direction
}

# Utility function to set a pin as an input
setInput()
{
  echo "in" > $BASE_GPIO_PATH/gpio$1/direction
}

# Utility function to change state of a gpio pin
setState()
{
  echo $2 > $BASE_GPIO_PATH/gpio$1/value
}

# Ctrl-C handler for clean shutdown
shutdown()
{
  setInput $POWER
  exit 0
}

trap shutdown SIGINT

# Export pins so that we can use them
exportPin $POWER
exportPin $STATUS

# Set pin direction
setInput $STATUS

# Check whether the server is already on
ISPOWERED=$(cat $BASE_GPIO_PATH/gpio$STATUS/value)

# If the server isn't on, turn it on
if [ "$ISPOWERED" -eq "0" ]
then
  echo "Powering on server... "
  setOutput $POWER
  setState $POWER $ON
  sleep 1
  setState $POWER $OFF
  # Check that the server actually turned on
  POWERONTEST=$(cat $BASE_GPIO_PATH/gpio$STATUS/value)
  if [ "$POWERONTEST" -eq "1" ]
  then
    # Set the power pin as an input (high-z) to not fight against the physical button
    setInput $POWER
    echo "Server powered on successfully."
    exit 0
  else
    setInput $POWER
    echo "Server failed to power on. Something went wrong."
    exit 2
  fi
else
  echo "Server already powered on. Exiting."
  exit 1
fi

