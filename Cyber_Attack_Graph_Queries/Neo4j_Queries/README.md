# HPE-MDC-Cybersecurity-Solutions

## MITRE ATTACK NOTEBOOKS
    Attack : Pass The Ticket(T1097)
        Notebook : Pass the ticket.ipynb
        Graph    : Neo4j
        Data Loading : neo4j-import
        Data Needed : LANL 2v & nf
        queries : 5
        Tested : First 25Lakh Rows for 85th day
        Comments : The SET operation to change the flags might take a long time to execute

    Attack : Pass The Hash(T1075)
        Notebook : Pass the hash.ipynb
        Graph    : Neo4j
        Data Loading : neo4j-import
        Data Needed : LANL 1v & nf
        queries : 2
        Tested : Full 1v & nf for 85th day
        Comments :

    Attack : Third Party Software(T1072)
        Notebook : Third_Party_Software_Wiper.ipynb
        Graph    : Neo4j
        Data Loading : neo4j-import
        Data Needed : LANL 1v & nf
        queries : 2
        Tested : Full 1v & nf for 85th day
        Comments : This query is only applicable for Wiper malware under Third Party Software(CAN NOT BE GENERALIZED FOR THE ATTACK)

