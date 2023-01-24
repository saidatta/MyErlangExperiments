-module(chat_server).
-export([start/0, stop/0]).

start() ->
    {ok, ListenSocket} = gen_tcp:listen(4444, [binary, {packet, 0}, {active, false}, {reuseaddr, true}]),
    register(chat_server, spawn(fun() -> accept_loop(ListenSocket) end)).

accept_loop(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
    spawn(fun() -> handle_client(Socket) end),
    accept_loop(ListenSocket).

handle_client(Socket) ->
    {ok, ClientName} = gen_tcp:recv(Socket, 0),
    register(ClientName, spawn(fun() -> client_loop(Socket, ClientName) end)),
    broadcast(ClientName ++ " has joined the chat"),
    client_loop(Socket, ClientName).

client_loop(Socket, ClientName) ->
    receive
        {tcp, Socket, Message} ->
            broadcast(ClientName ++ ": " ++ Message),
            client_loop(Socket, ClientName);
        {'EXIT', _, _} ->
            broadcast(ClientName ++ " has left the chat"),
            gen_tcp:close(Socket)
    end.

broadcast(Message) ->
    [gen_tcp:send(whereis(Client), Message) || Client <- registered()].

stop() ->
    gen_tcp:close(whereis(chat_server)),
    [gen_tcp:close(whereis(Client)) || Client <- registered()].
