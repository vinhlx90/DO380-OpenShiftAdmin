#!/bin/bash
#this script to get ocp user
#maintainer vinhlx90@outlook.com
#create Dec2023

PROVIDER_NAME=$1

FILTER="?(.name=='${PROVIDER_NAME}' )"
#echo $FILTER
SECRET_NAME=$(oc get oauth cluster -o jsonpath="{.spec.identityProviders[$FILTER].htpasswd.fileData.name}")

SECRET_FILE=$(oc extract secret/$SECRET_NAME -n openshift-config --confirm)
#echo $SECRET_FILE
cut -d : -f 1 <$SECRET_FILE

rm $SECRET_FILE
