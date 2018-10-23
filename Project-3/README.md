# Project3

## Team Members
Yifan Wang, Jingyang Guo

## Descriptions
We successfully simulated the main functions of a Chord protocol by implementing Node, Algorithm and Manager modules.

The manager deals with the basic mission process, which is to extract the num_nodes, num_requests parameters and start initializing the Chord ring, requesting and counting the hops.

Each node is a separate actor who maintains its attributes (i.e. successor, predecesor, finger table...) with GenServer, dealing with requests and report hops to the manager.

The module Algorithm manages the request process, implementing the find_processor function with the help of finger table according to the paper's API: keep finding the closest preceding node of target key in the finger table, until reaching a node whose immediate succesor is target's succesor. A "logic larger" function is to manage the problem of "overlapping".

Some details are not identical with what the paper illustrated, we focused a bit more on the application itself. However, main ideas are implemented according to the paper API.

The largest network we managed to deal with is 1000 nodes scale, with each node sending 20 requests.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project_3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project_3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project_3](https://hexdocs.pm/project_3).

