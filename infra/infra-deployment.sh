#!/bin/bash
set -x

if ! command -v az &>/dev/null; then
  echo "Azure CLI could not be found. Please install it first. https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit
fi

az config set extension.use_dynamic_install=yes_without_prompt

# shellcheck source=settings.sh
source ./settings.sh

# read parameters
prefix=${prefix:-}
environment=${environment:=dev}
clientid=${clientid:-}
clientsecret=${clientsecret:-}
tenantid=${tenantid:-}
location=${location:-}
sqlAdminPassword=${sqlAdminPassword:=}

# Default values for setup
cosmosdbName=${cosmosdbName:=database01}
cosmosContainerName=${cosmosContainerName:=graph01}
searchIndex=${searchIndex:=cosmosdb-index}
dashboardPort=${dashboardPort:=80}
primaryRegion=${primaryRegion:=eastus}
secondaryRegion=${secondaryRegion:=westus}
maxThroughput=${maxThroughput:=4000}
partitionKey=${partitionKey:=accountId}
clientIp=${clientIp:=0.0.0.0}

# Calculate variables
resourceGroupName="rg-${prefix}-${environment}-001"
cosmosAccountName="cosmos-${prefix}-${environment}"
searchServiceName="srch-${prefix}-${environment}"
synapseWkspName="syn-${prefix}-${environment}"
storageAccountName="sa${prefix}${environment}300622"
containerRegistryName="cr${prefix}${environment}300622"
appDnsName=${appDnsName:=app-${prefix}-${environment}}
appContainerName=${appContainerName:=demo-${appDnsName}}

while [ $# -gt 0 ]; do

  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare "$param"="$2"
    # echo $1 $2 // Optional to see the parameter:value result
  fi

  shift
done

info() {
  echo "$(date +"%Y-%m-%d %T") [INFO]"
}

# declare all variables
if [[ $prefix == "" ]]; then
  echo "prefix is required, set it in settings.sh"
  exit 1
fi

if [[ $clientid == "" ]]; then
  echo "clientid is required, set it in settings.sh"
  exit 1
fi

if [[ $clientsecret == "" ]]; then
  echo "clientsecret is required, set it in settings.sh"
  exit 1
fi

if [[ $tenantid == "" ]]; then
  echo "tenantid is required, set it in settings.sh"
  exit 1
fi

if [[ $location == "" ]]; then
  echo "location is required, set it in settings.sh"
  exit 1
fi

if [[ $sqlAdminPassword == "" ]]; then
  echo "sqlAdminPassword is required, set it in settings.sh"
  exit 1
fi

echo "$(info) Login using service principle"
az login --service-principal -u "$clientid" -p "$clientsecret" --tenant "$tenantid"

echo "$(info) Create resource group"
if [ "$(az group exists --name "$resourceGroupName")" != "true" ]; then
  az group create --name "$resourceGroupName" --location "$location"
fi

echo "$(info) start deploying Cosmos Gremlin and Synapse Workspace"
echo "including: Synapse Spark, StorageAccount, Azure Search etc."
response=$(az deployment group create --name CosmosGremlinDemo \
  --resource-group "$resourceGroupName" \
  --parameters location="$location" \
  --parameters primaryRegion="$primaryRegion" \
  --parameters maxThroughput="$maxThroughput" \
  --parameters partitionKey="$partitionKey" \
  --parameters databaseName="$cosmosdbName" \
  --parameters graphName="$cosmosContainerName" \
  --parameters clientIp="$clientIp" \
  --parameters sqlAdminPassword="$sqlAdminPassword" \
  --parameters cosmosAccountName="$cosmosAccountName" \
  --parameters searchServiceName="$searchServiceName" \
  --parameters synapseWkspName="$synapseWkspName" \
  --parameters storageAccountName="$storageAccountName" \
  --parameters containerRegistryName="$containerRegistryName" \
  --template-file main.bicep)

echo "$response"
echo "$(info) Wait for 5 seconda before continuing"
sleep 5
echo "$(info) Create Cosmos DB datasource for Azure search"

cosmos_connection_string=$(az cosmosdb keys list --name "$cosmosAccountName" \
  --resource-group "$resourceGroupName" \
  --type connection-strings | jq -r '.connectionStrings[-1].connectionString')

az_search_name=$(az search service list --resource-group "$resourceGroupName" | jq -r ".[0].name")
az_search_url=https://$az_search_name.search.windows.net
az_search_api_admin_key=$(az search admin-key show --resource-group "$resourceGroupName" --service-name "$az_search_name" | jq -r ".primaryKey")

create_datasource=$(
  cat <<-END
{
  "name": "transactions",
  "description": "Cosmos DB for transactions",
  "type": "cosmosdb",
  "subtype": "Gremlin",
  "credentials": {
    "connectionString": "${cosmos_connection_string}Database=database01"
  },
  "container": {
    "name": "graph01",
    "query": "g.E()"
  }
}
END
)

echo "$(info) Creating datasource in Search service"
curl_datasource_req=$(echo "$create_datasource" | curl -sS -X POST -H "Content-Type: application/json" -H "api-key: ${az_search_api_admin_key}" --data-binary "@-" "${az_search_url}/datasources?api-version=2021-04-30-Preview")
echo "$curl_datasource_req"

create_index=$(
  cat <<-END
{
  "name": "cosmosdb-index",
  "fields": [
    {
      "name": "type",
      "type": "Edm.String",
      "facetable": false,
      "filterable": true,
      "key": false,
      "retrievable": true,
      "searchable": true,
      "sortable": false,
      "analyzer": "standard.lucene",
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "sink",
      "type": "Edm.String",
      "key": false,
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "searchable": true,
      "sortable": false,
      "analyzer": "standard.lucene",
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "sinkLabel",
      "type": "Edm.String",
      "key": false,
      "facetable": false,
      "filterable": false,
      "retrievable": true,
      "searchable": false,
      "sortable": false,
      "analyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "vertexId",
      "type": "Edm.String",
      "key": false,
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "searchable": true,
      "sortable": false,
      "analyzer": "standard.lucene",
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "vertexLabel",
      "type": "Edm.String",
      "key": false,
      "facetable": false,
      "filterable": false,
      "retrievable": true,
      "searchable": false,
      "sortable": false,
      "analyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "amount",
      "type": "Edm.Double",
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "sortable": true,
      "analyzer": null,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "oldbalanceOrg",
      "type": "Edm.Double",
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "sortable": true,
      "analyzer": null,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "oldbalanceDest",
      "type": "Edm.Double",
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "sortable": true,
      "analyzer": null,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "newbalanceDest",
      "type": "Edm.Double",
      "facetable": false,
      "filterable": true,
      "retrievable": true,
      "sortable": true,
      "analyzer": null,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    },
    {
      "name": "rid",
      "type": "Edm.String",
      "facetable": false,
      "filterable": false,
      "key": true,
      "retrievable": true,
      "searchable": false,
      "sortable": false,
      "analyzer": null,
      "indexAnalyzer": null,
      "searchAnalyzer": null,
      "synonymMaps": [],
      "fields": []
    }
  ]
}
END
)

echo "$(info) Creating index for Cosmos DB in Search service"
curl_index_req=$(echo "$create_index" | curl -sS -X POST -H "Content-Type: application/json" -H "api-key: ${az_search_api_admin_key}" --data-binary "@-" "${az_search_url}/indexes?api-version=2021-04-30-Preview")
echo "$curl_index_req"

create_indexer=$(
  cat <<-END
{
  "name": "cosmosdb-indexer",
  "description": "",
  "dataSourceName": "transactions",
  "targetIndexName": "cosmosdb-index",
  "schedule": null,
  "parameters": {
    "maxFailedItems": 0,
    "maxFailedItemsPerBatch": 0,
    "base64EncodeKeys": false,
    "configuration": {}
  },
  "fieldMappings": [
    {
      "sourceFieldName": "_sink",
      "targetFieldName": "sink"
    },
    {
      "sourceFieldName": "_sinkLabel",
      "targetFieldName": "sinkLabel"
    },
    {
      "sourceFieldName": "_vertexId",
      "targetFieldName": "vertexId"
    },
    {
      "sourceFieldName": "_vertexLabel",
      "targetFieldName": "vertexLabel"
    }
  ],
  "outputFieldMappings": []
}
END
)

echo "$(info) Creating indexer for Cosmos DB in Search service"
curl_indexer_req=$(echo "$create_indexer" | curl -sS -X POST -H "Content-Type: application/json" -H "api-key: ${az_search_api_admin_key}" --data-binary "@-" "${az_search_url}/indexers?api-version=2021-04-30-Preview")
echo "$curl_indexer_req"

cd ../visualize || exit
echo "$(info) Building Container for Streamlit app"
acr_login_server=$(az acr list --resource-group "${resourceGroupName}" --query '[0].loginServer' --output tsv)
acr_login_username=$(echo "$acr_login_server" | cut -d"." -f1)
acr_login_key=$(az acr credential show --resource-group "${resourceGroupName}" --name "${acr_login_server}" --query 'passwords[0].value' --output tsv)
build_container=$(az acr build --resource-group "${resourceGroupName}" --registry "${acr_login_server}" --image cosmosgraphdemo:v3 .)
echo "$build_container"

echo "$(info) Deploying Streamlit app to Container instance"
COSMOS_KEY=$(az cosmosdb keys list --name "${cosmosAccountName}" --resource-group "${resourceGroupName}" --query primaryMasterKey --output tsv)
COSMOS_ENDPOINT=$(az cosmosdb keys list --type connection-strings --name "${cosmosAccountName}" --resource-group "${resourceGroupName}" --query 'connectionStrings[0].connectionString' | awk -F'[=/]' '{print $4}' | sed 's/.documents./.gremlin.cosmos./')
SEARCH_KEY=$(az search query-key list --resource-group "${resourceGroupName}" --service-name "${searchServiceName}" --query "[0].key" --output tsv)
SEARCH_ENDPOINT="https://${searchServiceName}.search.windows.net"
STREAMLIT_SERVER_HEADLESS="true"

container_create=$(az container create \
  --resource-group "$resourceGroupName" \
  --name "$appContainerName" \
  --image "$acr_login_server"/cosmosgraphdemo:v3 \
  --restart-policy OnFailure \
  --registry-login-server "$acr_login_server" \
  --registry-username "$acr_login_username" \
  --registry-password "$acr_login_key" \
  --ip-address Public \
  --dns-name-label "$appDnsName" \
  --ports 80 \
  --environment-variables COSMOS_DATABASE="${cosmosdbName}" COSMOS_GRAPH_COLLECTION="${cosmosContainerName}" COSMOS_KEY="${COSMOS_KEY}" COSMOS_ENDPOINT="${COSMOS_ENDPOINT}" SEARCH_KEY="${SEARCH_KEY}" SEARCH_INDEX="${searchIndex}" SEARCH_ENDPOINT="${SEARCH_ENDPOINT}" STREAMLIT_SERVER_PORT="${dashboardPort}" STREAMLIT_SERVER_HEADLESS="${STREAMLIT_SERVER_HEADLESS}")

echo "$container_create"

web_address=$(az container show \
  --resource-group "$resourceGroupName" \
  --name "$appContainerName" \
  --query ipAddress.fqdn \
  --output tsv)
echo "$(info) Web address: $web_address"
az logout
