#!/bin/sh

for i in $(seq 1 3); do
    virt-install -n cluster-${i} \
                 --description "Modin cluster VM ${i}" \
                 --os-type=Linux \
                 --os-variant ubuntu20.04 \
                 --ram=16384 \
                 --vcpus=4 \
                 --disk path=/localdisk/libvirt/cluster-${i}.img,size=256 \
                 --graphics vnc \
                 --network bridge:clusbr1 \
                 --input keyboard \
                 --input mouse \
                 --serial pty \
                 --console pty \
                 --boot network \
                 --noautoconsole \
                 --noreboot \
                 --wait
done
