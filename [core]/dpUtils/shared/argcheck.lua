function argcheck(arg, argType, options)
	if not argType or type(argType) ~= "string" then
		argType = "nil"
	end
	if argType == "function" then
		outputDebugString("argcheck: Cannot check functions")
		return true
	end
	local result = tostring(type(arg)) == argType
	-- Проверка МТА типов
	if isElement(arg) then
		result = tostring(arg.type) == argType 
	end
	if not result then
		return result
	end

	if options then
		if argType == "table" then
			if options.notEmpty and next(arg) == nil then
				outputDebugString("argcheck: table must not be empty")
				return false
			end
		end
	end
	return result
end