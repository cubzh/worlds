
Config = {
    Items = { "caillef.wooden_crate", "caillef.barrels", "xavier.damage_indicator", "caillef.roboteye", "k40s.gun_bullet", "voxels.dustzh_chunk_1", "voxels.dustzh_chunk_2", "voxels.dustzh_chunk_3", "voxels.dustzh_chunk_4", "voxels.dustzh_chunk_5" }
}

-- TODO
--- [ ] spawnpoints

local MAP_SCALE = 2
local DEBUG = false -- starts with a single player
local SOUND = true
local ROUND_DURATION = 240
local SPAWN_BLOCK_COLOR = Color(136,0,252)
local MAX_NB_KILLS_END_ROUND = 40
local weaponName = nil

Config.ConstantAcceleration.Y = -300

local weaponsList = {
    { name="Rifle", item="voxels.assault_rifle", cooldown=0.12, mode="auto", dmg=15, ammo=12, muzzleFlashY=-1, scale=0.4, mirror=true },
    { name="Pistol", item="voxels.silver_pistol", cooldown=0.2, mode="manual", dmg=25, ammo=6, scale=0.4, mirror=true },
    { name="P90", item="voxels.p90", cooldown=0.06, mode="auto", dmg=7, ammo=22, scale=0.4, mirror=true },
    { name="Deagle", item="voxels.golden_pistol", cooldown=0.4, mode="manual", dmg=40, ammo=4, scale=0.4, mirror=true },
    { name="RailCow", item="jacksbertox.milk_cannon_triple", scale=0.3, sfx="cow_", cooldown=1, mode="auto", dmg=100, ammo=10 },
    --{ name="Bluecar", item="caillef.bluecar", scale=0.5, sfx="carhonk_", cooldown=1, mode="auto", dmg=100, ammo=10 },
}

local function generateMapFromChunks()
	local scale = MAP_SCALE
	local initChunk = function(name)
		local chunk = Shape(Items.voxels[name])
		chunk.Physics = PhysicsMode.StaticPerBlock
		chunk.Scale = scale
		chunk.Friction = Map.Friction
		chunk.Bounciness = Map.Bounciness
		chunk.CollisionGroups = Map.CollisionGroups
		chunk.CollidesWithGroups = Map.CollidesWithGroups
		chunk:SetParent(World)
		return chunk
	end
	
	local chunk1 = initChunk("dustzh_chunk_1")
	local chunk2 = initChunk("dustzh_chunk_2")
	local chunk3 = initChunk("dustzh_chunk_3")
	local chunk4 = initChunk("dustzh_chunk_4")
	local chunk5 = initChunk("dustzh_chunk_5")

	chunk2.Position = Number3(-2 * scale, 4 * scale, chunk1.Depth * scale)
	chunk3.Position = Number3(-chunk1.Width * scale, 0 * scale, (12 + chunk1.Depth) * scale)
	chunk4.Position = Number3((-chunk1.Width - 12) * scale, 0, 20 * scale)
	chunk5.Position = Number3(-12 * scale, 0, 20 * scale)
end

function placeProps()

local savedObjects = JSON:Decode("[{\"p\":[-37.5632,8,155.478],\"r\":[0,5.72718,0],\"n\":\"voxels.gate\",\"s\":[0.5,0.5,0.5]},{\"p\":[-9.43368,34,396.3],\"r\":[0,1.30072,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-240.13,32,86.1386],\"r\":[0,3.13041,0],\"n\":\"voxels.dumpster_open\",\"s\":[0.506684,0.5,0.5]},{\"p\":[80.1377,32,197.193],\"r\":[0,0,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-35.4596,16,247.592],\"r\":[0,0.812674,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[80.4423,32,207.653],\"r\":[0,0,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[236.275,8,152.791],\"r\":[0,1.02623,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-11.2556,8,199.319],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-190.361,32,89.794],\"r\":[0,1.07044,0],\"n\":\"voxels.fence\",\"s\":[0.604606,0.5,0.5]},{\"p\":[-35.9643,24,396.072],\"r\":[0,1.92795,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-6.35962,18,188.426],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-4.34632,7.99999,187.779],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-210.136,32,87.0317],\"r\":[0,3.10089,0],\"n\":\"voxels.dumpster\",\"s\":[0.5,0.5,0.547456]},{\"p\":[76.1532,32,188.869],\"r\":[0,1.97064,0],\"n\":\"voxels.oil_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-4.9465,8,163.456],\"r\":[0,0.191109,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[71.7146,32,210.385],\"r\":[0,0,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[133.846,32,64.259],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[139.3,24,339.183],\"r\":[0,2.13248,0],\"n\":\"voxels.street_barrier_1\",\"s\":[0.5,0.5,0.5]},{\"p\":[205.408,10.3522,154.058],\"r\":[4.71239,1.05962,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.514443]},{\"p\":[133.164,24,218.618],\"r\":[0,1.31709,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[121.959,24,264.51],\"r\":[0,1.9113,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[126.463,24.6937,365.643],\"r\":[0.683969,0.143828,4.9377],\"n\":\"voxels.stop_sign\",\"s\":[0.459101,0.5,0.5]},{\"p\":[19.363,56,422.667],\"r\":[-0,4.42766,0],\"n\":\"voxels.broken_car\",\"s\":[0.566085,0.608845,0.645303]},{\"p\":[-173.305,32,362.15],\"r\":[0,1.24956,0],\"n\":\"voxels.toxic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[60.9466,8,90.5894],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-11.1591,7.99998,141.671],\"r\":[0,2.69145,0],\"n\":\"voxels.gate\",\"s\":[0.5,0.5,0.5]},{\"p\":[-38.781,24,372.766],\"r\":[0,2.68338,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[113.147,46.9297,40],\"r\":[0,0,0],\"n\":\"voxels.poster_a\",\"s\":[1.10497,1.00187,0.5]},{\"p\":[-25.5188,10,76.3064],\"r\":[0,2.89749,0],\"n\":\"voxels.broken_car\",\"s\":[0.7,0.7,0.7]},{\"p\":[-224.02,32,86.1938],\"r\":[0,5.56634,0],\"n\":\"voxels.toxic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-28.8899,34,389.978],\"r\":[0,1.39138,0],\"n\":\"voxels.crate_large\",\"s\":[0.498574,0.5,0.5]},{\"p\":[-31.1697,24,382.06],\"r\":[-0,3.19653,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[35.4607,40,196.403],\"r\":[0,0,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-4.92926,18,177.76],\"r\":[0,1.40899,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-22.4344,24,394.284],\"r\":[0,1.41656,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-19.1073,48,395.192],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-238.56,40,230.174],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-109.938,12,200.877],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-240.124,32,227.72],\"r\":[-0,3.37908,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[-4.23164,28,187.978],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-6.04191,8,176.535],\"r\":[0,1.52983,0],\"n\":\"voxels.crate_large\",\"s\":[0.520342,0.5,0.5]},{\"p\":[-23.3106,7.69819,48.4862],\"r\":[0,3.12781,0],\"n\":\"voxels.garage_door\",\"s\":[0.5,0.5,0.5]},{\"p\":[68.8492,34,41.6179],\"r\":[1.5708,4.76841e-06,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[-10.587,24,385.661],\"r\":[0,1.42144,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[62.1985,32,51.6528],\"r\":[0,1.88235,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[248,7.95921,118.46],\"r\":[0,1.56075,0],\"n\":\"voxels.garage_door\",\"s\":[0.5,0.5,0.5]},{\"p\":[225.87,7.99999,163.939],\"r\":[0,5.21368,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[149.046,24.3197,323.709],\"r\":[4.82748,1.75768,1.4805],\"n\":\"voxels.stop_sign\",\"s\":[0.5,0.5,0.5]},{\"p\":[117.002,34,235.524],\"r\":[0,0,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[232.548,8,178.406],\"r\":[0,0,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-3.42425,56,421.184],\"r\":[0,2.25615,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[132.199,24,266.602],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[147.431,24,234.992],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[141.531,37.99,366.994],\"r\":[0,0.0345237,0],\"n\":\"voxels.poster_x\",\"s\":[1.10251,0.890659,0.5]},{\"p\":[117.773,24,230.576],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[167.055,24,333.469],\"r\":[0,1.5994,0],\"n\":\"voxels.fence\",\"s\":[0.5,0.5,0.468997]},{\"p\":[-47.5,23.6129,324.599],\"r\":[-0,4.72402,0],\"n\":\"voxels.garage_door\",\"s\":[0.5,0.5,0.5]},{\"p\":[70.3327,8,84.5788],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[160.081,23.2383,332.007],\"r\":[0.302724,1.5269,2.89301e-07],\"n\":\"voxels.fence\",\"s\":[0.5,0.5,0.425834]},{\"p\":[-161.586,56,414.053],\"r\":[0,0,0],\"n\":\"voxels.car_lift\",\"s\":[0.5,0.5,0.5]},{\"p\":[-140.308,56,398.025],\"r\":[0,0,0],\"n\":\"voxels.fire_hydrant\",\"s\":[0.5,0.5,0.5]},{\"p\":[30.6004,8,85.599],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-42.2361,8,55.9171],\"r\":[0,0,0],\"n\":\"voxels.tire_stack\",\"s\":[0.5,0.5,0.5]},{\"p\":[-204.644,34,318.755],\"r\":[0,1.22995,0],\"n\":\"voxels.construction_truck\",\"s\":[0.64386,0.645042,0.657126]},{\"p\":[59.942,31.9228,107.827],\"r\":[6.13325,1.58433,4.46747e-06],\"n\":\"voxels.ladder_metal\",\"s\":[0.5,0.5,0.516611]},{\"p\":[-28.6331,44,392.737],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[-119.66,12,200.643],\"r\":[0,1.6639,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[-20.8977,24,383.758],\"r\":[0,1.38406,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[-2.36415,8,199.28],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-27.583,16,245.788],\"r\":[0,0.982933,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[62.6406,32,46.6156],\"r\":[0,0,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[-0.301805,56,414.835],\"r\":[0,3.12855,0],\"n\":\"voxels.tool_chest\",\"s\":[0.277812,0.23542,0.218786]},{\"p\":[161.26,32,81.0211],\"r\":[0,0,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[165.253,24,329.978],\"r\":[0,1.54984,0],\"n\":\"voxels.fence\",\"s\":[0.5,0.5,0.5]},{\"p\":[172.443,40,46.1448],\"r\":[0,0,0],\"n\":\"voxels.telephone_pole_2\",\"s\":[0.5,0.5,0.5]},{\"p\":[-57.0809,8,56.6613],\"r\":[0,0,0],\"n\":\"voxels.ladder_wood\",\"s\":[0.5,0.5,0.5]},{\"p\":[-10.8756,24,395.62],\"r\":[0,2.81677,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.55674]},{\"p\":[34.2299,8,100.524],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-246.498,33.0744,316.502],\"r\":[0,4.69579,0],\"n\":\"voxels.garage_door\",\"s\":[0.5,0.5,0.5]},{\"p\":[-204.051,32,104.332],\"r\":[0,0.491865,0],\"n\":\"voxels.fence\",\"s\":[0.5,0.5,0.50841]},{\"p\":[-74.1917,55.9653,399.502],\"r\":[0,3.14133,0],\"n\":\"voxels.gate\",\"s\":[0.314133,0.344452,0.5]},{\"p\":[-212.798,32,100.629],\"r\":[0,1.64272,0],\"n\":\"voxels.tire_stack\",\"s\":[0.5,0.5,0.5]},{\"p\":[-235.625,32,235.606],\"r\":[-0,3.25714,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[-1.84917,18,198.052],\"r\":[0,0,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[185.599,8,157.904],\"r\":[0,0.999184,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[-108.441,22,202.424],\"r\":[0,1.37323,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[34.0518,32,191.853],\"r\":[0,1.45507,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[65.2278,34.5,48.9973],\"r\":[0,0,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[-18.6588,34,393.704],\"r\":[0,0,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[-221.693,32,108.757],\"r\":[0,0,0],\"n\":\"voxels.fence\",\"s\":[0.5,0.5,0.5]},{\"p\":[36.0789,32,199.302],\"r\":[0,2.00901,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[-188.725,32,146.437],\"r\":[0,1.83753,0],\"n\":\"voxels.car\",\"s\":[0.730401,0.621147,0.702817]},{\"p\":[72.7646,32,202.351],\"r\":[0,0,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[132.157,32,74.3864],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.519135]},{\"p\":[63.6524,32,63.8574],\"r\":[-0,4.56971,0],\"n\":\"voxels.dumpster\",\"s\":[0.5,0.5,0.408304]},{\"p\":[117.088,8,105.609],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[105.191,8,106.715],\"r\":[0,1.52207,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[-20.4315,42,394.913],\"r\":[0,0,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[192.902,8,149.298],\"r\":[0,6.09974,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[236.292,7.99999,164.547],\"r\":[0,0.570963,0],\"n\":\"voxels.barrel_red\",\"s\":[0.5,0.5,0.5]},{\"p\":[196.094,8,158.781],\"r\":[0,1.29524,0],\"n\":\"voxels.classic_barrel\",\"s\":[0.5,0.5,0.5]},{\"p\":[-122.89,8,192.355],\"r\":[0,1.43128,0],\"n\":\"voxels.crate_small\",\"s\":[0.5,0.5,0.5]},{\"p\":[68.1769,32,48.4396],\"r\":[0,1.23283,0],\"n\":\"voxels.spare_tire\",\"s\":[0.5,0.5,0.5]},{\"p\":[110.101,18,104.246],\"r\":[0,1.37939,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[135.431,24,353.715],\"r\":[0,0,0],\"n\":\"voxels.street_barrier_2\",\"s\":[0.5,0.5,0.5]},{\"p\":[155.392,24,352.951],\"r\":[0,1.13871,0],\"n\":\"voxels.street_barrier_2\",\"s\":[0.5,0.5,0.5]},{\"p\":[118.429,24,242.044],\"r\":[0,0,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[72.9663,22.9524,272.5],\"r\":[0,3.1377,0],\"n\":\"voxels.garage_door\",\"s\":[0.5,0.5,0.5]},{\"p\":[-189.181,32,378.719],\"r\":[0,0,0],\"n\":\"voxels.dumpster\",\"s\":[0.5,0.5,0.5]},{\"p\":[-89.7741,55.7656,399.489],\"r\":[0,0.0120837,0],\"n\":\"voxels.gate\",\"s\":[0.333328,0.347237,0.5]},{\"p\":[24.604,8,132.909],\"r\":[0,0,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]},{\"p\":[46.3335,8,122.91],\"r\":[0,0.950216,0],\"n\":\"voxels.crate_large\",\"s\":[0.5,0.5,0.5]},{\"p\":[66.9265,8,98.3201],\"r\":[0,0,0],\"n\":\"voxels.crate_medium\",\"s\":[0.5,0.5,0.5]}]")

	local initProp = function(s, info)
		s:SetParent(World)
		s.Position = info.p
		s.Rotation = info.r
		s.Scale = info.s
		s.Pivot = Number3(s.Width / 2, 0, s.Depth / 2)

		require("hierarchyactions"):applyToDescendants(s, { includeRoot = true }, function(shape)
			shape.Physics = PhysicsMode.StaticPerBlock
			shape.CollisionGroups = Map.CollisionGroups
		end)
	end

	for _,info in ipairs(savedObjects) do
		local cachedObjects = {}
		if not cachedObjects[info.n] then
			Object:Load(info.n, function(s)
				cachedObjects[info.n] = s
				initProp(s, info)
			end)
		else
			local s = Shape(cachedObjects[info.n], { includeChildren = true })
			initProp(s, info)
		end
	end
end

Client.OnStart = function()
	placeProps()
    -- Map

	generateMapFromChunks()
    spawnPoints = JSON:Decode("[{\"p\":[-54.734,11.6904,62.8359],\"rY\":0.0126201},{\"p\":[-245.448,39.3373,98.7844],\"rY\":0.0605912},{\"p\":[-268.832,32.6757,224.197],\"rY\":1.5624},{\"p\":[-176.63,37.7461,281.024],\"rY\":5.91473},{\"p\":[-130.289,64.3296,454.234],\"rY\":4.13691},{\"p\":[103.866,46.8537,460.034],\"rY\":3.6675},{\"p\":[-13.5333,31.5645,352.71],\"rY\":3.22079},{\"p\":[153.182,28.8819,314.506],\"rY\":3.92754},{\"p\":[220.249,14.7999,196.709],\"rY\":3.44043},{\"p\":[153.557,34.7014,63.7065],\"rY\":0.420805},{\"p\":[76.2078,34.8703,59.8622],\"rY\":6.20929},{\"p\":[50.9595,10.5063,83.8885],\"rY\":6.12099},{\"p\":[-87.317,14.3838,180.542],\"rY\":1.61218}]")

    require("ambience"):set(ambience.dawn)

    -- Modules
    multi = require("multi")
    multi.teleportTriggerDistance = 100

    weapons:init()
    weapons:setList(weaponsList)
    weapons:setPlayerMaxHP(100)

    victoryPodium:init()
    uiRoundScore:init()
    uiRoundDuration:init()
    killfeed:init()

    cameraCustomFirstPerson = function()
        Camera:SetModeFirstPerson()
        Player.Head.IsHidden = false
        Player.Head.IsHiddenSelf = true
        Player.Body.IsHiddenSelf = true
        Player.RightArm.IsHidden = true
        Player.LeftArm.IsHidden = true
        Player.RightLeg.IsHidden = true
        Player.LeftLeg.IsHidden = true
		if Player.equipments then
	        for _,v in pairs(Player.equipments) do
 	       	v.IsHiddenSelf = true
 	       	if v.attachedParts then
 	       		for _,v2 in ipairs(v.attachedParts) do
 	       			v2.IsHiddenSelf = true
 	           	end
 	       	end
 	       end
		end

		local localevent = require("localevent")
		localevent:Listen(localevent.Name.AvatarLoaded, function()
			for _,v in pairs(Player.equipments) do
 	       	v.IsHiddenSelf = true
	       		if v.attachedParts then
	       			for _,v2 in ipairs(v.attachedParts) do
	       				v2.IsHiddenSelf = true
	           		end
	       		end
	      	 end
		end)
    end

    -- Player
    Camera:SetModeFirstPerson()
    Player.Head:AddChild(AudioListener)
    World:AddChild(Player)

    respawn = function(target)
		if not target or target.IsHidden == nil then return end
        if target == Player then
            weapons:setWeapon(Player, math.random(#weaponsList))
            dropPlayer()
        end
        Timer(0.5, function()
			if not target or target.IsHidden == nil then return end
            target.IsHidden = false
            target:resetHP()
        end)
    end

    dropPlayer = function()
        local randomSpawnPoint = spawnPoints[math.random(#spawnPoints)]
        Player.Position = Number3(randomSpawnPoint.p[1], randomSpawnPoint.p[2], randomSpawnPoint.p[3])
        Player.Rotation = { 0, randomSpawnPoint.rY, 0 }
        Player.Velocity = { 0, 0, 0 }
    end
    
    -- Game State Manager
    gsm.clientLobbyOnStart = function()
        victoryPodium:stop()
        cameraCustomFirstPerson()
        print("Lobby, waiting for one more player.")
        respawn(Player)
    end
    gsm.clientPreRoundOnStart = function()
        victoryPodium:stop()
    end
    gsm.clientRoundOnStart = function()
		killfeed:clearEntries()
		weapons:toggleUI(true)
        cameraCustomFirstPerson()
        for _,p in ipairs(gsm.playersInRound) do
            respawn(p)
            p.nbKills = 0
        end
        uiRoundScore:update(gsm.playersInRound, "nbKills")

        uiRoundDuration:update(Time.UnixMilli() + ROUND_DURATION * 1000)
        uiRoundDuration.bg.LocalPosition.Y = uiRoundScore.bg.LocalPosition.Y + uiRoundScore.bg.Height
    end
    gsm.clientEndRoundOnStart = function()
		weapons.shooting = false
		weapons:toggleUI(false)
		killfeed:clearEntries()
        local sortedPlayers = {}
        for _,v in ipairs(gsm.playersInRound) do
            table.insert(sortedPlayers,v)
            pcall(function()
                v.Motion = Number3(0,0,0)
                v.nbKills = v.nbKills or 0
            end)
        end
        table.sort(sortedPlayers, function(a, b) 
            return a.nbKills > b.nbKills
        end)

		weapons:setWeapon(Player, Player.weaponId, true)
		Player.Motion = { 0, 0, 0 }
		Player.Velocity = { 0, 0, 0 }
        victoryPodium:teleportPlayers(sortedPlayers)
    end

    gsm.clientRoundPlayersUpdate = function(gsm, list)
        uiRoundScore:update(gsm.playersInRound, "nbKills")
        uiRoundDuration:_refreshUI()
        uiRoundDuration.bg.LocalPosition.Y = uiRoundScore.bg.LocalPosition.Y + uiRoundScore.bg.Height
    end
end

Client.OnPlayerJoin = function(p)
	p.Scale = 0.3
	local bg
	if p == Player then
		local ui = require("uikit")
		bg = ui:createFrame(Color.Black)	
		bg.Width = Screen.Width
		bg.Height = Screen.Height
	end
    print(p.Username.." joined the game.")

	Timer(1, function()
		cameraCustomFirstPerson()
		if p == Player then
		    respawn(p)
			bg:remove()
		end
	end)
    instructions:display()
end

Client.OnPlayerLeave = function(p)
    print(p.Username.." just left the game.")
end

Client.AnalogPad = function(dx, dy)
    Player.LocalRotation.Y = Player.LocalRotation.Y + dx * 0.01
    Player.LocalRotation.X = Player.LocalRotation.X + -dy * 0.01

	if Player:isDead() or gsm.state == gsm.States.EndRound then
		return
	end
    if dpadX ~= nil and dpadY ~= nil then
        Player.Motion = (Player.Forward * dpadY + Player.Right * dpadX) * 40
    end
end

Client.DirectionalPad = function(x, y)
    dpadX = x dpadY = y
    -- No move if dead
    if Player:isDead() or gsm.state == gsm.States.EndRound then
		return
	end
    Player.Motion = (Player.Forward * y + Player.Right * x) * 40
end

Client.OnChat = function(message)
	if message == "/kill" or message == "!kill" then
		respawn(Player)
		return
	end
    print(Player.Username .. ": " .. message)
    local e = Event()
    e.action = "chat"
    e.t = Player.Username .. ": " .. message
    e:SendTo(OtherPlayers)
end

Client.DidReceiveEvent = function(event)
    if gsm:clientHandleEvent(event) then return end

    if event.action == "chat" then
        print(event.t)
    end
    if event.action == "nbKills" then
        local source = Players[math.floor(event.p)]
        if not source then return end
        source.nbKills = event.nb
        uiRoundScore:update(gsm.playersInRound, "nbKills")
    end
    if event.action == "roundEndAt" then
        uiRoundDuration:update(event.t)
        uiRoundDuration.bg.LocalPosition.Y = uiRoundScore.bg.LocalPosition.Y + uiRoundScore.bg.Height
    end
end

Client.Tick = function(dt)
    -- Offmap
    if Player.Position.Y < -500 then
        dropPlayer()
        Player:TextBubble("💀 Oops!")
    end

	-- auto jump
	if Player.Motion.SquaredLength > 0 then
		local d = Player.Motion:Copy()
		d.Y = 0
		d:Normalize()
		local impact1 = Ray(Player.Position + Number3(0,0.1,0), d):Cast(Map.CollisionGroups)
		local dist = 6.35 + MAP_SCALE * 0.5 -- player collider radius + half map block
		if impact1 and impact1.Distance < dist then
			local impact2 = Ray(Player.Position + Number3(0,MAP_SCALE * 1.5,0), d):Cast(Map.CollisionGroups)
			if not impact2 or impact2.Distance > dist then
				Player.Velocity.Y = 30
			end
		end
	end
end

-- jump function, triggered with Action1
Client.Action1 = function()
	if gsm.state == gsm.States.EndRound or Player:isDead() then return end
    if Player.IsOnGround then
        Player.Velocity.Y = 90
    end
end

Client.Action2 = function()
	if gsm.state == gsm.States.EndRound then return end
    weapons:pressShoot()
	if instructions:isVisible() then
		instructions:hide()
	end
end

Client.Action2Release = function()
    weapons:releaseShoot()
end

Client.Action3Release = function()
	weapons:reload()
end


instructions = {
    bg = nil
}

instructions.display = function(self)
    if self.bg == nil then
        local ui = require("uikit")
        local bg = ui:createFrame(Color(0,0,0,0.5))

        local welcomeText = ui:createText("Welcome to Dustzh!", Color.White)
        welcomeText:setParent(bg)

        local Action1Text = ui:createText("Action1: Jump", Color.White)
        Action1Text:setParent(bg)

        local Action2Text = ui:createText("Action2: Shoot", Color.White)
        Action2Text:setParent(bg)

        local Action3Text = ui:createText("Action3: Reload", Color.White)
        Action3Text:setParent(bg)

        local dismissText = ui:createText("(shoot to dismiss)", Color.White, "small")
        dismissText:setParent(bg)

        bg.parentDidResize = function(self)
            local padding = 4
            local maxWidth = math.max(welcomeText.Width, Action1Text.Width, Action2Text.Width, Action3Text.Width, dismissText.Width)
            local height = welcomeText.Height + padding + Action1Text.Height + padding + Action2Text.Height + padding + Action3Text.Height + padding + dismissText.Height

            self.Width = maxWidth + padding * 2
            self.Height = height + padding * 2
            self.pos = {Screen.Width * 0.5 - self.Width * 0.5, Screen.Height * 0.5 - self.Height * 0.5, 0}

            welcomeText.pos = {self.Width * 0.5 - welcomeText.Width * 0.5, self.Height - padding - welcomeText.Height, 0}
            Action1Text.pos = {self.Width * 0.5 - Action1Text.Width * 0.5,  welcomeText.pos.Y - padding - Action1Text.Height, 0}
            Action2Text.pos = {self.Width * 0.5 - Action2Text.Width * 0.5,  Action1Text.pos.Y - padding - Action2Text.Height, 0}
            Action3Text.pos = {self.Width * 0.5 - Action3Text.Width * 0.5,  Action2Text.pos.Y - padding - Action3Text.Height, 0}
            dismissText.pos = {self.Width * 0.5 - dismissText.Width * 0.5,  Action3Text.pos.Y - padding - dismissText.Height, 0}
        end
        bg:parentDidResize()
        self.bg = bg
    end
    self.bg:show()
end

instructions.hide = function(self)
    if self.bg ~= nil then self.bg:hide() end
end

instructions.isVisible = function(self)
    return self.bg and self.bg:isVisible()
end

indicatorsPool = {}
addDamageIndicator = function(shooterPos)
    local displayedTime = 0.5
    local depth = 3.0
    local radius = 15.0
    local pos = Player:PositionWorldToLocal(shooterPos)
    local angle = math.atan(pos.X, pos.Z)

    local damageIndicator = nil
    if #indicatorsPool == 0 then
        damageIndicator = Shape(Items.xavier.damage_indicator)
        damageIndicator.Scale = 0.02
        damageIndicator.Pivot = damageIndicator:LocalToBlock(Number3(0, radius, 0))
    else
        damageIndicator = indicatorsPool[#indicatorsPool]
        indicatorsPool[#indicatorsPool] = nil
    end
    Camera:AddChild(damageIndicator)
	damageIndicator.Physics = PhysicsMode.Disabled
    damageIndicator.LocalPosition = Number3(0, 0, depth)
    damageIndicator.LocalRotation.Z = -angle + math.pi

    local t = Timer(displayedTime, function()
        damageIndicator:SetParent(nil)
        table.insert(indicatorsPool, damageIndicator)
    end)
end

-- This function spawn SFX if needed an recycle it
function sfx(name, position, volume)
    if sfxPool == nil then sfxPool = {} end

    local recycled
    local pool = sfxPool[name]
    if pool == nil then
        sfxPool[name] = {}
    else
        recycled = table.remove(pool)
    end 

    if recycled ~= nil then
        recycled.Position = position
        recycled.Volume = volume or 0.3
        recycled:Play()
        Timer(recycled.Length + 0.1, function()
            table.insert(sfxPool[name], recycled)
        end)
        return
    end

    local as = AudioSource()
    as.Sound = name
    as.Volume = volume or 0.3
    as.Radius = 200
    as.Spatialized = true
    as:SetParent(World)
    as:Play()

    Timer(as.Length + 0.1, function()
        table.insert(sfxPool[name], as)
    end)
end

-- This function create an audio source, not recycled, handled by the developer
function audioSource(name, parent, sp, v, r)
    local as = AudioSource()
    as.Sound = name
    as:SetParent(parent or World)
    as.Volume = v
    as.Spatialized = sp
    if r ~= nil then
        as.Radius = r
    end
    return as
end


--
-- Server code
--

Server.OnStart = function()
    gsm.minPlayersToStart = DEBUG == true and 1 or 2
    gsm.playerCanJoinDuringRound = true
    gsm.durationPreRound = 1
    gsm.durationRound = ROUND_DURATION
    gsm.durationEndRound = 7

    gsm.serverRoundOnStart = function()
        for _,p in ipairs(gsm.playersInRound) do
            p.nbKills = 0
        end
    end

    -- Timer to wait all players when restarting the server
    Timer(3, function()
        if gsm.state == gsm.States.Lobby then
            gsm:serverSetGameState(gsm.States.Lobby)
        end
    end)
end

Server.OnPlayerJoin = function(p)
    gsm:serverOnPlayerJoin(p)
end

Server.OnPlayerLeave = function(p)
    gsm:serverOnPlayerLeave(p)
end

Server.DidReceiveEvent = function(e)
    if gsm:serverHandleEvent(e) then return end

    if e.action == "killed" then
        local source = Players[math.floor(e.s)]
        source.nbKills = source.nbKills or 0
        source.nbKills = source.nbKills + 1
        local e2 = Event()
        e2.action = "nbKills"
        e2.p = source.ID
        e2.nb = source.nbKills
        e2:SendTo(Players)

        if source.nbKills >= MAX_NB_KILLS_END_ROUND then
            gsm:serverSetGameState(gsm.States.EndRound)
        end
    end
end



walkSoundModule = {}
walkSoundModuleMetatable = {
    __index = {
        _isInit = false,
        _init = function(self)
            Player.Head:AddChild(AudioListener)
            Player.walk = 0
            local audio = AudioSource()
            audio.Volume = 0.2
            Player:AddChild(audio)
            self.audio = audio
            self._isInit = true
        end,
        tick = function(self, dt)
            if not self._isInit then self:_init() end
            Player.walk = Player.walk + dt
            if not (Player.IsOnGround and (Player.Motion.SquaredLength > 0.01) and Player.walk > 0.3) then return end
            Player.walk = 0
            if Player.BlockUnderneath == nil then return end
            local audio = self.audio
            local fileNum = math.random(5) 
            audio:Stop()
            audio.Volume = 0.17 + math.random() * 0.06
            audio.Pitch = 0.95 + math.random() * 0.1
            local surfaceType = "grass"
            local color = Player.BlockUnderneath.Color
            if color.R == color.G and color.R == color.B then -- shade of grey
                surfaceType = "concrete"
            end
            if color.R == color.G and color.R == color.B then -- shade of grey
                surfaceType = "concrete"
            end
            audio.Sound = "walk_"..surfaceType.."_"..fileNum
            audio:Play()
        end,
    }
}
setmetatable(walkSoundModule, walkSoundModuleMetatable)
LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
    walkSoundModule:tick(dt)
end)

entityHP = {}
entityHPMetatable = {
    __index = {
        _initUI = function(module, entity)
            local ui = require("uikit")
            local bg = ui:createFrame(Color.Black)
			module.uiBg = bg
			module.uiHidden = false
            local progressBar = ui:createFrame(Color.Red)
            progressBar:setParent(bg)
            local progressBarText = ui:createText("100/100", Color.White)
            progressBarText:setParent(bg)

            bg.update = function()
                progressBar.Width = bg.Width * (Player.hp / Player.maxHP)
                progressBar.Height = bg.Height
                progressBarText.Text = math.floor(Player.hp).."/"..math.floor(Player.maxHP)
                progressBarText.pos = { bg.Width / 2 - progressBarText.Width / 2, bg.Height / 2 - progressBarText.Height / 2, 0 }
            end

            bg.parentDidResize = function()
                if Screen.Width > Screen.Height then
                    bg.Height = 30
                    bg.Width = 180
                else
                    bg.Height = 20
                    bg.Width = 120
                end
                local pos = Number3(10, Screen.Height / 3 + bg.Height, 0)
                bg.pos = pos
                bg:update()
            end
            bg:parentDidResize()
            Player.hpBar = bg
        end,
		toggleUI = function(self, show)
			if show == nil then
				self.uiHidden = not self.uiHidden
			else
				self.uiHidden = not show
			end

			if self.uiHidden then
				self.uiBg:hide()
			else
				self.uiBg:show()
			end
		end,
        showHitPoints = function(module, entity, hp, special)
            local t = Text()
            t.Text = hp
            t.Color = special and Color(255, 215, 0) or Color.White
            t.BackgroundColor = Color(0,0,0,0)
            t.Type = TextType.Screen
            t.IsUnlit = true
            if Screen.Width > Screen.Height then
                t.FontSize = 30
            else
                t.FontSize = 60
            end
            t:SetParent(entity)
            t.LocalPosition = { 0, 25, 0 }
            t.dir = Number3(((math.random() * 2) - 1) * 5, 20, 0)
            t.Tick = function(o,dt)
                if not o then return end
                o.LocalPosition = o.LocalPosition + o.dir * dt
            end
            Timer(1, function()
                t:RemoveFromParent()
                t = nil
            end)
        end,
        setupEntity = function(module, entity, maxHP)
            entity.maxHP = maxHP
            entity.hp = maxHP
            entity.damage = function(self, hp, special)
                self.hp = self.hp - hp
                if self.hp <= 0 then
                    self.hp = 0
                end
                if self == Player then Player.hpBar:update() end
                if self ~= Player then
                    module:showHitPoints(entity, -hp, special)
                end
            end
            entity.heal = function(self, hp)
                self.hp = self.hp + hp
                if entity.hp > entity.maxHP then
                    entity.hp = entity.maxHP
                end
                if self == Player then Player.hpBar:update() end
                if self ~= Player then
                    module:showHitPoints(entity, hp)
                end
            end
            entity.resetHP = function(self)
                self.hp = self.maxHP
                if self == Player then Player.hpBar:update() end
            end
            entity.isDead = function(self)
                return self.hp <= 0
            end
            entity.isAlive = function(self)
                return not self:isDead()
            end

            if entity == Player then
                module:_initUI(entity)
            end
        end,
    }
}
setmetatable(entityHP, entityHPMetatable)

local displayedWeapon = {}
weapons = {}
weaponsMetatable = {
    __index = {
        maxHP = 100,
        cooldown = 0,
        hitmarkerVolume = 0.6, -- todo add this is UI settings
        headshotMultiplier = 1.5,
        nbMaxBulletImpactDecals = 100, -- max nb of decal at the same time
        decalDuration = 10, -- nb seconds before a decal is removed
        init = function(self)
			self.particles = require("particles")
            local multi = require("multi")
			self.entityHP = entityHP
            multi:registerPlayerAction("dmg", function(_, data)
                self:damage(data)
            end)
            multi:registerPlayerAction("shoot", function(p)
                self:onShoot(p)
            end)
            multi:registerPlayerAction("changeWeapon", function(p, data)
                self:setWeapon(p, data.id)
            end)
            multi:registerPlayerAction("bidecal", function(_, data)
                local pos = Number3(data.pos._x,data.pos._y,data.pos._z)
                local rot = Number3(data.rot._x,data.rot._y,data.rot._z)
                self:placeNextBulletImpactDecal(pos, rot)
            end)
            Object:Load("voxels.bullethole_large", function(obj)
                local list = {}
                for i=1,self.nbMaxBulletImpactDecals do
                    local d = Shape(obj)
                    d.Pivot = {d.Width * 0.5, d.Height * 0.5, d.Depth * 0.5}
                    d:SetParent(World)
                    d.Scale = 0.2
                    d.Scale.Z = 0.2 + i * 0.001 -- to avoid z fighting
                    d.Physics = PhysicsMode.Disabled
                    d.IsHidden = true
                    table.insert(list, d)
                end
                self.bullet_impact_decals = list
                self.next_bidecal = 1
            end)
            local as = audioSource("hitmarker_1",p.Head,false,self.hitmarkerVolume)
            as.StopAt = 0.15
            self.hitmarkerSFX = as

            local as = audioSource("gun_reload_1",p.Head,false,0.25)
            self.reloadSFX = as

            local s = MutableShape()
            local hitMarkerColor = Color.White
            for i=1,5 do
                s:AddBlock(hitMarkerColor,i,i,0)
                s:AddBlock(hitMarkerColor,i,-i,0)
                s:AddBlock(hitMarkerColor,-i,i,0)
                s:AddBlock(hitMarkerColor,-i,-i,0)
            end
            s.Pivot = Number3(0.5,0.5,0.5)
            local ui = require("uikit")
            Pointer:Hide()
            UI.Crosshair = true
            local hitMarker = ui:createShape(s)
            s.Scale = 0.5
            hitMarker.pos = { Screen.Width / 2 - hitMarker.Width / 2, Screen.Height / 2 - hitMarker.Height / 2, 0 }
            hitMarker:hide()
            self.hitMarker = hitMarker

            weaponName = ui:createText("weaponsName", Color.Black)
            self.ammoCountText = ammoCount
            self.weaponNameText = weaponName
            weaponName.parentDidResize = function()
                self.weaponNameText.pos = { 30, Screen.Height / 3, 0 }
            end
            weaponName:parentDidResize()
            self:updateAmmoUI()
            self:updateNameUI()

			self.templates = {}
        end,
        updateAmmoUI = function(self)
            if self.ammo == nil then return end
            addAmmoIndication(math.floor(self.ammo), self.weaponNameText)
        end,
        updateNameUI = function(self)
            if self.weaponName == nil then return end
            self.weaponNameText.Text = self.weaponName
        end,
		toggleUI = function(self, show)
			if show == nil then
				self.uiHidden = not self.uiHidden
			else
				self.uiHidden = not show
			end
			self.entityHP:toggleUI(not self.uiHidden)
		end,
        placeNextBulletImpactDecal = function(self, pos, rot)
        	if not self.bullet_impact_decals then return end -- bullet_impact_decals may not be loaded yet
			if not self.next_bidecal then self.next_bidecal = 0 end
            local list = self.bullet_impact_decals
            local d = list[self.next_bidecal]
            self.next_bidecal = self.next_bidecal + 1
            if self.next_bidecal > #list then
                self.next_bidecal = 1
            end
            if d.timer then d.timer:Cancel() end
            d.IsHidden = false
            d.Rotation = rot
            d.Position = pos
            d.timer = Timer(self.decalDuration, function()
                d.IsHidden = true
                d.timer = nil
            end)
        end,
        onShoot = function(self, p)
            if not p.muzzleFlash or not p.weapon then return end
            -- Muzzle Flash
            if p.muzzleFlashTimer then
                p.muzzleFlashTimer:Cancel()
            end
            p.muzzleFlash.IsHidden = false
            p.muzzleFlash:SetParent(p.weapon)
            p.muzzleFlash.LocalPosition = Number3(p.weapon.Width / 2 + 0.3,p.weapon.muzzleFlashY or 0.5,p.weapon.Depth)
            p.muzzleFlashTimer = Timer(0.03, function()
                p.muzzleFlash.IsHidden = true
                p.muzzleFlashTimer = nil
            end)

            p.weapon.LocalRotation.X = -0.1 * (p.weapon.mirror and -1 or 1)
            Timer(0.05, function()
                p.weapon.LocalRotation.X = 0
            end)

			if self.currentWeapon.sfx then
				sfx(self.currentWeapon.sfx.."1", p.weapon.Position, 0.3)
				sfx("small_explosion_2", p.weapon.Position, 0.3)
				return
			end

            -- SFX
            local shootAs = p.shootAs[p.shootAsIndex]
            shootAs:Stop()
            shootAs.Pitch = 0.9 + math.random() * 0.2
            shootAs:Play()
            p.shootAsIndex = p.shootAsIndex + 1
            if p.shootAsIndex > #p.shootAs then p.shootAsIndex = 1 end
        end,
        _initPlayer = function(self, p)
            p.shootAs = {}
            p.shootAsIndex = 1
            local as = audioSource("gun_shot_2", p.Head, true, 0.2, 200)
            table.insert(p.shootAs, as)
            local as = audioSource("gun_shot_2", p.Head, true, 0.2, 200)
            table.insert(p.shootAs, as)
            local as = audioSource("gun_shot_2", p.Head, true, 0.2, 250)
            table.insert(p.shootAs, as)

            p.dmgAs = {}
            p.dmgAsIndex = 1
            for i=1,5 do
                local as = audioSource("hurt_scream_male_"..i, p.Head, true, 0.3)
                table.insert(p.dmgAs, as)
            end

            local b = MutableShape()
            b:AddBlock(Color.White,0,0,0)
            b:AddBlock(Color.White,1,0,0)
            b:AddBlock(Color.White,-1,0,0)
            b:AddBlock(Color.White,0,1,0)
            b:AddBlock(Color.White,0,-1,0)
            b:AddBlock(Color.White,0,0,1)
            b.Scale = 1
            b.Pivot = { 0.5, 0.5, 0.5 }
            b.IsHidden = true
            b.Physics = PhysicsMode.Disabled
            p.muzzleFlash = b

            self.entityHP:setupEntity(p, self.maxHP) -- add hp, maxHP, and functions damage, heal, resetHP, isDead and isAlive
            self:setWeapon(p, 1)
        end,
        pressShoot = function(self)
			if self.reloading then return end
            if Player.hp ~= nil and Player.hp <= 0 then return end
            self.shooting = true
        end,
        releaseShoot = function(self)
            self.shooting = false
        end,
		reload = function(self)
			if self.reloading or self.ammo == self.maxAmmo then return end
            self.reloading = true
			self.shooting = false
            self.reloadSFX:Play()
            local tmpPos = Player.weapon.LocalPosition:Copy()
            local tmpRot = Player.weapon.LocalRotation:Copy()

            require("ease"):outBack(Player.weapon, 1).LocalPosition = tmpPos + Number3(0,-3,0)
            require("ease"):outBack(Player.weapon, 1).LocalRotation = tmpRot + Number3(0.9,0,0)
            Timer(1, function()
            	require("ease"):outBack(Player.weapon, 1).LocalPosition = tmpPos
            	require("ease"):outBack(Player.weapon, 1).LocalRotation = tmpRot
            end)
            Timer(2, function()
            	self.reloading = false
            	self.ammo = self.maxAmmo
            	self:updateAmmoUI()
            end)
		end,
		updateUI = function(self)
			if not self.weaponInfo then return end
			-- display the weapon next to the weapon name
			if self.displayedWeapon then self.displayedWeapon:remove() end
			if self.templates[self.weaponInfo.item] == nil then return end

            local ui = require("uikit")
            local displayedWeapon = ui:createShape(Shape(self.templates[self.weaponInfo.item]), { spherized = true })
			self.displayedWeapon = displayedWeapon
      	  displayedWeapon.parentDidResize = function()
  		      displayedWeapon.Height = self.weaponNameText.Height * 2
      		  displayedWeapon.LocalPosition =  self.weaponNameText.pos + Number3(self.weaponNameText.Width + 5, - self.weaponNameText.Height / 2, 0)
     	   end
     	   displayedWeapon.LocalRotation.Y = math.pi / 2
     	   displayedWeapon:parentDidResize()
	        self:updateAmmoUI()
	        self:updateNameUI()
		end,
        _tick = function(self, dt)
            if self.cooldown > 0 then
				self.cooldown = self.cooldown - dt
				return
			end
			if self.shooting and Player.hp <= 0 then self.shooting = false end
            if not self.shooting or not self.ammo then return end
			if self.cooldown > 0 then return end

            if self.ammo <= 0 then
                self:reload()
                return
            end
            self.ammo = self.ammo - 1
            self:updateAmmoUI()

            if self.ammo == 0 then
                self:reload()
            end

            multi:playerAction("shoot")
            self:onShoot(Player)

            -- recul
            Player.LocalRotation.X = Player.LocalRotation.X - 0.01
            Player.LocalRotation.Y = Player.LocalRotation.Y + ((math.random() * 2) - 1) * 0.01

            self.cooldown = self.currentWeapon.cooldown

			local mapImpact = Camera:CastRay(Map.CollisionGroups, Player)
            local impact
            if self.headshotMultiplier then
                for _,p in pairs(Players) do
                    if p ~= Player then
                        local tmp = Camera:CastRay(p.Head, Player)
                        if tmp and p.hp > 0 and (not mapImpact or mapImpact.Distance > tmp.Distance) then
                            impact = tmp
                            impact.p = p
                            impact.head = true
                            break
                        end
                    end
                end
            end

            if not impact then
                impact = Camera:CastRay(Player.CollisionGroups + Map.CollisionGroups, Player)
            end

            if impact and impact.Object.CollisionGroups == Map.CollisionGroups then
				local impact = Camera:CastRay(impact.Object, Player)
                local pos = Camera.Position + Camera.Forward * impact.Distance
                local rot = impact.Object.Rotation:Copy()
                if impact.FaceTouched == Face.Top then rot = rot + {math.pi * 0.5, 0, 0} end
                if impact.FaceTouched == Face.Bottom then rot = rot + {math.pi * -0.5, 0, 0} end
                if impact.FaceTouched == Face.Left then rot = rot + {0, math.pi * -0.5, 0} end
                if impact.FaceTouched == Face.Right then rot = rot + {0, math.pi * 0.5, 0} end
				if impact.Object.type ~= "barrels" then
	                self:placeNextBulletImpactDecal(pos, rot)
	                multi:playerAction("bidecal", { pos=pos, rot=rot })
				end
            end

            if impact and impact.head or (impact.Object and impact.Object:GetChild(1) and type(impact.Object:GetChild(1)) == "Player") then
                local player
                if impact.head then
                    player = impact.p
                else
                    player = impact.Object:GetChild(1)
                end
				if player.hp <= 0 then return end
                local data = {
                    t = player.ID,
					type = "human",
                    s = Player.ID,
                    dmg = self.currentWeapon.dmg,
                    mult = impact.head and self.headshotMultiplier or 1
                }
                self.hitmarkerSFX:Stop()
                self.hitmarkerSFX:Play()
                self.hitMarker:show()
                UI.Crosshair = false
                Timer(0.1, function()
                    self.hitMarker:hide()
                    UI.Crosshair = true
                end)
                multi:playerAction("dmg", data)
                self:damage(data)
            end

            if self.currentWeapon.mode == "manual" then self.shooting = false end
        end,
        damage = function(self, data)
            local source = Players[math.floor(data.s)]
            local target = Players[math.floor(data.t)]
			if not target then return end
            if target:isDead() then return end
            local dmg = data.dmg * data.mult
            target:damage(dmg, data.mult > 1)

			if target == Player then
				addDamageIndicator(source.Position)
			end

            if target:isDead() then
                require("explode"):shapes(target.Body)
                target.IsHidden = true
                killfeed:addEntry(target.Username, source.Username)
                if target == Player then
                    target.Motion = { 0, 0, 0 }
                    target.Velocity = { 0, 0, 0 }
                    local e = Event()
                    e.action = "killed"
                    e.t = target.ID
                    e.s = source.ID
                    e:SendTo(Server)
                end
                Timer(3, function()
                    respawn(target)
                end)
            end

            local dmgAs = target.dmgAs[target.dmgAsIndex]
			if not dmgAs then return end
            dmgAs:Stop()
            dmgAs:Play()
            target.dmgAsIndex = target.dmgAsIndex + 1
            if target.dmgAsIndex > #target.dmgAs then target.dmgAsIndex = 1 end        
        end,
        setList = function(self, list)
            self.list = list
			for _,weaponInfo in ipairs(list) do
				Object:Load(weaponInfo.item, function(weapon)
					self.templates[weaponInfo.item] = weapon
				end)
			end
        end,
        setWeapon = function(self, p, id, forceNotFPS)
			if id == 5 then id = math.random(4) end
			
            local weaponInfo = self.list[id]
            if not weaponInfo then return end

            if p == Player then
                self.currentWeapon = weaponInfo
                self.maxAmmo = weaponInfo.ammo
                self.ammo = weaponInfo.ammo
                self.weaponName = weaponInfo.name
                self:updateAmmoUI()
                self:updateNameUI()
                multi:playerAction("changeWeapon", { id = id })
            end
			p.weaponId = id
			if not self.templates[weaponInfo.item] then
	            Object:Load(weaponInfo.item, function(weapon)
					self:_setWeapon(p, weapon, weaponInfo, forceNotFPS)
	            end)
				return
			end
		
			local weapon = Shape(self.templates[weaponInfo.item])
			weapon.Pivot = self.templates[weaponInfo.item].Pivot
			self:_setWeapon(p, weapon, weaponInfo, forceNotFPS)
        end,
		_setWeapon = function(self, p, weapon, weaponInfo, forceNotFPS)
			if p.weapon then
                p.weapon:RemoveFromParent()
            end
			weapon.muzzleFlashY = weaponInfo.muzzleFlashY
			weapon.mirror = weaponInfo.mirror
            weapon.Physics = PhysicsMode.Disabled
            p.weapon = weapon
            if p == Player and not forceNotFPS then
                -- attach weapon
                weapon:SetParent(Camera)
				weapon.Scale = (weaponInfo.scale or 1)
				if weaponInfo.mirror then
					weapon.LocalRotation.Y = weapon.LocalRotation.Y + math.pi
				end
                if Screen.Width > Screen.Height then
                    weapon.LocalPosition = Number3(5,-4,10)
                else
                    weapon.LocalPosition = Number3(3,-6,10)
                end
				self.weaponInfo = weaponInfo
				self:updateUI()
            else
                p:EquipRightHand(weapon)
				weapon.Scale = (weaponInfo.scale or 1)
				weapon.LocalPosition.X = weapon.LocalPosition.X - 3
                p.RightArm.IgnoreAnimations = true
                p.RightHand.IgnoreAnimations = true
                p.RightArm.LocalRotation = { -math.pi / 2, -math.pi / 2, 0 }
            end
		end,
        setPlayerMaxHP = function(self, hp)
            self.maxHP = hp
        end
    }
}
setmetatable(weapons, weaponsMetatable)
LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
    weapons:_tick(dt)
end)
LocalEvent:Listen(LocalEvent.Name.OnPlayerJoin, function(p)
    weapons:_initPlayer(p)
end)

uiRoundDuration = {}
local uiRoundDurationMetatable = {
    __index = {
        _isInit = false,
        init = function(self)
            local ui = require("uikit")
            if self._isInit then return end

            local text = ui:createText("End in 0:00")
            text.LocalPosition = Number3(4,2,0)
            text.color = Color.White
            self.text = text

            local bg = ui:createFrame(Color(0,0,0,0.5))
            bg:setParent(ui.rootFrame)
            bg.Width = 150
            bg.Height = text.Height + 6
            self.bg = bg
            bg.IsHidden = true

            text:setParent(self.bg)

            local obj = Object()
            obj:SetParent(World)
            obj.Tick = function()
                if self.endTimeMs == nil or self.endTimeMs < Time.UnixMilli() then
                    self.bg.IsHidden = true
                    return
                end
                self.bg.IsHidden = false
                local time = math.floor((self.endTimeMs - Time.UnixMilli()) / 1000)
                local nbSeconds = string.format("%02d", time % 60)
                local nbMinutes = string.format("%d", math.floor(time / 60))
                text.text = "End in "..nbMinutes..":"..nbSeconds
            end

            self._isInit = true
        end,
        _refreshUI = function(self)            
            self.bg.Width = self.text.Width + 12
            self.bg.LocalPosition = { Screen.Width - self.bg.Width, Screen.Height - self.bg.Height, 0 }
        end,
        update = function(self, endTimeMs)
            self.bg.IsHidden = false
            self.endTimeMs = endTimeMs
            self:_refreshUI()
        end
    }
}
setmetatable(uiRoundDuration,uiRoundDurationMetatable)

uiRoundScore = {}
local uiRoundScoreMetatable = {
    __index = {
        _isInit = false,
        init = function(self)
            local ui = require("uikit")
            if self._isInit then return end

            local bg = ui:createFrame(Color(0,0,0,0))
            bg:setParent(ui.rootFrame)
            bg.Width = 150
            bg.Height = 500
            self.bg = bg
            bg.IsHidden = true

            self._isInit = true
        end,
        _refreshUI = function(self)
            local sortEntries = self:_sortByKillsDesc(self.entries)
            local widerTextWidth = 0
            for k,t in ipairs(sortEntries) do
                t.Text = t.player.Username.."   "..tostring(t.player[self.scoreKey])
                t.LocalPosition = Number3(3, (k-1) * (t.Height + 2), 0)
                t.LocalPosition.Z = -1
                if t.Width > widerTextWidth then
                    widerTextWidth = t.Width
                end
            end
            self.bg.Height = #self.players * (sortEntries[1].Height + 2)
            self.bg.Width = widerTextWidth + 10
            self.bg.parentDidResize = function()
                self.bg.LocalPosition = { 5, Screen.Height - (self.bg.Height + 5), 0 }
            end
            self.bg.parentDidResize()
        end,
        _sortByKillsDesc = function(self,arr)
            local arrCopy = {}
            for i,v in ipairs(arr) do
                table.insert(arrCopy,v)
                v.player[self.scoreKey] = v.player[self.scoreKey] or 0
            end
            table.sort(arrCopy, function(a, b) 
                return a.player[self.scoreKey] < b.player[self.scoreKey]
            end)
            return arrCopy
        end,
        update = function(self, players, scoreKey)
            self.bg.IsHidden = false

            self.players = players
            self.scoreKey = scoreKey

            if self.entries and #self.entries > 0 then
                for k,v in ipairs(self.entries) do
                    v:remove()
                end
            end
            self.entries = {}
            for k,v in ipairs(players) do
                local nameUI = require("uikit"):createText(v.Username.." 0")
                nameUI:setParent(self.bg)
                nameUI.player = v
                --nameUI.color = v == Player and Color.Green or Color.White
                nameUI.color = Color.White
                table.insert(self.entries, nameUI)
            end
            self:_refreshUI()
        end
    }
}
setmetatable(uiRoundScore,uiRoundScoreMetatable)

victoryPodium = {}
local victoryPodiumMetatable = {
    __index = {
        _isInit = false,
        podiumPosition = Number3(0,1000,0),
        _podium = nil,
        init = function(self)
            self._podium = Object()
            self._podium:SetParent(World)
            self._podium.Position = self.podiumPosition - Number3(0,10,0)
            self._podium.IsHidden = true
			self._podium.Physics = PhysicsMode.Disabled

            local floor = MutableShape()
            floor:AddBlock(Color.Black,0,0,0)
            floor:SetParent(self._podium)
            floor.Pivot = Number3(0.5,1,1)
            floor.Scale.X = 200
            floor.Scale.Z = 200
			floor.Physics = PhysicsMode.Disabled

            local wall = MutableShape()
            wall:AddBlock(Color.Black,0,0,0)
            wall:SetParent(self._podium)
            wall.Pivot = Number3(0.5,0,0.5)
            wall.Scale.X = 200
            wall.Scale.Y = 200
			wall.Physics = PhysicsMode.Disabled

            local gold = MutableShape()
            gold:AddBlock(Color.Yellow,0,0,0)
            gold:SetParent(self._podium)
            gold.CollidesWithGroups = Player.CollisionGroups
            gold.Pivot = Number3(0.5,0,1)
            gold.Scale.X = 15
            gold.Scale.Y = 9
            gold.Scale.Z = 15
            gold.LocalPosition = Number3(0,0,0)

            local silver = MutableShape()
            silver:AddBlock(Color.Grey,0,0,0)
            silver:SetParent(self._podium)
            silver.CollidesWithGroups = Player.CollisionGroups
            silver.Pivot = Number3(0.5,0,1)
            silver.Scale.X = 15
            silver.Scale.Y = 6
            silver.Scale.Z = 15
            silver.LocalPosition = Number3(15,0,0)

            local bronze = MutableShape()
            bronze:AddBlock(Color.Orange,0,0,0)
            bronze:SetParent(self._podium)
            bronze.CollidesWithGroups = Player.CollisionGroups
            bronze.Pivot = Number3(0.5,0,1)
            bronze.Scale.X = 15
            bronze.Scale.Y = 3
            bronze.Scale.Z = 15
            bronze.LocalPosition = Number3(-15,0,0)

			asApplause = AudioSource()
    		asApplause.Sound = "crowdapplause_1"
    		asApplause.Volume = 0.07
   		 asApplause.Spatialized = false
			self.asApplause = asApplause

    		asApplause2 = AudioSource()
   		 asApplause2.Sound = "crowdapplause_1"
   		 asApplause2.Volume = 0.08
   		 asApplause2.Pitch = 0.9
   		 asApplause2.Spatialized = false
			self.asApplause2 = asApplause2

   		 asApplause3 = AudioSource()
  		  asApplause3.Sound = "crowdapplause_1"
   		 asApplause3.Volume = 0.09
  		  asApplause3.Pitch = 0.95
  		  asApplause3.Spatialized = false
			self.asApplause3 = asApplause3

            self._isInit = true
        end,
        stop = function(self)
            if not self._lastWinners then return end

            -- hide nameplate
            for _,p in ipairs(self._lastWinners) do
                pcall(function()
                    if p.nameplate then
                        p.nameplate.IsHidden = true
                    end
                end)
            end
        end,
        teleportPlayers = function(self, winners)
            if not self._isInit then print("call victoryPodium:init() first") return end

			if SOUND then
				local asApplause = self.asApplause
				local asApplause2 = self.asApplause2
				local asApplause3 = self.asApplause3
   	         self.asApplause:Play()
   	         Timer(0.49, function()
   	             asApplause2:Play()
   	         end)
   	         Timer(0.94, function()
   	             asApplause3:Play()
   	         end)
   	         Timer(1.49, function()
   	             asApplause:Stop()
   	             asApplause:Play()
   	         end)
   	         Timer(2.1, function()
   	             asApplause2:Stop()
   	             asApplause2:Play()
   	         end)
   	         Timer(2.44, function()
   	             asApplause3:Stop()
   	             asApplause3:Play()
   	         end)
   	         Timer(2.89, function()
   	             asApplause:Stop()
   	             asApplause:Play()
   	         end)
   	         Timer(3.1, function()
   	             asApplause2:Stop()
   	             asApplause2:Play()
   	         end)
   	         Timer(3.44, function()
   	             asApplause3:Stop()
   	             asApplause3:Play()
   	         end)
   	         Timer(3.89, function()
   	             asApplause:Stop()
   	             asApplause:Play()
   	         end)
   	         Timer(4.1, function()
   	             asApplause2:Stop()
   	             asApplause2:Play()
   	         end)
   	         Timer(4.44, function()
   	             asApplause3:Stop()
   	             asApplause3:Play()
   	         end)
   	     end
	
            Player.Head.IsHiddenSelf = false
            Player.Body.IsHiddenSelf = false
            Player.RightArm.IsHidden = false
            Player.LeftArm.IsHidden = false
            Player.RightLeg.IsHidden = false
            Player.LeftLeg.IsHidden = false
            for _,v in pairs(Player.equipments) do
            	v.IsHiddenSelf = false
            	if v.attachedParts then
           	 	for _,v2 in ipairs(v.attachedParts) do
                    	v2.IsHiddenSelf = false
                	end
            	end
            end

            self._podium.IsHidden = false

            self._lastWinners = winners

            Camera:SetModeFree()
            Camera:SetParent(World)
            Camera.Position = self.podiumPosition + Number3(0,10,-40)
            Camera.Rotation = Number3(0.2,0,0)

            pcall(function()
                local p1 = Players[winners[1].ID]
                p1.Position = self.podiumPosition + Number3(0,15,-7.5)
                p1.Forward = Number3(0,0,-1)
                p1.IsHidden = false
                if not p1.nameplate then
                    p1.nameplate = Text()
                    p1.nameplate.Text = p1.Username
                    p1.nameplate:SetParent(p1.Head)
                    p1.nameplate.LocalRotation = Number3(0,math.pi,0)
                    p1.nameplate.LocalPosition = Number3(0,15,0)
                end
                p1.nameplate.IsHidden = false
            end)
            if #winners > 1 then
                pcall(function()
                    local p2 = Players[winners[2].ID]
                    p2.Position = self.podiumPosition + Number3(15,15,-7.5)
                    p2.Forward = Number3(-0.4,0,-1)
                    p2.IsHidden = false
                    if not p2.nameplate then
                        p2.nameplate = Text()
                        p2.nameplate.Text = p2.Username
                        p2.nameplate:SetParent(p2.Head)
                        p2.nameplate.LocalRotation = Number3(0,math.pi,0)
                        p2.nameplate.LocalPosition = Number3(0,15,0)
                    end
                    p2.nameplate.IsHidden = false
                end)
            end
            if #winners > 2 then
                pcall(function()
                    local p3 = Players[winners[3].ID]
                    p3.Position = self.podiumPosition + Number3(-15,15,-7.5)
                    p3.Forward = Number3(0.4,0,-1)
                    p3.IsHidden = false
                    if not p3.nameplate then
                        p3.nameplate = Text()
                        p3.nameplate.Text = p3.Username
                        p3.nameplate:SetParent(p3.Head)
                        p3.nameplate.LocalRotation = Number3(0,math.pi,0)
                        p3.nameplate.LocalPosition = Number3(0,15,0)
                    end
                    p3.nameplate.IsHidden = false
                end)
            end
        end
    },
}
setmetatable(victoryPodium, victoryPodiumMetatable)

local gameStateManager = {}
local gameStateManagerMetatable = {
    __index = {
        States = {
            Lobby = 1,
            PreRound = 2,
            Round = 3,
            EndRound = 4
        },    
        StateNames = {
            "Lobby",
            "PreRound",
            "Round",
            "EndRound"
        },
        Events = {
            GameState = "gs",
            SyncState = "st",
            PlayersInRound = "pr"
        },
        state = 1,
        playerCanJoinDuringRound = true,
        _isClientInit = false,
        _isServerInit = false,
        _clientInit = function(self)
            self.object = Object()
            self.object:SetParent(World)
            self.object.Tick = function(dt)
                self:_clientUpdate(dt)
            end
            self._isClientInit = true
        end,
        playersInRound = {},
        _clientUpdate = function(self, dt)
            if not self._isClientInit then self:_clientInit() end
            local state = self.state

            local tickFunctionName = "client"..self.StateNames[state].."Tick"
            local tickFunction = self[tickFunctionName]
            if tickFunction then
                tickFunction()
            end
        end,
        _clientSetGameState = function(self,newState)
            if not self._isClientInit then self:_clientInit() end
            self.prevState = self.state
            self.state = newState

            local startFunctionName = "client"..self.StateNames[newState].."OnStart"
            local startFunction = self[startFunctionName]
            if startFunction then
                startFunction()
            end
        end,
        clientHandleEvent = function(self, e)
            if not self._isClientInit then self:_clientInit() end
            if e.action == self.Events.GameState then
                self:_clientSetGameState(e.state)
                return true

            elseif e.action == self.Events.PlayersInRound then
                local list = JSON:Decode(e.list)
                local playersInRound = {}
                for _,id in ipairs(list) do
                    table.insert(playersInRound, Players[math.floor(id)])
                end
                self.playersInRound = playersInRound    
                if self.clientRoundPlayersUpdate then
                    self:clientRoundPlayersUpdate(playersInRound)
                end
                return true
            end
            
            return false
        end,
        clientSyncState = function(self)
            local e = Event()
            e.action = gameStateManager.Events.SyncState
            e:SendTo(Server)
        end,    
        _serverInit = function(self)
            self.object = Object()
            self.object:SetParent(World)
            self.object.Tick = function(dt)
                self:_serverUpdate(dt)
            end
            self._isServerInit = true
        end,
        _serverUpdate = function(self, dt)
            if not self._isServerInit then self:_serverInit() end
            local state = self.state
            local tickFunctionName = "server"..self.StateNames[state].."Tick"
            local tickFunction = self[tickFunctionName]
            if tickFunction then
                tickFunction()
            end

            if state == self.States.Lobby then
                if self.minPlayersToStart and #Players >= self.minPlayersToStart then
                    self:serverSetGameState(self.States.PreRound)
                end
            end
        end,
        _serverUpdatePlayersInRound = function(self)
            local playersId = {}

            for _,p in pairs(Players) do
                local alreadyIn = false
                for _,p2 in ipairs(self.playersInRound) do
                    if p2 == p then alreadyIn = true end
                end
                if not alreadyIn then
                    table.insert(self.playersInRound, p)
                end
                table.insert(playersId, p.ID)
                p.nbKills = p.nbKills or 0
            end

            -- sync players in round with clients
            local e = Event()
            e.action = self.Events.PlayersInRound
            e.list = JSON:Encode(playersId)
            e:SendTo(Players)
        end,
        serverSetGameState = function(self,newState)
            if not self._isServerInit then self:_serverInit() end

            if gsm._serverPhaseTimer then
                gsm._serverPhaseTimer:Cancel()
            end

            if newState == self.state then return end
            self.prevState = self.state
            self.state = newState    

            local stateName = self.StateNames[newState]
            local startFunctionName = "server"..stateName.."OnStart"
            local startFunction = self[startFunctionName]
            if startFunction then
                startFunction()
            end

            if self["duration"..stateName] ~= nil then
                gsm.stateEndAt = Time.UnixMilli() + self["duration"..stateName] * 1000
                gsm._serverPhaseTimer = Timer(self["duration"..stateName], function()
                    local nextState
                    if newState == self.States.EndRound then
                        nextState = self.States.PreRound
                    else
                        nextState = newState + 1
                    end
                    self:serverSetGameState(nextState)
                end)
            end

            if newState == self.States.Lobby then
                self.playersInRound = {}
            elseif newState == self.States.PreRound then
                self:_serverUpdatePlayersInRound()
                if self.minPlayersToStart and #self.playersInRound < self.minPlayersToStart then
                    self:serverSetGameState(self.States.Lobby)
                end
            elseif newState == self.States.Round then
                self:_serverUpdatePlayersInRound()
            elseif newState == self.States.EndRound then

            end

            -- sync with players
            local e = Event()
            e.action = self.Events.GameState
            e.state = newState
            e:SendTo(Players)
        end,
        serverHandleEvent = function(self, e)
            if not self._isServerInit then self:_serverInit() end
            if e.action == self.Events.SyncState then
                local ev = Event()
                ev.action = self.Events.GameState
                ev.state = self.state
                ev:SendTo(e.Sender)
                return true
            end
            return false
        end,
        serverOnPlayerJoin = function(self, player)
            if gsm.playerCanJoinDuringRound then
                self:_serverUpdatePlayersInRound()
            end

            Timer(1, function()
                for _,p in ipairs(self.playersInRound) do
                    local e = Event()
                    e.action = "nbKills"
                    e.p = p.ID
                    e.nb = p.nbKills or 0
                    e:SendTo(player)
                end
                if gsm.state == gsm.States.Round then
                    local e = Event()
                    e.action = "roundEndAt"
                    e.t = gsm.stateEndAt
                    e:SendTo(player)
                end
            end)
        end,
        serverOnPlayerLeave = function(self, player)
            for k,p in ipairs(self.playersInRound) do
                if player == p then
                    table.remove(self.playersInRound,k)
                    self:_serverUpdatePlayersInRound()
                end
            end

            if self.minPlayersToStart and #self.playersInRound < self.minPlayersToStart then
                self:serverSetGameState(self.States.Lobby)
            end
        end
    }
}
setmetatable(gameStateManager, gameStateManagerMetatable)
gsm = gameStateManager

killfeed = {}
killfeedMetatable = {
	__index = {
		init = function(self)
			local ui = require("uikit")
			local bg = ui:createFrame(Color(0,0,0,0.0))
			local entries = {}
			for i=1,5 do
				local entry = ui:createText("", Color.White)
				entry:setParent(bg)
				table.insert(entries, entry)
			end
			local redEntries = {}
			for i=1,5 do
				local entry = ui:createText("", Color.Red)
				entry:setParent(bg)
				table.insert(redEntries, entry)
			end
			self.entries = entries
			self.redEntries = redEntries
			bg.parentDidResize = function(self)
				local minWidth = 350
				self.Width = minWidth
				self.Height = (entries[1].Height + 5) * #entries + 5
				for k,e in ipairs(entries) do
					e.pos = { self.Width - 5 - e.Width, self.Height - k * (e.Height + 5), 0 }
					redEntries[k].pos = e.pos
				end
				self.pos = { Screen.Width - self.Width, Screen.Height - self.Height, 0 }
			end
			bg:parentDidResize()
			self.bg = bg
		end,
		addEntry = function(self, target, source)
			local entries = self.entries
			local redEntries = self.redEntries
			for i=#entries,2,-1 do
				entries[i].Text = entries[i - 1].Text
				redEntries[i].Text = redEntries[i - 1].Text
			end
			entries[1].Text = target.." ☠️ by "..source
			redEntries[1].Text = target
			self.bg:parentDidResize()
		end,
		clearEntries = function(self)
			for _,e in ipairs(self.entries) do e.Text = "" end
			for _,e in ipairs(self.redEntries) do e.Text = "" end
		end
	}
}
setmetatable(killfeed, killfeedMetatable)

-- display ammo on the left of the screen
local ammoIndicators = {}
local maxAmmoPerRow = 12

addAmmoIndication = function(numberAmmo, weaponNameText)
    local rowSpacing = weaponNameText.Height * 1.2
	for _, indicator in ipairs(ammoIndicators) do
        indicator:hide()
    end
    ammoIndicators = {}

    local ui = require("uikit")
    local numRows = math.ceil(numberAmmo / maxAmmoPerRow)
    for row = 1, numRows do
        local numAmmoThisRow = math.min(maxAmmoPerRow, numberAmmo - (row - 1) * maxAmmoPerRow)

        for i = 1, numAmmoThisRow do
            local ammoIndicator = ui:createShape(Shape(Items.k40s.gun_bullet))
            
            ammoIndicator.parentDidResize = function()
                ammoIndicator.Width = weaponNameText.Height * 0.6
                ammoIndicator.Height = weaponNameText.Height
                ammoIndicator.LocalPosition = Number3(
                    ((i - 1) / 2) * (ammoIndicator.Width * 3) + 20,
                    (Screen.Height / 3 - 10) - ammoIndicator.Height - (row - 1) * rowSpacing,
                    0
                )
            end
            ammoIndicator.LocalPosition = Number3(
                ((i - 1) / 2) * 35 + 20,
                (Screen.Height / 3 - 10) - ammoIndicator.Height - (row - 1) * rowSpacing,
                0
            )
            ammoIndicator:parentDidResize()
            table.insert(ammoIndicators, ammoIndicator)
        end
    end
end
