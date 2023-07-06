Config = {
    Map = "aduermael.hills",
	Items = { "caillef.shop" }
}

-- UI FUNCTIONS

-- compact function to create and draw from a noun pool generated from a GPT thread.
function querySuggestionPool(textObject)
	if nounPool == nil then
		nounAwaiter = textObject
		nounPool = {}
		local chat = AI:CreateChat("You are a tool whose duty is to provide nothing but a list with the requested data separated with newlines.")
		chat:Say("Please give me 30 words containing common english nouns or funny concepts for physical objects.", function(err, msg)
			if err ~= nil then error(err)
			else
				for word in string.gmatch(msg, "[%a%-%']+") do
					table.insert(nounPool, word)
				end
				if nounAwaiter._setText ~= nil then
				nounAwaiter:_setText(nounPool[math.random(#nounPool)]) end
			end
		end)
	end 
	if #nounPool == 0 then	-- replace receiver when waiting for pool to init...
		nounAwaiter = textObject
	else	-- or we're completely done and the awaiter gets changed instantly.
		textObject:_setText(nounPool[math.random(#nounPool)])
	end
end

-- MENU
local menu = {
	dlg = nil, x = 0, y = 0, impact = nil, pos = nil, input = nil, visible = false,
	animate = function(self, node)
		local anim = ease:outElastic(node.object, 0.5)
		node.object.LocalScale = Number3(1, 0, 0)
		anim.LocalScale = Number3(1, 1, 1)
	end,
	sfxValid = function(self)
		sfx("modal_3", {Spatialized=false, Pitch=2.0})
	end,
	init = function(menu, x, y, pos, dir, impact)
		menu.x = x menu.y = y menu.impact = impact
		if impact ~= nil then
			menu.pos = pos + (dir * impact.Distance)
		end
		menu:create()	-- no referrer on init
		gameHintText:setParent(nil)	-- specific to this game
	end,
	defaultActions = function(menu, btns)	-- default click actions
		-- specific to this game
		if menu.impact ~= nil and menu.impact.Object.userInput ~= nil then
			menu.selected = menu.impact.Object
			menu.selected.PrivateDrawMode = 2
			button(btns, "👁 \""..menu.impact.Object.userInput.."\"")
			button(btns, "by "..menu.impact.Object.user)
		else
			spawnDisc(menu.impact, menu.pos)	-- specific to this game
			button(btns, "➕ Create Image", spawnImage)
		end
	end,
	create = function(menu, referrer)	-- create menu with cached init info
		menu.visible = true
		local root = ui:createNode()
		root.pos = Number3(Screen.Width * menu.x, Screen.Height * menu.y, 0)
		menu:animate(root)
		menu.dlg = root
		-- populate:
		local buttons = {}
		if referrer == nil then
			menu:defaultActions(buttons)
		end
		-- end
		for i, b in ipairs(buttons) do
			b:setParent(root)
			b.impact = impact
			b.pos.Y = -i * b.Height
		end
		return root
	end,
	hide = function(menu)
		menu.visible = false
		if menu.dlg ~= nil then
			if menu.input ~= nil then menu.input.object.Tick = nil end	-- TEMP BUG WORKAROUND :)
			menu.input = nil
			menu.dlg:remove()
			menu.dlg = nil
		end
		-- specific to this game
		if menu.selected ~= nil then menu.selected.PrivateDrawMode = 0 menu.selected = nil end
		deleteDisc()	
	end,
	createInput = function(menu, referrer)	-- input needed with referrer
		menu:hide()
		menu.visible = true
		local root = ui:createNode()
		local input = ui:createTextInput(nil, referrer.placeholder, "big")
		if referrer.useAI then querySuggestionPool(input.placeholder) end
		input:setParent(root)
		input:focus()
		input.onSubmit = referrer.send
		root.pos = Number3(Screen.Width * menu.x - (input.Width * 0.5), (Screen.Height * menu.y) + input.Height, 0)
		local send = ui:createButton("✅", {textSize="big"})
		send:setParent(root)
		send.onRelease = function() referrer.send(input) end
		if referrer.send == nil then send.onRelease = (function() menu:hide() end) end
		menu:animate(root)
		menu.input = input
		menu.dlg = root
		input.object.Tick = function()
			send.pos = Number3(input.pos.X + input.Width, input.pos.Y, 0)
			input.Width = math.max(280, input.string.Width) + 16
		end
		if referrer.disc then spawnDisc(menu.impact, menu.pos) end	-- specific to this game
	end
}

function button(tbl, text, action)
	local btn = ui:createButton(text, {textSize="big"}) btn.Width = 300
	if action == nil then btn.onRelease = function(self) menu:hide() end
	else btn.onRelease = action end
	table.insert(tbl, btn)
	return btn
end

-- ACTION FUNCTIONS
function spawnImage(btn)
	local impact = btn.impact
	menu:createInput({
		placeholder = "✨ something ✨",
		useAI = true,
		disc = true,
		send = function(self)
			imageQuery(self.Text, menu.impact, menu.pos)
			menu:hide()
			menu:sfxValid()
		end
	})
end

-- YASSIFICATION
faceNormals = {
	[Face.Back] = Number3(0.0, -1.0, 0.0), [Face.Bottom] = Number3(0.0, 0.0, -1.0), [Face.Front] = Number3(0.0, 1.0, 0.0),
	[Face.Left] = Number3(-1.0, 0.0, 0.0), [Face.Right] = Number3(1.0, 0.0, 0.0), [Face.Top] = Number3(0.0, 0.0, 1.0)
}

function spawnDisc(impact, pos)
	if impact == nil then return end
	_disc = MutableShape()
	_disc:AddBlock(Color.White, 0, 0, 0)
	_disc.LocalScale = Number3(0, 0, 20)
	_disc.Pivot = Number3(0.5,0.5,0.5)
	_disc.LocalPosition = pos
	_disc.Up = faceNormals[impact.FaceTouched] or Number3(0, 1, 0)
	_disc.Tick = function(o, dt) o:RotateLocal(o.Backward, dt) end
	_disc:SetParent(World)
	local anim = ease:outSine(_disc, 0.2)
	anim.LocalScale = Number3(8, 8, 1)
end

function deleteDisc()
	if _disc ~= nil then _disc:SetParent(nil) end
	_disc = nil
end

apiURL = "https://api.voxdream.art"

Client.OnStart = function()
    addPlayerOnStart = false

	multi = require "multi"
	amb = require "ambience"

	Fog.Near = 150
	Fog.Far = 300

	--[[local m = amb.noon:copy()

	m.sky.skyColor = Color(29, 118, 213)
	m.sky.horizonColor = Color(95, 168, 236)
	m.sky.abyssColor = Color(31, 81, 143)
	m.ambient.color = Color(80,120,100)
	amb:set(m)]]

	Clouds.Altitude = 100

	sun = Light()
    sun.On = true
	sun.CastsShadows = true
	sun.Color = Color(99,75,0)
	sun.Type = LightType.Directional
	World:AddChild(sun)
	sun.Rotation = {math.pi * 0.3, math.pi * 0.5, 0}

	gens = {}

    -- Defines a function to drop
    -- the player above the map.
    dropPlayer = function()
        Player.Position = Number3(Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5) * Map.Scale
        Player.Rotation = { 0, 0, 0 }
        Player.Velocity = { 0, 0, 0 }
    end

    if addPlayerOnStart then
		World:AddChild(Player)
	    dropPlayer()
	end

	AudioListener:SetParent(Player.Head)

	makeBubble = function(e)
		local bubble = MutableShape()
		bubble:AddBlock(Color.White, 0, 0, 0)
		bubble:SetParent(World)
		bubble.Pivot = Number3(0.5,0,0.5)
		bubble.Position = e.pos
		bubble.Rotation.Y = e.rotY
		bubble.eid = e.id

		bubble.Tick = function(o, dt)
			o.Scale.X = o.Scale.X + dt * 2
			o.Scale.Y = o.Scale.Y + dt * 2
			if o.text ~= nil then
				o.text.Position = o.Position
				o.text.Position.Y = o.Position.Y + o.Height * o.Scale.Y + 1
			end
		end

		local t = Text()
		t:SetParent(World)
		t.Rotation.Y = e.rotY
		t.Text = e.m
		t.Type = TextType.World
		t.IsUnlit = true
		t.Tail = true
		t.Anchor = { 0.5, 0 }
		t.Position.Y = bubble.Position.Y + bubble.Height * bubble.Scale.Y + 1
		bubble.text = t

		-- remove after 15 seconds without response
		Timer(15, function()
			if bubble then
				gens[bubble.eid] = nil
				bubble.Tick = nil
				if bubble.text then bubble.text:RemoveFromParent() end
				bubble:RemoveFromParent()
			end
		end)

		gens[e.id] = bubble
	end

	-- ADDITIONS:

	sfx = require "sfx"
	ease = require "ease"
	ui = require "uikit"
	ui:init()
	-- non-modal instructions
	local text = ui:createText(" 🎥 Drag to move camera,\n   ☝️ Click to bring up CREATOR MENU!\n     👁 Click on an image for info.", Color(1.0,1.0,1.0))
	text.object.BackgroundColor = Color(0,0,0,128)
	text.object.Padding = 8
	text.parentDidResize = function() text.pos.Y = 8 end
	-- intrusive hint
	gameHintText = ui:createText("Start by pressing a block!", Color(1.0,1.0,1.0), "big")
	gameHintText.parentDidResize = function() gameHintText.pos.X = (Screen.Width / 2) gameHintText.pos.Y = Screen.Height - (Screen.Height / 4) end
	gameHintText.object.Anchor = { 0.5, 0.5 }
	gameHintText.object.time = 0 gameHintText.object.Tick = 
		function(o, dt) if (o.time % 0.4) <= 0.2 then o.Color = Color(0.0, 0.8, 0.6) else o.Color = Color(1.0, 1.0, 1.0) end o.time = o.time + dt end
	LocalEvent:Send(LocalEvent.Name.ScreenDidResize, Screen.Width, Screen.Height)
end

-- UI CODE

Pointer.Down = function(pe)
end

Pointer.Up = function(pe)
end

Pointer.Drag2Begin = function(pe)
end

Pointer.Drag2 = function(pe)
end

Screen.DidResize = function(w,h)
	ui:fitScreen()
end

Pointer.Click = function(pe)
	if menu.visible then
		menu:hide()
	-- hijack ui:pointerDown logic
	else
		menu:init(pe.X, pe.Y, pe.Position, pe.Direction, pe:CastRay())
	end
end

-- CLIENT CODE

Client.OnSubmit = function(what)
	print(what)
end

Client.OnPlayerJoin = function(p)
    if not addPlayerOnStart and p == Player then
		World:AddChild(Player)
	    dropPlayer()
	end
	--multi:initPlayer(p)
	p.CollidesWithGroups = Map.CollisionGroups
end

Client.OnPlayerLeave = function(p)
	multi:removePlayer(p)
end

Client.Tick = function(dt)
	--multi:tick(dt)

    -- Detect if player is falling,
    -- drop it above the map when it happens.
    if Player.Position.Y < -500 then
        dropPlayer()
        Player:TextBubble("💀 Oops!")
    end
end

-- jump function, triggered with Action1
Client.Action1 = function()
    --if Player.IsOnGround then
        Player.Velocity.Y = 100
    --end
end

function imageQuery(message, impact, pos)
	if impact then
		pos = pos + {0,1,0}

		local e = Event()
		e.id = math.floor(math.random() * 1000000)
		e.pos = pos
		e.rotY = Player.Rotation.Y
		e.action = "gen"
		e.userInput = message
		e:SendTo(Server)

		local e2 = Event()
		e2.action = "otherGen"
		e2.id = e.id
		e2.m = message
		e2.pos = e.pos
		e2.rotY = e.rotY
		e2:SendTo(OtherPlayers)

		makeBubble(e2)
	end
end

Client.OnSubmit = function() end

Client.OnChat = function(message)
	local e = Event()
	e.action = "chat"
	e.msg = message
	e:SendTo(Players)
end

Client.DidReceiveEvent = function(e)
	--multi:receive(e)

	if e.action == "vox" then

		local pos
		local rotY

		local bubble = gens[e.id]
		if bubble then
			pos = bubble.Position:Copy()
			rotY = bubble.Rotation.Y
			bubble.Tick = nil
			if bubble.text then bubble.text:RemoveFromParent() end
			bubble:RemoveFromParent()
			gens[e.id] = nil
			if e.vox == nil then
				print("sorry, request failed!")
				return
			end
		elseif e.pos then
			print("sync packet from server")
			pos = e.pos
			rotY = e.rotY
		else
			return
		end

		local success = pcall(function()
			if JSON:Encode(e.vox)[1] == "{" then
				print(JSON:Encode(e.vox))
				return
			end
			local s = Shape(e.vox)
			s.CollisionGroups = Map.CollisionGroups
			s.userInput = e.userInput
			s.user = e.user
			s:SetParent(World)

			-- first block is not at 0,0,0
			-- use collision box min to offset the pivot 
			local collisionBoxMin = s.CollisionBox.Min

			local center = s.CollisionBox.Center:Copy()

			center.Y = s.CollisionBox.Min.Y
			s.Pivot = {s.Width * 0.5 + collisionBoxMin.X,
						0 + collisionBoxMin.Y,
						s.Depth * 0.5 + collisionBoxMin.Z}
			s.Position = pos
			s.Rotation.Y = rotY
			s.Physics = PhysicsMode.Dynamic

			--REMOVED: TriggerPerBlock with max encompassing box works.
			--s.CollisionBox = Box(center - {0.5, 0, 0.5}, center + {0.5, 1, 0.5})

			Timer(1, function()
				s.Physics = PhysicsMode.TriggerPerBlock
				s.CollisionGroups = {}
			end)
			-- s.Scale = 0.7
			sfx("waterdrop_2", {Position = pos})
		end)
		if not success then
			print("Can't load shape")
			sfx("twang_2", {Position = pos})
		end
	elseif e.action == "otherGen" then
		makeBubble(e)
	elseif e.action == "chat" then
		print(e.Sender.Username..": "..e.msg)
	end
end

-- Server code

Server.OnStart = function()
	gens = {}
end

Server.OnPlayerJoin = function(p)
	Timer(2, function()
		for _,d in ipairs(gens) do
			local headers = {}
			headers["Content-Type"] = "application/octet-stream"
			HTTP:Get(d.url, headers, function(data)
				local e = Event()
				e.vox = data.Body
				e.id = d.e.id
				e.pos = d.e.pos
				e.rotY = d.e.rotY
				e.userInput = d.e.userInput
				e.user = d.e.user
				e.action = "vox"
				e:SendTo(p)
			end)
		end
	end)
end

Server.DidReceiveEvent = function(e)
	if e.action == "gen" then
		local headers = {}
		headers["Content-Type"] = "application/json"
		HTTP:Post(apiURL.."/pixelart/vox", headers, { userInput=e.userInput }, function(data)
			local body = JSON:Decode(data.Body)
			if not body.urls or #body.urls == 0 then print("Error: can't generate content.") return end
			voxURL = apiURL.."/"..body.urls[1]
			table.insert(gens, { e=e, url=voxURL })

			local headers = {}
			headers["Content-Type"] = "application/octet-stream"
			HTTP:Get(voxURL, headers, function(data)
				local e2 = Event()
				e2.vox = data.Body
				e2.user = e.Sender.Username
				e2.userInput = e.userInput
				e2.id = e.id
				e2.action = "vox"
				e2:SendTo(Players)
			end)
		end)
	end
end
