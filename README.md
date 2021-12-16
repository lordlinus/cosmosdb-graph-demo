# Cosmos Graph Demo

## Create cosmosdb database and collection

- update `param.dev.json` file
- run below command to create cosmosdb database and collection
  - ```console az login```
  - ```az deployment sub create --location southeastasia --template-file infra/main.bicep --parameters infra/params.dev.json```
  
## Load data

- update environment variables with correct values
  - ```set COSMOS_KEY=<cosmosdb primary/secondary key>```
  - ```set COSMOS_ENDPOINT=<cosmosdb endpoint>```
- run "```pip install -r requirements.txt```"
- run "```python insert_transact_data.py```"

## Query data

- [Sample Queries](load_data/sample_queries.md)


## Misc

### list paired region in AZ

```az account list-locations --query "[?not_null(metadata.latitude)] .{RegionName:name, PairedRegion:metadata.pairedRegion[0].name}" --output json```

## Gephi

- Connect to Cosmos using Gremlin console - <https://docs.microsoft.com/en-us/azure/cosmos-db/graph/create-graph-console>

## References

- <https://tinkerpop.apache.org/docs/current/tutorials/getting-started/>

## Gremlin - Console connect to Cosmos DB remote and execute queries

- :plugin use tinkerpop.gephi
- :remote connect tinkerpop.gephi
- :remote connect tinkerpop.server conf/remote-secure.yaml
  - Sample remote-secure.yaml file
    ```
    hosts: [ebcbin5oofjcs.gremlin.cosmos.azure.com]
    port: 443
    username: /dbs/database01/colls/graph01
    password: <cosmosdb primary/secondary key>
    connectionPool: {
      enableSsl: true
      }
    serializer: { className: org.apache.tinkerpop.gremlin.driver.ser.GraphSONMessageSerializerV2d0, config: { serializeResultToString: true }}
    ```

- :remote console
- g.V().out()

## Load sample data

### active plugin

gremlin> :plugin use tinkerpop.gephi

### create graph

gremlin> graph = TinkerFactory.createModern()
==>tinkergraph[vertices:6 edges:6]

### connect to tinkerpop.gephi

gremlin> :remote connect tinkerpop.gephi
==>Connection to Gephi - <http://localhost:8080/workspace1> with stepDelay:1000, startRGBColor:[0.0, 1.0, 0.5], colorToFade:g, colorFadeRate:0.7, startSize:10.0,sizeDecrementRate:0.33

### config to remote gephi (Optinal)

gremlin> :remote config port 8080
gremlin>  :remote config host 192.25.11.38
gremlin> :remote config workspace workspace1

### send data to gephi

gremlin> :> graph
