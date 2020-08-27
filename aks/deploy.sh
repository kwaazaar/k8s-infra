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
#AAD_SERVER_APPID="#{AADServerAppId}#"
#AAD_SERVER_APPSECRET="#{AADServerAppSecret}#"
#AAD_CLIENT_APPID="#{AADClientAppId}#"

# Monitoring
#WORKSPACE_RG=#{OMSWorkspaceResourceGroup}#
#WORKSPACE_NAME=#{OMSWorkspaceName}#

# Nodepool
MIN_NODES=#{ClusterAutoscalerMinNodes}#
MAX_NODES=#{ClusterAutoscalerMaxNodes}#


# Networking
#VNET_RG=#{VnetResourceGroup}#
#VNET_NAME=#{VnetName}#
#SUBNET_NAME=#{SubnetName}#
DNS_PREFIX=#{DNSPrefix}#
DNS_SERVICEIP=#{DNSServiceIP}#
SERVICE_CIDR="#{ServiceCIDR}#"

# Gather additional information
#WORKSPACE_RESOURCEID=`az monitor log-analytics workspace show -g ${WORKSPACE_RG} -n ${WORKSPACE_NAME} --query id -o tsv`
#echo "Workspace resource id found ${WORKSPACE_RESOURCEID}"
#SUBNET_ID=`az network vnet subnet show -g ${VNET_RG} --vnet-name ${VNET_NAME} --name ${SUBNET_NAME} --query id -o tsv`
#echo "Subnet resource id found ${SUBNET_ID}"

# Determine if existing cluster
AKS_RESOURCEID=`az aks show -n $AKSNAME -g $AKSRG --query id -o tsv`

if [ -z $AKS_RESOURCEID ]; then
    echo "Cluster does not exist and will be created."

    # Cluster aanmaken
    # - Cluster monitoring
    # - Azure AD integration
    # - Default node pool (with cluster autoscaling)
    ## - Networking
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
