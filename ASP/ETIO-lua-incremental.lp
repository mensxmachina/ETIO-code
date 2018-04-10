#script(lua)

local Fun = gringo.Fun
local Control = gringo.Control
local SolveResult = gringo.SolveResult

local condsets = {size = 0}
local contexts = {}

-- http://stackoverflow.com/questions/19262761/lua-need-to-split-at-comma
function string:split(inSplitPattern, keepempty)
	local outResults = {}
	local theStart = 1
	local theSplitStart, theSplitEnd = self:find(inSplitPattern, theStart )
	while theSplitStart do
		local s = self:sub(theStart, theSplitStart-1)
		if(keepempty or s ~= "") then
			table.insert(outResults, self:sub(theStart, theSplitStart-1 ) )
		end
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = self:find(inSplitPattern, theStart )
	end
	local s = self:sub(theStart)
	if(keepempty or s ~= "") then
		table.insert(outResults, self:sub(theStart))
	end
	return outResults
end

-- http://stackoverflow.com/questions/22831701/lua-read-beginning-of-a-string
function string:starts(prefix)
   return self:sub(1,prefix:len())==prefix
end

-- http://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua
local function read_lines(file)
	local l = {}
	for line in io.lines(file) do 
		l[#l + 1] = line:gsub("%s", "")
	end
	return l
end

local function parse_lines(l)
	local tokey = function(x)
		local y = {}
		for _, j in pairs(x) do
			y[#y + 1] = j
		end
		table.sort(y)
		
		local key = {}
		for i = 1, #y do
			key[#key+1] = tostring(y[i])
		end
		return table.concat(key," ")
	end

	local ndatasets = 0
	local nconstraints = 0
	
	local problem = {allowselection = false, allowmanipulations = false, allowlatent = false}
	local constraints = {type = {}, x = {}, y = {}, z = {}, dataset = {}, key = {}, weight = {}}
	local datasets = {}
	local output = {
		arrow = false, notarrow = false, latent = false, notlatent = false, connected = false, notconnected = false, 
		ancestor = false, notancestor = false, selected = false, notselected = false, manipulated = false, notmanipulated = false
	}
	
	local stringtoboolean = {}
	stringtoboolean["false"] = false
	stringtoboolean["true"] = true
	
	for i = 1, #l do
		local s = l[i]:split(";", true)
		if(s[1] == "constraint") then
			nconstraints = nconstraints + 1
			constraints.type[nconstraints] = s[2]
			constraints.x[nconstraints] = tonumber(s[3])
			constraints.y[nconstraints] = tonumber(s[4])
			constraints.dataset[nconstraints] = tonumber(s[6])
			constraints.weight[nconstraints] = tonumber(s[7])
			local z = {}
			for _, x in pairs(s[5]:split(",",true)) do
				local i = tonumber(x)
				if(i ~= nil) then
					z[#z + 1] = i
				end
			end
			constraints.z[nconstraints] = z
			constraints.key[nconstraints] = tokey(z)
		elseif(s[1] == "dataset") then
			ndatasets = ndatasets + 1
			datasets[ndatasets] = {}

			-- Selected
			datasets[ndatasets].selected = {}
			for _, x in pairs(s[2]:split(",",true)) do
				local y = x:split(":",true)
				local bool = stringtoboolean[y[2]]
				if(bool ~= nil) then datasets[ndatasets].selected[tonumber(y[1])] = bool end
			end
						
			-- Manipulated
			datasets[ndatasets].manipulated = {}
			for _, x in pairs(s[3]:split(",",true)) do
				local y = x:split(":",true)
				local bool = stringtoboolean[y[2]]
				if(bool ~= nil) then datasets[ndatasets].manipulated[tonumber(y[1])] = bool end				
			end				
		elseif(s[1] == "output") then
			output[s[2]] = true
		else
			if(s[2] == "true") then
				problem[s[1]] = true
			elseif(s[2] == "false") then
				problem[s[1]] = false
			else
				problem[s[1]] = tonumber(s[2])
			end
		end
	end
	if(not problem.allowselection) then
		output.selected, output.notselected = false, false
	end
	if(not problem.allowmanipulations) then
		output.manipulated, output.notmanipulated = false, false
	end
	if(not problem.allowlatent) then
		output.latent, output.notlatent = false, false
	end
	problem.nconstraints = nconstraints
	problem.datasets = datasets
	problem.constraints = constraints
	problem.output = output
	return problem
end

local function ground(prg, fun, value)
    prg:ground({{fun, value}})
end

local function addContext(prg, condset, dataset)
	local t = contexts[dataset]
	if(t == nil) then
		contexts[dataset] = {}
		t = contexts[dataset]
	end
	
    if(t[condset] == nil) then
		t[condset] = 1
		local value = {condset, dataset}
        ground(prg, "fun_context", value)
        prg:assign_external(Fun("context", value), true)
    else
		t[condset] = t[condset] + 1
	end
end

local function addDatasetConstraints(prg, problem)
	local datasets = problem.datasets

	if(problem.allowlatent) then 
		ground(prg, "fun_latent", {}) 
	end
	if(problem.allowselection) then 
		for i = 1, #datasets do
			ground(prg, "fun_selected", {i}) 
			for var, val in pairs(datasets[i].selected) do
				if(val == true) then ground(prg, "in_selected", {var, i}) else ground(prg, "in_notselected", {var, i}) end
			end
		end
	end
	if(problem.allowmanipulations) then 
		for i = 1, #datasets do
			ground(prg, "fun_manipulated", {i}) 
			for var, val in pairs(datasets[i].manipulated) do
				if(val == true) then ground(prg, "in_manipulated", {var, i}) else ground(prg, "in_notmanipulated", {var, i}) end
			end
		end
	end
end

local function addSets(prg, problem)
	local addSet = function(prg, key, inside, nodes)
		if(condsets[key] == nil) then
			condsets.size = condsets.size + 1
			local s = condsets.size
			condsets[key] = s
			for _, i in ipairs(inside) do
				ground(prg, "fun_inside", {i, s})
			end
		end
	end
	
	local nodes = problem.nodes
	addSet(prg, "", {}, nodes)

	local constraints = problem.constraints
	local key = constraints.key
	local z = constraints.z
	for i = 1, problem.nconstraints do
		addSet(prg, key[i], z[i], nodes)
	end
end

local function checkConstraints(prg, problem, options)
	local check = function(prg, type, x, y, z, d)
		local value = {x, y, z, d}
		local fun = Fun(type, value)
		
		addContext(prg, z, d)
		ground(prg,"fun_" .. type, value)
		prg:assign_external(fun, true)	

		if(prg:solve() == SolveResult.UNSAT) then
			prg:release_external(fun)
		end
	end
	
	local constraints = problem.constraints
	local x = constraints.x
	local y = constraints.y
	local z = constraints.z
	local key = constraints.key
	local dataset = constraints.dataset
	local type = constraints.type

	for i = 1, problem.nconstraints do
		if(i % 100 == 0) then
			print('#' .. i .. '/' .. problem.nconstraints)-- .. ' ' .. x[i] .. ' ' .. y[i] .. ' ' .. key[i] .. ' ' .. dataset[i])
			io.stdout:flush()
		end
		if(x[i] < y[i]) then
			check(prg, type[i], x[i], y[i], condsets[key[i]], dataset[i])
		else
			check(prg, type[i], y[i], x[i], condsets[key[i]], dataset[i])
		end
	end
end

local function configure(prg, models, mode)
    prg.conf.solve.models = models
    prg.conf.solve.enum_mode = mode
    prg.conf.asp.trans_ext = "all"
    prg.conf.configuration = "auto" 
	-- Depending on the problem, different configurations may work better.
	-- Other options are: auto, frumpy, jumpy, tweety, handy, crafty, trendy, many
		-- auto  : Select configuration based on problem type
		-- frumpy: Use conservative defaults
		-- jumpy : Use aggressive defaults
		-- tweety: Use defaults geared towards asp problems
		-- handy : Use defaults geared towards large problems
		-- crafty: Use defaults geared towards crafted problems
		-- trendy: Use defaults geared towards industrial problems
		-- many  : Use default portfolio to configure solver(s)
end

function main(prg)
	local inputfile = tostring(prg:get_const("input"))
	local outputfile = tostring(prg:get_const("output"))
	if(outputfile == nil) then
		outputfile = inputfile .. "_out"
	end
	
	local problem = parse_lines(read_lines(inputfile))

	-- Initializing the main program
    configure(prg, 1, "bt")
    ground(prg, "init", {problem.nodes, #problem.datasets})
	
	-- Adding constraints about the datasets (i.e., if latent variables, selection bias and manipulated variables are allowed or not)
	addDatasetConstraints(prg, problem)
	
	-- Adding all conditioning sets
	addSets(prg, problem)

	-- Adding input constraints incrementally and checking them
	checkConstraints(prg, problem, {k = 0, solve_limit = "25,25", batch = 1})

	-- Making final inferences using all consistent input constraints and collecting results
	configure(prg, 0, "cautious")
	local results = {}
	local function on_model_final(model)
		results = {}
		for _, x in pairs(model:atoms(model.ATOMS)) do
			local s = tostring(x)
			local key = s:split("[0-9(),.]", true)[1]
			local ij = s:split("[^0-9]", false)

			if(key:starts("not")) then
				results[#results+1] = key:sub(4) .. " " .. ij[1] .. " " .. ij[2] .. " 0\n"
			else
				results[#results+1] = key .. " " .. ij[1] .. " " .. ij[2] .. " 1\n"
			end
		end
	end	
	prg:solve({}, on_model_final)

	-- Writing results to file
	-- The output format is of the type "relation_name x y boolean_value". 
	-- Examples include "arrow x y 1", indicating that x->y is present or "latent x y 0" indicating that there is no latent confounder between x and y.
	local file = io.open(outputfile, "w")
	for _, x in ipairs(results) do
		file:write(x)
	end
	file:close()
end
#end.