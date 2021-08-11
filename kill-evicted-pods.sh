#!/bin/bash



CLUSTERS=""
EXIT_CODE=0

function _clear_evicted() {
 export CLUSTER=$1
 echo -e "\nAnalisando $CLUSTER..."
 QTD=$(kubectl --context=${CLUSTER} get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted"))' |jq .metadata.name|wc -l)
 echo "QTD: $QTD"
 if [[ ${QTD} -gt 0 ]]
   then
     echo -e "\n-----------------------------------------------------------------------------------------\n"
     echo "kubectl --context=${CLUSTER} get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted"))' |jq .metadata.name"
     kubectl --context=${CLUSTER} get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted"))' | jq .metadata.name
     echo -e "\n-----------------------------------------------------------------------------------------\n"
     COMANDOS=$(kubectl --context=${CLUSTER} get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted"))' | jq -r  '"kubectl --context=" + env.CLUSTER + " delete po " + .metadata.name + " -n " + .metadata.namespace')
     while IFS= read -r line; do
        echo "... bash -c '$line' ..."
        #echo "'$linha'" | xargs -n 20  bash -x -c
        bash -x -c "$line"
        sleep 1
     done <<< "$COMANDOS"
     echo "Removendo pods com status Evicted"
     let "EXIT_CODE = $EXIT_CODE + 1"
   else
     echo "Nenhum pod com status Evicted no cluster $CLUSTER.."
     let "EXIT_CODE = $EXIT_CODE + 1"
 fi
}

for CLUSTER in $CLUSTERS; do
   _clear_evicted $CLUSTER
   sleep 5
done
# kubectl --context=arn:aws:eks:us-east-1:107192072649:cluster/hmg-eks get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted")) | "kubectl --context=arn:aws:eks:us-east-1:107192072649:cluster/hmg-eks delete po \(.metadata.name) -n \(.metadata.namespace)"' | xargs -n 1 bash -c


exit $EXIT_CODE
~
