defmodule HelloWorld do
  # https://whatdidilearn.info/2017/12/17/elixir-multiple-processes-basics.html
  def hello do
    # receive is used for listening to messages
    # send is used to send messages, first arg is the destination, in this case the process identifier that was received.
    # the second arg is the message, it can be any type, but best practice is a tuple, so this can be pattern matched against.
    receive do
      {pid, name} ->
        send(pid, {:ok, "Hello, #{name}!"})
        # if we want our hello function to listen to multiple messages, we use recursion.
        # once a message is received, we call the hello function again.
        hello()
    end
  end
end

# Elixir Processes
# ```
# defmodule HelloWorld do
#   def hello do
#     IO.puts("Hello, world!")
#   end
# end

# ```

# Here with have a function that prints hello world.
# ```
# iex(2)> c "hello_world.ex"
# [HelloWorld]
# iex(3)> HelloWorld.hello
# Hello, world!
# :ok
# ```

# Let’s run this in a process

# ## Spawning processes
# Kernel.spawn/1 or spawn/3

# Spawn/1 -> takes an anonymous function
# ```
# iex(5)> spawn(fn -> HelloWorld.hello end)
# Hello, world!
# #PID<0.115.0>
# ```

# Spawn/3 -> takes the module, the function name (as an atom), function args (in a [])
# ```
# iex(4)> spawn(HelloWorld, :hello, [])
# Hello, world!
# #PID<0.113.0>
# ```

# These processes can send messages back and forth between each other.

# First we need to update the function to listen for messages.

# ```
# defmodule HelloWorld do
#   def hello do
#     receive do
#       {pid, name} -> send(pid, {:ok, "Hello, #{name}!"})
#     end
#   end
# end
# ```

# ```
# iex(2)> pid = spawn(HelloWorld, :hello, [])
# #PID<0.110.0>
# # Here we are spawning a process and saving the process id.
# iex(3)> send(pid, {self(), "message"}
# ...(3)> )
# {#PID<0.103.0>, "message"}
# # Here we are sending a message to that process using the pid,  and a name. In our case calling process isiex, so we pass PID ofiexsession.

# iex(4)> receive do
# ...(4)> {:ok, msg} -> msg
# ...(4)> end
# "Hello, message!"

# Now as soon as HelloWorld.hello/0sent us the message back, all we need to do is to receive that message. And we did.
# ```

# If we try send a second message and try to receive it, we get no response as once we send a message for the first time HelloWorld.hello/0 receives it and the exits. So there is nothing there to respond.

# ```
# iex(5)> send(pid, {self(), "second message"}
# ...(5)> )
# {#PID<0.103.0>, "second message"}
# iex(6)> receive do
# ...(6)> {:ok, msg} -> msg
# ...(6)> end
# ```

# We can fix this up by setting a time out, so it doesn’t just sit there.

# ```
# iex(2)> pid = spawn(HelloWorld, :hello, [])
# #PID<0.110.0>
# iex(3)> send(pid, {self(), "first message"})
# {#PID<0.103.0>, "first message"}
# iex(4)> receive do
# ...(4)> {:ok, msg} -> msg
# ...(4)> end
# "Hello, first message!"
# iex(5)> send(pid, {self(), "second message"})
# {#PID<0.103.0>, "second message"}
# iex(6)> receive do
# ...(6)> {:ok, msg} -> msg
# ...(6)> after 1_000 -> "Time is up!"
# ...(6)> end
# "Time is up!"
# iex(7)>
# ```

# But what if we want our hello function to listen to multiple messages.
# We use recursion, but calling hello() after a message has been received.

# ```
#   def hello do
#     receive do
#       {pid, name} ->
#         send(pid, {:ok, "Hello, #{name}!"})

#         hello()
#     end
#   end
# ```

# ```
# iex(2)> pid = spawn(HelloWorld, :hello, [])
# #PID<0.110.0>
# iex(3)> send(pid, {self(), "first message"})
# {#PID<0.103.0>, "first message"}
# iex(4)> receive do
# ...(4)> {:ok, msg} -> msg
# ...(4)> end
# "Hello, first message!"
# iex(5)> send(pid, {self(), "second message"})
# {#PID<0.103.0>, "second message"}
# iex(6)> receive do
# ...(6)> {:ok, msg} -> msg
# ...(6)> end
# "Hello, second message!"
# iex(7)> send(pid, {self(), "second message"})
# {#PID<0.103.0>, "second message"}
# iex(8)> receive do
# ...(8)> {:ok, msg} -> msg
# ...(8)> end
# "Hello, second message!"
# iex(9)> send(pid, {self(), "third message"})
# {#PID<0.103.0>, "third message"}
# iex(10)> receive do
# ...(10)> {:ok, msg} -> msg
# ...(10)> end
# "Hello, third message!"
# ```

# LINKING PROCESSES
# Here we are breaking our process by send an anonymous function, to the hello function. As it doesn’t expect this as an argument it will break.

# ```
# iex(11)> self
# #PID<0.103.0>
# iex(12)> pid = spawn(HelloWorld, :hello, [])
# #PID<0.129.0>
# iex(13)> send(pid, {self, fn -> "Error" end})
# {#PID<0.103.0>, #Function<20.128620087/0 in :erl_eval.expr/5>}
# iex(14)>
# 12:57:29.961 [error] Process #PID<0.129.0> raised an exception
# ** (Protocol.UndefinedError) protocol String.Chars not implemented for #Function<20.128620087/0 in :erl_eval.expr/5>
#     (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
#     (elixir) lib/string/chars.ex:22: String.Chars.to_string/1
#     hello_world.ex:9: HelloWorld.hello/0

# Here the process breaks as a result of sending it an anonymous  function.

# Then we try send the process another message, and see that we don't get a response.

# iex(16)> send(pid, {self, "Not an error"})
# {#PID<0.103.0>, "Not an error"}
# iex(17)> receive do
# ...(17)> {:ok, msg} -> msg
# ...(17)> after 1_000 -> "No response"
# ...(17)> end
# "No response"
# iex(18)> self
# #PID<0.103.0>

# Here we can see that we are still in the same parent process.
# ```

# If want processes to know about each others problems we can link them using spawn_link.

# ```
# iex(2)> self
# #PID<0.103.0>
# iex(3)> pid = spawn_link(HelloWorld, :hello, [])
# #PID<0.111.0>
# iex(4)> send(pid, {self, fn -> "Error" end})
# ** (EXIT from #PID<0.103.0>) shell process exited with reason: an exception was raised:
#     ** (Protocol.UndefinedError) protocol String.Chars not implemented for #Function<20.128620087/0 in :erl_eval.expr/5>
#         (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
#         (elixir) lib/string/chars.ex:22: String.Chars.to_string/1
#         hello_world.ex:9: HelloWorld.hello/0

# Interactive Elixir (1.8.1) - press Ctrl+C to exit (type h() ENTER for help)
# iex(1)>
# 13:06:25.448 [error] Process #PID<0.111.0> raised an exception
# ** (Protocol.UndefinedError) protocol String.Chars not implemented for #Function<20.128620087/0 in :erl_eval.expr/5>
#     (elixir) lib/string/chars.ex:3: String.Chars.impl_for!/1
#     (elixir) lib/string/chars.ex:22: String.Chars.to_string/1
#     hello_world.ex:9: HelloWorld.hello/0
# iex(2)> self
# #PID<0.113.0>
# iex(3)> pid
# ** (CompileError) iex:3: undefined function pid/0
# ```

# This time once we make our process crash we can see that the linked parent process was restarted (you can see it by the different PID) and all the process has been started over.
