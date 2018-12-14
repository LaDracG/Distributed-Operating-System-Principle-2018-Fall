#Project 4.2

##Team Members
Jingyang Guo: 01616106

Yifan Wang: 40166989

##Dependencies
- Elixir
- Phoenix
- PostgreSQL
- HTTPoison 1.0
- Chart.js

##Configuration
1. Configure database tables:
  With PostgreSQL service on, run `code here`
2. Update database and schema:
  Run `mix ecto.migrate`
3. Start server:
  Run `mix phx.server`
4. Start Bitcoin simulation

### Code structure

The folder "./project_4_1" contains all code of bitcoin clients (nodes) implementation.

The folder "./project_4_2" contains web server and front end (web interface) files.

### Most tested node number

We tested on at most 100 nodes. It worked well.

### Test 

**1. Normal transaction between two nodes**

(1) This is for testing transactions in normal case.

(2) We start two nodes and ask one of them to start a transaction to another one. Then we check their balances and transaction pools as well as the block chain after one block is mined.

(3) If correct, their balances are correct, and there will a new transaction in transaction pools. Then the next block will contain this transaction.

**2. No enough balance**

(1) This is for testing the case that a node tries to start a transaction but it has no enough balance.

(2) We start two nodes and ask one to start a transaction with amount higher than its balance. Then we check the two nodes' transaction pools and the next mined block.

(3) If correct, the transaction will fail. Nodes' balances will not change. And it will not appear in either any node's transaction pool or the next block.

**3. Two nodes are transacting to one node at the same time**

(1)  This is for testing the case that two (or more) nodes are transacting at the same time to the same destination node.

(2) We start three nodes and ask two of them to start transactions to the other one at the same time. Then we check the their transaction pools and the next mined block.

(3) If correct, it should be like normal transactions arriving one by one.

**4. Someone tries to declare a fake transaction**

(1)  This is for testing the case that some node want to declare and broadcast that it does a transaction but it actually did not. 

(2)  We start three nodes and ask one of them to declare a fake transaction. Then we check transaction pools of the other two nodes and the next mined block. 

(3) If correct, the other two nodes should reject this transaction because the verifying process will fail. So it will not appear in pools and the next block.

**5. Mining a block normally**

(1) This is for testing mining in normal case.

(2) We start two nodes and ask one of them to start a transaction to another one. Then we check the block chain after one block is mined.

(3) If correct, the next block will contain this transaction and be linked to tail of blockchain.

**6. Someone tries to declare mining a fake block**

(1)  This is for testing the case that some node want to declare and broadcast that it mined a block but it actually did not. 

(2)  We start three nodes and ask one of them to declare a fake block. Then we check the next mined block. 

(3) If correct, the other two nodes should reject this block because the verifying process will fail. So it will not appear on block chain.





 

