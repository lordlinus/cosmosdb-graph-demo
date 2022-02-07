import os
import math

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

# Limit the max number of results returned by a raw gremlin query to avoid excess RU's and timeouts
GREMLIN_QUERY_LIMIT = 100

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

# Initialize streamlit  dashboard
st.set_page_config(layout="wide")
st.markdown("<h1 style='text-align: center; color: black;'>Transaction data Graph Explorer</h1>", unsafe_allow_html=True)
st.metric(label="Number of unique Accounts", value="6.36 M")
st.metric(label="Number of Transactions", value="9.07 M")

col4, col5 = st.columns(2)
# container = st.container()
# Create a graph from the results of a Gremlin query, ir expects the query to return with e and v properties
def create_graph(cosmos_result: list) -> None:
    # graphviz layout options: neato, dot, twopi, circo, fdp, nop, wc, acyclic, gvpr, gvcolor, ccomps, sccmap, tred, sfdp, unflatten
    # See http://www.graphviz.org/doc/info/attrs.html for a list of attributes.
    config = Config(
        width=1920,
        height=1080,
        directed=True,
        nodeHighlightBehavior=True,
        collapsible=False,
        node={
            "labelProperty": "label",
        },
        link={"labelProperty": "label", "renderLabel": True},
        node_color="#F7A7A6",
        graphviz_layout="circo",
        graphviz_config={"overlap": "false", "splines": "curved"},
    )
    nodes = []
    edges = []
    accounts = []
    for r in cosmos_result:            
        if r["e"]["inV"] not in nodes:
            accounts.append(r["e"]["inV"])
            nodes.append(Node(id=r["e"]["inV"], label=r["e"]["inV"]))
        if r["e"]["outV"] not in nodes:
            accounts.append(r["e"]["outV"])
            nodes.append(Node(id=r["e"]["outV"], label=r["e"]["outV"]))
        edges.append(
            Edge(
                source=r["e"]["outV"],
                target=r["e"]["inV"],
                type="CURVE_SMOOTH",
                label=f"${int(r['e']['properties']['amount']):,}-{r['e']['properties']['type']}",
            )
        )
    st.metric("Number of unique Accounts: ", len(set(accounts)))
    st.metric("Number of Transactions: ", len(edges))
    agraph(nodes=nodes, edges=edges, config=config)


def print_status_attributes(result, q):
    result.status_attributes["query"] = q
    with st.expander(
        f"Cosmos RU charge: {math.ceil(result.status_attributes['x-ms-total-request-charge'])}, Click to see more"
    ):
        st.json(result.status_attributes)


# Get adjacent vertices ( 2 levels ) and create a graph
def get_adj_vertices_and_graph(vertices_list: list) -> None:
    query = f"g.V().has('accountId',within({vertices_list})).optional(both().both()).bothE().as('e').inV().as('v').select('e', 'v')"
    try:
        callback = cql.submitAsync(query)
        if callback.result() is not None:
            r = callback.result().all().result()
            with st.expander("Click to see Cosmos json response"):
                st.json(r)
            create_graph(r)
        else:
            st.write(f"Something went wrong with this query:", query)
        print_status_attributes(callback.result(), query)
    except Exception as e:
        st.write(f"Something went wrong with this query:", query)
        st.error(e)


# Execute gremlin query
def execute_gremlin_query(query: str) -> None:
    # print(f"Executing query: {query}")
    try:
        callback = cql.submitAsync(f"{query}.limit({GREMLIN_QUERY_LIMIT})")
        accountId_list = []
        if callback.result() is not None:
            results = callback.result().all().result()
            # print(f"\tGot results:\n\t{results}")
            for r in results:
                accountId_list.append(r["id"])
            get_adj_vertices_and_graph(accountId_list)
        else:
            st.write(f"Something went wrong with this query:", query)
        print_status_attributes(callback.result(), query)
    except Exception as e:
        st.write(f"Something went wrong with this query:", query)
        st.error(e)


# Execute Azure search to find accounts either in
def execute_search(search_text: str, filter=None) -> None:
    accountId_list = []
    response = search_client.search(
        search_text=search_text,
        include_total_count=True,
        filter=filter,
        search_fields=["sink", "vertexId"],
    )
    for r in response:
        accountId_list.append(r["vertexId"])
        accountId_list.append(r["sink"])
    get_adj_vertices_and_graph(list(set(accountId_list)))


with col4:
    st.header("Gremlin Query")
    with st.form(key="search_form"):
        query_input = st.text_input(
            label="Enter a Gremlin query in the text box below.",
            help="e.g. g.V().limit(10)",
            placeholder="g.V().limit(10)",
        )
        submit_button_t = st.form_submit_button(label="Submit")

with col5:
    st.header("Search Query")
    with st.form(key="gremlin-query"):
        text_input = st.text_input(
            label="Account Number either sent or received",
            help="e.g. C1151008535",
            placeholder="C1151008535",
            autocomplete="True",
        )
        submit_button_q = st.form_submit_button(label="Submit")

with st.container():
    if submit_button_t:
        execute_gremlin_query(query_input)
    elif submit_button_q:
        execute_search(text_input)
