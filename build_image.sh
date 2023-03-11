#!/bin/bash

# set variables
_VERSION=10.0.6

# build image glpi
docker build -t johann8/glpi:${_VERSION} .
_BUILD=$?
if ! [ ${_BUILD} = 0 ]; then
   echo "ERROR: Docker Image build was not successful"
   exit 1
else
   echo "Docker Image build successful"
   docker images -a
fi

#push image to dockerhub
if [ ${_BUILD} = 0 ]; then
   echo "Pushing docker images to dockerhub..."
   docker push johann8/glpi:${_VERSION}
   _PUSH=$?
   docker images -a |grep glpi
fi

#delete build
if [ ${_PUSH} = 0 ]; then
   echo "Deleting docker images..."
   docker rmi johann8/glpi:${_VERSION}
   docker rmi rockylinux:8
   docker rmi $(docker images -f "dangling=true" -q)
   docker images -a
fi
