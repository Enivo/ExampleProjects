local Gun = {}
Gun.__index = Gun

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")

local StateMachine = require(SharedModules:WaitForChild("StateMachine"))
local GunList = require(script:WaitForChild("GunList"))

local GunModel = ReplicatedStorage:WaitForChild("Gun")

local GunStates : {StateMachine.State} = {
	[1] = {
		Name = "Withdrawn",
		Duration = 0,
		CanEnter = function(prevState)
			return (prevState == "Holding")
		end,
		Started = function()
			print("Withdrawn weapon")
		end,
		Completed = function()
			return "Holding"
		end,
	},
	
	[2] = {
		Name = "Holding",
		Duration = 0,
		CanEnter = function(prevState)
			return true
		end,
		Started = function()
			print("Holding")
		end,
		Completed = function()
			return "Holding"
		end,
	},
	
	
	[3] = {
		Name = "Firing",
		Duration = 0,
		CanEnter = function(prevState)
			return (prevState == "Holding")
		end,
		Started = function()
			print("Firing weapon")
		end,
		Completed = function()
			return "Holding"
		end,
	},
	
	[4] = {
		Name = "Reloading",
		Duration = 0,
		CanEnter = function(prevState)
			return (prevState == "Holding")
		end,
		Started = function()
			print("Reloading")
		end,
		Completed = function()
			return "Holding"
		end,
	}
}

export type Guns = typeof(setmetatable(
	{} :: {
		Name : string,
		Type : string,
		Model : Model,
		Holder : Player,
		Ammo : number,
		MaxAmmo : number,
		ReserveAmmo : number,
		MaxReserverAmmo : number,
		Damage : number,
		Firerate : number,
		_fsm : StateMachine.FiniteStateMachine
	}, Gun)
)


function Gun.new(gunName, playerHolding)
	local newGun : {any}? = GunList.FindWeaponData(gunName)
	
	if not newGun then
		warn("Gun could not be found")
		return
	end
	
	local self = setmetatable({}, Gun)
	
	self.Name = newGun.Name
	self.Type = newGun.Type
	self.Model = newGun.Model:Clone()
	self.Holder = playerHolding
	self.Ammo = newGun.MaxAmmo
	self.MaxAmmo = newGun.MaxAmmo
	self.ReserveAmmo = newGun.MaxReserveAmmo
	self.MaxReserveAmmo = newGun.MaxReserveAmmo
	self.Damage = newGun.Damage
	self.Firerate = newGun.Firerate
	self._fsm = StateMachine.new(GunStates)
	
	return self
	
end

function Gun:Fire(mouseHitPos, muzzlePos)
	if self.Ammo <= 0 then
		--print("Out of ammo")
		return false
	end
	
	self._fsm:GoToState("Firing")
	
	if self._fsm.CurrentState ~= "Firing" then
		return
	end
	
	local char : Model = self.Holder.Character
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	
	if not char or not rootPart then
		print("Character not found")
		return false
	end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char, workspace:WaitForChild("BulletTrails")}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	
	--print("Mouse Pos: "..tostring(mouseHitPos))

	
	local raycastResult = workspace:Raycast(muzzlePos, (mouseHitPos - muzzlePos).Unit * 100000, rayParams)
	
	self.Ammo -= 1
	
	
	if not raycastResult then
		
		task.wait(self.Firerate)
		
		self._fsm:GoToState("Holding")
		
		
		return true, mouseHitPos
	end
	
	--print(raycastResult.Instance)
	
	local targetHum = raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid")
	
	if targetHum then
		targetHum:TakeDamage(self.Damage)
	end
	
	
	task.wait(self.Firerate)
	
	self._fsm:GoToState("Holding")
	
	return true, raycastResult.Position
end

function Gun:Reload()
	if self.ReserveAmmo <= 0 then
		--print("Out of reserve ammo")
		return false
	end
	
	self._fsm:GoToState("Reloading")
	
	if self._fsm.CurrentState ~= "Reloading" then
		return false
	end
	
	local diff = self.MaxAmmo - self.Ammo
	
	if self.ReserveAmmo < diff then
		diff = self.ReserveAmmo
	end
	
	self.ReserveAmmo = math.clamp(self.ReserveAmmo - diff, 0, math.huge)
	
	self.Ammo += diff
	task.wait(2)
	
	--print("Reloaded")
	
	self._fsm:GoToState("Holding")
	
	return true
end

function Gun:Select()
	self._fsm:GoToState("Holding")
end

function Gun:Withdraw()
	self._fsm:GoToState("Withdrawn")
end

function Gun:Destroy()
	self.Model:Destroy()
	setmetatable(self, nil)
	self = nil
end

return Gun
