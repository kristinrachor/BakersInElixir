defmodule Customer do
	def makeCustomers(numberOfCus, manager, list) do
		addToList(list, numberOfCus, manager)		
	end


	def addToList(list, n, manager) when n <= 1 do
    	list = [spawn(Customer, :customer, [n, manager]) | list]
  	end


 	def addToList(list, n, manager) do
		list = [spawn(Customer, :customer, [n, manager]) | list]
    		addToList(list, n - 1, manager)
  	end
	
	def customer(customerName, manager) do
		:random.seed(:erlang.now)
		sleepTime = :random.uniform(10000)
		:timer.sleep(sleepTime)
		send(manager, {:awake, self()})
		loop()
	end

	def loop() do
		receive do
			#management sends the servers name to customer that they got paired with
			{:talkTo, serverName, fibNumber, manager} -> IO.puts("Server #{inspect serverName} is helping customer #{inspect self()} with fib number #{fibNumber}")
								send(serverName, {:fib, fibNumber, self(), manager})
			#server sends the result to the customer
			{:result, answer, manager, server} -> IO.puts("answer: #{answer}")
									send(manager, {:ready, server})
		end
		loop()
	end
end



defmodule Management do 
	def makeAManager do
		line = []
		availableServers = []
		manage(line, availableServers)
	end

	def addToLine(line, customer, availableServers, manager) do
		line = [customer|line]
		if(Enum.count(line) !== 0 and Enum.count(availableServers) !== 0) do
			pair(List.last(line), List.last(availableServers), manager)
			line = List.delete_at(line, -1)
			availableServers = List.delete_at(availableServers, -1)
		end
		manage(line, availableServers)
	end

	def addToAvailableServers(line, server, availableServers, manager) do
		availableServers = [server|availableServers]
		if(Enum.count(line) !== 0 and Enum.count(availableServers) !== 0) do
			pair(List.last(line), List.last(availableServers), manager)
			line = List.delete_at(line, -1)
			availableServers = List.delete_at(availableServers, -1)
		end
		manage(line, availableServers)
	end

	def pair(customer, server, manager) do
		:random.seed(:erlang.now)
		fibNumber = :random.uniform(35)
		send(customer, {:talkTo, server, fibNumber, manager})
	end


	def manage(line, availableServers) do
		receive do
			#customer tells management that they are awake and want to be in line
			{:awake, customer_pid} -> addToLine(line, customer_pid, availableServers, self())
								
		
			#Server tells management that they are ready to help someone
			{:ready, server_pid} -> addToAvailableServers(line, server_pid, availableServers, self())
								
								
		end

	end
end



defmodule Server do 

	def makeServers(numberOfServers, manager, list) do
		addToList(list, numberOfServers, manager)		
	end

	def addToList(list, n, manager) when n <= 1 do
    		list = [spawn(Server, :server, [n, manager]) | list]
  	end

 	def addToList(list, n, manager) do
		list = [spawn(Server, :server, [n, manager]) | list]
    	addToList(list, n - 1, manager)
  	end

  	def fib(0) do 0 end
  	def fib(1) do 1 end
  	def fib(n) do fib(n-1) + fib(n-2) end

	def server(serverName , manager) do
		send(manager, {:ready, self()})
		loop
	end
	
	def loop do 
		receive do
			#customer sends server the number they want fibbed
			{:fib, number, pairedCustomer, manager} -> send(pairedCustomer, {:result, fib(number), manager, self()})
		end
		loop
	end
end



defmodule Starter do
	def start(numberOfCus, numberOfServers) do
		customers = []
		servers = []
		manager = spawn(Management, :makeAManager, [])
		servers = Server.makeServers(numberOfServers, manager, servers)
		customers = Customer.makeCustomers(numberOfCus, manager, customers)
	end
 end

