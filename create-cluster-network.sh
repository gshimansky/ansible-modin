#!/bin/sh

virsh net-define cluster.xml && virsh net-start CLUSTER_1

