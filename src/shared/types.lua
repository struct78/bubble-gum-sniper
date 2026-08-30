--[[
	Type definitions for Bubble Gum Sniper
	Used for documentation and runtime type-checking (Luau)
]]

export type Vector = {
	x: number,
	y: number,
	z: number,
}

export type ProjectileData = {
	Instance: BasePart,
	Position: Vector3,
	Velocity: Vector3,
	Wind: Vector3,
	CreatedAt: number,
	CaliberSize: "small" | "medium" | "large" | "mega",
}

export type TargetData = {
	Instance: Model,
	Position: Vector3,
	Health: number,
	MaxHealth: number,
	PunName: string,
	IsDefeated: boolean,
}

export type LevelData = {
	LevelNumber: number,
	Name: string,
	Description: string,
	StartPosition: Vector3,
	TargetSpawns: { Vector3 },
	WindProfile: {
		BaseWind: number,
		WindDirection: Vector3,
		WindVariance: number,
	},
	TimeLimit: number,
	Difficulty: number,
}

export type PlayerCosmetics = {
	Owned: { string }, -- List of cosmetic IDs
	Equipped: {
		Scope: string?,
		Ammunition: string?,
		Outfit: string?,
		GunSkin: string?,
	},
}

export type PlayerData = {
	UserId: number,
	LevelProgress: number,
	Cosmetics: PlayerCosmetics,
	SoftCurrency: number,
	Stats: {
		LevelsCompleted: number,
		TotalScore: number,
		TotalShotsHit: number,
		TotalShots: number,
		Accuracy: number, -- Calculated
	},
	LastUpdated: number,
}

export type CosmeticItem = {
	Id: string,
	Name: string,
	Category: "Scope" | "Ammunition" | "Outfit" | "GunSkin",
	Description: string,
	Price: number,
	Color: Color3,
	Rarity: "Common" | "Rare" | "Epic" | "Legendary",
	UnlockLevel: number?, -- Level required to purchase
}

export type HitResult = {
	HitTarget: TargetData?,
	Distance: number,
	Accuracy: number, -- 0-1
	Score: number,
	Timestamp: number,
}

return {}
