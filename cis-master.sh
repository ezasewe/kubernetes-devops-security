#!/bin/bash
#cis-master.sh

total_fail=$(kube-bench master  --version 1.20 --check 1.1.7,1.1.8,1.1.12,1.3.2 --json | jq .Totals.total_fail)

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed MASTER while testing for ETCD 1.1.7-1.1.12,1.3.2"
                exit 1;
        else
                echo "CIS Benchmark Passed for MASTER - 1.1.17-1.1.12,1.3.2"
fi;
