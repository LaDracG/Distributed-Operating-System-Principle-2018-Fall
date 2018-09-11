# Notes of DOS

## About Elixir

### 1. Returning values 

**(1) Function**

Elixir has no keyword "return". It regards value of the last expression in a function as its returning value. 

```elixir
def addOne(arg) do
	arg + 1
end
```

**(2) Block**

In Elixir, a block (do .. end) also has returning value. It is the same case as a function, which means the returning value of a block is value of the last expression in this block.

So this code is correct, you will assign value of var "ans" correctly.

**Note:** This is a common way to assign or change values of existing variables according to different cases, though it seems strange. We will explain it later in this article.

```elixir
ans = 
	if list == [nil] do
		IO.puts XXXX
		ans # the last expression in the first case
	else
		IO.puts XXXX
		ans ++ list # the last expression in the second case
	end  

```

But this code is wrong because the last expression is not the value to be assigned to "ans". This will cause "ans" to become nil.

```elixir
# returning value of this block would be the value of "IO.puts XXXX" instead of what we want.
ans = 
	if list == [nil] do
		ans
		IO.puts XXXX 
	else
		ans ++ list
		IO.puts XXXX
	end  
```

### 2. Rebinding of variables



### 3. Module attributes

constant instead of state variables

### 4. State memorization

pass current state as arguments into next function call instead of using global state variable

### [Important] Distributed applications in Elixir

(1) If A connecting to B, and now A go to connect to C, then B and C will be connected to each other automatically.

That is, at first, A \<-\> B. Now we connect A and C (A \<-\> C). Then B and C will be connected by Elixir itself. Finally, after connecting A and B and connecting A and C, we have A, B, C connected to each other.

(2) As long as two nodes establish connection, they can be treated as in one computer.

For example, if A \<-\> B, and there is a process a on A, process b on B. If we want send msg from a to b, a just needs to use send(dst, {....}), where dst is pid of process b. That is, no need to know node identifier when sending msg between processes of different nodes. Node identifiers are only necessary when doing Node.XXX. Once we establish the connection between two nodes, they will act as they are one. The case "They are two nodes" is transparent at this time. You can only see processes and no need to care about nodes.

(3) After establishing connection between nodes, no matter on which node you currently are, you can use :global to get info about any one of the nodes and any process on those nodes.

(4) Node and Process are different abstracts. Process is more high-level. When we connect, disconnect and so on, we care about Node. When we do some computing tasks, send msg and so on, we care about Process and forget Node.

(5) :global.sync()

(6) Make work unit larger when using remote nodes since the bottleneck is networking communication speed now. So we should pass more data in each transporting.

