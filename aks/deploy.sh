#!/bin/bash

# This script is populated through parameters of a AzureDevOps release pipeline.

# Name
AKSRG="#{RG_NAME}#"
AKSNAME="#{CLUSTER_NAME}#"
AKSVER="#{AKS_VER}#"

# Service principal
SP="#{spClientId}#"
SP_CLIENTSECRET="#{spClientSecret}#"

# AAD Integration
AAD_AKSADMINGROUP_ID="#{AADAdminGroupId}#"

# Nodepool
MIN_NODES=#{ClusterAutoscalerMinNodes}#
MAX_NODES=#{ClusterAutoscalerMaxNodes}#

# Networking
DNS_PREFIX=#{DNSPrefix}#
DNS_SERVICEIP=#{DNSServiceIP}#
SERVICE_CIDR="#{ServiceCIDR}#"

# Gather additional information

# Determine if existing cluster
AKS_RESOURCEID=`az aks show -n $AKSNAME -g $AKSRG --query id -o tsv`

if [ -z $AKS_RESOURCEID ]; then
    echo "Cluster does not exist and will be created."

    # Cluster aanmaken
    # - Cluster monitoring
    # - Azure AD integration
    # - Default node pool (with cluster autoscaling)
    # - Multi AZ
    az aks create \
        --no-ssh-key \
        --kubernetes-version $AKSVER \
        --resource-group $AKSRG \
        --name $AKSNAME \
        --service-principal "${SP}" \
        --client-secret "${SP_CLIENTSECRET}" \
        --enable-aad \
        --aad-admin-group-object-ids ${AAD_AKSADMINGROUP_ID} \
        --nodepool-name lin1 \
        --vm-set-type VirtualMachineScaleSets \
        --node-vm-size Standard_DS3_v2 \
        --node-osdisk-size 1024 \
        --max-pods 50 \
        --node-count $MIN_NODES \
        --enable-cluster-autoscaler \
        --min-count $MIN_NODES \
        --max-count $MAX_NODES \
        --network-plugin azure \
        --network-policy azure \
        --docker-bridge-address 172.17.0.1/16 \
        --load-balancer-sku standard \
        --load-balancer-managed-outbound-ip-count 1 \
        --service-cidr $SERVICE_CIDR \
        --dns-service-ip $DNS_SERVICEIP \
        --zones 1 2 3

# Disabled features
#        --enable-addons monitoring \
#        --workspace-resource-id "${WORKSPACE_RESOURCEID}" \
#        --vnet-subnet-id $SUBNET_ID \

else
    echo "Cluster exists and will be updated."

    # Cluster updaten door de node pool(s) te updaten (de rest is niet te updaten)
    az aks nodepool update \
        --resource-group $AKSRG \
        --cluster-name $AKSNAME \
        --name lin1 \
        --update-cluster-autoscaler \
        --min-count $MIN_NODES \
        --max-count $MAX_NODES
fi
