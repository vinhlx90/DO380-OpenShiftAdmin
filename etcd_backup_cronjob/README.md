Openshift Container Platform 4: Etcd backup cronjob.
 SOLUTION VERIFIED - Updated August 14 2024 at 2:19 PM - English 
Environment
Red Hat OpenShift Container Platform
4.x
Issue
To schedule OpenShift Container 4 etcd backups with a cronjob.
Resolution
Create a project.
Raw
$ oc new-project ocp-etcd-backup --description "Openshift Backup Automation Tool" --display-name "Backup ETCD Automation"
Create Service Account
Raw
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: openshift-backup
  namespace: ocp-etcd-backup
  labels:
    app: openshift-backup
---
$ oc apply -f sa-etcd-bkp.yml
Create ClusterRole
Raw
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-etcd-backup
rules:
- apiGroups: [""]
  resources:
     - "nodes"
  verbs: ["get", "list"]
- apiGroups: [""]
  resources:
     - "pods"
     - "pods/log"
     - "pods/attach"
  verbs: ["get", "list", "create", "delete", "watch"]
- apiGroups: [""]
  resources:
     - "namespaces"
  verbs: ["get", "list", "create"]
---
$ oc apply -f cluster-role-etcd-bkp.yml
NOTE: If the cronjob runs the oc debug command without --to-namespace=ocp-etcd-backup option, the "delete" verb would also be necessary for the "namespaces" resource in order to delete the temporary namespace after the oc debug command finished.

Create ClusterRoleBinding
Raw
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: openshift-backup
  labels:
    app: openshift-backup
subjects:
  - kind: ServiceAccount
    name: openshift-backup
    namespace: ocp-etcd-backup
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-etcd-backup
---
$ oc apply -f cluster-role-binding-etcd-bkp.yml
Add service account to SCC "privileged"
Raw
$ oc adm policy add-scc-to-user privileged -z openshift-backup
Create Backup CronJob
Raw
kind: CronJob
apiVersion: batch/v1
metadata:
  name: openshift-backup
  namespace: ocp-etcd-backup
  labels:
    app: openshift-backup
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 5
  failedJobsHistoryLimit: 5
  jobTemplate:
    metadata:
      labels:
        app: openshift-backup
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels:
            app: openshift-backup
        spec:
          containers:
            - name: backup
              image: "registry.redhat.io/openshift4/ose-cli"
              command:
                - "/bin/bash"
                - "-c"
                - oc get no -l node-role.kubernetes.io/master --no-headers -o name | head -n 1 |xargs -I {} -- oc debug {}  --to-namespace=ocp-etcd-backup -- bash -c 'chroot /host rm -rf /home/core/backup && chroot /host  mkdir /home/core/backup && chroot /host  sudo -E  mount -t nfs <nfs-server-IP>:<shared-path>    /home/core/backup && chroot /host sudo -E /usr/local/bin/cluster-backup.sh /home/core/backup && chroot /host sudo -E find /home/core/backup/ -type f -mmin +"1" -delete'
          restartPolicy: "Never"
          terminationGracePeriodSeconds: 30
          activeDeadlineSeconds: 500
          dnsPolicy: "ClusterFirst"
          serviceAccountName: "openshift-backup"
          serviceAccount: "openshift-backup"
---
$ oc apply -f cronjob-etcd-bkp.yml

Note: Change <nfs-server-IP>:<shared-path>  as required. Also, make sure on you already have the /home/core/backup directory created.
After creating CronJob, you can force the execution for validation with the command:
Raw
oc create job backup --from=cronjob/openshift-backup
Important Note: This procedure may not be suitable for production use-cases and has not been tested or guaranteed to work reliably.

Root Cause
It is needed to set up etcd cronJob in NFS server, which could be set up as per following:
Using a RHEL/CentOS 8.2 host on the same network as your OpenShift Cluster install nfs-utils:

Raw
# sudo dnf install nfs-utils -y
# systemctl start nfs-server
# systemctl enable nfs-server
# systemctl status nfs-server
# sudo mkdir -p /mnt/openshift/registry
# vi /etc/exports
Add the following, including the options for rw,no_wdelay,no_root_squash:

Raw
# /mnt/openshift/registry         192.168.0.1/24(rw,sync,no_wdelay,no_root_squash,insecure)
Export the new share with:

Raw
# exportfs -arv
And confirm the share is visible:

Raw
# exportfs  -s
# showmount -e 127.0.0.1
If required, open up the firewall ports needed:

Raw
# firewall-cmd --permanent --add-service=nfs
# firewall-cmd --permanent --add-service=rpc-bind
# firewall-cmd --permanent --add-service=mountd
# firewall-cmd --reload
