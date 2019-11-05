local safeChatTree = 
{
	Label = "ROOT";
	Branches = {};
}

do
	local mTreeData = script:WaitForChild("RawTreeData")
	local treeData = require(mTreeData)
	
	local stack = {}
	stack[0] = safeChatTree
	
	for line in treeData:gmatch("[^\n]+") do
		if #line > 0 then
			local stackIndex = 0
			while line:sub(1,1) == "\t" do
				stackIndex = stackIndex + 1
				line = line:sub(2)
			end
			
			local tree = stack[stackIndex]
			assert(tree,"Bad safechat tree setup at depth " .. stackIndex .. ": " .. line)
			
			local branch = {}
			branch.Label = line
			branch.Branches = {}
			table.insert(tree.Branches,branch)
			
			stack[stackIndex+1] = branch
		end
	end
end

return safeChatTree