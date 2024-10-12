#!/bin/sh
oc get pods --all-namespaces \
    -o jsonpath="{.items[*].spec.containers[*].image}"  \
    | sed 's/ /\n/g' \
    | sort \
    | uniq
