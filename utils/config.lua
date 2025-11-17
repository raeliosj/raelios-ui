local Config = {}
local HttpService = game:GetService("HttpService")

function Config:NewConfig(config)
	-- Support both old style (string, string) and new style (table)
	local configName, directory
	
	if type(config) == "table" then
		-- New style: table parameter
		configName = config.ConfigName or config.FileName or config.Name
		directory = config.Directory or config.FolderName
	elseif type(config) == "string" then
		-- Old style: first parameter is configName
		configName = config
		directory = nil
	else
		warn("RaeUI:NewConfig: config must be a string or table")
		return nil
	end
	
	if not configName or type(configName) ~= "string" then
		warn("RaeUI:NewConfig: configName must be a string")
		return nil
	end
	
	-- Use custom directory or default to RaeUI Configuration folder
	local customDirectory = directory
	if customDirectory and type(customDirectory) ~= "string" then
		warn("RaeUI:NewConfig: directory must be a string, using default")
		customDirectory = nil
	end
	
	-- Create independent storage for this custom config
	local Flags = {}
	
	-- Save function for this custom config
	local function SaveConfiguration()
		print("RaeUI.CustomConfig: Saving configuration for", configName)
		-- Filter out keys with nil values
		local dataToSave = {}
		local hasData = false
		
		for key, value in pairs(Flags) do
			if value ~= nil then
				dataToSave[key] = value
				hasData = true
			end
		end
		
		if not hasData then
			print("RaeUI.CustomConfig: No valid data to save for " .. configName)
			return false
		end
		
		if not writefile or not isfolder or not makefolder then
			warn("RaeUI.CustomConfig: File operations not available")
			return false
		end
		
		-- Use custom directory or default to RaeUI folder structure
		local dynamicFolderName, dynamicConfigurationFolder, filePath
		
		if customDirectory then
			-- Custom directory path
			dynamicFolderName = customDirectory
			dynamicConfigurationFolder = customDirectory
			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
		else
			-- Default RaeUI folder structure
			dynamicFolderName = RaeUI.Configuration.FolderName or "RaeUI"
			dynamicConfigurationFolder = dynamicFolderName .. "/Configurations"
			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
		end
		
		-- Create folders if they don't exist
		if not isfolder(dynamicFolderName) then
			makefolder(dynamicFolderName)
		end
		
		-- Only create Configurations subfolder if not using custom directory
		if not customDirectory and not isfolder(dynamicConfigurationFolder) then
			makefolder(dynamicConfigurationFolder)
		end
		
		-- Save to JSON file
		local success, result = pcall(function()
			writefile(filePath, HttpService:JSONEncode(dataToSave))
		end)
		
		if success then
			local savedCount = 0
			for _ in pairs(dataToSave) do
				savedCount = savedCount + 1
			end
			print("RaeUI.CustomConfig: " .. configName .. " saved to " .. filePath .. " (" .. savedCount .. " keys)")
			return true
		else
			warn("RaeUI.CustomConfig: Failed to save " .. configName .. ": " .. tostring(result))
			return false
		end
	end
	
	-- Load function for this custom config
	local function LoadConfiguration()
		if not readfile or not isfile then
			warn("RaeUI.CustomConfig: File operations not available")
			return false
		end
		
		-- Use custom directory or default to RaeUI folder structure
		local filePath
		
		if customDirectory then
			-- Custom directory path
			filePath = customDirectory .. "/" .. configName .. ".json"
		else
			-- Default RaeUI folder structure
			local dynamicFolderName = RaeUI.Configuration.FolderName or "RaeUI"
			local dynamicConfigurationFolder = dynamicFolderName .. "/Configurations"
			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
		end
		
		if not isfile(filePath) then
			print("RaeUI.CustomConfig: No file found for " .. configName .. " at " .. filePath)
			return false
		end
		
		local success, configData = pcall(function()
			print("RaeUI.CustomConfig: Loading configuration from " .. filePath)
			-- Decode JSON data
			return HttpService:JSONDecode(readfile(filePath))
		end)
		
		if not success then
			warn("RaeUI.CustomConfig: Failed to load " .. configName .. ": " .. tostring(configData))
			return false
		end
		
		-- Apply loaded data and update components
		local applied = 0
		for flagName, flagValue in pairs(configData) do
			print("RaeUI.CustomConfig: Loaded", flagName, "=", flagValue)
			Flags[flagName] = flagValue
			applied = applied + 1
		end
		
		print("RaeUI.CustomConfig: " .. configName .. " loaded (" .. applied .. " settings applied)")
		return true
	end
	
	local configAPI = {}
	
	-- Get value by key
	function configAPI:GetValue(key)
		if not key then
			warn("RaeUI.CustomConfig.GetValue: key parameter is required")
			return nil
		end
		return Flags[key]
	end
	
	-- Set value by key and update associated components
	function configAPI:SetValue(key, value)
		if not key then
			warn("RaeUI.CustomConfig.SetValue: key parameter is required")
			return false
		end
		print("RaeUI.CustomConfig: Setting", key, "to", value)
		
		Flags[key] = value
		
		SaveConfiguration()
		return true
	end
	
	-- Get all key-value pairs
	function configAPI:GetAll()
		local result = {}
		for key, value in pairs(Flags) do
			if value ~= nil then
				result[key] = value
			end
		end
		return result
	end
	
	-- Get All Keys
	function configAPI:GetAllKeys()
		local keys = {}
		for key, value in pairs(Flags) do
			if value ~= nil then
				table.insert(keys, key)
			end
		end
		return keys
	end
	
	-- Delete a specific key
	function configAPI:DeleteKey(key)
		if not key then
			warn("RaeUI.CustomConfig.DeleteKey: key parameter is required")
			return false
		end
		
		if Flags[key] ~= nil then
			Flags[key] = nil
			
			SaveConfiguration()
			return true
		else
			warn("RaeUI.CustomConfig.DeleteKey: key '" .. key .. "' not found")
			return false
		end
	end
	
	-- Get configuration info
	function configAPI:GetInfo()
		local folderName, configFolder, filePath
		
		if customDirectory then
			folderName = customDirectory
			configFolder = customDirectory
			filePath = customDirectory .. "/" .. configName .. ".json"
		else
			folderName = RaeUI.Configuration.FolderName or "RaeUI"
			configFolder = folderName .. "/Configurations"
			filePath = configFolder .. "/" .. configName .. ".json"
		end
		
		return {
			ConfigName = configName,
			CustomDirectory = customDirectory,
			FolderName = folderName,
			ConfigFolder = configFolder,
			FilePath = filePath,
			IsCustomDirectory = customDirectory ~= nil
		}
	end
	
	-- Manual save
	function configAPI:Save()
		return SaveConfiguration()
	end
	
	-- Manual load
	function configAPI:Load()
		return LoadConfiguration()
	end
	
	-- Return custom configuration object
	return configAPI
end

return Config
