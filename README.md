# Cosmos Graph Demo 

## Create cosmosdb database and collection
- update `param.dev.json` file
- run below command to create cosmosdb database and collection
    - ```console az login```
    - ``` az deployment sub create --location southeastasia --template-file infra/main.bicep --parameters infra/params.dev.json```
  
## Load data 
- update environment variables with correct values
  - ```set COSMOS_KEY=<cosmosdb primary/secondary key>```
  - ```set COSMOS_ENDPOINT=<cosmosdb endpoint>```
- run "```pip install -r requirements.txt```"
- run "```python insert_transact_data.py```"

## Query data
- 
## Misc:
### list paired region in AZ
```az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json```
