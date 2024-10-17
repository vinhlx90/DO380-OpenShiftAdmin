#!/bin/bash
key='/home/devadmin/OCP/creds/sshNodeKey' #path to key
host='core@master01.ocp-dev.thanhcong.vn'

ssh -i $key $host 'sudo -E  mount -t nfs 10.64.62.200:/opt/openshift/backup  /home/core/backup && sudo /bin/bash /usr/local/bin/cluster-backup.sh /home/core/backup'
