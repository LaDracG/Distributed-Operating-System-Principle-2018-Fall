defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  plug Plug.Parsers, parsers: [:urlencoded, :json],
                   pass: ["text/*"],
                   json_decoder: Jason

  def index(conn, _params) do
    #Hello.Repo.delete_all(Hello.Balance)
    all_balance_rec = Hello.Balance |> Hello.Repo.all
    balance_list = Enum.sort(depackage(all_balance_rec, [], "balance"))
    all_transaction_rec = Hello.Transaction |> Hello.Repo.all
    transaction_list = depackage(all_transaction_rec, [], "transaction")
    Hello.Repo.delete_all(Hello.Transaction)
    pid_string = ""
    balance_string = ""
    sender_string = ""
    receiver_string = ""
    amount_string = ""
    pid_string =
      for {pid, amount} <- balance_list do
        pid_string = pid_string <> pid <> " "
      end
    balance_string = 
      for {pid, amount} <- balance_list do
        balance_string = balance_string <> amount <> " "
      end
    sender_string = 
      for {sender, receiver, amount} <- transaction_list do
        sender_string = sender_string <> sender <> " "
      end
    receiver_string = 
      for {sender, receiver, amount} <- transaction_list do
        receiver_string = receiver_string <> receiver <> " "
      end
    amount_string = 
      for {sender, receiver, amount} <- transaction_list do
        amount_string = amount_string <> amount <> " "
      end
    IO.puts pid_string
    #IO.puts inspect transaction_list
    render(conn, "index.html", n_nodes: length(balance_list), pids: pid_string, balances: balance_string, senders: sender_string, receivers: receiver_string, amounts: amount_string)
    #render(conn, "test.html")
  end

  def renew(conn, _params) do
    msg = conn.params["msg"]
    #IO.puts inspect conn.params["amount"]
    if msg == "balance" do
        pid = conn.params["pid"]
        amount = conn.params["amount"] / 1
        Hello.Repo.insert!(%Hello.Balance{pid: pid, amount: amount |> Float.round(2)}, on_conflict: :replace_all, conflict_target: :pid)
    else
        sender = conn.params["sender"]
        receiver = conn.params["receiver"]
        amount = conn.params["amount"]
        Hello.Repo.insert!(%Hello.Transaction{sender: sender, receiver: receiver, amount: amount |> Float.round(2)})
    end
    render(conn, "new.html")
  end
  
  def depackage(rec_list, target_list, mode) do
    if Enum.empty?(rec_list) do
      target_list
    else
      [first | rest] = rec_list
      if mode == "balance" do
        depackage(rest, target_list ++ [{first.pid, inspect(first.amount)}], mode)
      else # "transaction"
        depackage(rest, target_list ++ [{first.sender, first.receiver, inspect(first.amount)}], mode)
      end
    end
  end


  '''
  def show(conn, %{"messenger" => messenger}) do
    #Hello.Repo.delete_all(Hello.Balance)
    all_rec = Hello.Balance |> Hello.Repo.all
    {pid_list, balance_list} = depackage(all_rec, [], [])
    IO.puts inspect balance_list
    render(conn, "show.html", messenger: Enum.at(balance_list, 0), pids: pid_list, balances: balance_list)
    #render(conn, "show.html", messenger: messenger)
  end
  '''
  
end