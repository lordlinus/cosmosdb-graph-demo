---
page_type: sample
languages:
  - python
products:
  - cosmosdb
  - azure-synapse
  - azure-cognitive-search
  - container-instance-service
  - container-registry
---

<!-- markdownlint-disable MD033 - HTML rule -->

# Cosmos DB Gremlin Graph Demo

## Problem statement<!-- omit in toc -->

Bank transactions have traditionally been stored in transactional databases and analysed using SQL queries and to increase scale they are now analysed in distributed systems using Apache Spark. While SQL is great to analyse this data finding relationships between transactions and accounts can be challenging. In this scenario we want to visualize 2 level of customer relationships i.e. if A sends to B and B send to C then we want to identify C when we look at transactions made by A together with C and vice versa.

## Contents<!-- omit in toc -->

---

- [Cosmos DB Gremlin Graph Demo](#cosmos-db-gremlin-graph-demo)
  - [Overview](#overview)
  - [Features:](#features)
  - [Prerequisites](#prerequisites)
  - [Getting started](#getting-started)
    - [Step.1 Deploy infrastructure](#step1-deploy-infrastructure)
    - [Step.2 Post install access setup](#step2-post-install-access-setup)
    - [Step.3 Load data](#step3-load-data)
    - [Step.4 Data ingestion using PySpark](#step4-data-ingestion-using-pyspark)
    - [Step.5 Sample dashboard app](#step5-sample-dashboard-app)
  - [Limitations](#limitations)
  - [References](#references)

## Overview

---

Graph helps solve **complex** problems by utilizing power of **relationships** between objects, some of these can be modeled as SQL statements but gremlin api provide a more concise way to express and search relationships. In this solution we are using Azure Cosmos Graph DB to store transactions data with customer account id as vertices and transaction as edges and transactional amount as properties of the edges.Since running fan out queries on Cosmos DB is not ideal we are leveraging Azure cognitive search to index data in Cosmos DB and leverage search api perform full scan/search queries. Additionally, Azure search will give us the flexibility to search for account either received or sent. This provides a scalable solution that can scale for any number of transactions and keeping the RU requirement for Cosmos queries low.

## Features:

---

1. Synapse spark is used to bulk load data into gremlin using SQL api NOTE: Cosmos gremlin expects to have certain json fields in the edge properties. Since cosmos billing is charged per hour we need to adjust the RU's accordingly to minimize cost, a spark cluster with 4 nodes and cosmos throughput at 20,000 RU/s ( single region) both edges (9 Million ) and vertices (6 Million) records can be ingested in an hour.
2. All search fan-out queries are done using Azure cognitive search api, Cosmos indexer can be scheduled at regular intervals to update the index
3. To keep the RU's low, Gremlin query is constructed to include account list e.g. when you search for account `xyz` all account send or received from `xyz` is created as `vertices_list` and gremlin query to get 2 level of transactions is executed as `g.V().has('accountId',within({vertices_list})).optional(both().both()).bothE().as('e').inV().as('v').select('e', 'v')` you can customize this query based on your use-case

## Prerequisites

---

Installing this connector requires the following:

1. Azure subscription-level role assignments for both `Contributor` and `User Access Administrator`.
2. Azure Service Principal with client ID and secret - [How to create Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal).

## Getting started

---

### Step.1 Deploy infrastructure

There are three deployment options for this demo:

1. Option 1:

   1. Click on link to deploy the template.

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flordlinus%2Fcosmosdb-graph-demo%2Fmain%2Finfra%2Fmain.json)

2. Option 2.

   1. Open a browser to https://shell.azure.com, Azure Cloud Shell is an interactive, authenticated, browser-accessible shell for managing Azure resources. It provides the flexibility of choosing the shell experience that best suits the way you work, either Bash or PowerShell
   2. Select the Cloud Shell icon on the Azure portal
   3. Select Bash
   4. `git clone` this repo and cd into `infra` directory
   5. Update `settings.sh` file with required values, use `code` command in bash shell to open the file in VS Code
   6. Run `./infra-deployment.sh` to deploy infrastructure

   The above deployment should create container instance with a sample dashboard

3. Option 3.
   1. Use GiHub actions to deploy services. Go to [github_action_infra_deployment](github_action_infra_deployment.md) to see how to deploy services.

### Step.2 Post install access setup

1. Add client ip to allow access to Synapse workspace. Navigate to resource group -> Synapse workspace -> Networking -> Click "Add client IP" and Save

2. Add yourself as a user to Synapse workspace. Navigate to Synapse workspace -> manage -> Access control -> Add -> scope "workspace" -> role "Synapse Administrator" -> select user "username@contoso.com" -> Apply

3. Add yourself as a user to Synapse Apache Spark administrator. Navigate to Synapse workspace -> manage -> Access control -> Add -> scope "workspace" -> role "Synapse Apache Spark administrator" -> select user "username@contoso.com" -> Apply

4. Create data container.Navigate to storage account and create container e.g. "data" and upload [CSV file](load_data/data/PS_20174392719_1491204439457_log.csv) into this container

5. Assign read/write access to storage account.Navigate to Synapse workspace -> select "Data" sec -> select and expand "Linked" storage -> select Primary storage account and container e.g. data > right click on container "data" and click "Manage access" -> Add -> search and select user "username@contoso.com" -> assign read and write -> click Apply

### Step.3 Load data

1. Upload CSV file [PS_20174392719_1491204439457_log.csv](load_data/data/PS_20174392719_1491204439457_log.csv) into Synapse default storage account. Data source: [Kaggle Fraud Transaction Detection](https://www.kaggle.com/llabhishekll/fraud-transaction-detection/data).( NOTE: you need to use [git-lfs](https://git-lfs.github.com/) to download the csv file locally )

### Step.4 Data ingestion using PySpark

1. Import notebook ["`Load_Bank_transact_data.ipynb`"](load_data/Load_Bank_transact_data.ipynb)
2. Update `linkedService` , `cosmosEndpoint`, `cosmosMasterKey`, `cosmosDatabaseName` and `cosmosContainerName` in notebook
3. Run notebook and monitor the progress of data load from Cosmos DB insights view ( NOTE: Cosmos billing is per hour so adjust your RU's accordingly to minimize cost)

### Step.5 Sample dashboard app

A sample python webapp is deployed as part of infra deployment. Navigate to the public url from container instances and start exploring the data.

## Limitations

- User authentication is not implemented yet for dashboard app

## References

- <https://tinkerpop.apache.org/docs/current/tutorials/getting-started/>
- <https://tinkerpop.apache.org/docs/current/reference/#a-note-on-lambdas>
- <https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/cosmos-db/graph/gremlin-limits.md>
- <https://github.com/LuisBosquez/azure-cosmos-db-graph-working-guides/blob/master/graph-backend-json.md>
- <https://syedhassaanahmed.github.io/2018/10/28/writing-apache-spark-graphframes-to-azure-cosmos-db.html>
