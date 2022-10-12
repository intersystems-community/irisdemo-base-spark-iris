#!/bin/bash

source ./buildtools.sh

ping local-registry -c 1
if [ ! $? -eq 0 ]; 
then
    printf "\nYour /etc/hosts is not configured properly. Add the following line to it and run this script again:"
    printf "\n\n\t127.0.0.1 local-registry"
    printf "\n\n"
    printf "If you are running on windows:\n"
    printf "\t- this script must be run as an administrator"
    printf "\t- your hosts file is at C:\\Windows\\System32\\drivers\\etc\\hosts\n\n"

else
    printf "\nCreating spark namespace"
	kubectl create namespace "spark"
    
    # skaffold dev -p dev --port-forward=true --default-repo local-registry:5000 --cleanup=false --tail=false
    skaffold dev -p dev --default-repo local-registry:5000 --cleanup=false --tail=false
fi