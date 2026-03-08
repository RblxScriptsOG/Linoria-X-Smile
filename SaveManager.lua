local httpService = game:GetService('HttpService')

local SaveManager = {} do

	SaveManager.Folder = 'Smile Hub/Rivals'
	SaveManager.Ignore = {}

	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object)
				return { type = 'Toggle', idx = idx, value = object.Value }
			end,
			Load = function(idx, data)
				if Toggles[idx] then Toggles[idx]:SetValue(data.value) end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = 'Slider', idx = idx, value = tostring(object.Value) }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue(data.value) end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = 'Dropdown', idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue(data.value) end
			end,
		},
		ColorPicker = {
			Save = function(idx, object)
				return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end
			end,
		},
		KeyPicker = {
			Save = function(idx, object)
				return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] then Options[idx]:SetValue({ data.key, data.mode }) end
			end,
		},
		Input = {
			Save = function(idx, object)
				return { type = 'Input', idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if Options[idx] and type(data.text) == 'string' then Options[idx]:SetValue(data.text) end
			end,
		},
	}

	function SaveManager:BuildFolderTree()
		local paths = {
			'Smile Hub',
			'Smile Hub/Rivals',
			'Smile Hub/Rivals/settings',
			'Smile Hub/Rivals/UnlockAll',
			'Smile Hub/Rivals/themes',
		}
		for _, path in ipairs(paths) do
			if not isfolder(path) then makefolder(path) end
		end
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do self.Ignore[key] = true end
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor',
			'ThemeManager_ThemeList', 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName',
			'MenuBind',
			'SaveManager_ConfigList', 'SaveManager_ConfigName',
			'UAManager_ConfigList',   'UAManager_ConfigName',
		})
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
	end

	function SaveManager:Save(name)
		if not name or name:gsub(' ', '') == '' then return false, 'no config name provided' end

		local data = { objects = {} }

		for idx, toggle in next, Toggles do
			if self.Ignore[idx] then continue end
			local ok, entry = pcall(self.Parser.Toggle.Save, idx, toggle)
			if ok then table.insert(data.objects, entry) end
		end

		for idx, option in next, Options do
			if self.Ignore[idx] then continue end
			if not self.Parser[option.Type] then continue end
			local ok, entry = pcall(self.Parser[option.Type].Save, idx, option)
			if ok then table.insert(data.objects, entry) end
		end

		local ok, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not ok then return false, 'failed to encode data' end

		writefile('Smile Hub/Rivals/settings/' .. name .. '.json', encoded)
		return true
	end

	function SaveManager:Load(name)
		if not name then return false, 'no config name provided' end

		local file = 'Smile Hub/Rivals/settings/' .. name .. '.json'
		if not isfile(file) then return false, 'config file not found' end

		local ok, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not ok then return false, 'failed to decode config' end

		for _, option in next, decoded.objects do
			if self.Parser[option.type] then
				task.spawn(function() pcall(self.Parser[option.type].Load, option.idx, option) end)
			end
		end

		return true
	end

	function SaveManager:RefreshConfigList()
		local folder = 'Smile Hub/Rivals/settings'
		if not isfolder(folder) then return {} end
		
		local list = listfiles(folder)
		local out = {}
		
		for _, file in ipairs(list) do
			if type(file) == 'string' and file:sub(-5) == '.json' then
				-- Extract filename using pattern (handles both / and \ separators)
				local name = file:match("([^/\\]+)%.json$")
				if name and name ~= "" then
					table.insert(out, name)
				end
			end
		end
		
		return out
	end

	function SaveManager:LoadAutoloadConfig()
		local autoloadFile = 'Smile Hub/Rivals/settings/autoload.txt'
		if isfile(autoloadFile) then
			local name = readfile(autoloadFile)
			local ok, err = self:Load(name)
			if not ok then
				if self.Library then self.Library:Notify('[SmileHub] Autoload failed: ' .. err) end
				return
			end
			if self.Library then self.Library:Notify(string.format('[SmileHub] Auto-loaded: %q', name)) end
		end
	end

	function SaveManager:SaveUnlockAll(name, ua_equipped, ua_favorites)
		if not name or name:gsub(' ', '') == '' then return false, 'no profile name provided' end

		local data = { equipped = {}, favorites = ua_favorites or {} }

		for weaponName, cosTable in pairs(ua_equipped or {}) do
			data.equipped[weaponName] = {}
			for ctype, cosData in pairs(cosTable) do
				if cosData and cosData.Name then
					data.equipped[weaponName][ctype] = {
						name     = cosData.Name,
						seed     = cosData.Seed,
						inverted = cosData.Inverted,
					}
				end
			end
		end

		local ok, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not ok then return false, 'failed to encode profile' end

		writefile('Smile Hub/Rivals/UnlockAll/' .. name .. '.json', encoded)
		return true
	end

	function SaveManager:LoadUnlockAll(name, cloneCosmetic)
		if not name then return false, 'no profile name provided' end

		local file = 'Smile Hub/Rivals/UnlockAll/' .. name .. '.json'
		if not isfile(file) then return false, 'profile not found' end

		local ok, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not ok then return false, 'failed to decode profile' end

		local ua_equipped  = {}
		local ua_favorites = decoded.favorites or {}

		if decoded.equipped then
			for weaponName, cosTable in pairs(decoded.equipped) do
				ua_equipped[weaponName] = {}
				for ctype, dat in pairs(cosTable) do
					if cloneCosmetic then
						local clone = cloneCosmetic(dat.name, ctype, { inverted = dat.inverted })
						if clone then
							clone.Seed = dat.seed
							ua_equipped[weaponName][ctype] = clone
						end
					else
						ua_equipped[weaponName][ctype] = dat
					end
				end
			end
		end

		return true, ua_equipped, ua_favorites
	end

	function SaveManager:RefreshUnlockAllList()
		local folder = 'Smile Hub/Rivals/UnlockAll'
		if not isfolder(folder) then return {} end
		
		local list = listfiles(folder)
		local out = {}
		
		for _, file in ipairs(list) do
			if type(file) == 'string' and file:sub(-5) == '.json' then
				-- Extract filename using pattern (handles both / and \ separators)
				local name = file:match("([^/\\]+)%.json$")
				if name and name ~= "" then
					table.insert(out, name)
				end
			end
		end
		
		return out
	end

	function SaveManager:BuildConfigSection(tabOrGroupbox)
		assert(self.Library, 'SaveManager: call SetLibrary before BuildConfigSection')

		local section
		if type(tabOrGroupbox.AddLeftGroupbox) == 'function' then
			section = tabOrGroupbox:AddLeftGroupbox('Gameplay Configs')
		elseif type(tabOrGroupbox.AddInput) == 'function' then
			section = tabOrGroupbox
		else
			error('BuildConfigSection: expected a Tab or Groupbox')
		end

		section:AddInput('SaveManager_ConfigName',    { Text = 'Config name' })
		section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true })

		section:AddDivider()

		section:AddButton({ Text = 'Create', Func = function()
			local name = Options.SaveManager_ConfigName.Value
			if name:gsub(' ', '') == '' then return self.Library:Notify('[SmileHub] Name cannot be empty', 2) end
			local ok, err = self:Save(name)
			if not ok then return self.Library:Notify('[SmileHub] Save failed: ' .. err) end
			self.Library:Notify(string.format('[SmileHub] Created %q', name))
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end }):AddButton({ Text = 'Load', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No config selected', 2) end
			local ok, err = self:Load(name)
			if not ok then return self.Library:Notify('[SmileHub] Load failed: ' .. err) end
			self.Library:Notify(string.format('[SmileHub] Loaded %q', name))
		end })

		section:AddButton({ Text = 'Overwrite', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No config selected', 2) end
			local ok, err = self:Save(name)
			if not ok then return self.Library:Notify('[SmileHub] Overwrite failed: ' .. err) end
			self.Library:Notify(string.format('[SmileHub] Overwrote %q', name))
		end }):AddButton({ Text = 'Delete', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No config selected', 2) end
			local path = 'Smile Hub/Rivals/settings/' .. name .. '.json'
			if isfile(path) then
				delfile(path)
				self.Library:Notify(string.format('[SmileHub] Deleted %q', name))
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end
		end })

		section:AddButton({ Text = 'Refresh list', Func = function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			Options.SaveManager_ConfigList:SetValue(nil)
		end }):AddButton({ Text = 'Set as autoload', Func = function()
			local name = Options.SaveManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No config selected', 2) end
			writefile('Smile Hub/Rivals/settings/autoload.txt', name)
			if SaveManager.AutoloadLabel then SaveManager.AutoloadLabel:SetText('Autoload: ' .. name) end
			self.Library:Notify(string.format('[SmileHub] Autoload -> %q', name))
		end })

		local autoName = 'none'
		if isfile and isfile('Smile Hub/Rivals/settings/autoload.txt') then
			autoName = readfile('Smile Hub/Rivals/settings/autoload.txt')
		end
		SaveManager.AutoloadLabel = section:AddLabel('Autoload: ' .. autoName, true)

		self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
	end

	function SaveManager:BuildUnlockAllSection(tab, getEquipped, getFavorites, setEquipped, setFavorites, cloneCosmetic, onLoad)
		assert(self.Library, 'SaveManager: call SetLibrary before BuildUnlockAllSection')

		local section
		if type(tab.AddLeftGroupbox) == 'function' then
			section = tab:AddLeftGroupbox('Unlock All / Skin Profiles')
		else
			section = tab
		end

		section:AddInput('UAManager_ConfigName',    { Text = 'Profile name' })
		section:AddDropdown('UAManager_ConfigList', { Text = 'Saved profiles', Values = self:RefreshUnlockAllList(), AllowNull = true })

		section:AddDivider()

		section:AddButton({ Text = 'Save profile', Func = function()
			local name = Options.UAManager_ConfigName.Value
			if name:gsub(' ', '') == '' then return self.Library:Notify('[SmileHub] Profile name cannot be empty', 2) end
			local ok, err = self:SaveUnlockAll(name, getEquipped(), getFavorites())
			if not ok then return self.Library:Notify('[SmileHub] UA save failed: ' .. err) end
			self.Library:Notify(string.format('[SmileHub] UA profile %q saved', name))
			Options.UAManager_ConfigList:SetValues(self:RefreshUnlockAllList())
			Options.UAManager_ConfigList:SetValue(nil)
		end }):AddButton({ Text = 'Load profile', Func = function()
			local name = Options.UAManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No profile selected', 2) end
			local ok, equipped, favorites = self:LoadUnlockAll(name, cloneCosmetic)
			if not ok then return self.Library:Notify('[SmileHub] UA load failed: ' .. equipped) end
			setEquipped(equipped)
			setFavorites(favorites)
			if onLoad then pcall(onLoad) end
			self.Library:Notify(string.format('[SmileHub] UA profile %q loaded', name))
		end })

		section:AddButton({ Text = 'Overwrite profile', Func = function()
			local name = Options.UAManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No profile selected', 2) end
			local ok, err = self:SaveUnlockAll(name, getEquipped(), getFavorites())
			if not ok then return self.Library:Notify('[SmileHub] UA overwrite failed: ' .. err) end
			self.Library:Notify(string.format('[SmileHub] UA profile %q overwritten', name))
		end }):AddButton({ Text = 'Delete profile', Func = function()
			local name = Options.UAManager_ConfigList.Value
			if not name then return self.Library:Notify('[SmileHub] No profile selected', 2) end
			local path = 'Smile Hub/Rivals/UnlockAll/' .. name .. '.json'
			if isfile(path) then
				delfile(path)
				self.Library:Notify(string.format('[SmileHub] Deleted UA profile %q', name))
				Options.UAManager_ConfigList:SetValues(self:RefreshUnlockAllList())
				Options.UAManager_ConfigList:SetValue(nil)
			end
		end })

		section:AddButton({ Text = 'Refresh profiles', Func = function()
			Options.UAManager_ConfigList:SetValues(self:RefreshUnlockAllList())
			Options.UAManager_ConfigList:SetValue(nil)
		end })

		section:AddLabel('Saves all equipped skins, wraps,')
		section:AddLabel('charms, camos & favorited items.')
		section:AddLabel('Saved to: Smile Hub/Rivals/UnlockAll/')

		self:SetIgnoreIndexes({ 'UAManager_ConfigList', 'UAManager_ConfigName' })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
