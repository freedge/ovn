#!/bin/bash

# Create the first logical switch with one port
ovn-nbctl ls-add frigonetwork
ovn-nbctl lsp-add frigonetwork fr1p
ovn-nbctl lsp-set-addresses fr1p "fa:16:3e:ff:10:eb 192.168.0.10"
ovn-nbctl lsp-add frigonetwork fr3p
ovn-nbctl lsp-set-addresses fr3p "fa:16:3e:37:79:8d 192.168.0.7"

# Create the second logical switch with one port
ovn-nbctl ls-add public

# Create a logical router and attach both logical switches
ovn-nbctl lr-add frigorouter
ovn-nbctl lrp-add frigorouter lrp-c6c11c72 fa:16:3e:fc:40:8f 192.168.0.1/28
ovn-nbctl lsp-add frigonetwork lrp-c6c11c72-attach
ovn-nbctl lsp-set-type lrp-c6c11c72-attach router
ovn-nbctl lsp-set-options lrp-c6c11c72-attach router-port=lrp-c6c11c72

# create the rest
ovn-nbctl lr-nat-add frigorouter snat 172.18.144.165 192.168.0.0/28 
ovn-nbctl lr-nat-add frigorouter dnat_and_snat 172.18.144.42 192.168.0.10
ovn-nbctl lrp-add frigorouter lrp-cbbbd436 fa:16:3e:ec:e9:dd 172.18.144.165/24
ovn-nbctl lsp-add public lrp-cbbbd436-attach
ovn-nbctl lsp-set-options lrp-cbbbd436-attach router-port=lrp-cbbbd436
ovn-nbctl lsp-set-type lrp-cbbbd436-attach router
ovn-nbctl lsp-add public provnet
ovn-nbctl lsp-set-type provnet localnet
ovn-nbctl lsp-set-addresses provnet unknown

# no idea what this does but it aligns with what we find in production
ovn-nbctl lsp-set-enabled lrp-cbbbd436-attach enabled
ovn-nbctl lsp-set-addresses lrp-cbbbd436-attach router

ovn-nbctl lsp-set-enabled fr1p enabled
ovn-nbctl lsp-set-enabled fr3p enabled
ovn-nbctl lsp-set-port-security fr1p "fa:16:3e:ff:10:eb 192.168.0.10"
ovn-nbctl lsp-set-port-security fr3p "fa:16:3e:37:79:8d 192.168.0.7"
ovn-nbctl lsp-set-enabled lrp-c6c11c72-attach enabled
ovn-nbctl lsp-set-addresses lrp-c6c11c72-attach router

ovn-nbctl lr-route-add frigorouter 0.0.0.0/0 172.18.144.1

# need to actually add the port to an openvswitch for it to be up
ovs-vsctl add-port br-int p1 -- \
    set Interface p1 external_ids:iface-id=fr1p

ovs-vsctl add-port br-int p3 -- \
    set Interface p3 external_ids:iface-id=fr3p

# need to bind ports to chassis
ovn-sbctl chassis-add cirp05ospcpufc248110 geneve 172.18.145.121

ovn-nbctl lrp-set-gateway-chassis lrp-cbbbd436  cirp05ospcpufc248110 1


# ovs-docker add-port  br-int eth1 fr1 \
#      --ipaddress=192.168.0.10/28 --gateway=192.168.0.1 \
#      --macaddress="fa:16:3e:ff:10:eb" --mtu=1450
# ovs-docker add-port  br-int eth1 fr3 \
#      --ipaddress=192.168.0.7/28 --gateway=192.168.0.1 \
#      --macaddress="fa:16:3e:37:79:8d" --mtu=1450

# ovs-vsctl set Interface 1cbb16cd57574_l external_ids:iface-id=fr1p
# ovs-vsctl set Interface 87340bafaab14_l external_ids:iface-id=fr3p

# View a summary of the configuration
printf "\n=== ovn-nbctl show ===\n\n"
ovn-nbctl show
printf "\n=== ovn-nbctl show with wait hv ===\n\n"
ovn-nbctl --wait=hv show
printf "\n=== ovn-sbctl show ===\n\n"
ovn-sbctl show

# Trace it
ovn-trace   frigonetwork 'eth.src == fa:16:3e:ff:10:eb && eth.dst == fa:16:3e:fc:40:8f && ip4.src == 192.168.0.10 && ip4.dst == 8.8.8.8 && ip.ttl==42 && inport=="fr1p"'
