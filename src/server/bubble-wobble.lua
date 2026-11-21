local WOBBLE = 0.01
local BubbleWobble = {
	HalfPeriod = 1.2,
}

function BubbleWobble.SizeAtPhase(size, phase)
	local squash = WOBBLE * phase
	return Vector3.new(size.X * (1 + squash), size.Y, size.Z * (1 - squash))
end

return BubbleWobble
