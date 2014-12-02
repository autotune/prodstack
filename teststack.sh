#!/bin/bash
source /tmp/prodstack/openstack.rc

printf "$(openstack-config --set /etc/glance/glance-api.conf database \
  connection mysql://glance:$GLANCE_DBPASS@controller/glance)"

printf "$(openstack-config --set /etc/glance/glance-registry.conf database \
  connection mysql://glance:$GLANCE_DBPASS@controller/glance)"
