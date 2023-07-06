--[[

EAT YOUR FRUITS

Made this game in 48h for Ludum Dare 52 (https://ldjam.com/events/ludum-dare/52/eat-your-fruits).

- [X] players should collide with tree, /!\ though, shake scale should push back
- [X] fix punch (trigger far from a tree, then move to touch a tree)
- [x] auto-destroy fruits if not collected
- [x] set max number of collected fruits
- [x] spawn points
- [x] remove apple from other players when nbFruits == 0
- [x] map
- [x] die when falling off from map
- [ ] consider deaths to compute score (not only kills)
- [ ] improve random positions for trees and spawn points

ISSUES: 
- Implemeted triggers using Objects with collision boxes + Physics = false,
  best workaround I know, but not free of glitches (fruits moving players when falling on them).
  Cubzh physics engine v2 will provide a proper way to implement triggers.

]]--

Config = {
    Map = "aduermael.ld52_arena",
    Items = {"aduermael.apple"}
}

-- Increasing gravity, giving more weight to all objects.
Config.ConstantAcceleration.Y = -300

local PLAYER_CONSTANT_ACCELERATION_Y = -330
local JUMP_STRENGTH = 160

local PLAYER_SPEED = 80

local ROUND_DURATION = 90 -- seconds
local PRE_ROUND_DURATION = 1
local END_ROUND_DURATION = 7
local PROJECTILE_VELOCITY = 400
local PROJECTILE_LIFE = 5.0 -- auto destroyed if not touching anything
local MAX_PROJECTILES = 10 -- maximum number of fruits a player can hold
local FRUIT_LIFE_ON_GROUND = 4.0 -- seconds

local SPAWNPOINT_SEARCH_BOX_SIZE = 5 -- multiplied by map scale
local SPAWN_HEIGHT = 2 -- in "map blocks" (multiplied by map scale)

local MAP_SCALE = 9
local FIRST_PERSON_FOV = 80

Client.OnStart = function()

	-- Dev.DisplayColliders = true 
	
	-- CONSTANTS
	kTreeCollisionGroups = CollisionGroups(4)
	kPunchCollisionGroups = CollisionGroups(5)
	kFruitCollisionGroups = CollisionGroups(6)
	kOtherPlayersCollisionGroups = CollisionGroups(8)

	-- VARS
	roundEndTime = 0 -- client side cache for timer
	
	-- AMBIENCE
	
	-- local ambience = require("ambience")
	-- ambience:set(ambiance.noon)

	require("ambience"):set({
		sky = {
			skyColor = Color(23,165,238),
			horizonColor = Color(137,222,229),
			abyssColor = Color(25,132,180),
			lightColor = Color(148,178,198),
			lightIntensity = 0.600000,
		},
		fog = {
			color = Color(73,221,223),
			near = 280,
			far = 700,
			lightAbsorbtion = 0.400000,
		},
		sun = {
			color = Color(246,242,148),
			intensity = 1.000000,
			rotation = Number3(1.026254, 1.850041, 0.000000),
		},
		ambient = {
			skyLightFactor = 0.100000,
			dirLightFactor = 0.200000,
		}
	})

	Clouds.Altitude = 30

	Map.Scale = MAP_SCALE
	Camera.FOV = FIRST_PERSON_FOV

	-- MODULES
	explode = require("explode")
	particles = require("particles")

	multi = require("multi")
	-- multi.teleportTriggerDistance = 100

	initGameShapes()

	ui:init()

    initSounds()

    -- PARTICLES

	-- explosionEmitter is used to spawn all explosions
	-- other local emitters are used, created when needed
	local config = {
		velocity = function()
			--return Number3(math.random() * 200 - 100, math.random() * 140, math.random() * 200 - 100)
			return Number3(((math.random() * 2) - 1) * 50, 20 + math.random(100), ((math.random() * 2) - 1) * 50)
		end,
		life = function() return 1 end,
		scale = function()
			return 0.5 + math.random() * 0.5
		end,
	}
	explosionEmitter = particles:newEmitter(config)
	explosionEmitter:SetParent(World)

	projectileEmitterConfig = {
		acceleration = function()
			return -Config.ConstantAcceleration * 0.95
		end,
		velocity = function()
			return Number3(((math.random() * 2) - 1) * 10, ((math.random() * 2) - 1) * 10, ((math.random() * 2) - 1) * 10)
		end,
		scale = function()
			return 0.2 + math.random() * 0.1
		end,
		life = function() return 0.3 end
	}

    -- SYNC

    multi:registerPlayerAction("collect", function(sender, data)
		if not sender then return end
		collect(sender, data.fid)
	end)

    multi:registerPlayerAction("punch", function(sender, data)
		if not sender then return end
		sender:SwingRight()
	end)

	multi:registerPlayerAction("fruit", function(sender, data)
		if not sender then return end
		local pos = Number3(data.p[1], data.p[2], data.p[3])
		spawnFruit(nil, sender, data.fid, pos)
	end)

	multi:registerPlayerAction("shake", function(sender, data)
		if not sender then return end
		local tree = _trees[math.floor(data.tid)]
		if tree ~= nil then
			shake(tree, sender)
		end
	end)

    multi:registerPlayerAction("shoot", function(sender, data)
		if not sender then return end
		sender:SwingRight()
		-- local author = Players[math.floor(data.a)]
		local pos = Number3(data.p[1], data.p[2], data.p[3])
		local dir = Number3(data.d[1], data.d[2], data.d[3])
		shoot(sender, pos, dir, data.pid)
	end)

	multi:registerPlayerAction("hit", function(sender, data)
		local source = data.s
		local target = data.t
		local hp = data.hp
		hitPlayer(source, target, hp)
	end)

	gsm.clientLobbyOnStart = function()
		UI.Crosshair = true
		victoryPodium:stop()
		firstPerson()
		print("Waiting for one more player.")
		respawn(Player)
	end

	gsm.clientPreRoundOnStart = function()
		UI.Crosshair = true
		victoryPodium:stop()
		firstPerson()
		for _,p in ipairs(gsm.playersInRound) do
			respawn(p)
		end
	end
	gsm.clientRoundOnStart = function()
		firstPerson()
		for _,p in ipairs(gsm.playersInRound) do
			p.nbKills = 0
			p.nbDeaths = 0
			setNbFruits(p, 0)
			-- respawn(p)
		end

		ui:updateScores()
		roundEndTime = Time.UnixMilli() + ROUND_DURATION * 1000
	end
	gsm.clientRoundTick = function()
	    -- anything to do here?
	end
	gsm.clientEndRoundOnStart = function()
		UI.Crosshair = false

		thirdPerson()
		Player.canMove = false

		local sortedPlayers = {}
		for _,v in ipairs(gsm.playersInRound) do
		    table.insert(sortedPlayers,v)
			pcall(function()
				v.Motion = Number3(0,0,0)
				v.nbKills = v.nbKills or 0
				v.nbDeaths = v.nbDeaths or 0
			end)
		end
		table.sort(sortedPlayers, function(a, b) 
		    return a.nbKills - a.nbDeaths > b.nbKills - b.nbDeaths
		end)

		-- remove what the player may be holding
		if Player.equipped ~= nil then 
			Player.equipped.Tick = nil
			Player.equipped:RemoveFromParent()
			Player:EquipRightHand(nil)
		end

		if Player.equippedHand ~= nil then -- hack for first person mode
			Player.equippedHand.Tick = nil
			Player.equippedHand:RemoveFromParent()
			Player.equippedHand = nil
		end

		victoryPodium:teleportPlayers(sortedPlayers)
	end

	gsm.clientRoundPlayersUpdate = function()
		ui:updateScores()
	end

	-- timer required, otherwise, Map scale not ready for ray casts
	Timer(0.2, function()
		placeMapElements()
		-- again, timer required, otherwise trees aren't really there
		Timer(0.2, function()
			placeSpawnPoints()
		end)
	end)
end

-- CLIENT FUNCTIONS
if Client ~= nil then

	function setNbFruits(player, n)
		local tmp = player.nbFruits
		if n > MAX_PROJECTILES then n = MAX_PROJECTILES end
		if n < 0 then n = 0 end

		player.nbFruits = n
		if player.nbFruits == 0 then
			equip(player, nil)
		elseif tmp == nil or tmp == 0 then
			equip(player,Shape(appleModel))
		end
		if player == Player then
			ui.nbFruitsLabel.Text = "" .. player.nbFruits
			ui:refresh()
		end
	end

	function shake(tree, author)

		if author == Player then
			multi:playerAction("shake", {
	    		tid= tree.id,
	    	})
		end

		local o = tree.shapes

		o.dt = 0.0
		if o.scale == nil then
			o.scale = o.Scale:Copy()
		end

		local speed = 40
		local duration = 0.4
		local span = 0.7

		if o.Tick == nil then
			o.dt = 0.0
			o.shakeEnd = duration

			o.Tick = function(o, dt)
				o.dt = o.dt + dt

				local scaleDiff = (1 + math.sin(o.dt * speed)) * 0.05

				o.Scale = o.scale + {scaleDiff, scaleDiff, scaleDiff}
				if o.dt >= duration then
					o.Scale = o.scale
					o.Tick = nil
				end
			end
		else
			local remaining = o.shakeEnd - o.dt
			if remaining < duration then
				o.shakeEnd = o.shakeEnd + (duration - remaining)
			end
		end
	end

    -- drop player above the map, initializing multiplayer sync if needed
    dropPlayer = function(player)
		if not player then return end
		if player:GetParent() == nil then
            player.canMove = true -- will be used later
            player.nbFruits = 0

            player.Acceleration.Y = PLAYER_CONSTANT_ACCELERATION_Y

			World:AddChild(player)
			-- multi:initPlayer(player)

			if player == Player then
				player.Head:AddChild(AudioListener)

				local collectBox = Object()
				player:AddChild(collectBox)
				collectBox.Physics = PhysicsMode.Trigger
				local boxSize = 30
				local boxHalfSize = boxSize * 0.5
				collectBox.CollisionBox.Min = {-boxHalfSize, -15, -boxHalfSize}
				collectBox.CollisionBox.Max = {boxHalfSize, boxSize-15, boxHalfSize}
				collectBox.LocalPosition = {0,0,0}

				collectBox.CollisionGroups = {}
				collectBox.CollidesWithGroups = kFruitCollisionGroups

				player.collectBox = collectBox

				local punchBox = Object()
				player:AddChild(punchBox)
				punchBox.Physics = PhysicsMode.Trigger
				boxSize = 30
				boxHalfSize = boxSize * 0.5
				punchBox.CollisionBox.Min = {-boxHalfSize, 0, -boxHalfSize}
				punchBox.CollisionBox.Max = {boxHalfSize, boxSize, boxHalfSize}
				punchBox.LocalPosition = {0,2,15}
				
				punchBox.CollisionGroups = kPunchCollisionGroups
				punchBox.CollidesWithGroups = {} -- kTreeCollisionGroups

				player.punchBox = punchBox

				player.punchBox.OnCollisionBegin = function(o1, o2)
					o1.CollidesWithGroups = {}
					shake(o2.tree, player)
					spawnFruit(o2.tree.leaves, player)
					playPunchTree()
				end

			else
				player.CollisionGroups = kOtherPlayersCollisionGroups
			end
		end

		setNbFruits(player, 0)

		if player == Player then
			player.collectBox.OnCollisionBegin = function(o1, o2)
				-- ERROR: OnCollisionBegin seems to be called twice
				-- could be an engine problem.
				if not o2.collected then
					o2.collected = true
					o2.Physics = PhysicsMode.Disabled
					o2:RemoveFromParent()
					playReload()
					collect(player, o2.id)
				end
			end
		end
		
		local o = player.parentBox or player
		o.Velocity = { 0, 0, 0 }

		local mapCenter = Number3(Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5) * Map.Scale

		if _spawnPoints == nil or #_spawnPoints == 0 then
			o.Position = mapCenter
			o.Rotation = { 0, 0, 0 }
		else
			local spawnPoint = _spawnPoints[math.random(1,#_spawnPoints)]
			o.Position = spawnPoint

			local diff =  mapCenter - spawnPoint
			diff.Y = 0
			diff:Normalize()

			o.Rotation = {0, 0, 0}
			o.Forward = diff
		end
	end

	equip = function(player, shape)
		if player.equipped ~= nil then 
			player.equipped.Tick = nil
			player.equipped:RemoveFromParent()
			player:EquipRightHand(nil)
		end

		if player.equippedHand ~= nil then -- hack for first person mode
			player.equippedHand.Tick = nil
			player.equippedHand:RemoveFromParent()
			player.equippedHand = nil
		end

		player.equipped = shape
		
		if player == Player then
			if firstPersonMode then
				if shape == nil then
					local hand = Player.RightHand:Copy()
					Camera:AddChild(hand)

					player.equippedHand = hand
					hand.Pivot = Number3(hand.Width, hand.Height, hand.Depth) * 0.5
					hand.LocalPosition = {7,-5,5}
					hand.LocalRotation = {-math.pi * 0.2,math.pi * 1.5,0}
					hand.dt = 0.0
					hand.Tick = function(o, dt)
						o.dt = o.dt + dt
						hand.LocalPosition.Y = -5 + math.sin(o.dt * 3) * 0.3
					end

				else
					Camera:AddChild(shape)
					shape.Pivot = Number3(shape.Width, shape.Height, shape.Depth) * 0.5
					shape.LocalPosition = {7,-5,7}
					shape.LocalRotation = {0.4,0,0}
					shape.dt = 0.0
					shape.Tick = function(o, dt)
						o.dt = o.dt + dt
						shape.LocalPosition.Y = -5 + math.sin(o.dt * 3) * 0.3
					end
				end
			else
				player:EquipRightHand(shape)	
			end
		else
			player:EquipRightHand(shape)
		end
	end

	thirdPerson = function()
		if not firstPersonMode then return end
		firstPersonMode = false

		Camera:SetModeThirdPerson(Player)
		Player.Body.IsHidden = false
	end

	-- Camera:SetModeFirstPerson is currently broken. (since avatars have hair)
	-- Using this for now, but SetModeFirstPerson will certainly be fixed at some point.
	firstPerson = function()
		if firstPersonMode then return end
		firstPersonMode = true

		Camera:SetModeFree()
		Camera:SetParent(Player)
		Camera.LocalPosition = Number3(0,25,2)
		Camera.LocalRotation = Number3(0,0,0)
		Player.Body.IsHidden = true
	end

	-- places trees, rocks, grass, spawn points...
	function placeMapElements()
		-- using seed for now to avoid syncing trees generation,
		-- but it would be nice to get rid of this and place trees 
		-- differently for each round.
		
		math.randomseed(23)

		local ray = Ray(Number3(0,0,0), Number3(0,-1,0))
		local impact
		for x=3,Map.Width-2 do
			for z=3,Map.Depth-2 do
				ray.Origin = Number3(x-0.5,Map.Height + 10,z-0.5) * Map.Scale
				impact = ray:Cast(Map)

				if impact ~= nil then
					if impact.Block.Color.R == 170 then
						local r = math.random()
						if r > 0.87 then
							local p = ray.Origin + ray.Direction * impact.Distance

							if r > 0.98 then
								local tree = createTree()
								World:AddChild(tree)
								tree.Position = p
							elseif r > 0.93 then
								placeGrass(p)
							else
								placeSmallRock(p)
							end
						end
					end
				end
			end
		end
	end

	function placeSpawnPoints()

		if not _spawnPoints then
			_spawnPoints = {}
		end

		local ray = Ray(Number3(0,0,0), Number3(0,-1,0))
		local impact

		local boxSize = Map.Scale.Y * SPAWNPOINT_SEARCH_BOX_SIZE
		local boxHalfSize = boxSize * 0.5
		local minDelta = Number3(-boxHalfSize,0,-boxHalfSize)
		local maxDelta = Number3(boxHalfSize,boxSize,boxHalfSize)
		local box = Box({0,0,0}, {1,1,1})
		local dir = Number3(0,-1,0)
		local boxImpact

		local n = 0
		for x=3,Map.Width-2 do
			for z=3,Map.Depth-2 do
				local origin = Number3(x-0.5,Map.Height + 20,z-0.5) * Map.Scale

				box.Min = origin + minDelta
				box.Max = origin + maxDelta
				ray.Origin = origin

				boxImpact = box:Cast(dir, 10000, Map.CollisionGroups + kTreeCollisionGroups)
				impact = ray:Cast(Map)

				if impact.Block ~= nil and boxImpact ~= nil then
					if impact.Distance == boxImpact.Distance then
						-- n = n + 1
						local p = ray.Origin + ray.Direction * impact.Distance + {0, SPAWN_HEIGHT * Map.Scale.Y, 0}
						table.insert(_spawnPoints, p)
					end
				end
			end
		end
		-- print("found " .. n .. " spawn points")
	end
end

Client.Tick = function(dt)

    walkTick(dt)

    -- Detect if player is falling,
    -- drop it above the map when it happens.
    if Player.Position.Y < -300 then
    	if gsm.state ~= gsm.States.Round then 
    		respawn(Player)
    		Player:TextBubble("💀 Oops!")
    		return
    	else
    		hitPlayer(Player.ID, Player.ID, 100)
    		multi:playerAction("hit", {s = Player.ID, t = Player.ID, hp = 100})
        end
        asDeathByFalling:Play()

    	-- quick way to avoid calling that condition in loop
    	Player.Position.Y = 100000
    end

    if roundEndTime > 0 then
    	local time = math.floor((roundEndTime - Time.UnixMilli()) / 1000)
    	if time < 0 then time = 0 end
		local nbSeconds = string.format("%02d", time % 60)
		local nbMinutes = string.format("%d", math.floor(time / 60))
		ui.timerLabel.Text = nbMinutes..":"..nbSeconds
    end
end

Client.AnalogPad = function(dx, dy)
    if not Player.canMove then
        Player.Motion = Number3(0,0,0)     
        return
    end
    Player.LocalRotation.Y = Player.LocalRotation.Y + dx * 0.005
    Camera.LocalRotation.X = Camera.LocalRotation.X + -dy * 0.005

    if dpadX ~= nil and dpadY ~= nil then
        Player.Motion = (Player.Forward * dpadY + Player.Right * dpadX) * PLAYER_SPEED
    end
end

Client.DirectionalPad = function(x, y)
    if not Player.canMove then
        Player.Motion = Number3(0,0,0)    
        dpadX = 0
        dpadY = 0
        return
    end
    -- storing globals here for AnalogPad
    -- to update Player.Motion
    dpadX = x dpadY = y
    Player.Motion = (Player.Forward * y + Player.Right * x) * PLAYER_SPEED
end


-- jump function, triggered with Action1
Client.Action1 = function()
    if Player.IsOnGround and Player.canMove then
        Player.Velocity.Y = JUMP_STRENGTH
		playJump()
    end
end

Client.Action2 = function()
	if gsm.state ~= gsm.States.Round and gsm.state ~= gsm.States.Lobby then return end
	if not Player.canMove then return end

	if Player.nbFruits ~= nil and Player.nbFruits > 0 then

		if not Player.nextProjectileID then Player.nextProjectileID = 1 end
		local projectileID = Player.nextProjectileID
		Player.nextProjectileID = Player.nextProjectileID + 1

	    multi:playerAction("shoot", {
	    	a= Player.ID,
	        p={ Camera.Position.X,Camera.Position.Y,Camera.Position.Z },
	        d={ Camera.Forward.X,Camera.Forward.Y,Camera.Forward.Z },
	        pid=projectileID
	    })

	    shoot(Player, Camera.Position:Copy(), Camera.Forward:Copy(), projectileID)
	else
		punch(Player)
	end
end

Client.Action3 = function()
	punch(Player)
end

function punch(player)

	if player == Player then

		player.punchBox.CollidesWithGroups = kTreeCollisionGroups
		Timer(0.1, function()
			player.punchBox.CollidesWithGroups = {}
		end)

		if firstPersonMode then

			local hand = player.equippedHand or player.equipped
			if not hand.punching then
				hand.tick = hand.Tick
				hand.pos = hand.LocalPosition:Copy()
				hand.punching = true
			end
			hand.punchDT = 0.0
			hand.punchDelta = Number3(0,-2,3)
			hand.Tick = function(o, dt)
				local done = false
				local punchDuration = 0.2
				o.punchDT = o.punchDT + dt
				if o.punchDT >= punchDuration then
					o.punchDT = punchDuration
					done = true
				end
				local progress = o.punchDT / punchDuration

				local mov = math.sin(progress*math.pi*2-math.pi*0.5) + 1
				o.LocalPosition = o.pos + (o.punchDelta * mov)

				if done then 
					o.Tick = o.tick
					o.punching = false
				end
			end
		else
			player:SwingRight()
		end

		multi:playerAction("punch", {
	    	a= Player.ID,
	    })

	else
		player:SwingRight()
	end
end

function collect(author, fruitID)
	setNbFruits(author, author.nbFruits + 1)
		
	local fruit = _fruits[fruitID]
	if fruit ~= nil then
		fruit:RemoveFromParent()
		_fruits[fruitID] = nil
	end

	if author == Player then
		-- inform others that fruit has been collected
		multi:playerAction("collect", {
			fid= fruitID,
		})
	end
end


function shoot(author, pos, dir, projectileID)
	if projectileID == nil then error("projectile should have an ID") end

	if author == Player and author.nbFruits == 0 then return end -- can't shoot without fruits

	setNbFruits(author, author.nbFruits - 1)

	author.asThrow.Position = pos
	author.asThrow:Stop()
	author.asThrow.Pitch = 1 + ((math.random() * 2) - 1) * 0.1
	author.asThrow:Play()

	local projectile = Shape(appleModel)
	projectile.id = projectileID

	if not author.projectiles then author.projectiles = {} end

	author.projectiles[projectile.id] = projectile

	projectile.life = PROJECTILE_LIFE
	World:AddChild(projectile)

	projectile.CollisionGroups = {}
	projectile.CollidesWithGroups = {}

	-- adding little delay to active collisions
	-- otherwise, explosion is triggered when there's a wall
	-- in your back ^^'
	Timer(0.02, function()
		projectile.CollidesWithGroups = Map.CollisionGroups + kOtherPlayersCollisionGroups + kTreeCollisionGroups
	end)

	projectile.Physics = true
	projectile.Position = pos
	projectile.Forward = dir
	projectile.Acceleration = -Config.ConstantAcceleration
	projectile.Velocity = dir * PROJECTILE_VELOCITY
	projectile.Friction = 1
	projectile.Bounciness = 0.8
	
	projectile.emitter = particles:newEmitter(projectileEmitterConfig)
	projectile.emitter:SetParent(projectile)
	
	projectile.emitter.Tick = function(o, dt)
		o:spawn(2)
	end

	projectile.rot = Number3(0,0,0)
	projectile.rotX = (math.random() * 6.0) - 3.0
	projectile.rotY = (math.random() * 10.0) - 5.0

	projectile.Tick = function(o, dt)
		o.rot.X = o.rot.X + dt * o.rotX
		o.rot.Y = o.rot.Y + dt * o.rotY
		o.Rotation = o.rot

		o.life = o.life - dt
		if o.life <= 0 then
			o:OnCollision(Map)
		end
	end

	-- o1: projectile
	-- o2: object projectile enters in collision with
	projectile.OnCollision = function(o1, o2) 

		if author == Player then
			if o2.CollisionGroups == kTreeCollisionGroups then
				shake(o2.tree, author)
				spawnFruit(o2.tree.leaves, author)
			end
		end

		author.projectiles[o1.id] = nil
		
		o1.Tick = nil
		o1.emitter.Tick = nil
		author.asExplode.Position = o1.Position
		if author.asThrow:GetParent() == o1 then
			author.asThrow:Stop()
		end
		author.asExplode:Stop()
		author.asExplode:Play()

		explosionEmitter.Position = o1.Position
		explosionEmitter:spawn(20)

		o1:RemoveFromParent()

		local pos = o1.Position:Copy()

		local sphere1 = {center = pos, radius = 15}
		local sphere2 = {center = pos, radius = 25}

		if Player == author then
			for _,p in pairs(Players) do
				if p ~= Player and p.hp > 0 then

					-- NOTE: this is weird that the box has to be offseted
					-- prior to local to world conversion.
					-- It's not clear in docs if the collision box is expressed
					-- in local coorfinates, but they're definitely not world coords. 
					-- Let's clarify that.
					local box = p.CollisionBox:Copy()
					box.Min = {-box.Max.X * 0.5, 0, -box.Max.Z * 0.5}
					box.Max = {box.Max.X * 0.5, box.Max.Y, box.Max.Z * 0.5}
					box.Min = p:PositionLocalToWorld(box.Min)
					box.Max = p:PositionLocalToWorld(box.Max)

					if sphereCollidesWithBox(sphere1, box) then
						multi:playerAction("hit", {s = Player.ID, t = p.ID, hp = 100})
						hitPlayer(Player.ID, p.ID, 100)
					elseif sphereCollidesWithBox(sphere2, box) then
						multi:playerAction("hit", {s = Player.ID, t = p.ID, hp = 50})
						hitPlayer(Player.ID, p.ID, 50)
					end
				end
			end
		end
	end
end

function killAndRespawn(player)
	if not player then return end
    player.IsHidden = true
    if player == Player then
        player.canMove = false
    end
    Timer(2, function()
		if gsm.state ~= gsm.States.Round then return end
		-- Avoid error when player just left
		pcall(function()
 	       respawn(player)
		end)
    end)
end

function respawn(player)
	if not player then return end

    if player == Player then
    	dropPlayer(player)
        player.canMove = true
	end

	-- Wait to avoid showing character when respawning
	Timer(0.5, function()
		if gsm.state ~= gsm.States.Round then return end
		-- Avoid error when player just left
		pcall(function()
	    	player.IsHidden = false
			player.hp = 100
		end)
	end)
end

function hitPlayer(source, target, hp)
	if gsm.state ~= gsm.States.Round then return end
    local sourcePlayer
	local targetPlayer

	for k,p in pairs(Players) do
		if k == source then
			sourcePlayer = p
		end
		if k == target then
			targetPlayer = p
		end
	end

	if sourcePlayer == nil then return end
	if targetPlayer == nil then return end
	targetPlayer.hp = targetPlayer.hp - hp
	if targetPlayer.hp <= 0 then
		if targetPlayer == Player then
			local e = Event()
			e.action = "killed"
			e.t = target
			e.s = source
			e:SendTo(Server)
		end
		explode:shapes(targetPlayer.Body)
        killAndRespawn(targetPlayer)
		print(targetPlayer.Username.." 💀 by "..sourcePlayer.Username)
		if sourcePlayer == Player then
			asPingKill:Play()
		end
	end
end

Client.OnPlayerJoin = function(player)
	print(player.Username.." joined the game.")

	player.CollidesWithGroups = Map.CollisionGroups

	dropPlayer(player)

	player.hp = 100
	player.kills = 0
	player.deaths = 0

	local asThrow = AudioSource()
	asThrow.Sound = "whooshes_small_4"
	asThrow.Volume = 0.3
	asThrow.Radius = 600
	
	asThrow.Spatialized = true
	asThrow:SetParent(World)
	player.asThrow = asThrow

	local asExplode = AudioSource()
	asExplode.Sound = "drumkick_1" -- "small_explosion_3"
	asExplode.Volume = 0.75
	asExplode.Radius = 300
	asExplode.Spatialized = true
	asExplode:SetParent(World)
	player.asExplode = asExplode

	if player == Player then
		Player.Body.IsHidden = true
		gsm:clientSyncState()
	end
end

Client.OnPlayerLeave = function(player)
	print(player.Username.." just left the game.")
end

Client.DidReceiveEvent = function(event)
	if gsm:clientHandleEvent(event) then return end

	if event.action == "stats" then
		local source = Players[math.floor(event.p)]
		if not source then return end
		source.nbKills = event.kills
		source.nbDeaths = event.deaths
		ui:updateScores()
	end
end

Screen.DidResize = function(width, height)
	uikit:fitScreen()
	ui:refresh()
end

-- SERVER

Server.OnStart = function()
	gsm.minPlayersToStart = DEBUG == true and 1 or 2
	gsm.playerCanJoinDuringRound = true
	gsm.durationPreRound = PRE_ROUND_DURATION
	gsm.durationRound = ROUND_DURATION
	gsm.durationEndRound = END_ROUND_DURATION

	gsm.serverLobbyOnStart = function() end

	gsm.serverRoundOnStart = function()
		for _,p in ipairs(gsm.playersInRound) do
			p.nbKills = 0
			p.nbDeaths = 0
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
		local target = Players[math.floor(e.t)]

		source.nbKills = source.nbKills or 0
		target.nbDeaths = target.nbDeaths or 0

		if source == target then -- self kill
			target.nbDeaths = target.nbDeaths + 1
		else
			source.nbKills = source.nbKills + 1
			target.nbDeaths = target.nbDeaths + 1
		end

		local e = Event()
		e.action = "stats"
		e.p = source.ID
		e.kills = source.nbKills
		e.deaths = source.nbDeaths
		e:SendTo(Players)

		if source ~= target then
			local e = Event()
			e.action = "stats"
			e.p = target.ID
			e.kills = target.nbKills
			e.deaths = target.nbDeaths
			e:SendTo(Players)
		end

		if source.nbKills >= 10 then
			gsm:serverSetGameState(gsm.States.EndRound)
		end
	end
end

-- UI

ui = {
	padding = 8,
	smallPadding = 4,
	players = {}, -- labels for each connected player, indexed by ID
	orderedPlayers = {}, -- ordered labels
}

ui.init = function(self)

	victoryPodium:init()

	uikit = require("uikit")
	uikit:init()

	Pointer:Hide()
	UI.Crosshair = true

	local topLeft = uikit:createNode()
	topLeft:setParent(uikit.rootFrame)
	self.topLeft = topLeft

	local bg = uikit:createFrame(Color(0,0,0,0.5))
	bg:setParent(topLeft)
	topLeft.LocalPosition.Z = -1 -- nessary due to uikit issues (temporary)
	topLeft.bg = bg

	local topRight = uikit:createNode()
	topRight:setParent(uikit.rootFrame)
	self.topRight = topRight

	bg = uikit:createFrame(Color(0,0,0,0.5))
	bg:setParent(topRight)
	topRight.LocalPosition.Z = -1 -- nessary due to uikit issues (temporary)
	topRight.bg = bg

	local bottomRight = uikit:createNode()
	bottomRight:setParent(uikit.rootFrame)
	self.bottomRight = bottomRight

	bg = uikit:createFrame(Color(0,0,0,0.5))
	bg:setParent(bottomRight)
	-- nessary due to uikit issues (temporary)
		-- bottomRight.LocalPosition.Z = 250 
		bg.LocalPosition.Z = -1
	bottomRight.bg = bg

	self.nbFruitsLabel = uikit:createText("" .. 0, Color.White)
	self.nbFruitsLabel:setParent(bottomRight)

	local apple = Shape(appleModel)

	self.fruitsIcon = uikit:createShape(apple)
	self.fruitsIcon:setParent(bottomRight)

	-- NOTE: -2 to exclude apple's stem
	apple.Pivot = Number3(apple.Width, apple.Height - 2, apple.Depth) * 0.5

	apple.rot = Number3(0.1,0,0)
	apple.dt = 0.0
	apple.scale = apple.Scale:Copy()
	apple.Tick = function(o, dt)
		o.rot.Y = o.rot.Y + dt
		o.Rotation = o.rot
		o.dt = o.dt + dt
		o.Scale = apple.scale + apple.scale * math.sin(o.dt * 10) * 0.1
	end

	self.timerLabel = uikit:createText("0:00", Color.White)
	self.timerLabel:setParent(topRight)

	ui:refresh()
end

ui.refresh = function(self)
	
	-- BOTTOM RIGHT

	self.nbFruitsLabel.LocalPosition.X = -self.nbFruitsLabel.Width - self.padding
	self.nbFruitsLabel.LocalPosition.Y = self.padding

	self.fruitsIcon.LocalPosition.X = self.nbFruitsLabel.LocalPosition.X - self.fruitsIcon.Width - self.padding * 2
	self.fruitsIcon.LocalPosition.Y = self.nbFruitsLabel.LocalPosition.Y + self.nbFruitsLabel.Height * 0.5 - self.fruitsIcon.Height * 0.5

	self.bottomRight.LocalPosition.X = Screen.Width - self.padding
	self.bottomRight.LocalPosition.Y = self.padding

	self.bottomRight.bg.Width = self.nbFruitsLabel.Width + self.padding * 2 + 40
	self.bottomRight.bg.Height = self.nbFruitsLabel.Height + self.padding * 2
	self.bottomRight.bg.LocalPosition.X = -self.bottomRight.bg.Width

	-- TOP RIGHT

	self.timerLabel.LocalPosition.X = -self.timerLabel.Width - self.padding
	self.timerLabel.LocalPosition.Y = -self.timerLabel.Height - self.padding

	self.topRight.LocalPosition.X = Screen.Width - self.padding
	self.topRight.LocalPosition.Y = Screen.Height - self.padding

	self.topRight.bg.Width = self.timerLabel.Width + self.padding * 2
	self.topRight.bg.Height = self.timerLabel.Height + self.padding * 2
	self.topRight.bg.LocalPosition.X = -self.topRight.bg.Width
	self.topRight.bg.LocalPosition.Y = -self.topRight.bg.Height

	-- TOP LEFT

	self.topLeft.LocalPosition.X = self.padding
	self.topLeft.LocalPosition.Y = Screen.Height - self.padding

	self:updateScores()
end

ui.updateScores = function(self)
	
	local startX = self.padding
	local startY = -self.padding

	local toRemove = {}
	local toAdd = {}

	local found
	for id, _ in pairs(self.players) do
		found = false
		for _, p in ipairs(gsm.playersInRound) do
			if id == p.ID then found = true break end
		end
		if found == false then
			table.insert(toRemove, id)
		end
	end

	-- REMOVE
	for _, id in ipairs(toRemove) do
		self.players[id].label:remove()
		self.players[id].kills:remove()
		self.players[id].separator:remove()
		self.players[id].deaths:remove()
		self.players[id] = nil
	end

	-- add newcomers
	local entry
	for _, p in ipairs(gsm.playersInRound) do
		entry = self.players[p.ID]
		if entry == nil then
			entry = {}

			entry.nbKills = p.nbKills or 0
			entry.nbDeaths = p.nbDeaths or 0

			entry.ID = p.ID

			entry.label = uikit:createText(p.Username, Color.White)
			entry.label:setParent(self.topLeft)

			entry.kills = uikit:createText("" .. entry.nbKills, Color.Green)
			entry.kills:setParent(self.topLeft)

			entry.separator = uikit:createText("|", Color.White)
			entry.separator:setParent(self.topLeft)

			entry.deaths = uikit:createText("" .. entry.nbDeaths, Color.Red)
			entry.deaths:setParent(self.topLeft)

			self.players[entry.ID] = entry
		end

		-- update
		if p.nbKills ~= nil and entry.nbKills ~= p.nbKills then
			entry.nbKills = p.nbKills
			entry.kills.Text = "" .. entry.nbKills
		end

		if p.nbDeaths ~= nil and entry.nbDeaths ~= p.nbDeaths then
			entry.nbDeaths = p.nbDeaths
			entry.deaths.Text = "" .. entry.nbDeaths
		end
		
	end

	local ordered = {}

	for _,entry in pairs(self.players) do
		entry.nbKills = entry.nbKills or 0
		table.insert(ordered,entry)
	end

	if #ordered == 0 then return end

	table.sort(ordered, function(a, b) 
		return a.nbKills - a.nbDeaths > b.nbKills - b.nbDeaths
	end)

	local previous
	local maxEdge = 0
	for i, e in ipairs(ordered) do

		e.label.LocalPosition.X = startX

		if previous ~= nil then
			e.label.LocalPosition.Y = previous.LocalPosition.Y - e.label.Height - self.padding
		else
			e.label.LocalPosition.Y = -e.label.Height + startY
		end

		e.kills.LocalPosition.Y = e.label.LocalPosition.Y
		e.separator.LocalPosition.Y = e.label.LocalPosition.Y
		e.deaths.LocalPosition.Y = e.label.LocalPosition.Y

		e.kills.LocalPosition.X = e.label.LocalPosition.X + e.label.Width + self.padding
		e.separator.LocalPosition.X = e.kills.LocalPosition.X + e.kills.Width + self.smallPadding
		e.deaths.LocalPosition.X = e.separator.LocalPosition.X + e.separator.Width + self.smallPadding

		local edge = e.deaths.LocalPosition.X + e.deaths.Width
		if edge > maxEdge then maxEdge = edge end

		previous = e.label
	end

	self.topLeft.bg.Width = maxEdge + self.padding
	self.topLeft.bg.LocalPosition.Y = previous.LocalPosition.Y - self.padding
	self.topLeft.bg.Height = -self.topLeft.bg.LocalPosition.Y
end


-- Inits/builds shapes used by the game.
function initGameShapes()
	-- tree trunk colors
	local c1 = Color(100,100,100)
	local c2 = Color(80,80,80)
	local c3 = Color(150,150,150) -- inside

	-- leaves colors
	local c4 = Color(100,150,100)
	local c5 = Color(80,100,80)

	local trunkPartSize = 10
	local trunkPartSizeMinusOne = trunkPartSize - 1

	local _trunkPart = MutableShape()
	for x=0,trunkPartSizeMinusOne do
		for z=0,trunkPartSizeMinusOne do
			for y=0,trunkPartSizeMinusOne do
				if x == 0 or z == 0 or x == trunkPartSizeMinusOne or z == trunkPartSizeMinusOne then
					if math.random() > 0.8 then
						_trunkPart:AddBlock(c2, x,y,z)
					else
						_trunkPart:AddBlock(c1, x,y,z)
					end
				elseif y == 0 or y == trunkPartSizeMinusOne then
					_trunkPart:AddBlock(c3, x,y,z)
				end
			end
		end
	end
	_trunkPart.Pivot = {trunkPartSize * 0.5, 0, trunkPartSize * 0.5}

	trunkPart = Shape(_trunkPart)

	trunkPart.CollisionGroups = kTreeCollisionGroups

	local leavesPartSize = 10
	local leavesPartSizeMinusOne = leavesPartSize - 1

	local _leavesPart = MutableShape()
	for x=0,leavesPartSizeMinusOne do
		for z=0,leavesPartSizeMinusOne do
			for y=0,leavesPartSizeMinusOne do
				if x == 0 or x == leavesPartSizeMinusOne
					or z == 0 or z == leavesPartSizeMinusOne
					or y == 0 or y == leavesPartSizeMinusOne then
					if math.random() > 0.8 then
						_leavesPart:AddBlock(c5, x,y,z)
					else
						_leavesPart:AddBlock(c4, x,y,z)
					end
				end
			end
		end
	end
	_leavesPart.Pivot = {leavesPartSize * 0.5, 0, leavesPartSize * 0.5}
	leavesPart = Shape(_leavesPart)

	leavesPart.CollisionGroups = kTreeCollisionGroups

	createTree = function()
		if not _trees then -- create index for trees
			_trees = {}
			_treesNextIndex = 1
		end

		local tree = Object()

		tree.id = _treesNextIndex
		_treesNextIndex = _treesNextIndex + 1
		_trees[tree.id] = tree

		tree.shapes = Object()
		tree.colliders = Object()

		tree:AddChild(tree.shapes)
		tree:AddChild(tree.colliders)

		local parts = math.random(3,4)

		local part
		local previousPart

		local collider
		local previousCollider
		-- trunk
		for i = 1,parts do
			part = Shape(trunkPart)

			part.tree = tree

			local thickness = 1 - (i - 1) / 15
			part.Scale = {thickness, 1.0 + math.random() * 0.5, thickness}

			if previousPart ~= nil then
				previousPart:AddChild(part)
				part.LocalPosition.Y = trunkPartSize - 1
			else
				tree.shapes:AddChild(part)
			end

			part.LocalRotation = {math.random() * 0.2, math.random(0,3) * math.pi, 0}

			-- set collider
			-- Using separate colliders because we scale tree parts
			-- and don't want the box to be affected by what's only 
			-- supposed to be a visual effect. 
			collider = Object()

			-- againg, offsetting boxes to compensate probable engine issue
			-- + adding little scale margin
			local box = part.CollisionBox:Copy()
			box.Min = Number3(-box.Max.X * 0.5, 0, -box.Max.Z * 0.5) * 1.05
			box.Max = Number3(box.Max.X * 0.5, box.Max.Y, box.Max.Z * 0.5) * 1.05
			collider.CollisionBox = box

			collider.CollidesWithGroups = Player.CollisionGroups
			if previousCollider ~= nil then
				previousCollider:AddChild(collider)
			else
				tree.colliders:AddChild(collider)
			end
			collider.LocalPosition = part.LocalPosition
			collider.LocalRotation = part.LocalRotation
			collider.Scale = part.Scale

			-- fix for 0.0.49
			if PhysicsMode ~= nil then
				collider.Physics = PhysicsMode.Static
				collider.Friction = Map.Friction -- 1 -- 1: no friction
				collider.Bounciness = 0
			end

			-- part.Physics = PhysicsMode.Disabled

			previousCollider = collider
			previousPart = part
		end

		parts = math.random(2,3)

		-- leaves
		for i = 1,parts do
			part = Shape(leavesPart)
			part.tree = tree

			local thickness = (5 - i) * (1 + math.random() * 0.3) * 0.8

			previousPart:AddChild(part)
			part.LocalPosition.Y = trunkPartSize - 1

			part.Scale = {thickness, 1.0 + math.random() * 0.5, thickness}
			part.Scale = part.Scale / previousPart.LossyScale

			part.LocalRotation = {math.random() * 0.2, math.random(0,3) * math.pi, 0}

			previousPart = part

			-- fruits will fall from there
			if i == 1 then
				part.Shadow = true
				tree.leaves = part
			end
		end

		return tree
	end

	-- Fruits

	appleModel = Shape(Items.aduermael.apple)

	-- if & pos are nil when the fruit is generated locally
	spawnFruit = function(leaves, author, id, pos)

		-- create index for fruits
		-- fruit ids are built combining player ID + increment
		if not _fruits then
			_fruits = {}
			_fruitsNextIndex = 1
		end

		local apple = Shape(appleModel)

		if author == Player then
			if id ~= nil then error("id should be nil when spawning local fruit") end
			id = "" .. Player.ID .. ":".. _fruitsNextIndex
			_fruitsNextIndex = _fruitsNextIndex + 1
		end

		apple.id = id
		_fruits[apple.id] = apple

		if pos ~= nil then
			-- use provided spawn position
			World:AddChild(apple)
			apple.Position = pos
		else 
			leaves:AddChild(apple)

			-- pick random position within first level of tree leaves
			-- not too close from trunk

			local halfW = leaves.Width * 0.5
			local dFromCenter = 2.5

			local d = Number3(0,0,1)
			d:Rotate({0,math.random() * math.pi * 2, 0})
			d = d * (dFromCenter + math.random() * (halfW - dFromCenter))

			apple.LocalPosition.Y = -2
			apple.LocalPosition.X = d.X
			apple.LocalPosition.Z = d.Z

			World:AddChild(apple, true) -- keep world position
		end
		
		apple.Rotation = {0,0,0}
		apple.Physics = true
		apple.CollisionGroups = kFruitCollisionGroups
		apple.CollidesWithGroups = Map.CollisionGroups

		local fruitID = apple.id
		Timer(FRUIT_LIFE_ON_GROUND, function()
			local fruit = _fruits[fruitID]
			if fruit ~= nil then
				fruit:RemoveChildren() -- removes trigger
				fruit.dt = 0.0
				local duration = 0.3
				fruit.Tick = function(o,dt)
					local done = false
					o.dt = o.dt + dt
					if o.dt > duration then o.dt = duration done = true end
					local progress = o.dt / duration
					o.Scale = 1 - progress * progress
					if done then
						o.Tick = nil
						o:RemoveFromParent()
					end
				end
				_fruits[fruitID] = nil
			end
		end)

		if author == Player then
			multi:playerAction("fruit", {
				fid= apple.id,
				p={ apple.Position.X,apple.Position.Y,apple.Position.Z },
			})
		end
	end
end

-- SOUNDS

function initSounds()

	local asPunchTree1 = AudioSource()
	asPunchTree1.Sound = "wood_impact_1"
	asPunchTree1.Volume = 0.5
	asPunchTree1.Spatialized = false

	local asPunchTree2 = AudioSource()
	asPunchTree2.Sound = "wood_impact_3"
	asPunchTree2.Volume = 0.5
	asPunchTree2.Spatialized = false

	asPunchTree3 = AudioSource()
	asPunchTree3.Sound = "wood_impact_4"
	asPunchTree3.Volume = 0.5
	asPunchTree3.Spatialized = false

	local asPunchTree4 = AudioSource()
	asPunchTree4.Sound = "wood_impact_5"
	asPunchTree4.Volume = 0.5
	asPunchTree4.Spatialized = false

	asPunchTree = { asPunchTree1, asPunchTree2, asPunchTree3, asPunchTree4 }

	function playPunchTree()
		local s = asPunchTree[math.random(1,#asPunchTree)]
		s:Stop()
		s:Play()
	end

	asReload1 = AudioSource()
	asReload1.Sound = "gun_reload_1"
	asReload1.Volume = 0.3
	asReload1.Spatialized = false

	asReload2 = AudioSource()
	asReload2.Sound = "gun_reload_2"
	asReload2.Volume = 0.3
	asReload2.Spatialized = false

	asReload3 = AudioSource()
	asReload3.Sound = "gun_reload_3"
	asReload3.Volume = 0.3
	asReload3.Spatialized = false

	asReload = { asReload1, asReload2, asReload3 }

	function playReload()
		local s = asReload[math.random(1,#asReload)]
		s:Stop()
		s:Play()
	end

	asJump1 = AudioSource()
	asJump1.Sound = "hurtscream_1"
	asJump1.Volume = 0.2
	asJump1.Spatialized = false

	asJump2 = AudioSource()
	asJump2.Sound = "hurtscream_2"
	asJump2.Volume = 0.2
	asJump2.Spatialized = false

	asJump3 = AudioSource()
	asJump3.Sound = "hurtscream_3"
	asJump3.Volume = 0.2
	asJump3.Spatialized = false

	asJumps = { asJump1, asJump2, asJump3 }

	function playJump()
		local s = asJumps[math.random(1,#asJumps)]
		s:Stop()
		s:Play()
	end

	asDeathByFalling = AudioSource()
	asDeathByFalling.Sound = "deathscream_3"
	asDeathByFalling.Volume = 0.3
	asDeathByFalling.Spatialized = false

	asPingKill = AudioSource()
	asPingKill.Sound = "metal_clanging_3"
	asPingKill.Volume = 0.65
	asPingKill.Spatialized = false
	asPingKill.Pitch = 2

	function walkAudioPlay(shape, asset, key)
        local audio
        if key == nil then
            audio = shape.audio
        else audio = shape[key] end
        audio:Stop()
        audio.Sound = asset
        audio.Spatialized = true
        audio.Volume = audio.vol    -- proxy attribute
        audio:Play()
    end

    Player.walk = 0
	local audio = AudioSource()
	audio.vol = 0.2
	Player.step = audio
	Player:AddChild(audio)

	function walkTick(dt)
        Player.walk = Player.walk + dt
        if Player.IsOnGround and (Player.Motion.SquaredLength > 0.01) then
            if Player.walk > 0.3 then
                Player.walk = 0
                if Player.BlockUnderneath == nil then return end
                local fileNum = math.random(5) 
                local c = Player.BlockUnderneath.Color
                local r = c.R
                local g = c.G
                local b = c.B
                -- quick way to define what sound to play
				-- changing the map would break that... 
                if r == g and r == b then
					walkAudioPlay(Player, "walk_concrete_"..fileNum, "step")
                elseif r == 170 or r == 209 then
                	walkAudioPlay(Player, "walk_grass_"..fileNum, "step")
                else
                	walkAudioPlay(Player, "walk_wood_"..fileNum, "step")
                end
				
            end
        end
    end
end

-- GAME STATE MANAGER
-- This is a work in progress module by @caillef, 
-- pasted here because not available directly on Cubzh yet.

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
				p.nbDeaths = p.nbDeaths or 0
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
                    e.action = "stats"
                    e.p = p.ID
                    e.kills = p.nbKills or 0
                    e.deaths = p.nbDeaths or 0
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


-- VICTORY PODIUM
-- This is a work in progress module by @caillef, 
-- pasted here because not available directly on Cubzh yet.

victoryPodium = {}
local victoryPodiumMetatable = {
	__index = {
		_isInit = false,
		podiumPosition = Number3(0,500,0),
		_podium = nil,
		init = function(self)
			self._podium = Object()
			self._podium:SetParent(World)
			self._podium.Position = self.podiumPosition - Number3(0,10,0)
			self._podium.IsHidden = true

			local floor = MutableShape()
			floor:AddBlock(Color.Black,0,0,0)
			floor:SetParent(self._podium)
			floor.CollidesWithGroups = Player.CollisionGroups
			floor.Pivot = Number3(0.5,1,1)
			floor.Scale.X = 200
			floor.Scale.Z = 200

			local wall = MutableShape()
			wall:AddBlock(Color.Black,0,0,0)
			wall:SetParent(self._podium)
			wall.Pivot = Number3(0.5,0,0.5)
			wall.Scale.X = 200
			wall.Scale.Y = 200

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

			self._podium.IsHidden = false

			self._lastWinners = winners

			Camera:SetModeFree()
			Camera:SetParent(World)
			Camera.Position = self.podiumPosition + Number3(0,10,-30)
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

-- UTILS

-- sphere: {center, radius, sqRadius}
function sphereCollidesWithBox(sphere, box)
	if sphere == nil then return false end
	if sphere.radius == nil then return false end
	if sphere.sqRadius == nil then sphere.sqRadius = sphere.radius * sphere.radius end

  	-- get box closest point to sphere center
	local x = math.max(box.Min.X, math.min(sphere.center.X, box.Max.X));
	local y = math.max(box.Min.Y, math.min(sphere.center.Y, box.Max.Y));
	local z = math.max(box.Min.Z, math.min(sphere.center.Z, box.Max.Z));

	-- see if closest point is within sphere
	local sqDistance = (x - sphere.center.X) * (x - sphere.center.X) +
						(y - sphere.center.Y) * (y - sphere.center.Y) +
						(z - sphere.center.Z) * (z - sphere.center.Z)

 	return sqDistance < sphere.sqRadius;
end

-- generates & places grass at given position
placeGrass = function(pos)

	if _bladeModel == nil then
		_bladeModel = MutableShape()
		_bladeModel:AddBlock(Color(52,131,63),0,0,0)
		_bladeModel.Pivot = {0.5, 0, 0.5}
		_bladeModel = Shape(_bladeModel)
	end

	local grass = Object()

	for i = 1, math.random(1,4) do
		local blade = Shape(_bladeModel)

		blade.Physics = PhysicsMode.Disabled

		grass:AddChild(blade)
		blade.Scale.Y = 2 + math.random() * 4
		blade.LocalRotation = {math.random() * 0.9, math.random() * math.pi * 2, 0}
	end

	World:AddChild(grass)
	grass.Position = pos
	grass.Rotation = {0, math.random() * math.pi * 2, 0}
end

-- places small rock at given position
placeSmallRock = function(pos)
	if _rockModel == nil then
		_rockModel = MutableShape()
		_rockModel:AddBlock(Color(170,170,170),0,0,0)
		_rockModel.Pivot = {0.5, 0, 0.5}
	end

	local rock = Shape(_rockModel)
	rock.Scale = {1 + math.random() * 3, 0.5 + math.random() * 1.5, 1 + math.random() * 3}

	World:AddChild(rock)
	rock.Position = pos
	rock.Rotation = {0, math.random() * math.pi * 2, 0}
	rock.Physics = PhysicsMode.Disabled
end