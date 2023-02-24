#!/bin/bash

configuration="config: {}
networks:
- config:
    ipv4.address: 10.154.149.1/24
    ipv4.nat: "true"
    ipv6.address: fd42:f54a:d008:5776::1/64
    ipv6.nat: "true"
  description: ""
  name: lxdbr0
  type: bridge
  project: default
- config:
    ipv4.address: none
    ipv6.address: none
  description: ""
  name: rt
  type: bridge
  project: default
- config:
    ipv4.address: none
    ipv6.address: none
  description: ""
  name: tc
  type: bridge
  project: default
storage_pools:
- config:
    source: /var/snap/lxd/common/lxd/storage-pools/default
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: Default LXD profile
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
- config: 
    security.privileged: true
    cloud-init.network-config: |
      network:
        version: 2
        ethernets:
            enp0s3:
                dhcp4: true
            enp0s8:
                dhcp4: false
                addresses:
                    - 192.168.22.101/24  
  description: Router LXD profile
  devices:
    enp0s3:
      name: enp0s3
      network: lxdbr0
      type: nic
    enp0s8:
      name: enp0s8
      network: rt
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: router
- config: 
    security.privileged: true
    cloud-init.network-config: |
      network:
        version: 2
        ethernets:
            enp0s8:
                dhcp4: false
                addresses:
                    - 192.168.22.102/24
                routes:
                    - to: default
                      via: 192.168.22.101
                nameservers:
                    addresses: [8.8.8.8,8.8.4.4]
            enp0s9:
                dhcp4: false
                addresses:
                    - 192.168.23.102/24 
  description: Testing LXD profile
  devices:
    enp0s8:
      name: enp0s8
      network: rt
      type: nic
    enp0s9:
      name: enp0s9
      network: tc
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: testing
- config: 
    security.privileged: true
    cloud-init.network-config: |
      network:
          version: 2
          ethernets:
              enp0s8:
                  dhcp4: false
                  addresses:
                      - 192.168.23.104/24
                  routes:
                      - to: default
                        via: 192.168.23.102
  description: Client LXD profile
  devices:
    enp0s8:
      name: enp0s8
      network: tc
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: client
- config: 
    security.privileged: true
    cloud-init.network-config: |
      network:
          version: 2
          ethernets:
              eth1:
                  dhcp4: false
                  addresses:
                      - 192.168.23.103/24
                  routes:
                      - to: default
                        via: 192.168.23.102
  description: Metasploitable LXD profile
  devices:
    eth1:
      name: eth1
      network: tc
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: metasploitable
projects:
- config:
    features.images: "true"
    features.networks: "true"
    features.networks.zones: "true"
    features.profiles: "true"
    features.storage.buckets: "true"
    features.storage.volumes: "true"
  description: Default LXD project
  name: default"

echo "$configuration" | lxd init --preseed
lxc init ubuntu:22.04 router --profile router
lxc init ubuntu:22.04 testing --profile testing
lxc init ubuntu:22.04 client --profile client
lxc init ubuntu:22.04 metasploitable --profile metasploitable
lxc start router
lxc start testing
lxc start client
lxc start metasploitable