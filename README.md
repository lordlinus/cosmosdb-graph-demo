# Cosmos Graph Demo 

## load data 

## Query data

## list paired region in AZ
az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json
