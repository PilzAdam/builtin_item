local function get_nodes(pos)
	local tab,n = {},1
	for i = -1,1,2 do
		for _,p in pairs({
			{x=pos.x+i, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+i}
		}) do
			tab[n] = {p, minetest.get_node(p)}
			n = n+1
		end
	end
	return tab
end

local function get_flowing_dir(pos)
	local data = get_nodes(pos)
	local param2 = minetest.get_node(pos).param2
	if param2 > 7 then
		return
	end
	for _,i in pairs(data) do
		local nd = i[2]
		local name = nd.name
		local par2 = nd.param2
		if name == "default:water_flowing"
		and par2 < param2 then
			return i[1]
		end
	end
	for _,i in pairs(data) do
		local nd = i[2]
		local name = nd.name
		local par2 = nd.param2
		if name == "default:water_flowing"
		and par2 >= 11 then
			return i[1]
		end
	end
	for _,i in pairs(data) do
		local nd = i[2]
		local name = nd.name
		local par2 = nd.param2
		local tmp = minetest.registered_nodes[name]
		if tmp
		and not tmp.walkable
		and name ~= "default:water_flowing" then
			return i[1]
		end
	end
end

local item_entity = minetest.registered_entities["__builtin:item"]
local old_on_step = item_entity.on_step or function()end

item_entity.on_step = function(self, dtime)
	old_on_step(self, dtime)
		
	local p = self.object:getpos()
	
	local name = minetest.get_node(p).name
	if name == "default:lava_flowing"
	or name == "default:lava_source" then
		minetest.sound_play("builtin_item_lava", {pos=p})
		self.object:remove()
		return
	end

	local tmp = minetest.registered_nodes[name]
	if tmp
	and tmp.liquidtype == "flowing" then
		local vec = get_flowing_dir(self.object:getpos())
		if vec then
			local v = self.object:getvelocity()
			if vec.x-p.x > 0 then
				self.object:setvelocity({x=0.5,y=v.y,z=0})
			elseif vec.x-p.x < 0 then
				self.object:setvelocity({x=-0.5,y=v.y,z=0})
			elseif vec.z-p.z > 0 then
				self.object:setvelocity({x=0,y=v.y,z=0.5})
			elseif vec.z-p.z < 0 then
				self.object:setvelocity({x=0,y=v.y,z=-0.5})
			end
			self.object:setacceleration({x=0, y=-10, z=0})
			self.physical_state = true
			self.object:set_properties({
				physical = true
			})
		end
	end
end

minetest.register_entity(":__builtin:item", item_entity)

if minetest.setting_get("log_mods") then
	minetest.log("action", "builtin_item loaded")
end
