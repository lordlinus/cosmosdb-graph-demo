# Cosmos Graph Demo

## Problem statement

Bank transactions have traditionally been stored in transactional databases and analysed using SQL queries and to increase scale they are now analysed in distributed systems using Apache Spark. While SQL is great to analyse this data finding relationships between transactions and accounts can be challenging. In this scenario we want to visualize 2 level of customer relationships i.e. if A sends to B and B send to C then we want to identify C when we look at transactions made by A together with C and vice versa.

## Why does this solution solve the problem

Graph helps solve **complex** problems by utilizing power of **relationships** between objects, some of these can be modeled as SQL statements but gremlin api provide a more concise way to express and search relationships. In this solution we are using Azure Cosmos Graph DB to store transactions data with customer account id as vertices and transaction as edges and transactional amount as properties of the edges.Since running fan out queries on Cosmos DB is not ideal we are leveraging Azure cognitive search to index data in Cosmos DB and leverage search api perform full scan/search queries. Additionally, Azure search will give us the flexibility to search for account either received or sent. This provides a scalable solution that can scale for any number of transactions and keeping the RU requirement for Cosmos queries low.

## Getting started

### Step.1 Deploy infrastructure

Option 1. Click on below link to deploy the template.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Flordlinus%2Fcosmosdb-graph-demo%2Fmain%2Finfra%2Fmain.json)

Option 2.

1.  Open a browser to https://shell.azure.com
2.  Select the Cloud Shell icon on the Azure portal
3.  cd into `infra` folder
4.  Update `settings.sh` file with required values, use `code` command in bash shell to open the file in VS Code
5.  Run `./infra-deployment.sh` to deploy infrastucture

Option 3. Use GiHub actions to deploy services. Go to [github_action_infra_deployment](github_action_infra_deployment.md) to see how to deploy services.

### Step.2 Post install access setup

#### Add client ip to allow access to Synapse workspacce

Navigate to resource group -> Synapse workspace -> Networking -> Click "Add client IP" and save

#### Add yourself as a user to Synapse workspace

Navigate to Synapse workspace -> manage -> Access control -> Add -> scope "workspace" -> role "Synapse Adminstrator" -> select user "username@contoso.com" -> Apply

#### Add yourself as a user to Synapse Apache Spark administrator

Navigate to Synapse workspace -> manage -> Access control -> Add -> scope "workspace" -> role "Synapse Apache Spark administrator" -> select user "username@contoso.com" -> Apply

#### create data container

Navigate to storage account and create container e.g. "data" and upload [CSV file](load_data/data/PS_20174392719_1491204439457_log.csv) into this container

#### Assign read/write access to storage account

Navigate to Synapse workspace -> select "Data" sec -> select and expand "Linked" storage -> select Primary storage account and container e.g. data > right click on container "data" and click "Manage access" -> Add -> search and select user "username@contoso.com" -> assign read and write -> click Apply

### Step.3 Load data

Data source: [Kaggle Fraud Transaction Detection](https://www.kaggle.com/llabhishekll/fraud-transaction-detection/data). A copy of this data is available in this repo at [PS_20174392719_1491204439457_log.csv](load_data/data/PS_20174392719_1491204439457_log.csv) ( NOTE: you need to use [git-lfs](https://git-lfs.github.com/) to download the csv file locally )

### Step.4 Data ingestion using PySpark

- Upload csv file into Synapse linked storage account
- create linked service to mount the storage account e.g. `linked-storage-service`
- Import notebook ["`insert_transact_data_spark.ipynb`"](load_data/insert_transact_data_spark.ipynb)
- Update `linkedService` , `cosmosEndpoint`, `cosmosMasterKey`, `cosmosDatabaseName` and `cosmosContainerName` in notebook
- run notebook and monitor the progress of data load from Cosmos DB insights view ( NOTE: Cosmos billing is per hour so adjust your RU's accordingly to minimize cost)

## Key highlights:

1. Synapse spark is used to bulk load data into gremlin using SQL api NOTE: Cosmos gremlin expects to have certain json fields in the edge properties. Since cosmos billing is charged per hour we need to adjust the RU's accordingly to minimize cost, a spark cluster with 4 nodes and cosmos throughput at 20,000 RU/s ( single region) both edges (9 Million ) and vertices (6 Million) records can be ingested in an hour.
2. All search fan-out queries are done using Azure cognitive search api, Cosmos indexer can be scheduled at regular intervals to update the index
3. To keep the RU's low, Gremlin query is constructed to include account list e.g. when you search for account `xyz` all account send or received from `xyz` is created as `vertices_list` and gremlin query to get 2 level of transactions is executed as `g.V().has('accountId',within({vertices_list})).optional(both().both()).bothE().as('e').inV().as('v').select('e', 'v')` you can customize this query based on your use-case

## Next steps

Clone/Fork this repo [cosmosdb-graph-demo](https://github.com/lordlinus/cosmosdb-graph-demo) update configurations and deploy in your own subscription. GitHub action to deploy [infra](github_action_infra_deploy.md) and [dashboard](github_action_dashboard_deployment.md) are provided for reference.

## References

- <https://tinkerpop.apache.org/docs/current/tutorials/getting-started/>
- <https://tinkerpop.apache.org/docs/current/reference/#a-note-on-lambdas>
- <https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/cosmos-db/graph/gremlin-limits.md>
- <https://github.com/LuisBosquez/azure-cosmos-db-graph-working-guides/blob/master/graph-backend-json.md>
- <https://syedhassaanahmed.github.io/2018/10/28/writing-apache-spark-graphframes-to-azure-cosmos-db.html>
