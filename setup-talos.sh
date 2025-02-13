#!/bin/sh
brew install talhelper 1password-cli age sops talosctl ubi
ubi -v --in ~/bin/ --project https://github.com/turing-machines/tpi/
for nodenr in 1 2 3; do tpi flash -n $nodenr -i metal-arm64.raw; done
talhelper gensecret >talsecret.sops.yaml
op read op://Private/Age-Key/password >~/Library/Application\ Support/sops/age/keys.txt
sops --encrypt -i --age "$(cat public_age_keys.txt)" talsecret.sops.yaml
talhelper genconfig
cp clusterconfig/talosconfig ~/.talos/config
talosctl apply-config --insecure -n 192.168.1.52 --file clusterconfig/homecluster-node1.yaml
talosctl bootstrap --nodes 192.168.1.52
talosctl apply-config --insecure -n 192.168.1.44 --file clusterconfig/homecluster-node2.yaml
talosctl apply-config --insecure -n 192.168.1.108 --file clusterconfig/homecluster-node3.yaml
talosctl --cluster homecluster -n 192.168.1.52 kubeconfig .
talosctl patch mc --patch "$(sops --decrypt --age "$(cat public_age_keys.txt)" tailscale-config.sops.yaml)"
