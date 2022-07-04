#!/bin/bash

# Fill values in here.

prefix="graphdemo"
environment="test"
clientid="xxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
clientsecret="xxxxxxxxxxxxxxx"
tenantid="xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"
location="eastus"
sqlAdminPassword="**ChangeMeNow1234!**"

# Find paired regions for the given location.
#  az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json
