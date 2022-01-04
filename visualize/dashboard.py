import os

import streamlit as st
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from dotenv import load_dotenv
from gremlin_python.driver import client, serializer
from streamlit_agraph import Config, Edge, Node, agraph

# Load environment variables from .env file
load_dotenv()

cosmos_database = os.getenv("COSMOS_DATABASE")
cosmos_graph_collection = os.getenv("COSMOS_GRAPH_COLLECTION")
cosmos_key = os.getenv("COSMOS_KEY")
cosmos_endpoint = os.getenv("COSMOS_ENDPOINT")
search_key = os.getenv("SEARCH_KEY")
search_index = os.getenv("SEARCH_INDEX")
search_endpoint = os.getenv("SEARCH_ENDPOINT")

st.session_state.NUM_ACCOUNTS = 0
st.session_state.NUM_TRANSACTIONS = 0

credential = AzureKeyCredential(search_key)

search_client = SearchClient(
    endpoint=search_endpoint, index_name=search_index, credential=credential
)

cql = client.Client(
    f"wss://{cosmos_endpoint}",
    "g",
    username=f"/dbs/{cosmos_database}/colls/{cosmos_graph_collection}",
    password=cosmos_key,
    message_serializer=serializer.GraphSONSerializersV2d0(),
)

#
def create_graph(cosmos_result):
    # graphviz layout options: neato, dot, twopi, circo, fdp, nop, wc, acyclic, gvpr, gvcolor, ccomps, sccmap, tred, sfdp, unflatten
    # See http://www.graphviz.org/doc/info/attrs.html for a list of attributes.
    config = Config(
        width=1024,
        height=800,
        directed=True,
        nodeHighlightBehavior=True,
        collapsible=False,
        node={
            "labelProperty": "label",
        },
        link={"labelProperty": "label", "renderLabel": True},
        node_color="#F7A7A6",
        graphviz_layout="twopi",
        graphviz_config={"overlap": "false", "splines": "curved"},
    )
    nodes = []
    edges = []
    for r in cosmos_result:
        if r["e"]["inV"] not in nodes:
            nodes.append(Node(id=r["e"]["inV"], label=r["e"]["inV"]))
        if r["e"]["outV"] not in nodes:
            nodes.append(Node(id=r["e"]["outV"], label=r["e"]["outV"]))
        edges.append(
            Edge(
                source=r["e"]["outV"],
                target=r["e"]["inV"],
                type="CURVE_SMOOTH",
                label=f"${int(r['e']['properties']['amount']):,}-{r['e']['properties']['type']}",
            )
        )
    st.session_state.NUM_ACCOUNTS = len(nodes)
    st.session_state.NUM_TRANSACTIONS = len(edges)
    agraph(nodes=nodes, edges=edges, config=config)


def print_status_attributes(result):
    print(f"\tResponse status_attributes:\n\t{result.status_attributes}")


def exec_graphql(query):
    # print(query)
    callback = cql.submitAsync(query)
    if callback.result() is not None:
        r = callback.result().all().result()
        # print(f"\tGot results:\n\t{r}")
        create_graph(r)

    else:
        print(f"Something went wrong with this query: {query}\n")
    # print_status_attributes(callback.result())


def search_create_graph(query=None, filter=None, accountId_list=[]):
    results = search_client.search(
        search_text=query, include_total_count=True, filter=filter
    )
    for r in results:
        # print(r)
        accountId_list.append(r["sink"])
        accountId_list.append(r["vertexId"])
    query = f"g.V().has('accountId',within({accountId_list})).optional(both().both()).bothE().as('e').inV().as('v').select('e', 'v')"
    exec_graphql(query)


st.set_page_config(page_title="Sample Graph Dashboard", page_icon="🌍", layout="wide")


# Create search input box
with st.form(key="search_form"):
    text_input = st.text_input(
        label="Account Number either sent or received",
        help="e.g. C1151008535",
        autocomplete="True",
    )
    submit_button = st.form_submit_button(label="Submit")

# Create graph
with st.empty():
    if submit_button:
        search_create_graph(text_input)
