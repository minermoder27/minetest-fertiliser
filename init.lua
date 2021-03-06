fertiliser = {}

fertiliser.grows = {
	stdtree = function(pos, def)
		if farming~=nil and farming.generate_tree~=nil then
			farming.generate_tree(pos, def[4][1], def[4][2], def[4][3], def[4][4])
        end
	end,
	jungletree = function(pos, def)
--		farming:generate_tree(pos, def[4][1], def[4][2], def[4][3], def[4][4])
		local nu = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name
        local is_soil = minetest.get_item_group(nu, "soil")
        if is_soil == 0 then
                return
        end
        
		print("[fertiliser] spawned "..node.name.." tree")
        local vm = minetest.get_voxel_manip()
        local minp, maxp = vm:read_from_map({x=pos.x-16, y=pos.y, z=pos.z-16}, {x=pos.x+16, y=pos.y+16, z=pos.z+16})
        local a = VoxelArea:new{MinEdge=minp, MaxEdge=maxp}
        local data = vm:get_data()
        default.grow_jungletree(data, a, pos, math.random(1,100000))
        vm:set_data(data)
        vm:write_to_map(data)
        vm:update_map()
	end,
	call_abm = function(pos, def)
		if def.abm == nil then -- don't look for a abm more than once
			def.abm = false -- a value, in case we don't find anything
			local nodename = def[1]
			
			for _, abm in ipairs(minetest.registered_abms) do -- check each abm
				print(dump(abm))
				if #abm.nodenames == 1 then -- if there is only one node, save time
					if abm.nodenames[1] == nodename then
						def.abm = abm.action
					end
				elseif type(abm.nodenames) == "string" then -- another way to define a abm
					if abm.nodenames == nodename then
						def.abm = abm.action
					end
				else -- otherwise, check each node.
					for _, node in ipairs(abm.nodenames) do
						if node == nodename then
							def.abm = i.action
						end
					end
				end
			end
		end
		
		-- if we have a abm, run it
		if def.abm ~= false then
			def.abm(pos, minetest.get_node(pos), 0, 0)
			return true
		end
		return false
	end,
	clone = function(pos, def)
		local node = minetest.get_node(pos)
		
		while minetest.get_node(pos).name == node.name do
			pos.y = pos.y + 1
		end
		
		if minetest.get_node(pos).name=="air" then
			minetest.set_node(pos, node)
			return true
		end
		return false
	end,
}
fertiliser.saplings = {
	{
		"default:sapling",  --  name
		5,					--  chance
		fertiliser.grows.stdtree,
		{
			"default:tree",
			"default:leaves",
			{"default:dirt", "default:dirt_with_grass"},
			{},
		},
	},
	{
		"default:pine_sapling",  --  name
		5,					--  chance
		fertiliser.grows.stdtree,
		{
			"default:pinetree",
			"default:pine_needles",
			{"default:dirt", "default:dirt_with_grass"},
			{},
		},
	},
	{
		"farming_plus:banana_sapling",
		5,
		fertiliser.grows.stdtree,
		{
			"default:tree",
			"farming_plus:banana_leaves",
			{"default:dirt", "default:dirt_with_grass"},
			{["farming_plus:banana"]=20},
		},
	},
	{
		"farming_plus:cocoa_sapling",
		5,
		fertiliser.grows.stdtree,
		{
			"default:tree",
			"farming_plus:cocoa_leaves",
			{"default:sand", "default:desert_sand"},
			{["farming_plus:cocoa"]=20},
		},
	},
	{
		"default:cactus",
		1,
		fertiliser.grows.clone,
	},
	{
		"default:papyrus",
		1,
		fertiliser.grows.clone,
	},
}

minetest.after(0, function()
	if moretrees ~= nil and moretrees.treelist ~= nil then
		for tree in ipairs(moretrees.treelist) do
			local sapling = "moretrees:" .. moretrees.treelist[tree][1] .. "_sapling"
			fertiliser.saplings[#fertiliser.saplings + 1] = {
				sapling,
				1,
				fertiliser.grows.call_abm,
			}
		end
	end
	
	local register = function(val)
		for i = 1, #val.names do
			local name = val.names[i]
			fertiliser.saplings[#fertiliser.saplings + 1] = {
				name,
				1,
				function(pos, def)
					minetest.set_node(pos, {name = (val.names[i+1] or val.full_grown)})
				end,
			}
		end
	end
	
	if farming.registered_plants~=nil then
		for _, val in ipairs(farming.registered_plants) do
			register(val)
		end
	end
	
	local names = {"farming:wheat_1",
					"farming:wheat_2",
					"farming:wheat_3",
					"farming:wheat_4",
					"farming:wheat_5",
					"farming:wheat_6",
					"farming:wheat_7"}
	
	register( {
		full_grown = "farming:wheat_8",
		names = names
	})
	
	names = {		"farming:cotton_1",
					"farming:cotton_2",
					"farming:cotton_3",
					"farming:cotton_4",
					"farming:cotton_5",
					"farming:cotton_6",
					"farming:cotton_7"}
	
	register( {
		full_grown = "farming:cotton_8",
		names = names
	})
end)

minetest.register_craftitem("fertiliser:fertiliser", {
	description = "Fertiliser",
	inventory_image = "fertiliser_fertiliser.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type=="node" then
			local pos = pointed_thing.under
			local node = minetest.get_node(pos)
			for i=1, #fertiliser.saplings do
				local def = fertiliser.saplings[i]
				if node.name==def[1] then
					local res
					if math.random(def[2])==1 then
						res = def[3](pos, def)
					end
					if res~=false then itemstack:take_item() end
				end
			end
		end
		return itemstack
	end,
})

minetest.register_craft({
    output = 'fertiliser:fertiliser 9',
    recipe = {
        {'default:dirt',	'default:dirt',			'default:dirt'},
        {'default:dirt',	'bones:single_bone',	'default:dirt'},
        {'default:dirt',	'default:dirt',			'default:dirt'},
    },
})

minetest.register_craft({
    output = 'fertiliser:fertiliser 5',
    recipe = {
        {'',            'group:leaves',                  ''},
        {'group:leaves',   'default:apple',      'group:leaves'},
        {'default:dirt',   'default:dirt',         'default:dirt'},
    },
})

minetest.register_craft({
    output = 'bones:bones',
    recipe = {
        {'bones:single_bone', 'bones:single_bone', 'bones:single_bone'},
        {'bones:single_bone', 'bones:single_bone', 'bones:single_bone'},
        {'bones:single_bone', 'bones:single_bone', 'bones:single_bone'},
    },
})

minetest.register_craft({
	type = 'shapeless',
    output = 'bones:single_bone 9',
    recipe = {'bones:bones'},
})

minetest.register_craftitem(":bones:single_bone", {
	description = "Single Bone",
	inventory_image = "fertiliser_bone.png",
})

print("[Fertiliser] Loaded.")
