Config = {
    Map = "aduermael.hills",
	Items = {}
}

-- CONSTANTS
local PADDING = 8 -- used for UI elements
local POINTER_OFFSET = 20
local GENERATED_ITEM_COLLISION_GROUP = 5

faceNormals = {
	[Face.Back] = Number3(0,0,-1), [Face.Bottom] = Number3(0,-1,0), [Face.Front] = Number3(0,0,1),
	[Face.Left] = Number3(-1,0,0), [Face.Right] = Number3(1,0,0), [Face.Top] = Number3(0,1,0)
}

Client.OnStart = function()

	multi = require "multi"

	ambience = require "ambience"
	ambience:set(ambience.noon)

	Clouds.Altitude = 100

	gens = {} -- generated items

	-- MODULES
	sfx = require "sfx"
	ease = require "ease"
	ui = require "uikit"
	controls = require "controls"
	controls:setButtonIcon("action1", "⬆️")
	
	showInstructions()
	showWelcomeHint()

	Pointer:Show()
end

Pointer.Click = function(pe)
	hideWelcomeHint()
	hideInstructions()
	showMenu(pe)
end

-- Temporary fix
-- On mobile, Pointer.Click doesn't work if Pointer.Up is nil
-- (will be fixed in next update)
Pointer.Up = function(pe) end

Client.OnPlayerJoin = function(p)
	dropPlayer(p)
end

Client.Tick = function(dt)
    -- Detect if player is falling,
    -- drop it above the map when it happens.
    if Player.Position.Y < -500 then
        dropPlayer(Player)
        Player:TextBubble("💀 Oops!")
    end
end

function cancelMenu()
	hideMenu()
	showInstructions()
end

local dirPad = Client.DirectionalPad
Client.DirectionalPad = function(x, y)
	cancelMenu()
	dirPad(x, y)
end

Pointer.DragBegin = cancelMenu
Screen.DidResize = cancelMenu

-- jump function, triggered with Action1
Client.Action1 = function()
	cancelMenu()
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

Client.OnChat = function(message)
	local e = Event()
	e.action = "chat"
	e.msg = message
	e:SendTo(Players)
end

Client.DidReceiveEvent = function(e)

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

			Timer(1, function()
				s.Physics = PhysicsMode.TriggerPerBlock
				s.CollisionGroups = {GENERATED_ITEM_COLLISION_GROUP}
			end)
			sfx("waterdrop_2", {Position = pos})
		end)
		if not success then
			print("Can't load shape")
			sfx("twang_2", {Position = pos})
		end
	elseif e.action == "otherGen" then
		makeBubble(e)
	elseif e.action == "chat" then
		print(e.Sender.Username..": ".. e.msg)
		e.Sender:TextBubble(e.msg, true)
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
		local apiURL = "https://api.voxdream.art"

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

-- Utility functions

function hideMenu()
	if createButton then createButton:remove() createButton = nil end
	if prompt then prompt:remove() prompt = nil end
	if itemDetails then itemDetails:remove() itemDetails = nil end
	deleteTarget()
end

function showMenu(pointerEvent)
	hideMenu()

	local screenPos = Number2(pointerEvent.X * Screen.Width, pointerEvent.Y * Screen.Height)

	local impact = pointerEvent:CastRay(Map.CollisionGroups + {GENERATED_ITEM_COLLISION_GROUP})
	if impact ~= nil then
		if impact.Object == Map then

			local pos = pointerEvent.Position + pointerEvent.Direction * impact.Distance
			
			showTarget(impact, pos)
			
			createButton = ui:createButton("➕ Create Image")

			local px = screenPos.X - createButton.Width * 0.5
			if px < Screen.SafeArea.Left + PADDING then px = Screen.SafeArea.Left + PADDING end
			if px > Screen.Width - Screen.SafeArea.Right - createButton.Width - PADDING then px = Screen.Width - Screen.SafeArea.Right - createButton.Width - PADDING end

			local py = screenPos.Y + POINTER_OFFSET
			if py < Screen.SafeArea.Bottom + PADDING then py = Screen.SafeArea.Bottom + PADDING end
			if py > Screen.Height - Screen.SafeArea.Top - createButton.Height - PADDING then py = Screen.Height - Screen.SafeArea.Top - createButton.Height - PADDING end			

			createButton.pos.X = px
			createButton.pos.Y = py

			createButton.onRelease = function()
				createButton:remove() createButton = nil

				prompt = ui:createNode()
				local input = ui:createTextInput(nil, "What do you want?")
				input:setParent(prompt)
				input:focus()

				local send = function()
					if input.Text ~= "" then
						imageQuery(input.Text, impact, pos)
						sfx("modal_3", {Spatialized=false, Pitch=2.0})
					end
					prompt:remove()
					prompt = nil
					deleteTarget()
				end

				input.onSubmit = send

				local sendBtn = ui:createButton("✅", {textSize="big"})
				sendBtn:setParent(prompt)
				sendBtn.onRelease = send

				input.Height = sendBtn.Height
				input.Width = 250
				sendBtn.pos.X = input.Width

				local width = input.Width + sendBtn.Width
				local height = sendBtn.Height

				local px = screenPos.X - width * 0.5
				if px < Screen.SafeArea.Left + PADDING then px = Screen.SafeArea.Left + PADDING end
				if px > Screen.Width - Screen.SafeArea.Right - width - PADDING then px = Screen.Width - Screen.SafeArea.Right - width - PADDING end

				local py = screenPos.Y + POINTER_OFFSET
				if py < Screen.SafeArea.Bottom + PADDING then py = Screen.SafeArea.Bottom + PADDING end
				if py > Screen.Height - Screen.SafeArea.Top - height - PADDING then py = Screen.Height - Screen.SafeArea.Top - height - PADDING end

				prompt.pos.X = px
				prompt.pos.Y = py
			end
		
		else -- clicked on generated item

			itemDetails = ui:createFrame(Color(0,0,0,128))
			local line1 = ui:createText(impact.Object.userInput, Color.White)
			line1.object.MaxWidth = 200
			line1:setParent(itemDetails)
			local line2 = ui:createText("by " .. impact.Object.user, Color.White, "small")
			line2:setParent(itemDetails)

			itemDetails.parentDidResize = function()
				local width = math.max(line1.Width, line2.Width) + PADDING * 2
				local height = line1.Height + line2.Height + PADDING * 3
				itemDetails.Width = width
				itemDetails.Height = height
				line1.pos = {PADDING, itemDetails.Height - PADDING - line1.Height, 0}
				line2.pos = line1.pos - {0, line2.Height + PADDING, 0}

				local px = screenPos.X - itemDetails.Width * 0.5
				if px < Screen.SafeArea.Left + PADDING then px = Screen.SafeArea.Left + PADDING end
				if px > Screen.Width - Screen.SafeArea.Right - itemDetails.Width - PADDING then px = Screen.Width - Screen.SafeArea.Right - itemDetails.Width - PADDING end

				local py = screenPos.Y + POINTER_OFFSET
				if py < Screen.SafeArea.Bottom + PADDING then py = Screen.SafeArea.Bottom + PADDING end
				if py > Screen.Height - Screen.SafeArea.Top - itemDetails.Height - PADDING then py = Screen.Height - Screen.SafeArea.Top - itemDetails.Height - PADDING end	

				itemDetails.pos = {px, py, 0}
			end
			itemDetails:parentDidResize()

		end
	end
end

function showTarget(impact, pos)
	if impact == nil then return end

	if _target == nil then
		local ms = MutableShape()
		ms:AddBlock(Color.White, 0, 0, 0)

		ms:AddBlock(Color.White, -2, 0, -2)
		ms:AddBlock(Color.White, -2, 0, -1)
		ms:AddBlock(Color.White, -1, 0, -2)

		ms:AddBlock(Color.White, -2, 0, 2)
		ms:AddBlock(Color.White, -2, 0, 1)
		ms:AddBlock(Color.White, -1, 0, 2)

		ms:AddBlock(Color.White, 2, 0, 2)
		ms:AddBlock(Color.White, 2, 0, 1)
		ms:AddBlock(Color.White, 1, 0, 2)

		ms:AddBlock(Color.White, 2, 0, -2)
		ms:AddBlock(Color.White, 2, 0, -1)
		ms:AddBlock(Color.White, 1, 0, -2)

		_target = Shape(ms)
		_target.Pivot = {_target.Width * 0.5, _target.Height * 0.5, _target.Depth * 0.5}
		_target.Physics = PhysicsMode.Disabled
	end

	_target.LocalScale = Number3(0, 0, 0)
	_target.LocalPosition = pos
	_target.Up = faceNormals[impact.FaceTouched] or Number3(0, 1, 0)
	_target.Tick = function(o, dt) o:RotateLocal(o.Up, dt) end
	_target:SetParent(World)
	ease:outElastic(_target, 0.4).LocalScale = {1.6, 1, 1.6}
end

function deleteTarget()
	if _target ~= nil then _target:SetParent(nil) end
end

function dropPlayer(p)
	World:AddChild(p)
	p.Position = Number3(Map.Width * 0.5, Map.Height + 10, Map.Depth * 0.5) * Map.Scale
	p.Rotation = { 0, 0, 0 }
	p.Velocity = { 0, 0, 0 }
end

-- shows instructions at the top left corner of the screen
function showInstructions() 
	if instructions ~= nil then 
		instructions:show()
		return
	end

	instructions = ui:createFrame(Color(0,0,0,128))
	local line1 = ui:createText("🎥 Drag to move camera", Color.White)
	line1:setParent(instructions)
	local line2 = ui:createText("☝️ Click to bring up CREATOR MENU!", Color.White)
	line2:setParent(instructions)
	local line3 = ui:createText("🔎 Click on an image for info.", Color.White)
	line3:setParent(instructions)

	instructions.parentDidResize = function()
		local width = math.max(line1.Width, line2.Width, line3.Width) + PADDING * 2
		local height = line1.Height + line2.Height + line3.Height + PADDING * 4
		instructions.Width = width
		instructions.Height = height
		line1.pos = {PADDING, instructions.Height - PADDING - line1.Height, 0}
		line2.pos = line1.pos - {0, line1.Height + PADDING, 0}
		line3.pos = line2.pos - {0, line2.Height + PADDING, 0}
		instructions.pos = {Screen.SafeArea.Left + PADDING, Screen.Height - Screen.SafeArea.Top - instructions.Height - PADDING, 0}
	end
	instructions:parentDidResize()
end

function hideInstructions()
	if instructions ~= nil then instructions:hide() end
end

function showWelcomeHint()
	if welcomeHint ~= nil then return end
	welcomeHint = ui:createText("Click on a block!", Color(1.0,1.0,1.0), "big")
	welcomeHint.parentDidResize = function() 
		welcomeHint.pos.X = Screen.Width * 0.5 - welcomeHint.Width * 0.5
		welcomeHint.pos.Y = Screen.Height * 0.66 - welcomeHint.Height * 0.5 
	end
	welcomeHint:parentDidResize()

	local t = 0
	welcomeHint.object.Tick = function(o, dt) 
		t = t + dt
		if (t % 0.4) <= 0.2 then 
			o.Color = Color(0.0, 0.8, 0.6) 
		else 
			o.Color = Color(1.0, 1.0, 1.0) 
		end 
	end
end

function hideWelcomeHint()
	if welcomeHint == nil then return end
	welcomeHint:remove()
	welcomeHint = nil
end

-- creates loading bubble
function makeBubble(e)
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
