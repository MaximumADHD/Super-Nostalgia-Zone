local safeChatTree = 
{
	Label = "ROOT";
	Branches = {};
}

do
	local treeData = script:WaitForChild("RawTreeData")
	local str = treeData.Value
	
	local stack = {}
	stack[0] = safeChatTree
	
	for line in str:gmatch("[^\n]+") do
		if #line > 0 then
			local stackIndex = 0

			while line:sub(1, 1) == "\t" do
				stackIndex = stackIndex + 1
				line = line:sub(2)
			end
			
			local tree = stack[stackIndex]
			assert(tree, "Bad safechat tree setup at depth " .. stackIndex .. ": " .. line)
			
			local branch = 
			{
				Label = line,
				Branches = {}
			}
			
			table.insert(tree.Branches, branch)
			stack[stackIndex + 1] = branch
		end
	end
end

return safeChatTree