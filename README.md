# Cosmos Graph Demo

## Create cosmosdb database and collection

- update `param.dev.json` file
- run below command to create cosmosdb database and collection
  - `console az login`
  - `az deployment sub create --location southeastasia --template-file infra/main.bicep --parameters infra/params.dev.json`

## Load data

### Python

- update environment variables with correct values
  - `set COSMOS_KEY=<cosmosdb primary/secondary key>`
  - `set COSMOS_ENDPOINT=<cosmosdb endpoint>`
- run "`pip install -r requirements.txt`"
- run notebook ["`insert_transact_data_python.ipynb`"](load_data/insert_transact_data_python.ipynb)

### PySpark

- Create Synapse spark medium pool in Synpase. [Link](https://docs.microsoft.com/en-us/azure/synapse-analytics/quickstart-create-apache-spark-pool-portal) 
- Upload csv file into Synapse linked storagae account
- create linked service to mount the storage account e.g. `linked-storage-service`
- Import notebook ["`insert_transact_data_spark.ipynb`"](load_data/insert_transact_data_spark.ipynb)
- Update `linkedService` , `cosmosEndpoint`, `cosmosMasterKey`, `cosmosDatabaseName` and `cosmosContainerName` in notebook
- run notebook

## Query data

- [Sample Queries](load_data/sample_queries.md)

## Visualization

- TODO

###

## References

- <https://tinkerpop.apache.org/docs/current/tutorials/getting-started/>

## Misc

### list paired region in AZ

`az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json`
