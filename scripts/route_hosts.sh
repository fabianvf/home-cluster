#!/bin/bash

function add_routes_to_hosts {
  local hosts=$(oc get routes --all-namespaces --no-headers | awk '{print $3}' | tr '\n' ' ')
  sudo sed -i -r "s/(.*)master.example.org.*/\1master.example.org ${hosts}/g" /etc/hosts
}

add_routes_to_hosts
