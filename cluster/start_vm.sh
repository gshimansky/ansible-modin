#!/bin/sh

for i in $(seq 1 3); do
    virsh start cluster-${i}
done
