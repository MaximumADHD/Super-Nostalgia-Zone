local LinkedList = {}
LinkedList.__index = LinkedList

function LinkedList:Add(data)
	local node = {}
	node.data = data
	node.id = tostring(node):sub(8)

	local back = self.back
	if back then
		back.next = node
		node.prev = back
	end
	
	if not self.front then
		self.front = node
	end
	
	self.back = node
	self.size = self.size + 1
	
	self.nodes[node.id] = node
	self.lookup[data] = node

	return node.id
end

function LinkedList:Get(id)
	local node = self.nodes[id]
	if node then
		return node.data
	end
end

function LinkedList:Remove(id)
	local node = self.nodes[id]
	
	if node then
		if node.prev then
			node.prev.next = node.next
		end
		
		if node.next then
			node.next.prev = node.prev
		end
		
		if node == self.front then
			self.front = node.next
		end
		
		if node == self.back then
			self.back = node.prev
		end
		
		if node.data then
			node.data = nil
		end
		
		self.size = self.size - 1
	end
end

function LinkedList:GetEnumerator()
	return coroutine.wrap(function ()
		local node = self.front
		while node ~= nil do
			coroutine.yield(node.id, node.data)
			node = node.next
		end
	end)
end

function LinkedList.new()
	local list = 
	{
		nodes = {};
		lookup = {};
		size = 0;
	}

	return setmetatable(list, LinkedList)
end

return LinkedList