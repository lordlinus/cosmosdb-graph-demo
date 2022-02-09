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


class Transaction:
    def __init__(self) -> None:
        # Limit the max number of results returned by a raw gremlin query to avoid excess RU's and timeouts
        self.GREMLIN_QUERY_LIMIT = 100
        self.credential = AzureKeyCredential(search_key)

        # Create cognitive search client
        self.search_client = SearchClient(
            endpoint=search_endpoint,
            index_name=search_index,
            credential=self.credential,
        )

        # Create cosmos client
        self.cql = client.Client(
            f"wss://{cosmos_endpoint}",
            "g",
            username=f"/dbs/{cosmos_database}/colls/{cosmos_graph_collection}",
            password=cosmos_key,
            message_serializer=serializer.GraphSONSerializersV2d0(),
        )

        # graphviz layout options: neato, dot, twopi, circo, fdp, nop, wc, acyclic, gvpr, gvcolor, ccomps, sccmap, tred, sfdp, unflatten
        # See http://www.graphviz.org/doc/info/attrs.html for a list of attributes.
        self.graph_config = Config(
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

    # Create a graph from the results of a Gremlin query, expects the query to return with e and v properties
    def create_graph(self, cosmos_result: list) -> None:
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
        agraph(nodes=nodes, edges=edges, config=self.graph_config)

    # Get status attributes of the query
    def print_status_attributes(self, result, q) -> None:
        result.status_attributes["query"] = q
        with st.expander(
            f"Cosmos RU charge: {math.ceil(result.status_attributes['x-ms-total-request-charge'])}, Click to see more"
        ):
            st.json(result.status_attributes)

    # Get adjacent vertices ( 2 levels ) and create a graph
    def get_adj_vertices_and_graph(self, vertices_list: list) -> None:
        query = f"g.V().has('accountId',within({vertices_list})).optional(both().both()).bothE().as('e').inV().as('v').select('e', 'v')"
        try:
            callback = self.cql.submitAsync(query)
            if callback.result() is not None:
                r = callback.result().all().result()
                with st.expander("Click to see Cosmos json response"):
                    st.json(r)
                self.create_graph(r)
            else:
                st.write(f"Something went wrong with this query:", query)
            self.print_status_attributes(callback.result(), query)
        except Exception as e:
            st.write(f"Something went wrong with this query:", query)
            st.error(e)

    # Execute gremlin query
    def execute_gremlin_query(self, query: str) -> None:
        # print(f"Executing query: {query}")
        try:
            callback = self.cql.submitAsync(
                f"{query}.limit({self.GREMLIN_QUERY_LIMIT})"
            )
            accountId_list = []
            if callback.result() is not None:
                results = callback.result().all().result()
                # print(f"\tGot results:\n\t{results}")
                if type(results[0]) == int:
                    return results
                else:
                    for r in results:
                        accountId_list.append(r["id"])
                    self.get_adj_vertices_and_graph(accountId_list)
            else:
                return (f"Something went wrong with this query:", query)
            self.print_status_attributes(callback.result(), query)
        except Exception as e:
            st.write(f"Something went wrong with this query:", query)
            st.error(e)

    # Execute Azure search to find accounts either sent or received
    def execute_search(self, search_text: str, filter=None) -> None:
        accountId_list = []
        response = self.search_client.search(
            search_text=search_text,
            include_total_count=True,
            filter=filter,
            search_fields=["sink", "vertexId"],
        )
        for r in response:
            accountId_list.append(r["vertexId"])
            accountId_list.append(r["sink"])
        self.get_adj_vertices_and_graph(list(set(accountId_list)))


# Initialize streamlit  dashboard
st.set_page_config(layout="wide")
st.markdown(
    "<h1 style='text-align: center; color: black;'>Bank Transaction Data - Graph Explorer</h1>",
    unsafe_allow_html=True,
)

# Initialize the client and get number of vertices and edges
t = Transaction()
v = t.execute_gremlin_query("g.V().count()")[0]
e = t.execute_gremlin_query("g.E().count()")[0]

st.metric(label="Number of unique Accounts", value=format(v, ","))
st.metric(label="Number of Transactions", value=format(e, ","))

col4, col5 = st.columns(2)

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
        t.execute_gremlin_query(query_input)
    elif submit_button_q:
        t.execute_search(text_input)
