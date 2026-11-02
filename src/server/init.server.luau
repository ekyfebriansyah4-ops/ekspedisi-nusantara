-- Ekspedisi Nusantara: server (checkpoint, sungai, save progres, monetisasi)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataProgres = DataStoreService:GetDataStore("ProgresEkspedisi_v1")

-- ID produk dari Creator Hub
local ID_SKIP_CHECKPOINT = 3727109802
local ID_SPEED_PASS = 2064818276
local SPEED_NORMAL = 16
local SPEED_BOOST = 26
local TES_SPEED_DI_STUDIO = false  -- [ubah ke true kalau mau tes lagi]

local JARAK_Z = 60          -- jarak antar checkpoint ke depan
local NAIK_Y = 10           -- kenaikan tinggi tiap checkpoint
local PIJAKAN_PER_RUTE = 4  -- jumlah pijakan di antara checkpoint

local TEMA = {
	{ nama = "Hutan Tropis",   warna = Color3.fromRGB(76, 140, 74) },
	{ nama = "Gua Kapur",      warna = Color3.fromRGB(205, 198, 180) },
	{ nama = "Arung Jeram",    warna = Color3.fromRGB(70, 130, 180), jenis = "sungai" },
	{ nama = "Kawah Belerang", warna = Color3.fromRGB(222, 196, 70) },
	{ nama = "Puncak Gunung",  warna = Color3.fromRGB(235, 240, 250) },
}

print("Ekspedisi Nusantara: server siap!")

-- Hapus hasil generate lama
local lama = workspace:FindFirstChild("Ekspedisi")
if lama then lama:Destroy() end
workspace.Terrain:Clear()

local folderUtama = Instance.new("Folder")
folderUtama.Name = "Ekspedisi"
folderUtama.Parent = workspace

local function buatPart(nama, ukuran, posisi, warna, parent)
	local part = Instance.new("Part")
	part.Name = nama
	part.Size = ukuran
	part.Position = posisi
	part.Color = warna
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buatLabel(part, teks)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.StudsOffset = Vector3.new(0, 11, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = teks
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
	return label
end

-- Sungai arung jeram + ban pelampung untuk 2 pemain
local function buatSungai(dari, ke, parent)
	local terrain = workspace.Terrain
	-- Permukaan air disejajarkan dengan grid terrain (kelipatan 4 stud)
	local yAir = math.floor(dari.Y / 4) * 4
	local awal = Vector3.new(dari.X, yAir, dari.Z + 12)
	local akhir = Vector3.new(ke.X, yAir, ke.Z - 12)

	-- Titik jalur sungai yang berkelok
	local titik = {}
	local JUMLAH = 10
	for n = 0, JUMLAH do
		local t = n / JUMLAH
		local p = awal:Lerp(akhir, t)
		titik[n + 1] = p + Vector3.new(math.sin(t * math.pi * 2) * 14, 0, 0)
	end

	-- Hitung CFrame tiap segmen sungai
	local segmen = {}
	for n = 1, #titik - 1 do
		local a, b = titik[n], titik[n + 1]
		table.insert(segmen, {
			cf = CFrame.lookAt((a + b) / 2, b),
			panjang = (b - a).Magnitude + 8,
		})
	end

	-- Tahap 1: dasar sungai + air (tanpa menggali)
	for _, s in ipairs(segmen) do
		terrain:FillBlock(s.cf * CFrame.new(0, -6, 0), Vector3.new(42, 4, s.panjang), Enum.Material.Ground)
		terrain:FillBlock(s.cf * CFrame.new(0, -2, 0), Vector3.new(26, 4, s.panjang), Enum.Material.Water)
	end

	-- Tahap 2: tebing rumput di kiri dan kanan sungai
	for _, s in ipairs(segmen) do
		for _, sisi in ipairs({ -17, 17 }) do
			terrain:FillBlock(s.cf * CFrame.new(sisi, -2, 0), Vector3.new(8, 12, s.panjang), Enum.Material.LeafyGrass)
		end
	end

	-- Model ban pelampung
	local naik = Vector3.new(0, 1, 0)
	local startCF = CFrame.lookAt(titik[1] + naik, titik[2] + naik)

	local ban = Instance.new("Model")
	ban.Name = "BanPelampung"

	local inti = Instance.new("Part")
	inti.Name = "Inti"
	inti.Size = Vector3.new(1, 1, 1)
	inti.Transparency = 1
	inti.CanCollide = false
	inti.Anchored = true
	inti.CFrame = startCF
	inti.Parent = ban
	ban.PrimaryPart = inti

	local cincin = Instance.new("Part")
	cincin.Name = "Cincin"
	cincin.Shape = Enum.PartType.Cylinder
	cincin.Size = Vector3.new(2, 11, 11)
	cincin.Color = Color3.fromRGB(255, 120, 150)
	cincin.Material = Enum.Material.SmoothPlastic
	cincin.Anchored = true
	cincin.CFrame = startCF * CFrame.Angles(0, 0, math.rad(90))
	cincin.Parent = ban

	local kursiList = {}
	for _, x in ipairs({ -2.5, 2.5 }) do
		local kursi = Instance.new("Seat")
		kursi.Size = Vector3.new(2, 1, 2)
		kursi.Color = Color3.fromRGB(80, 170, 255)
		kursi.Anchored = true
		kursi.CFrame = startCF * CFrame.new(x, 1.5, 0)
		kursi.Parent = ban
		table.insert(kursiList, kursi)
	end

	ban.Parent = parent
	local label = buatLabel(inti, "Naik bareng temanmu!")

	-- Logika perjalanan
	local berjalan = false

	local function ambilPenumpang()
		local list = {}
		for _, kursi in ipairs(kursiList) do
			if kursi.Occupant then table.insert(list, kursi.Occupant) end
		end
		return list
	end

	local function jalankan()
		berjalan = true
		for detik = 3, 1, -1 do
			label.Text = "Berangkat dalam " .. detik .. "..."
			task.wait(1)
		end

		if #ambilPenumpang() == 0 then
			label.Text = "Naik bareng temanmu!"
			berjalan = false
			return
		end

		label.Text = "Arung jeram!"
		local KECEPATAN = 18
		for n = 1, #titik - 1 do
			local a = titik[n] + naik
			local b = titik[n + 1] + naik
			local jarak = (b - a).Magnitude
			local waktu = 0
			while waktu < jarak / KECEPATAN do
				waktu += RunService.Heartbeat:Wait()
				local t = math.min(waktu * KECEPATAN / jarak, 1)
				local goyang = Vector3.new(0, math.sin(os.clock() * 4) * 0.3, 0)
				local pos = a:Lerp(b, t) + goyang
				ban:PivotTo(CFrame.lookAt(pos, pos + (b - a)))
			end
		end

		-- Turunkan penumpang di checkpoint tujuan
		local penumpang = ambilPenumpang()
		for _, humanoid in ipairs(penumpang) do
			humanoid.Sit = false
		end
		task.wait(0.2)
		for _, humanoid in ipairs(penumpang) do
			humanoid.Parent:PivotTo(CFrame.new(ke + Vector3.new(0, 4, 0)))
		end

		task.wait(2)
		ban:PivotTo(startCF)
		label.Text = "Naik bareng temanmu!"
		berjalan = false
	end

	for _, kursi in ipairs(kursiList) do
		kursi:GetPropertyChangedSignal("Occupant"):Connect(function()
			if kursi.Occupant and not berjalan then
				task.spawn(jalankan)
			end
		end)
	end
end

-- Generate rute + checkpoint
local checkpoints = {}
local posisiSebelum = Vector3.new(0, 0.5, 0)

for i, tema in ipairs(TEMA) do
	local folderArea = Instance.new("Folder")
	folderArea.Name = string.format("%02d_%s", i, tema.nama)
	folderArea.Parent = folderUtama

	local posisiCP
	if tema.jenis == "sungai" then
		posisiCP = posisiSebelum + Vector3.new(0, 0, JARAK_Z * 2) -- sungai datar & lebih panjang
	else
		posisiCP = posisiSebelum + Vector3.new(0, NAIK_Y, JARAK_Z)
	end
	folderArea:SetAttribute("Nama", tema.nama)
	folderArea:SetAttribute("BatasZ", posisiCP.Z)

	if tema.jenis == "sungai" then
		buatSungai(posisiSebelum, posisiCP, folderArea)
	else
		-- Pijakan menuju checkpoint
		for n = 1, PIJAKAN_PER_RUTE do
			local t = n / (PIJAKAN_PER_RUTE + 1)
			local pos = posisiSebelum:Lerp(posisiCP, t)
			buatPart("Pijakan" .. n, Vector3.new(8, 1, 8), pos, tema.warna, folderArea)
		end
	end

	-- Checkpoint + tiang penanda (di pojok, supaya tidak menembus karakter)
	local cp = buatPart("Checkpoint", Vector3.new(14, 1, 14), posisiCP, tema.warna, folderArea)
	local penanda = buatPart("Penanda", Vector3.new(1, 8, 1), posisiCP + Vector3.new(5, 4.5, 5),
		Color3.fromRGB(255, 170, 0), folderArea)
	penanda.Material = Enum.Material.Neon
	penanda.CanCollide = false

	buatLabel(cp, i .. ". " .. tema.nama)
	checkpoints[i] = cp
	posisiSebelum = posisiCP
end

-- ===== Data pemain: stage, respawn, kecepatan =====
local function teleportKeCheckpoint(character, nomor)
	local cp = checkpoints[nomor]
	if cp then
		character:PivotTo(cp.CFrame + Vector3.new(0, 4, 0))
	end
end

local function cekSpeedPass(player)
	if RunService:IsStudio() and TES_SPEED_DI_STUDIO then return false end -- anggap belum punya saat tes
	if ID_SPEED_PASS == 0 then return false end
	local ok, punya = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, ID_SPEED_PASS)
	end)
	return ok and punya
end

local function terapkanSpeed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = player:GetAttribute("SpeedPass") and SPEED_BOOST or SPEED_NORMAL
	end
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0
	stage.Parent = leaderstats

	player:GetAttributeChangedSignal("SpeedPass"):Connect(function()
		terapkanSpeed(player)
	end)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		task.wait() -- tunggu karakter siap
		teleportKeCheckpoint(character, stage.Value)
		terapkanSpeed(player)
	end)

	-- Muat progres yang tersimpan
	local berhasil, tersimpan = pcall(function()
		return dataProgres:GetAsync("pemain_" .. player.UserId)
	end)

	if berhasil then
		if typeof(tersimpan) == "number" then
			stage.Value = math.clamp(tersimpan, 0, #checkpoints)
			if player.Character then
				teleportKeCheckpoint(player.Character, stage.Value)
			end
		end
		player:SetAttribute("DataSiap", true)
	else
		warn("Gagal memuat progres " .. player.Name .. ": " .. tostring(tersimpan))
	end

	player:SetAttribute("SpeedPass", cekSpeedPass(player))
end)

-- Simpan progres saat pemain keluar / server mati
local function simpanProgres(player)
	-- Jangan simpan kalau data gagal dimuat, supaya progres lama tidak tertimpa 0
	if not player:GetAttribute("DataSiap") then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local stage = leaderstats and leaderstats:FindFirstChild("Stage")
	if not stage then return end

	local berhasil, err = pcall(function()
		dataProgres:SetAsync("pemain_" .. player.UserId, stage.Value)
	end)
	if berhasil then
		print("Progres " .. player.Name .. " tersimpan: Stage " .. stage.Value)
	else
		warn("Gagal menyimpan progres " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerRemoving:Connect(simpanProgres)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(simpanProgres, player)
	end
	task.wait(3) -- beri waktu proses simpan selesai
end)

-- ===== Checkpoint disentuh =====
for i, cp in ipairs(checkpoints) do
	cp.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local stage = player.leaderstats.Stage
		if i > stage.Value then
			stage.Value = i
			print(player.Name .. " mencapai checkpoint " .. i)
		end
	end)
end

-- ===== Monetisasi =====
-- Game Pass dibeli saat sedang bermain: langsung aktif
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, dibeli)
		local simulasiTes = RunService:IsStudio() and TES_SPEED_DI_STUDIO
	if passId == ID_SPEED_PASS and (dibeli or simulasiTes) then
		player:SetAttribute("SpeedPass", true)
	end
end)

-- Proses pembelian Developer Product
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipt.ProductId == ID_SKIP_CHECKPOINT then
		local stage = player.leaderstats.Stage
		if stage.Value < #checkpoints then
			stage.Value += 1
			if player.Character then
				teleportKeCheckpoint(player.Character, stage.Value)
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ===== Ulang dari awal =====
local eventUlang = Instance.new("RemoteEvent")
eventUlang.Name = "UlangDariAwal"
eventUlang.Parent = ReplicatedStorage

eventUlang.OnServerEvent:Connect(function(player)
	local stage = player.leaderstats.Stage
	stage.Value = 0
	player:LoadCharacter() -- muncul lagi di titik awal
end)