#!/bin/bash

read -p "Enter ACR name: " acrname
read -p "Enter Images tag:: " imagetag
read -p "Enter Resoure Group: " resourcegroup
read -p "Enter AKS name: " aksname

if [[ -z "$acrname" ]]; then
   printf '%s\n' "No ACR name. Please specify ACR name"
   exit 1
fi

if [[ -z "$imagetag" ]]; then
   printf '%s\n' "No Images tag. Please specify Images tag"
   exit 1
fi

if [[ -z "$resourcegroup" ]]; then
   printf '%s\n' "No Resoure Group. Please specify Resoure Group name"
   exit 1
fi

if [[ -z "$aksname" ]]; then
   printf '%s\n' "No AKS name. Please specify AKS name"
   exit 1
fi

#Login to ACR
az acr login -n $acrname

#Build and push docker image
docker build -t $acrname.azurecr.io/tailwindtraders:$imagetag -f ./Source/Tailwind.Traders.Web/Dockerfile ./Source/Tailwind.Traders.Web
docker push $acrname.azurecr.io/tailwindtraders:$imagetag

#Get AKS creadentials
az aks get-credentials --name $aksname --resource-group $resourcegroup

#Create a service account that is using in helm chart 
kubectl create sa ttsa

# Deploy the application on the AKS cluster using Helm
helm upgrade --install tailwindtraders ./Deploy/helm/web -f ./Deploy/helm/gvalues.yaml -f ./Deploy/helm/values.b2c.yaml --set ingress.hosts={$aksname} --set ingress.protocol=http --set image.repository=$acrname.azurecr.io/tailwindtraders --set image.tag=$imagetag


