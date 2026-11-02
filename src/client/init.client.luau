-- Ekspedisi Nusantara: suasana (vibes) tiap area, berjalan di sisi pemain
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Pengaturan suasana per area (nama harus sama dengan TEMA di server)
local VIBES = {
	["Hutan Tropis"] = {
		jam = 10, terang = 2.5,
		kabut = { Density = 0.35, Haze = 1, Color = Color3.fromRGB(200, 230, 190), Decay = Color3.fromRGB(110, 145, 95) },
		warna = { TintColor = Color3.fromRGB(235, 255, 235), Saturation = 0.15, Contrast = 0.05 },
	},
	["Gua Kapur"] = {
		jam = 16, terang = 1.6,
		kabut = { Density = 0.45, Haze = 2, Color = Color3.fromRGB(225, 215, 195), Decay = Color3.fromRGB(150, 135, 110) },
		warna = { TintColor = Color3.fromRGB(255, 245, 230), Saturation = -0.05, Contrast = 0.1 },
	},
	["Arung Jeram"] = {
		jam = 12, terang = 3,
		kabut = { Density = 0.25, Haze = 0.5, Color = Color3.fromRGB(195, 225, 255), Decay = Color3.fromRGB(110, 160, 210) },
		warna = { TintColor = Color3.fromRGB(235, 245, 255), Saturation = 0.25, Contrast = 0.05 },
	},
	["Kawah Belerang"] = {
		jam = 15, terang = 2,
		kabut = { Density = 0.55, Haze = 3, Color = Color3.fromRGB(240, 230, 165), Decay = Color3.fromRGB(185, 155, 70) },
		warna = { TintColor = Color3.fromRGB(255, 245, 210), Saturation = -0.1, Contrast = 0.15 },
	},
	["Puncak Gunung"] = {
		jam = 6.3, terang = 3,
		kabut = { Density = 0.3, Haze = 1.5, Color = Color3.fromRGB(255, 205, 175), Decay = Color3.fromRGB(255, 140, 120) },
		warna = { TintColor = Color3.fromRGB(255, 232, 220), Saturation = 0.2, Contrast = 0.1 },
	},
}

-- Siapkan efek kabut dan warna
local atmosfer = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosfer then
	atmosfer = Instance.new("Atmosphere")
	atmosfer.Parent = Lighting
end

local warnaLayar = Instance.new("ColorCorrectionEffect")
warnaLayar.Name = "VibesWarna"
warnaLayar.Parent = Lighting

-- UI judul nama area
local gui = Instance.new("ScreenGui")
gui.Name = "NotifArea"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local judul = Instance.new("TextLabel")
judul.AnchorPoint = Vector2.new(0.5, 0)
judul.Position = UDim2.fromScale(0.5, 0.12)
judul.Size = UDim2.fromScale(0.6, 0.08)
judul.BackgroundTransparency = 1
judul.Font = Enum.Font.GothamBold
judul.TextScaled = true
judul.TextColor3 = Color3.new(1, 1, 1)
judul.TextTransparency = 1
judul.TextStrokeTransparency = 1
judul.Parent = gui

local infoTransisi = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local infoTeks = TweenInfo.new(0.8)
local nomorNotif = 0

local function terapkanVibes(nama)
	local v = VIBES[nama]
	if not v then return end
	TweenService:Create(Lighting, infoTransisi, { ClockTime = v.jam, Brightness = v.terang }):Play()
	TweenService:Create(atmosfer, infoTransisi, v.kabut):Play()
	TweenService:Create(warnaLayar, infoTransisi, v.warna):Play()
end

local function tampilkanNama(nama)
	nomorNotif += 1
	local nomorIni = nomorNotif
	judul.Text = nama
	TweenService:Create(judul, infoTeks, { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.wait(3)
	if nomorIni == nomorNotif then
		TweenService:Create(judul, infoTeks, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
end

-- Ambil daftar area dari server, urut berdasarkan batas Z
local folderEkspedisi = workspace:WaitForChild("Ekspedisi")

local function ambilArea()
	local daftar = {}
	for _, f in ipairs(folderEkspedisi:GetChildren()) do
		local z = f:GetAttribute("BatasZ")
		if z then
			table.insert(daftar, { nama = f:GetAttribute("Nama"), z = z })
		end
	end
	table.sort(daftar, function(a, b) return a.z < b.z end)
	return daftar
end

-- Cek posisi pemain secara berkala
local areaSekarang = nil
while true do
	task.wait(0.3)
	local karakter = player.Character
	local root = karakter and karakter:FindFirstChild("HumanoidRootPart")
	if root then
		local nama = nil
		for _, area in ipairs(ambilArea()) do
			nama = area.nama
			if root.Position.Z < area.z + 7 then break end
		end
		if nama and nama ~= areaSekarang then
			areaSekarang = nama
			terapkanVibes(nama)
			task.spawn(tampilkanNama, nama)
		end
	end
end