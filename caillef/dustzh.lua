
Config = {
    Map = "caillef.quakzh_dust2",
    Items = { "caillef.wooden_crate", "caillef.barrels", "xavier.damage_indicator", "caillef.roboteye" }
}

local DEBUG = false -- starts with a single player
local SOUND = true
local ROUND_DURATION = 240
local SPAWN_BLOCK_COLOR = Color(136,0,252)
local MAX_NB_KILLS_END_ROUND = 40
local displayControls =  true -- display controls at start

Config.ConstantAcceleration.Y = -300

local weaponsList = {
    { name="Rifle", item="caillef.default_rifle", cooldown=0.12, mode="auto", dmg=15, ammo=12, muzzleFlashY=-1 },
    { name="Pistol", item="caillef.default_pistol", cooldown=0.2, mode="manual", dmg=25, ammo=6 },
    { name="P90", item="caillef.default_p90", cooldown=0.06, mode="auto", dmg=7, ammo=22 },
    { name="Deagle", item="caillef.desert_eagle", cooldown=0.4, mode="manual", dmg=40, ammo=4 },
    { name="RailCow", item="jacksbertox.milk_cannon_triple", scale=0.3, sfx="cow_", cooldown=1, mode="auto", dmg=100, ammo=10 },
    --{ name="Bluecar", item="caillef.bluecar", scale=0.5, sfx="carhonk_", cooldown=1, mode="auto", dmg=100, ammo=10 },
}

Client.OnStart = function()
    -- Map
    Map.Scale = 12
	Map.Layers = { 1, 4 }
    spawnPoints = {}
    autoSpawnPoints:prepare(spawnPoints, SPAWN_BLOCK_COLOR)

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
		else
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
        Player.Position = Number3(1,1,1) * Map.Scale / 2 + randomSpawnPoint.p
        Player.Rotation = { 0, math.random() * 2 * math.pi, 0 }
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
    uiControls:init()
end

Client.OnPlayerJoin = function(p)
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
        Player.Motion = (Player.Forward * dpadY + Player.Right * dpadX) * 50
    end
end

Client.DirectionalPad = function(x, y)
    dpadX = x dpadY = y
    -- No move if dead
    if Player:isDead() or gsm.state == gsm.States.EndRound then
		return
	end
    Player.Motion = (Player.Forward * y + Player.Right * x) * 50
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
end

-- jump function, triggered with Action1
Client.Action1 = function()
	if gsm.state == gsm.States.EndRound or Player:isDead() then return end
    if Player.IsOnGround then
        Player.Velocity.Y = 115
    end
end

Client.Action2 = function()
	if gsm.state == gsm.States.EndRound then return end
    weapons:pressShoot()
    if displayControls == true then
        displayControls = false
        uiControls:hide()
    end
end

Client.Action2Release = function()
    weapons:releaseShoot()
end

Client.Action3Release = function()
	weapons:reload()
end


uiControls = {}
local uiControlsMetatable = {
    __index = {
        _isInit = false,
        init = function(self)
            local bg
            local ui = require("uikit")
            bg = ui:createFrame(Color(0,0,0,0.5))
            bg.Width = Screen.Width / 8
            bg.Height = Screen.Height / 5
            bg.pos = {Screen.Width / 2 - bg.Width / 2, Screen.Height / 2 - bg.Height / 2, 0}

            local welcomeText = ui:createText("Welcome to Dustzh!", Color.White)
            welcomeText:setParent(bg)
            welcomeText.pos = {bg.Width / 2 - welcomeText.Width / 2, bg.Height - (welcomeText.Height + 3), 0}

            local Action1Text = ui:createText("Action1: Jump", Color.White)
            Action1Text:setParent(bg)
            Action1Text.pos = {bg.Width / 2 - Action1Text.Width / 2, bg.Height / 2, 0}

            local Action2Text = ui:createText("Action2: Shoot", Color.White)
            Action2Text:setParent(bg)
            Action2Text.pos = {bg.Width / 2 - Action2Text.Width / 2, bg.Height / 2 - Action2Text.Height, 0}

            local Action3Text = ui:createText("Action3: Reload", Color.White)
            Action3Text:setParent(bg)
            Action3Text.pos = {bg.Width / 2 - Action3Text.Width / 2, bg.Height / 2 - (Action3Text.Height * 2), 0}

            local dismissText = ui:createText("Shoot to dismiss", Color.White)
            dismissText:setParent(bg)
            dismissText.pos = {bg.Width / 2 - dismissText.Width / 2, 0, 0}

            self._isInit = true
            self._bg = bg  -- Stockage de la référence de la frame bg dans _bg
        end,
        hide = function(self)
            if self._bg then
                self._bg:hide()  -- Utilisation de self._bg pour masquer la frame bg
            end
        end
    }
}
setmetatable(uiControls, uiControlsMetatable)

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
                bg.pos = { Screen.Width / 15 - bg.Width / 2, 200, 0 }
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

local CRATE_COLOR = Color(129,88,54)
local BARRELS_COLOR = Color(0,83,178)
autoSpawnPoints = {
    prepare = function(self, list, color)
        for z=0,Map.Depth do
            for y=0,Map.Height do
                for x=0,Map.Width do
                    local b = Map:GetBlock(x,y,z)
					local c = b.Color
                    if c == color then
                        table.insert(list, {
                            p = Number3(x,y,z) * Map.Scale
                        })
                        b:Remove()
                    elseif c == CRATE_COLOR then
						b:Remove()
                    	local obj = Shape(Items.caillef.wooden_crate)
                    	obj:SetParent(World)
						obj.CollisionGroups = Map.CollisionGroups
						obj.Friction = Map.Friction
						obj.Bounciness = 0
						obj.Pivot = Number3(obj.Width / 2, 0, obj.Depth / 2)
                    	obj.Position = Number3(x,y,z) * Map.Scale + Number3(6,0,6)
						obj.Scale = 0.55
						obj.Scale.Y = 0.545
                    elseif c == BARRELS_COLOR then
						b:Remove()
                    	local obj = Shape(Items.caillef.barrels)
                    	obj:SetParent(World)
						obj.type = "barrels"
						obj.CollisionGroups = Map.CollisionGroups
						obj.Physics = PhysicsMode.StaticPerBlock
						obj.Friction = Map.Friction
						obj.Bounciness = 0
						obj.Pivot = Number3(10,0,10)
						obj.Rotation.Y = math.random() * math.pi * 2
                    	obj.Position = Number3(x,y,z) * Map.Scale + Number3(6,0,6)
                    elseif c == Color(255,18,0) then
                        -- deprecated, red blocks must be removed from the item map and remove this condition
                        b:Remove()
					end
                end
            end
        end
    end
}

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
            Object:Load("caillef.bullet_impact_decal", function(obj)
                local list = {}
                for i=1,self.nbMaxBulletImpactDecals do
                    local d = Shape(obj)
                    d.Pivot = Number3(d.Width / 2, d.Height / 2, d.Depth / 2)
                    d:SetParent(World)
                    d.Scale = 0.2
                    d.Scale.Z = 0.5
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

            local ammoCount = ui:createText("20/20", Color.White, "big")
            self.ammoCountText = ammoCount
			ammoCount.parentDidResize = function(self)
                self.pos = { Screen.Width * 0.5 - self.Width * 0.5, 100 - self.Height - 10, 0 }
            end
            ammoCount:parentDidResize()
            self:updateAmmoUI()

			self.templates = {}
        end,
        updateAmmoUI = function(self)
            if self.ammo == nil then return end
            self.ammoCountText.Text = math.floor(self.ammo).."/"..self.maxAmmo
			self.ammoCountText.pos = { Screen.Width * 0.5 - self.ammoCountText.Width * 0.5, 100 - self.ammoCountText.Height - 10, 0 }
        end,
		toggleUI = function(self, show)
			if show == nil then
				self.uiHidden = not self.uiHidden
			else
				self.uiHidden = not show
			end

			if self.uiHidden then
				self.ammoCountText:hide()
			else
				self.ammoCountText:show()
			end
			self.entityHP:toggleUI(not self.uiHidden)
		end,
        placeNextBulletImpactDecal = function(self, pos, rot)
            local list = self.bullet_impact_decals
            local d = list[self.next_bidecal]
            self.next_bidecal = self.next_bidecal + 1
            if self.next_bidecal > #list then
                self.next_bidecal = 1
            end
            if d.timer then d.timer:Cancel() end
            d.IsHidden = false
            d.Rotation = rot
            d.Position = pos + d.Forward * 0.1 + d.Forward * math.random() * 0.1
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

            p.weapon.LocalRotation.X = -0.1
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
                local rot = Number3(0,0,0)
                if impact.FaceTouched == Face.Top then rot.X = math.pi / 2 end
                if impact.FaceTouched == Face.Bottom then rot.X = -math.pi / 2 end
                if impact.FaceTouched == Face.Left then rot.Y = math.pi / 2 end
                if impact.FaceTouched == Face.Right then rot.Y = -math.pi / 2 end
                if impact.FaceTouched == Face.Front then rot.Y = 0 end
                if impact.FaceTouched == Face.Back then rot.Y = math.pi end
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

			if impact.mode == "Ayrobot" then -- ayrobots
                local data = {
                    t = impact.Object.botId,
					type = "bot",
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
                self:updateAmmoUI()
                multi:playerAction("changeWeapon", { id = id })
            end
			p.weaponId = id
			if self.templates[weaponInfo.item] then
				local weapon =  Shape(self.templates[weaponInfo.item])
				weapon.Pivot = self.templates[weaponInfo.item].Pivot
				self:_setWeapon(p, weapon, weaponInfo, forceNotFPS)
				return
			end
            Object:Load(weaponInfo.item, function(weapon)
				self:_setWeapon(p, weapon, weaponInfo, forceNotFPS)
            end)
        end,
		_setWeapon = function(self, p, weapon, weaponInfo, forceNotFPS)
			if p.weapon then
                p.weapon:RemoveFromParent()
            end
			weapon.muzzleFlashY = weaponInfo.muzzleFlashY
            weapon.Physics = PhysicsMode.Disabled
            p.weapon = weapon
            if p == Player and not forceNotFPS then
                -- attach weapon
                weapon:SetParent(Camera)
				weapon.Scale = weaponInfo.scale or 1
                if Screen.Width > Screen.Height then
                    weapon.LocalPosition = Number3(5,-5,10)
                else
                    weapon.LocalPosition = Number3(3,-6,10)
                end
            else
                p:EquipRightHand(weapon)
				weapon.Scale = weaponInfo.scale or 1
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
            self.bg.LocalPosition = { 5, Screen.Height - (self.bg.Height + 5), 0 }
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
