# %%
import os

import nest_asyncio
import numpy as np
import pandas as pd
from gremlin_python.driver import client, protocol, serializer
from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
from gremlin_python.driver.protocol import GremlinServerError
from gremlin_python.structure.graph import Graph

nest_asyncio.apply()

# %%
database = os.environ.get("COSMOS_DATABASE", default="database01")
collection = os.environ.get("COSMOS_GRAPH_COLLECTION", default="graph03")
cosmos_key = os.environ.get("COSMOS_KEY", default="")
cosmos_endpoint = os.environ.get(
    "COSMOS_ENDPOINT", default="ebcbin5oofjcs.gremlin.cosmos.azure.com:443/"
)

cql = client.Client(
    f"wss://{cosmos_endpoint}",
    "g",
    username=f"/dbs/{database}/colls/{collection}",
    password=cosmos_key,
    message_serializer=serializer.GraphSONSerializersV2d0(),
)


def print_status_attributes(result):
    # This logs the status attributes returned for successful requests.
    # See list of available response status attributes (headers) that Gremlin API can return:
    #     https://docs.microsoft.com/en-us/azure/cosmos-db/gremlin-headers#headers
    #
    # These responses includes total request units charged and total server latency time.
    #
    # IMPORTANT: Make sure to consume ALL results returend by cliient tothe final status attributes
    # for a request. Gremlin result are stream as a sequence of partial response messages
    # where the last response contents the complete status attributes set.
    #
    print(f"\tResponse status_attributes:\n\t{result.status_attributes}")


def exec_graphql(query):
    print(query)
    # callback = cql.submitAsync(query)
    # if callback.result() is not None:
    #     print(f"\tInserted this vertex:\n\t{callback.result().all().result()}")
    # else:
    #     print(f"Something went wrong with this query: {query}\n")
    # print_status_attributes(callback.result())


def drop_graph():
    exec_graphql(query="g.V().drop()")


def count_graph():
    exec_graphql(query="g.V().count()")


def insert_edges(query):
    exec_graphql(query=query)


# %%
# count_graph()

# %%
# drop_graph()

# %%
# Add vertices as a batch
def add_account_vertex_batch(accounts_list: list):
    _tmp = []
    for account in accounts_list:
        _query = (
            f"addV('account')."
            f"property('id','{account[0]}')."
            f"property('accountId','{account[0]}')"
        )
        _tmp.append(_query)
    _q = f"g.{'.'.join(_tmp)}"
    # print(_q)
    try:
        exec_graphql(query=_q)
    except Exception as e:
        print(e)


def add_account_vertex(account: str):
    _query = (
        f"addV('account')."
        f"property('id','{account}')."
        f"property('accountId','{account}')"
    )
    _q = f"g.{_query}"
    exec_graphql(query=_q)


def add_transact_edge(edge_batch: pd.DataFrame):
    # print(edge_batch)
    _tmp = []
    for index, row in edge_batch.iterrows():
        query = (
            f"V('{row['nameOrig']}').addE('{row['type']}')."
            f"from(g.V('{row['nameOrig']}'))."
            f"to(g.V('{row['nameDest']}'))."
            f"property('type','{row['type']}')."
            f"property('amount',{int(row['amount'])})."
            f"property('oldbalanceOrg',{int(row['oldbalanceOrg'])})."
            f"property('newbalanceOrig',{int(row['newbalanceOrig'])})."
            f"property('oldbalanceDest',{int(row['oldbalanceDest'])})."
            f"property('newbalanceDest',{int(row['newbalanceDest'])})"
        )
        _tmp.append(query)
    _q = f"g.{'.'.join(_tmp)}"
    print(_q)
    # exec_graphql(query=_q)


if __name__ == "__main__":
    print("Starting data load..")
    csv_data = pd.read_csv("data/PS_20174392719_1491204439457_log.csv")
    account_of_interst = pd.read_csv("data/accounts_of_interest.csv")
    account_list = account_of_interst["id"].tolist()
    edges = csv_data.loc[
        csv_data["nameOrig"].isin(account_list)
        | csv_data["nameDest"].isin(account_list)
    ]
    vertices = pd.DataFrame(
        data=pd.concat([edges["nameOrig"], edges["nameDest"]]).unique()
    )
    # for batch in np.array_split(vertices, 200):
    #     add_account_vertex_batch(batch.values.tolist())
    #     break

    for batch in np.array_split(edges, 1000):
        add_transact_edge(batch)
        break

    print("Data load complete.")


#  manual - g.addV('account').property('id','C1480254471').property('accountId','C1480254471')
#  manual - g.addV('account').property('id','C39713115').property('accountId','C39713115')  
#  edge - g.V('C1480254471').addE('CASH_OUT').from(g.V('C1480254471')).to(g.V('C39713115')).property('type','CASH_OUT').property('amount',175207).property('oldbalanceOrg',9003).property('newbalanceOrig',0).property('oldbalanceDest',244076).property('newbalanceDest',0)

# g.V('C1376626882').addE('CASH_OUT').from(g.V('C1376626882')).to(g.V('C286977404'))
#    {
#         "label": "CASH_IN",
#         "id": "fecd1f25-ab5e-4508-903d-22720dcf8ad2",
#         "_sink": "C1376626882",
#         "_sinkLabel": "account",
#         "_vertexId": "C69495305",
#         "_vertexLabel": "account",
#         "_isEdge": "true",
#         "_rid": "LRgaAOGApHkNAAAAAAAAAA==",
#         "_self": "dbs/LRgaAA==/colls/LRgaAOGApHk=/docs/LRgaAOGApHkNAAAAAAAAAA==/",
#         "_etag": "\"0600e7b2-0000-0c00-0000-61bc15af0000\"",
#         "_attachments": "attachments/",
#         "_ts": 1639716271
#     }

#  {
#         "label": "CASH_OUT",
#         "id": "bf74378e-af82-4089-b76d-232d4a72f94c",
#         "_sink": "C286977404",
#         "_sinkLabel": "account",
#         "_sinkPartition": "C286977404",
#         "_vertexId": "C1376626882",
#         "_vertexLabel": "account",
#         "_isEdge": true,
#         "accountId": "C1376626882",
#         "_rid": "LRgaAOGApHkOAAAAAAAAAA==",
#         "_self": "dbs/LRgaAA==/colls/LRgaAOGApHk=/docs/LRgaAOGApHkOAAAAAAAAAA==/",
#         "_etag": "\"06005ab3-0000-0c00-0000-61bc16f30000\"",
#         "_attachments": "attachments/",
#         "_ts": 1639716595
#     }

# g.addV('account').property('id','C1542157370').property('accountId','C1542157370')
# g.addV('account').property('id','C1634109320').property('accountId','C1634109320')