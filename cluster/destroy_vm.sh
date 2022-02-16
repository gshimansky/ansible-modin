#!/bin/sh

for i in $(seq 1 3); do
    virsh shutdown cluster-${i}
    virsh destroy cluster-${i}
    virsh undefine cluster-${i}
done
