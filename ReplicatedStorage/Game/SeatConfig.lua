--[[
================================================================================
KOSMICMAZER -- SeatConfig
================================================================================

Purpose:
Centralized configuration for all ship seat types.
Maps seat names to UI modules, camera settings, and functionality.

Version:
0.1

Features:
- Seat type definitions with display names
- UI module mapping for each seat
- Camera settings per seat type
- Functionality flags for seat capabilities

API:
- GetSeatConfig(seatName) -- Returns full config for seat
- GetUIModule(seatName) -- Returns UI module name
- GetCameraSettings(seatName) -- Returns camera settings
- GetAllSeatNames() -- Returns list of all seat names

ChangeLog:
- 0.1: Initial seat configuration (2026-01-13)
================================================================================
]]

local SeatConfig = {
	-- Seat type definitions
	Seats = {
		PilotSeat = {
			displayName = "Пілотське крісло",
			uiModule = "PilotUI",
			seatType = "VehicleSeat",
			camera = {
				mode = "Custom",
				fov = 70,
				minZoom = 5,
				maxZoom = 50,
			},
			functionality = {
				canControl = true,
				canNavigate = true,
			}
		},

		Seat1 = {
			displayName = "Крісло-1",
			uiModule = "GenericSeatUI",
			seatType = "Seat",
			camera = {
				mode = "Custom",
				fov = 70,
				minZoom = 5,
				maxZoom = 30,
			},
			functionality = {}
		},

		Seat2 = {
			displayName = "Крісло-2",
			uiModule = "GenericSeatUI",
			seatType = "Seat",
			camera = {
				mode = "Custom",
				fov = 70,
				minZoom = 5,
				maxZoom = 30,
			},
			functionality = {}
		},

		Seat3 = {
			displayName = "Крісло-3",
			uiModule = "GenericSeatUI",
			seatType = "Seat",
			camera = {
				mode = "Custom",
				fov = 70,
				minZoom = 5,
				maxZoom = 30,
			},
			functionality = {}
		},

		Seat4 = {
			displayName = "Крісло-4",
			uiModule = "GenericSeatUI",
			seatType = "Seat",
			camera = {
				mode = "Custom",
				fov = 70,
				minZoom = 5,
				maxZoom = 30,
			},
			functionality = {}
		},
	},

	-- Default camera settings for unknown seats
	DefaultCamera = {
		mode = "Custom",
		fov = 70,
		minZoom = 5,
		maxZoom = 30,
	}
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function SeatConfig.GetSeatConfig(seatName)
	return SeatConfig.Seats[seatName]
end

function SeatConfig.GetUIModule(seatName)
	local config = SeatConfig.Seats[seatName]
	return config and config.uiModule or nil
end

function SeatConfig.GetCameraSettings(seatName)
	local config = SeatConfig.Seats[seatName]
	return config and config.camera or SeatConfig.DefaultCamera
end

function SeatConfig.GetDisplayName(seatName)
	local config = SeatConfig.Seats[seatName]
	return config and config.displayName or seatName
end

function SeatConfig.GetFunctionality(seatName)
	local config = SeatConfig.Seats[seatName]
	return config and config.functionality or {}
end

function SeatConfig.GetAllSeatNames()
	local names = {}
	for name, _ in pairs(SeatConfig.Seats) do
		table.insert(names, name)
	end
	return names
end

function SeatConfig.IsSeatKnown(seatName)
	return SeatConfig.Seats[seatName] ~= nil
end

return SeatConfig
