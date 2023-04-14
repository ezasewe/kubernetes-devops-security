#!/bin/bash
#cis-etcd.sh

total_fail=$(kube-bench run --targets etcd  --version 1.20 --check="1,2" --json | jq .Totals.total_fail)

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed ETCD while testing for 1.x and 2.x"
                exit 1;
        else
                echo "CIS Benchmark Passed for ETCD - 1.x and 2.x"
fi;
