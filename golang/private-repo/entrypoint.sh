#!/usr/bin/env sh

FFB_APPLET=${FFB_APPLET:-ffb}
MICRO_REGISTRY=${MICRO_REGISTRY:-consul}
MICRO_REGISTRY_ADDRESS=${MICRO_REGISTRY_ADDRESS:-consul-server.consul.svc.cluster.local:8500}
echo "launching $FFB_APPLET, registry is $MICRO_REGISTRY on $MICRO_REGISTRY_ADDRESS"

exec /ffgo/"${FFB_APPLET}"
