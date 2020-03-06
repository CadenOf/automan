#cloud-config
manage_etc_hosts: true
write_files: 
  - path: /etc/salt/minion.d/master.conf
    permissions: "0644"
    owner: root
    content: |
      master: 172.19.20.16
      grains_refresh_every: 1
  - path: /etc/salt/grains
    permissions: "0644"
    owner: root
    content: |
      roles:
        - kubernetes-node
        - telemetry-host
      zone: HD-DEV-A
runcmd:
  - MMYTIMESTAMP=`date +%Y%m%d%H%M%S`
  - MMYUUID=`uuidgen`
  - hostnamectl set-hostname ` echo dev-${MMYUUID:0:4}-${MMYTIMESTAMP:2}`
  - [systemctl,restart,salt-minion]
  - salt-call grains.setval fqdn_ip4 `curl http://100.100.100.200/latest/meta-data/private-ipv4`
  - salt-call state.sls telemetry.cfssl
  - salt-call state.sls kubernetes.cni
  - salt-call state.sls kubernetes.flanneld
  - salt-call state.sls kubernetes.kubelet
  - cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=/root/workspace/k8s/ca-config.json -profile=frognew /root/workspace/k8s/kubelet-config.json | cfssljson -bare /etc/kubernetes/pki/kubelet
  - cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=/root/workspace/k8s/ca-config.json -profile=frognew /root/workspace/k8s/flanneld-config.json | cfssljson -bare /etc/kubernetes/pki/flanneld
  - mv /etc/kubernetes/pki/kubelet.pem /etc/kubernetes/pki/kubelet.crt
  - mv /etc/kubernetes/pki/kubelet-key.pem /etc/kubernetes/pki/kubelet.key
  - mv /etc/kubernetes/pki/flanneld.pem /etc/kubernetes/pki/flanneld.crt
  - mv /etc/kubernetes/pki/flanneld-key.pem /etc/kubernetes/pki/flanneld.key
  - systemctl restart flanneld
  - systemctl restart kubelet
  - salt-call state.sls telemetry.prometheus.node_exporter
