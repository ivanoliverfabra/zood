--[[
  Helper Functions
]] --- Check if the data matches the expected type.
-- @param dataType string: The expected type (e.g., "string", "number").
-- @param data any: The data to check.
-- @return boolean: True if the data matches the type, false otherwise.
local function isType(dataType, data)
  if dataType == "array" then
    if type(data) ~= "table" then return false end
    for i, _ in ipairs(data) do if type(i) ~= "number" then return false end end
    return true
  end

  return type(data) == dataType
end

--[[
  Stack Levels
  1: Caller of customError
  2: Validator function
  3: Wrapper function
]]

--- Custom error function with improved formatting.
-- @param message string: The error message.
-- @param level number: The stack level to report (default: 1, the caller of this function).
local function customError(message, level)
  level = level or 1
  error(message, level)
end

--- Parse a message from the props table.
-- @param props table: The properties table.
-- @param data any: The data to pass to the message function.
-- @param default string: The default message if none is provided.
-- @return string: The parsed message.
local function parsePropsMessage(props, data, default)
  if not props.message then return default end
  if type(props.message) == "function" then return props.message(data) end
  if string.find(props.message, "%%s") then return string.format(props.message, data) end
  return tostring(props.message)
end

--- Remove functions from a table.
-- @param tbl table: The table to remove functions from.
-- @return table: The table with functions removed.
local function removeFunctionsFromTable(tbl)
  local newTable = {}
  for k, v in pairs(tbl) do
    if type(v) == "function" then
      newTable[k] = nil
    elseif type(v) == "table" then
      if next(v) ~= nil then newTable[k] = removeFunctionsFromTable(v) end
    else
      newTable[k] = v
    end
  end
  return newTable
end

local function transformAll(schema, data)
  if schema.type == "table" and schema.fields then
    local mergedData = {}
    for key, fieldSchema in pairs(schema.fields) do
      if data[key] ~= nil then
        mergedData[key] = transformAll(fieldSchema, data[key])
      elseif fieldSchema.default ~= nil then
        mergedData[key] = fieldSchema.default
      end
    end
    return mergedData
  elseif schema.type == "array" then
    local mergedData = {}
    for i, item in ipairs(data) do mergedData[i] = transformAll(schema.fields, item) end
    return mergedData
  elseif schema.type == "union" then
    for _, option in ipairs(schema.fields) do
      local success, result = option:safeParse(data)
      if success then return result end
    end
    return data
  else
    return data
  end
end

--[[
  Base Schema
]]

local Z = {}

local BaseSchema = {}
BaseSchema.__index = BaseSchema

--- Create a new schema instance.
-- @param type string: The type of the schema, used for error messages.
-- @param fields table: A table of fields that the schema will have.
-- @param optional boolean: If the schema is optional.
-- @param default any: The default value of the schema.
-- @param validate function: A function that validates the schema.
-- @param transform function: A function that transforms the schema.
-- @param error string: The error message that will be thrown if the schema is invalid.
-- @return BaseSchema: A new schema.
function BaseSchema.new(type, fields, optional, default, validate, transform, error)
  local schema = setmetatable({}, BaseSchema)
  schema.type = type or "unknown"
  schema.fields = fields or {}
  schema.optional = optional or false
  schema.default = default
  schema.validate = validate
  schema.transform = transform or function(data)
    return transformAll(schema, data)
  end
  schema.error = error or ("Expected value of type '" .. type .. "', but got '%s' instead.")

  schema.min = nil
  schema.max = nil
  schema.length = nil
  schema.email = nil
  schema.url = nil
  schema.pattern = nil
  schema.positive = nil
  schema.negative = nil

  return schema
end

--- Parse data and throw an error if invalid.
-- @param data any: The data to parse.
-- @return any: The parsed data.
function BaseSchema:parse(data)
  local success, result = self:safeParse(data)
  if not success then customError("Errors:\n" .. table.concat(result, "\n"), 3) end
  return result
end

--- Parse data without throwing an error.
-- @param data any: The data to parse.
-- @return boolean, table: True if the data is valid, false and a table of errors otherwise.
function BaseSchema:safeParse(data)
  local errors = {}

  if data == nil then
    if self.optional then
      return true, self.default
    else
      table.insert(errors, string.format(self.error, "nil"))
      return false, errors
    end
  end

  local mergedData
  if self.type == "table" and self.fields then
    mergedData = {}
    for key, schema in pairs(self.fields) do
      if data[key] ~= nil then
        mergedData[key] = data[key]
      elseif schema.default ~= nil then
        mergedData[key] = schema.default
      end
    end
  else
    mergedData = data
  end

  if self.transform then mergedData = self.transform(mergedData) end

  if not self.validate and not isType(self.type, mergedData) then
    table.insert(errors, string.format(self.error, type(mergedData)))
    return false, errors
  end

  if self.validate then
    local success, err = self.validate(mergedData)
    if not success then
      if isType("table", err) then
        for _, e in ipairs(err) do table.insert(errors, e) end
      else
        table.insert(errors, err or string.format(self.error, type(mergedData)))
      end
    end
  end

  if self.type == "table" and self.fields then
    for key, schema in pairs(self.fields) do
      if mergedData[key] ~= nil then
        local success, transformedValue = schema:safeParse(mergedData[key])
        if success then
          mergedData[key] = transformedValue
        else
          if isType("table", transformedValue) then
            for _, e in ipairs(transformedValue) do table.insert(errors, e) end
          else
            table.insert(errors, transformedValue)
          end
        end
      end
    end
  end

  if #errors > 0 then
    return false, errors
  else
    return true, mergedData
  end
end

--- Mark the schema as optional.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:nullable()
  self.optional = true

  local prevValidate = self.validate
  self.validate = function(data)
    if data == nil then return true end
    return prevValidate(data)
  end

  return self
end

--- Set a default value for the schema.
-- @param value any: The default value.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:default(value)
  self.default = value
  self.optional = true

  if value ~= nil then
    local isValid = self.validate(value)
    if not isValid then
      customError("Default value is invalid. Expected " .. self.type .. ", but got '" .. type(value) .. "' instead.", 3)
    end
  end

  local prevValidate = self.validate
  self.validate = function(data)
    if data == nil then return true end
    return prevValidate(data)
  end

  return self
end

--- Set a custom validation function.
-- @param func function: The validation function.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:validate(func)
  self.validate = func
  return self
end

--- Set a custom error message.
-- @param message string: The error message.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:error(message)
  self.error = message
  return self
end

--[[
  Helper Functions
]]

--- Set a minimum value for the schema.
-- @param value number: The minimum value.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:min(value, props)
  if not props then props = {} end

  self.validate = self.validate or function(data)
    return true
  end
  local prevValidate = self.validate
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if (isType("number", data) and data < value) then
      return false, parsePropsMessage(props, data, "Value must be at least " .. value .. ", got " .. data)
    elseif isType("string", data) and #data < value then
      return false, parsePropsMessage(props, #data, "Length must be at least " .. value .. ", got " .. #data)
    elseif isType("array", data) and #data < value then
      return false, parsePropsMessage(props, #data, "Length must be at least " .. value .. ", got " .. #data)
    end

    return true
  end

  self.min = value
  return self
end

--- Set a maximum value for the schema.
-- @param value number: The maximum value.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:max(value, props)
  if not props then props = {} end

  self.validate = self.validate or function(data)
    return true
  end
  local prevValidate = self.validate
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    local isNum, isStr, isArr = isType("number", data), isType("string", data), isType("array", data)

    if not isNum and not isStr and not isArr then
      return false, "Expected number, string, or array, got " .. type(data)
    end

    if isNum and data > value then
      return false, parsePropsMessage(props, data, "Value must be at most " .. value .. ", got " .. data)
    elseif isStr and #data > value then
      return false, parsePropsMessage(props, #data, "Length must be at most " .. value .. ", got " .. #data)
    elseif isArr and #data > value then
      return false, parsePropsMessage(props, #data, "Length must be at most " .. value .. ", got " .. #data)
    end

    return true
  end

  self.max = value
  return self
end

--- Validate that the number is positive.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:positive(props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("number", data) then return false, "Expected number, got " .. type(data) end

    if data <= 0 then return false, parsePropsMessage(props, data, "Value must be positive, got " .. data) end

    return true
  end

  self.positive = true
  return self
end

--- Validate that the number is negative.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:negative(props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("number", data) then return false, "Expected number, got " .. type(data) end

    if data >= 0 then return false, parsePropsMessage(props, data, "Value must be negative, got " .. data) end

    return true
  end

  self.negative = true
  return self
end

--- Set an exact length for the schema.
-- @param length number: The exact length.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:length(length, props)
  if not props then props = {} end
  self.validate = self.validate or function(data)
    return true
  end
  local prevValidate = self.validate
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    local len
    if isType("string", data) or isType("array", data) then
      len = #data
    else
      return false, "Expected string or array, got " .. type(data)
    end

    if len ~= length then
      return false, parsePropsMessage(props, len, "Length must be exactly " .. length .. ", got " .. len)
    end
    return true
  end

  self.length = length
  return self
end

--- Validate that the string is a valid email address.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:email(props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("string", data) then return false, "Expected string, got " .. type(data) end

    local pattern = "^[%w%.%%%+%-]+@[%w%.%-]+%.[a-zA-Z]+$"
    if not string.match(data, pattern) then
      return false, parsePropsMessage(props, data, "Value must be a valid email address, got " .. data)
    end

    return true
  end

  self.email = true
  return self
end

--- Validate that the string is a valid URL.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:url(props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("string", data) then return false, "Expected string, got " .. type(data) end

    local pattern = "^https?://([%w%.%-]+%.[a-zA-Z]+|localhost|%d+%.%d+%.%d+%.%d+)$"
    if not string.match(data, pattern) then
      return false, parsePropsMessage(props, data, "Value must be a valid URL, got " .. data)
    end

    return true
  end

  self.url = true
  return self
end

--- Validate that the string is a valid IP address.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:ip(props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("string", data) then return false, "Expected string, got " .. type(data) end

    local pattern = "^%d+%.%d+%.%d+%.%d+$"
    if not string.match(data, pattern) then
      return false, parsePropsMessage(props, data, "Value must be a valid IP address, got " .. data)
    end

    return true
  end

  self.ip = true
  return self
end

--- Validate that the string matches a regex pattern.
-- @param pattern string: The regex pattern to match.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:pattern(pattern, props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    if not isType("string", data) then return false, "Expected string, got " .. type(data) end

    if not string.match(data, pattern) then
      return false, parsePropsMessage(props, data, "Value must match pattern '" .. pattern .. "', got " .. data)
    end

    return true
  end

  self.pattern = pattern
  return self
end

--- Validate that the value is one of the specified values.
-- @param values table: A table of allowed values.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:enum(values, props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    for _, value in ipairs(values) do if data == value then return true end end

    return false,
        parsePropsMessage(props, data, "Value must be one of " .. table.concat(values, ", ") .. ", got " .. data)
  end

  self.fields = values
  return self
end

--- Trim whitespace from a string.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:trim(props)
  local prevTransform = self.transform or function(data)
    return data
  end
  self.transform = function(data)
    data = prevTransform(data)
    if type(data) == "string" then return string.match(data, "^%s*(.-)%s*$") end
    return data
  end
  return self
end

--- Convert a string to lowercase.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:lower(props)
  local prevTransform = self.transform or function(data)
    return data
  end
  self.transform = function(data)
    data = prevTransform(data)
    if type(data) == "string" then return string.lower(data) end
    return data
  end
  return self
end

--- Convert a string to uppercase.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:upper(props)
  local prevTransform = self.transform or function(data)
    return data
  end
  self.transform = function(data)
    data = prevTransform(data)
    if type(data) == "string" then return string.upper(data) end
    return data
  end
  return self
end

--- Validate that a number or string length is between two values.
-- @param min number: The minimum value.
-- @param max number: The maximum value.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:between(min, max, props)
  if not props then props = {} end
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end

    local value
    if type(data) == "number" then
      value = data
    elseif type(data) == "string" then
      value = #data
    else
      return false, "Expected number or string, got " .. type(data)
    end

    if value < min or value > max then
      return false,
          parsePropsMessage(props, value, "Value must be between " .. min .. " and " .. max .. ", got " .. value)
    end
    return true
  end

  self.min = min
  self.max = max
  return self
end

--- Add a custom validation function.
-- @param func function: The custom validation function.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function BaseSchema:custom(func, props)
  local prevValidate = self.validate or function(data)
    return true
  end
  self.validate = function(data)
    local success, err = prevValidate(data)
    if not success then return false, err end
    return func(data)
  end
  return self
end

--[[
  Primitive Schemas
]]

--- Create a string schema.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.string(props)
  if not props then props = {} end
  return BaseSchema.new("string"):validate(function(data)
    if not isType("string", data) then
      return false, parsePropsMessage(props, data, "Expected string, got " .. type(data))
    end
    return true
  end)
end

--- Create a number schema.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.number(props)
  if not props then props = {} end
  return BaseSchema.new("number"):validate(function(data)
    if not isType("number", data) then
      return false, parsePropsMessage(props, data, "Expected number, got " .. type(data))
    end
    return true
  end)
end

--- Create a boolean schema.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.boolean(props)
  if not props then props = {} end
  return BaseSchema.new("boolean"):validate(function(data)
    if not isType("boolean", data) then
      return false, parsePropsMessage(props, data, "Expected boolean, got " .. type(data))
    end
    return true
  end)
end

--[[
  Compound Schemas
]]

--- Create a table schema.
-- @param fields table: A table of fields for the schema.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.table(fields, props)
  return BaseSchema.new("table", fields):validate(function(data)
    local errors = {}
    if not isType("table", data) then
      table.insert(errors, "Expected table, got " .. type(data))
      return false, errors
    end

    for key, schema in pairs(fields) do
      local success, err = schema:safeParse(data[key])
      if not success then
        if type(err) == "table" then
          for _, e in ipairs(err) do table.insert(errors, "Field '" .. key .. "': " .. e) end
        else
          table.insert(errors, "Field '" .. key .. "': " .. err)
        end
      end
    end

    if #errors > 0 then
      return false, errors
    else
      return true
    end
  end)
end

--- Create an enum schema.
-- @param values table: A table of allowed values.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.array(elementSchema, props)
  return BaseSchema.new("array", elementSchema):validate(function(data)
    local errors = {}
    if not isType("table", data) then
      table.insert(errors, "Expected array, got " .. type(data))
      return false, errors
    end

    for i, item in ipairs(data) do
      local success, err = elementSchema:safeParse(item)
      if not success then
        if type(err) == "table" then
          for _, e in ipairs(err) do table.insert(errors, "Element " .. i .. ": " .. e) end
        else
          table.insert(errors, "Element " .. i .. ": " .. err)
        end
      end
    end

    if #errors > 0 then
      return false, errors
    else
      return true
    end
  end)
end

--[[
  Complex Schemas
]]

function Z.custom(validator)
  return BaseSchema.new("custom"):validate(validator)
end

--- Create a union schema.
-- @param schemas table: A table of schemas to union.
-- @param props table: Additional properties for the schema.
-- @return BaseSchema: The schema instance for chaining.
function Z.union(schemas, props)
  if not props then props = {} end
  return BaseSchema.new("union", schemas):validate(function(data)
    local errors = {}
    for i, schema in ipairs(schemas) do
      local success, result = schema:safeParse(data)

      if success then
        return true, result
      else
        table.insert(errors, "Option " .. i .. ": " .. table.concat(result, ", "))
      end
    end

    -- All options failed
    return false, parsePropsMessage(props, data, table.concat(errors, "\n"))
  end)
end

--[[
  Extra Functions
]]

function Z.toTable(schema)
  schema = removeFunctionsFromTable(schema)

  local function toTable(s)
    if getmetatable(s) == BaseSchema then
      local output = {
        type = s.type
      }
      if s.optional then output.optional = true end
      if s.default ~= nil then output.default = s.default end
      if s.error then output.error = s.error end

      if s.type == "table" and s.fields then
        output.fields = {}
        for key, fieldSchema in pairs(s.fields) do output.fields[key] = toTable(fieldSchema) end
      elseif s.type == "array" then
        output.element = toTable(s.fields)
      elseif s.type == "enum" then
        output.values = s.fields
      elseif s.type == "union" then
        output.options = {}
        for i, unionSchema in ipairs(s.fields) do output.options[i] = toTable(unionSchema) end
      end
      return output
    else
      return s
    end
  end

  return toTable(schema)
end

function Z.toJSON(schema)
  return textutils.serializeJSON(Z.toTable(schema))
end

--- Write a schema to a file.
-- @param schema BaseSchema: The schema to write.
-- @param name string: The name of the file.
-- @param type string: The file type.
function Z.toFile(schema, name, type)
  if type ~= "json" and type ~= "lua" then customError("Invalid file type: " .. type) end
  if not name then customError("File name is required") end

  local path = fs.combine(shell.dir(), name .. "." .. type)
  local file = io.open(path, "w")
  if not file then customError("Could not open file for writing: " .. path) end

  if type == "json" then
    file:write(Z.toJSON(schema))
  elseif type == "lua" then
    file:write("return " .. textutils.serialize(Z.toTable(schema)))
  else
    customError("Unsupported file type: " .. type)
  end

  file:close()
end

return Z
