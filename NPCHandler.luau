local NPCHandler = {}

-- Private Functions
local function getDialogue(npc : Model)
	local dialogue = npc:FindFirstChild("Dialogue")
	
	if dialogue then
		return require(dialogue)
	end
	
	return nil
end

local function setText(dialogueBranch, player : Player, npc)
	
	local ui = player.PlayerGui:FindFirstChild("DialogueUI")
	local frame = ui:FindFirstChild("MainFrame")
	local dialogueText = frame:FindFirstChild("Dialogue")
	local name = frame:FindFirstChild("Name")
	local options = frame:FindFirstChild("Options")
	
	for _, button in options:GetChildren() do
		if not button:IsA("TextButton") then continue end
		
		button.Visible = false
	end
	
	dialogueText.Text = dialogueBranch.Dialogue
	name.Text = npc.Name
	
	local buttons = {}
	
	frame.Visible = true
	options.Visible = true
	
	for i, info in ipairs(dialogueBranch.Options) do
		local optionText : TextButton = options:FindFirstChild("Option"..i)
		
		if not optionText then 
			warn("No option "..i) 
		end
		
		optionText.Text = info.Text
		optionText.Visible = true
		
		buttons[i] = optionText
	end
	
	return buttons
end

local function closeText(player : Player)
	local ui = player.PlayerGui:FindFirstChild("DialogueUI")
	local frame = ui:FindFirstChild("MainFrame")
	local dialogueText = frame:FindFirstChild("Dialogue")
	local name = frame:FindFirstChild("Name")
	local options = frame:FindFirstChild("Options")

	for _, button in options:GetChildren() do
		if not button:IsA("TextButton") then continue end
		
		button.Text = "..."
		
		button.Visible = false
	end

	dialogueText.Text = "[Text]"
	name.Text = "[Name]"
	
	frame.Visible = false
	
	print("Closed Text")
end

-- Public Functions

function NPCHandler.StartDialogue(player : Player, npc)
	print("Open")
	
	local dialogue = getDialogue(npc)
	
	local dialogueInfo = {
		Player = player,
		NPC = npc,
		Dialogue = dialogue,
		Branches = {}
	}
	
	local buttons = setText(dialogue, player, npc)
	
	local connections = {}
	local atNextPage
	
	for i, button in ipairs(buttons) do
		connections[i] = button.MouseButton1Click:Connect(function()
			dialogueInfo, atNextPage = NPCHandler.NextDialogue(dialogueInfo, i)
			
			if not atNextPage then
				NPCHandler.CloseDialogue(dialogueInfo)
				
				for _, conn in connections do
					conn:Disconnect()
				end
			end
		end)
	end	
	
	return dialogueInfo
end

function NPCHandler.NextDialogue(dialogueInfo, option)
	local currentBranch
	--Ok not here
	
	if #dialogueInfo.Branches > 0 then
		for i, branch in ipairs(dialogueInfo.Branches) do
			if i == 1 then
				print("Next: ")
				print("Branch No.: "..branch)
				currentBranch = dialogueInfo.Dialogue.Options[branch].Next
				print(currentBranch)
			else
				--print("Next: ")
				--print("Branch No.: "..branch)
				warn("Place of error")
				print(currentBranch)
				currentBranch = currentBranch.Options[branch].Next
				print("New branch:")
				print(currentBranch)
				--print(currentBranch.Options)
			end
			print("Now: ")
			currentBranch = currentBranch.Options[option].Next
			print("New branch:")
			print(currentBranch)
		end
	else
		--print(dialogueInfo.Branches)
		
		print("Info: ", dialogueInfo.Dialogue)
		
		print("Start:")
		print("Branch No.: "..option)
		currentBranch = dialogueInfo.Dialogue.Options[option].Next
		print(currentBranch)
	end
	
	local nextBranch = currentBranch
	
	if not nextBranch then
		print("Dialogue reached end")
		return dialogueInfo, false
	end
	
	setText(nextBranch, dialogueInfo.Player, dialogueInfo.NPC)

	dialogueInfo.Branches[#dialogueInfo.Branches + 1] = option

	return dialogueInfo, true
end

function NPCHandler.CloseDialogue(dialogueInfo)
	closeText(dialogueInfo.Player)
	
	table.clear(dialogueInfo)
	dialogueInfo = nil
end

return NPCHandler
