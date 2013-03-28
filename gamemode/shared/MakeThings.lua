-- automatically block players from doing certain things with their DarkRP entities
local blockTypes = {"Physgun1", "Spawning1", "Toolgun1"}


local requiredTeamItems = {"color", "model", "description", "weapons", "command", "max", "salary", "admin", "vote"}
local validShipment = {model = util.IsValidModel, "entity", "price", "amount", "seperate"}
local validVehicle = {"name", model = util.IsValidModel, "price"}
local validEntity = {"ent", model = util.IsValidModel, "price", "max", "cmd", "name"}
local function checkValid(tbl, requiredItems)
	for k,v in pairs(requiredItems) do
		local isFunction = type(v) == "function"

		if (isFunction and not v(tbl[k])) or (not isFunction and tbl[v] == nil) then
			return isFunction and k or v
		end
	end
end

RPExtraTeams = {}
function AddExtraTeam(Name, colorOrTable, model, Description, Weapons, command, maximum_amount_of_this_class, Salary, admin, Vote, Haslicense, NeedToChangeFrom, CustomCheck)
	local tableSyntaxUsed = colorOrTable.r == nil -- the color is not a color table.

	local CustomTeam = tableSyntaxUsed and colorOrTable or
		{color = colorOrTable, model = model, description = Description, weapons = Weapons, command = command,
			max = maximum_amount_of_this_class, salary = Salary, admin = admin or 0, vote = tobool(Vote), hasLicense = Haslicense,
			NeedToChangeFrom = NeedToChangeFrom, customCheck = CustomCheck
		}
	CustomTeam.name = Name

	local corrupt = checkValid(CustomTeam, requiredTeamItems)
	if corrupt then error("Corrupt team \"" ..(CustomTeam.name or "") .. "\": element " .. corrupt .. " is incorrect.", 2) end

	table.insert(RPExtraTeams, CustomTeam)
	team.SetUp(#RPExtraTeams, Name, CustomTeam.color)
	local Team = #RPExtraTeams

	timer.Simple(0, function() GAMEMODE:AddTeamCommands(CustomTeam, CustomTeam.max) end)

	// Precache model here. Not right before the job change is done
	if type(CustomTeam.model) == "table" then
		for k,v in pairs(CustomTeam.model) do util.PrecacheModel(v) end
	else
		util.PrecacheModel(CustomTeam.model)
	end
	return Team
end

RPExtraTeamDoors = {}
function AddDoorGroup(name, ...)
	RPExtraTeamDoors[name] = {...}
end

CustomVehicles = {}
CustomShipments = {}
function AddCustomShipment(name, model, entity, price, Amount_of_guns_in_one_shipment, Sold_seperately, price_seperately, noshipment, classes, shipmodel, CustomCheck)
	local tableSyntaxUsed = type(model) == "table"

	local AllowedClasses = classes or {}
	if not classes then
		for k,v in pairs(team.GetAllTeams()) do
			table.insert(AllowedClasses, k)
		end
	end

	local price = tonumber(price)
	local shipmentmodel = shipmodel or "models/Items/item_item_crate.mdl"

	local customShipment = tableSyntaxUsed and model or
		{model = model, entity = entity, price = price, amount = Amount_of_guns_in_one_shipment,
		seperate = Sold_seperately, pricesep = price_seperately, noship = noshipment, allowed = AllowedClasses,
		shipmodel = shipmentmodel, customCheck = CustomCheck, weight = 5}

	customShipment.name = name
	customShipment.allowed = customShipment.allowed or {}

	local corrupt = checkValid(customShipment, validShipment)
	if corrupt then error("Corrupt shipment \"" .. (name or "") .. "\": element " .. corrupt .. " is corrupt.", 2) end

	if SERVER and FPP then
		FPP.AddDefaultBlocked(blockTypes, customShipment.entity)
	end

	table.insert(CustomShipments, customShipment)
	util.PrecacheModel(customShipment.model)
end

function AddCustomVehicle(Name_of_vehicle, model, price, Jobs_that_can_buy_it, customcheck)
	local found = false
	for k,v in pairs(list.Get("Vehicles")) do
		if string.lower(k) == string.lower(Name_of_vehicle) then found = true break end
	end

	local vehicle = {name = Name_of_vehicle, model = model, price = price, allowed = Jobs_that_can_buy_it, customCheck = customcheck}
	local corrupt = checkValid(vehicle, validVehicle)
	if corrupt then error("Corrupt vehicle \"" .. (Name_of_vehicle or "") .. "\": element " .. corrupt .. " is corrupt.", 2) end
	if not found then error("Vehicle invalid: " .. Name_of_vehicle .. ". Unknown vehicle name.") end

	table.insert(CustomVehicles, vehicle)
end

DarkRPEntities = {}
function AddEntity(name, entity, model, price, max, command, classes, CustomCheck)
	local tableSyntaxUsed = type(entity) == "table"

	local tblEnt = tableSyntaxUsed and entity or
		{ent = entity, model = model, price = price, max = max,
		cmd = command, allowed = classes, customCheck = CustomCheck}
	tblEnt.name = name

	if type(tblEnt.allowed) == "number" then
		tblEnt.allowed = {tblEnt.allowed}
	end

	local corrupt = checkValid(tblEnt, validEntity)
	if corrupt then error("Corrupt Entity \"" .. (name or "") .. "\": element " .. corrupt .. " is corrupt.", 2) end

	if SERVER and FPP then
		FPP.AddDefaultBlocked(blockTypes, tblEnt.ent)
	end

	table.insert(DarkRPEntities, tblEnt)
end

DarkRPAgendas = {}

function AddAgenda(Title, Manager, Listeners)
	if not Manager then
		hook.Add("PlayerSpawn", "AgendaError", function(ply)
		if ply:IsAdmin() then ply:ChatPrint("WARNING: Agenda made incorrectly, there is no manager! failed to load!") end end)
		return
	end
	DarkRPAgendas[Manager] = {Title = Title, Listeners = Listeners}
end

GM.DarkRPGroupChats = {}
function GM:AddGroupChat(funcOrTeam, ...)
	-- People can enter either functions or a list of teams as parameter(s)
	if type(funcOrTeam) == "function" then
		table.insert(self.DarkRPGroupChats, funcOrTeam)
	else
		local teams = {funcOrTeam, ...}
		table.insert(self.DarkRPGroupChats, function(ply) return table.HasValue(teams, ply:Team()) end)
	end
end

GM.AmmoTypes = {}

function GM:AddAmmoType(ammoType, name, model, price, amountGiven, customCheck)
	table.insert(self.AmmoTypes, {
		ammoType = ammoType,
		name = name,
		model = model,
		price = price,
		amountGiven = amountGiven,
		customCheck = customCheck
	})
end

