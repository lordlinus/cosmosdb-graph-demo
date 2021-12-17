# Sample Graph Queries

### Retrieve all verices with account
`g.V().hasLabel('account')`

### Retrieve edges that label CASH_IN
`g.E().hasLabel('CASH_IN') `

### Get a vertex by id
`g.V().hasId('C551495160') or g.V('C551495160')`

### Retrieves incoming CASH_IN for account C551495160 count: 18
`g.V('C551495160').inE().hasLabel('CASH_IN')`

###  Retrieves the source vertices/accounts of the incoming edges of account C551495160 Count: 70
`g.V('C551495160').inE().outv()`

### Retrieves both incoming and outgoing edges for account C551495160 Count: 70
`g.V('C551495160').bothE()`

###  Traverses from C546116488 to the target vertices and get their ID: C551495160
`g.V('C546116488').outE().inV().id()`

### Graph Traversal 1: 
```g.V(). 
    has('accountId','C151078233'). #select vertices with accountId C151078233
    outE('CASH_OUT'). #select outgoing edges with label CASH_OUT
    inV(). #select incoming vertices
    outE('CASH_IN'). #select outgoing edges with label CASH_IN
    inV() #select incoming vertices
```
or 

`g.V('C151078233').out('CASH_OUT').out('CASH_IN')`


### Graph Traversal 2:

```g.V(). 
    has('accountId','C89143842'). #select vertices with accountId C89143842
    outE('TRANSFER'). #select outgoing edges with label TRANSFER
    inV(). #select incoming vertices
    inE('DEBIT'). # select incoming edges with label DEBIT
    outV() #select outgoing vertices
```
or 

`g.V('C89143842').out('TRANSFER').in('DEBIT')`

## Search the whole graph with outgoung as CASH_OUT and incoming as CASH_IN
g.V().out('CASH_OUT').out('CASH_IN')


```Example:
C1355319256 CASH_IN C1151008535
9 accounts( 1 transfer, 4 cash_in and 4 cash_out) are send to C1355319256
    C1894710121	TRANSFER
    C1849606250	CASH_IN
    C1763263808	CASH_IN
    C46742020	CASH_IN
    C477356311	CASH_IN
    C1574702575	CASH_OUT
    C151078233	CASH_OUT
    C444768769	CASH_OUT
    C1955399252	CASH_OUT
```

### Info:
`-- in => source`
`-- out => target`
`out() => outE().inV()`
`in() => inE().outV()`

### List of all accounts that have transferred to "account" and destination account also received `in` from another "account" - count: 21
`g.V().in().in()`


### Accounts that have incoming edges and filter destination accounts that have used "TRANSFER" option to send. 3 accounts C1894710121, C833807772 and C636706027
`g.V().in().inE().hasLabel('TRANSFER')`

```[
  {
    "id": "8ab6f302-9178-422e-b092-91e4413e2df0",
    "label": "TRANSFER",
    "type": "edge",
    "inVLabel": "account",
    "outVLabel": "account",
    "inV": "C1355319256",
    "outV": "C1894710121",
    "properties": {
      "type": "TRANSFER",
      "amount": 262651,
      "oldbalanceOrg": 10743,
      "newbalanceOrig": 0,
      "oldbalanceDest": 53130,
      "newbalanceDest": 315782
    }
  },
  {
    "id": "9630eaf2-719e-4edb-b2e4-f3c042f6d475",
    "label": "TRANSFER",
    "type": "edge",
    "inVLabel": "account",
    "outVLabel": "account",
    "inV": "C1134131776",
    "outV": "C833807772",
    "properties": {
      "type": "TRANSFER",
      "amount": 1112939,
      "oldbalanceOrg": 36303,
      "newbalanceOrig": 0,
      "oldbalanceDest": 661255,
      "newbalanceDest": 1774195
    }
  },
  {
    "id": "dcebc52b-ec3d-4384-a486-76f8402973de",
    "label": "TRANSFER",
    "type": "edge",
    "inVLabel": "account",
    "outVLabel": "account",
    "inV": "C1134131776",
    "outV": "C636706027",
    "properties": {
      "type": "TRANSFER",
      "amount": 789285,
      "oldbalanceOrg": 0,
      "newbalanceOrig": 0,
      "oldbalanceDest": 1590128,
      "newbalanceDest": 2379413
    }
  }
]
```