#!/bin/bash

##### CHANGE all values below!
envPrefix={ENV_PREFIX}
subscrId="{SUBSCR_ID}"
location=westeurope
eventHubsNamespace={EVENT_HUBS_NS_NAME}
eventHubName={EVENT_HUB_NAME}
functionAppName={FUNCTION_APP_NAME}



envSuffix=cw    # cw means consumption windows

# remove hyphen due to storage account name restrictions
envPrefixNoHyphens=${envPrefix//-/}
envSuffixNoHyphens=${envSuffix//-/}

# storage account must be letters or numbers only
storAccNameFunc="${envPrefixNoHyphens}staccfunc${envSuffixNoHyphens}"  

keyVaultName=$envPrefix-key-vault

resGroup=$envPrefix-rg

echo $envPrefixNoHyphens
echo $envSuffixNoHyphens
echo $storAccNameFunc
echo $keyVaultName
echo $subscrId
echo $location
echo $resGroup

az account set -s $subscrId
az account show

# RES GROUP #
az group create --name $resGroup --location $location

# STORAGE ACCOUNT #
az group deployment create \
    --name Deployment_$storAccNameFunc \
    --resource-group $resGroup \
    --template-file templates/Storage/StorageAccount.json \
    --parameters location=$location storageAccountName=$storAccNameFunc accountType=Standard_RAGRS kind=StorageV2 accessTier=Hot supportsHttpsTrafficOnly=true

# APP INSIGHTS #

appInsName=$envPrefix-appins
echo $appInsName

az group deployment create \
    --name Deployment_$appInsName \
    --resource-group $resGroup \
    --template-file templates/AppIns/AppIns.json \
    --parameters name=$appInsName

appInsightsKey=$(az resource show -g $resGroup -n $appInsName --resource-type "Microsoft.Insights/components" --query "properties.InstrumentationKey" -o tsv)
echo $appInsightsKey

# EVENT HUBS #
templateFile="templates/EventHubs/EventHubs.json"
paramFile="templates/EventHubs/EventHubs-parameters.json"
echo $paramFile

az group deployment create \
    --name EventHubsDeployment \
    --resource-group $resGroup \
    --template-file $templateFile \
    --parameters @$paramFile

# KEY VAULT #
az keyvault create --location $location --name $keyVaultName --resource-group $resGroup

eventHubsConnectionStringSecretName=EventHubsConnectionString
eventHubsConnStrValue=$(az eventhubs eventhub authorization-rule keys list --resource-group $resGroup --namespace-name $eventHubsNamespace --eventhub-name $eventHubName --name default | jq '.primaryConnectionString' -r)
echo $eventHubsConnStrValue
az keyvault secret set --name $eventHubsConnectionStringSecretName --vault-name $keyVaultName --value $eventHubsConnStrValue

eventHubsConnectionStringSecretId=$(az keyvault secret show --name $eventHubsConnectionStringSecretName --vault-name $keyVaultName | jq '.id' -r)
echo $eventHubsConnectionStringSecretId
appConfigEventHubsConnStrValue="@Microsoft.KeyVault(SecretUri=${eventHubsConnectionStringSecretId})"
echo $appConfigEventHubsConnStrValue

############ PLAN WITH FUNCTIONS ############

paramFile="templates/FuncApp/PlanWithFuncApps-parameters.json"
echo $paramFile

az group deployment create \
    --name PlanWithFuncAppsDeployment \
    --resource-group $resGroup \
    --template-file templates/FuncApp/PlanWithFuncApps.json \
    --parameters @$paramFile --parameters storageAccountName=$storAccNameFunc appInsInstrKey=$appInsightsKey eventHubConnStr=$appConfigEventHubsConnStrValue keyVaultName=$keyVaultName resGroupFuncApp=$resGroup resGroupKeyVault=$resGroup azureAppConfigConnStr=DummyValue


############ DEPLOY CODE ###############
cd ..
func azure functionapp publish $functionAppName


########### SET UP WEB TEST ###############
actionGroupName=$envPrefix-ag
echo $actionGroupName
paramFile="templates/AppIns/WebTests-parameters.json"
echo $paramFile
templateFile="templates/AppIns/WebTests.json"

az group deployment create \
    --name AppInsDeploymentWebTests \
    --resource-group $resGroup \
    --template-file $templateFile \
    --parameters @$paramFile --parameters actionGroupName=$actionGroupName appInsName=$appInsName appInsLocation=$location


    