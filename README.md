# HPE-MDC-Cybersecurity-Solutions

MITRE ATTACK NOTEBOOKS
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

OTHER NOTEBOOKS AND SCRIPTS
    SCRIPT 1 : 1v data modification for neo4j-import 
        Notebook : 1v_modify.ipynb
        Description : Adds another column with same entries as loghost in 1v file
  
