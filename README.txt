1) Build func app
dotnet restore
dotnet build 

2) Setup environment
a) Search and replace in all files in all subfolders {ENV_PREFIX} with an environment prefix of your choice, e.g. repro123 
b) Search and replace in all files in all subfolders {FUNCTION_APP_NAME} with a function app name of your choice, e.g. repro123-app 
c) Search and replace in all files in all subfolders {EVENT_HUBS_NS_NAME} with a function app name of your choice, e.g. repro123-event-hub 
d) Search and replace in all files in all subfolders {EVENT_HUB_NAME} with a function app name of your choice, e.g. repro123-test-events
e) Search and replace in all files in all subfolders {SUBSCR_ID} with your Azure subscription id 

f) bash: You can use Azure/setup_env_with_rg_stacc_kv_evh_appins_plan_funcapps.sh to deploy the environment
    NOTES: 
    -) EventHubs Connection string is put in Azure Key Vault, and referenced from the Function App's Configuration via @Microsoft.KeyVault(SecretUri=${eventHubConnectionStringSecretId}) reference
    -) WINDOWS Consumption Plan is used (the default serverless plan)

3) Deploy - bash or pwsh 
func azure functionapp publish c2d-repro-testapp-cw

4) Wait for e.g. 30 minutes to 1h and check Application Insights -> Failures
    NOTES: 
    -) The sample configures an automatic web test which runs every 5 minutes. You can edit the check to run every minutes to speed up the process
