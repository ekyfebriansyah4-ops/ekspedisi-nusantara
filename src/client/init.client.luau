-- Ekspedisi Nusantara: client (vibes tiap area + tombol toko)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ID produk (samakan dengan server)
local ID_SKIP_CHECKPOINT = 3727109802
local ID_SPEED_PASS = 2064818276

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

-- UI dasar
local gui = Instance.new("ScreenGui")
gui.Name = "UIEkspedisi"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Judul nama area
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

-- ===== Tombol toko =====
local panelToko = Instance.new("Frame")
panelToko.AnchorPoint = Vector2.new(0, 0.5)
panelToko.Position = UDim2.new(0, 16, 0.5, 0)
panelToko.Size = UDim2.fromOffset(180, 110)
panelToko.BackgroundTransparency = 1
panelToko.Parent = gui

local susunan = Instance.new("UIListLayout")
susunan.Padding = UDim.new(0, 10)
susunan.Parent = panelToko

local function buatTombol(teks, warna)
	local tombol = Instance.new("TextButton")
	tombol.Size = UDim2.new(1, 0, 0, 48)
	tombol.BackgroundColor3 = warna
	tombol.Text = teks
	tombol.TextColor3 = Color3.new(1, 1, 1)
	tombol.Font = Enum.Font.GothamBold
	tombol.TextSize = 16
	local sudut = Instance.new("UICorner")
	sudut.CornerRadius = UDim.new(0, 12)
	sudut.Parent = tombol
	tombol.Parent = panelToko
	return tombol
end

local tombolSkip = buatTombol("Lewati Checkpoint", Color3.fromRGB(230, 130, 60))
local tombolSpeed = buatTombol("Speed Boost", Color3.fromRGB(60, 130, 220))

tombolSkip.MouseButton1Click:Connect(function()
	if ID_SKIP_CHECKPOINT == 0 then
		warn("ID Lewati Checkpoint belum diisi")
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local stage = leaderstats and leaderstats:FindFirstChild("Stage")
	if stage and stage.Value >= #ambilArea() then return end -- sudah di checkpoint terakhir
	MarketplaceService:PromptProductPurchase(player, ID_SKIP_CHECKPOINT)
end)

tombolSpeed.MouseButton1Click:Connect(function()
	if ID_SPEED_PASS == 0 then
		warn("ID Speed Boost belum diisi")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, ID_SPEED_PASS)
end)

-- Sembunyikan tombol Speed kalau sudah punya
local function perbaruiTombolSpeed()
	tombolSpeed.Visible = not player:GetAttribute("SpeedPass")
end
perbaruiTombolSpeed()
player:GetAttributeChangedSignal("SpeedPass"):Connect(perbaruiTombolSpeed)
-- Tombol ulang dari awal (muncul saat sudah di puncak)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventUlang = ReplicatedStorage:WaitForChild("UlangDariAwal")

local tombolUlang = buatTombol("Ulang dari Awal", Color3.fromRGB(90, 90, 105))
tombolUlang.Visible = false
tombolUlang.MouseButton1Click:Connect(function()
	eventUlang:FireServer()
end)

task.spawn(function()
	local stage = player:WaitForChild("leaderstats"):WaitForChild("Stage")
	local function perbaruiTombol()
		local total = #ambilArea()
		local selesai = total > 0 and stage.Value >= total
		tombolUlang.Visible = selesai
		tombolSkip.Visible = not selesai -- tidak perlu skip kalau sudah di puncak
	end
	perbaruiTombol()
	stage.Changed:Connect(perbaruiTombol)
end)
-- ===== Cek posisi pemain secara berkala (harus paling bawah) =====
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