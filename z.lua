local pretty = require("cc.pretty")

local Z = {}

local function is_array(tbl)
  if type(tbl) ~= "table" then return false end
  local i = 0
  for _ in pairs(tbl) do
    i = i + 1
    if tbl[i] == nil then return false end
  end
  return true
end

local function shallow_copy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local t = {}
  for k, v in pairs(tbl) do t[k] = v end
  return t
end

Z._defaultMessages = {
  type = {
    string = "Expected string, got %s",
    number = "Expected number, got %s",
    boolean = "Expected boolean, got %s",
    table = "Expected table, got %s",
    ["function"] = "Expected function, got %s",
    userdata = "Expected userdata, got %s",
    ["nil"] = "Expected nil, got %s",
    any = "Invalid value, got %s"
  },
  required = "Field %s is required",
  optional = "Optional field %s is invalid",
  nullable = "Field %s cannot be null",
  default = "Failed to apply default value for %s",
  string = {
    min = "String must be at least %d characters",
    max = "String must be at most %d characters",
    length = "String must be exactly %d characters",
    pattern = "String must match pattern: %s",
    email = "Invalid email address format",
    url = "Invalid URL format",
    domain = "Invalid domain name",
    ip = "Invalid IP address",
    uuid = "Invalid UUID format",
    trim = "Failed to trim string",
    lower = "Failed to convert to lowercase",
    upper = "Failed to convert to uppercase",
    contains = "String must contain: %s",
    startsWith = "String must start with: %s",
    endsWith = "String must end with: %s",
    datetime = "Invalid datetime format",
    date = "Invalid date format",
    time = "Invalid time format"
  },
  number = {
    min = "Number must be at least %d",
    max = "Number must be at most %d",
    positive = "Number must be positive",
    negative = "Number must be negative",
    integer = "Number must be an integer",
    finite = "Number must be finite",
    between = "Number must be between %d and %d",
    multipleOf = "Number must be a multiple of %d",
    gt = "Number must be greater than %d",
    gte = "Number must be greater than or equal to %d",
    lt = "Number must be less than %d",
    lte = "Number must be less than or equal to %d",
    nonnegative = "Number must be non-negative",
    nonpositive = "Number must be non-positive"
  },
  table = {
    invalid = "Invalid table structure",
    unknownKey = "Unknown key: %s",
    missingKey = "Missing required key: %s",
    invalidKey = "Invalid key: %s",
    strict = "Unexpected field: %s",
    pick = "Failed to pick fields: %s",
    omit = "Failed to omit fields: %s",
    partial = "Failed to make fields partial",
    required = "Failed to make fields required",
    extend = "Failed to extend schema",
    shape = "Invalid table shape",
    minFields = "Table must have at least %d fields",
    maxFields = "Table must have at most %d fields",
    exactFields = "Table must have exactly %d fields"
  },
  array = {
    min = "Array must contain at least %d items",
    max = "Array must contain at most %d items",
    length = "Array must contain exactly %d items",
    unique = "Array items must be unique",
    element = "Invalid array element at index %d",
    type = "Expected array, got %s"
  },
  enum = {
    invalid = "Invalid enum value. Expected one of: %s",
    mismatch = "Value does not match any enum option",
    type = "Expected enum value, got %s"
  },
  union = {
    invalid = "Value does not match any union type",
    discriminator = "Invalid discriminator value: %s",
    type = "Expected union value, got %s"
  },
  coerce = {
    string = "Failed to coerce value to string: %s",
    number = "Failed to coerce value to number: %s",
    boolean = "Failed to coerce value to boolean: %s",
    date = "Failed to coerce value to date: %s",
    invalid = "Invalid value for coercion: %s"
  },
  peripheral = {
    notFound = "Peripheral not found: %s",
    wrongType = "Wrong peripheral type. Expected %s, got %s",
    invalid = "Invalid peripheral",
    missing = "No peripheral attached to %s",
    unavailable = "Peripheral is unavailable"
  },
  color = {
    invalid = "Invalid color value: %s",
    outOfRange = "Color value out of range",
    type = "Expected color value, got %s"
  },
  side = {
    invalid = "Invalid side value: %s",
    type = "Expected side value, got %s"
  },
  custom = {
    default = "Custom validation failed",
    invalid = "Invalid value: %s",
    error = "Validation error: %s"
  },
  transform = {
    failed = "Failed to transform value",
    invalid = "Invalid transformation result",
    error = "Transform error: %s"
  },
  validation = {
    failed = "Validation failed",
    invalid = "Invalid value",
    type = "Type validation failed",
    constraint = "Constraint validation failed",
    custom = "Custom validation failed"
  },
  format = {
    path = "Error at path: %s",
    value = "Invalid value: %s",
    type = "Type mismatch at %s",
    multiple = "Multiple validation errors occurred"
  }
}

Z._patterns = {
  email = "^[%w%.%%%-_]+@[%w%%%-_]+%.[%a]+$",
  url = "^https?://%w+%.[%w%.]+%w+$",
  domain = "^%w+%.[%w%.]+%w+$",
  ip = "^%d+%.%d+%.%d+%.%d+$",
  uuid = "^[%w%-]+$",
  datetime = "^%d{4}%-%d{2}%-%d{2}T%d{2}%:%d{2}%:%d{2}%.[%d%w]+Z$",
  date = "^%d{4}%-%d{2}%-%d{2}$",
  time = "^%d{2}%:%d{2}%:%d{2}%.[%d%w]+Z$"
}

local function format_message(msg, ctx)
  if type(msg) ~= "string" then return tostring(msg) or "[Zood] Unknown error" end

  ctx = ctx or {}
  -- Create safe path array
  local safe_path = {}
  if type(ctx.path) == "table" then
    for _, v in ipairs(ctx.path) do
      if type(v) == "string" or type(v) == "number" then safe_path[#safe_path + 1] = tostring(v) end
    end
  end

  -- Pre-compute values
  local value_length = (type(ctx.value) == "table" or type(ctx.value) == "string") and #ctx.value or 0

  -- Define formatters
  local formatters = {
    ["%%s"] = tostring(ctx.value),
    ["%%d"] = type(ctx.value) == "number" and tostring(math.floor(ctx.value)) or "0",
    ["%%f"] = type(ctx.value) == "number" and tostring(ctx.value) or "0",
    ["%%type"] = type(ctx.value),
    ["%%path"] = table.concat(safe_path, "."),
    ["%%expected"] = tostring(ctx.expected),
    ["%%received"] = tostring(ctx.received),
    ["%%arg"] = tostring(ctx.arg),
    ["%%key"] = tostring(ctx.key),
    ["%%index"] = tostring(ctx.index),
    ["%%length"] = tostring(value_length),
    ["%%code"] = tostring(ctx.code),
    ["%%rule"] = tostring(ctx.rule),
    ["%%schema"] = tostring(ctx.schemaType)
  }

  -- Replace all format specifiers
  for pattern, replacement in pairs(formatters) do msg = msg:gsub(pattern, replacement) end

  return msg
end

local function lookup_message(messages, ctx)
  if not messages or not ctx then return nil end

  -- Direct lookups
  if ctx.schemaType then
    local schema_messages = messages[ctx.schemaType]
    if type(schema_messages) == "table" then
      if ctx.rule and schema_messages[ctx.rule] then return schema_messages[ctx.rule] end
      if ctx.code and schema_messages[ctx.code] then return schema_messages[ctx.code] end
      return schema_messages
    end
  end

  -- Fallback lookups
  return messages[ctx.code] or messages[ctx.type] or messages[ctx.rule]
end

local function resolve_message(schema, rule, ctx, fallback)
  -- Check rule-specific message
  if rule and rule.msg then
    if type(rule.msg) == "function" then return format_message(rule.msg(ctx), ctx) end
    return format_message(rule.msg, ctx)
  end

  -- Check schema-specific message
  if schema and schema._opts and schema._opts.message then
    if type(schema._opts.message) == "function" then return format_message(schema._opts.message(ctx), ctx) end
    return format_message(schema._opts.message, ctx)
  end

  local msg = nil

  -- Get messages from config
  local messages = Z and Z._config and Z._config.messages
  if messages then
    msg = lookup_message(messages, ctx)
    if type(msg) == "table" then msg = msg[ctx.rule] or msg[ctx.code] or nil end
  end

  -- Fallback to default messages
  if not msg and Z then
    msg = lookup_message(Z._defaultMessages, ctx)
    if type(msg) == "table" then msg = msg[ctx.rule] or msg[ctx.code] or nil end
  end

  -- Final fallback
  msg = msg or fallback
  pretty.pretty_print(msg)

  -- Handle table messages
  if type(msg) == "table" then
    msg = (ctx.rule and msg[ctx.rule]) or (ctx.code and msg[ctx.code]) or "[Zood] Unknown error"
  end

  -- Handle function messages
  if type(msg) == "function" then msg = msg(ctx) end

  return format_message(msg, ctx)
end

local function make_error(ctx)
  return {
    message = ctx.message,
    code = ctx.code or "validation",
    path = ctx.path or {},
    value = ctx.value,
    expected = ctx.expected,
    received = ctx.received,
    details = ctx.details
  }
end

local function format_path(path)
  if not path then return "" end
  if type(path) == "table" then
    local safe_path = {}
    for _, v in ipairs(path) do
      if type(v) == "string" or type(v) == "number" then table.insert(safe_path, tostring(v)) end
    end
    return table.concat(safe_path, ".")
  end
  return tostring(path)
end

local function ValidationError(errors)
  return setmetatable({
    errors = errors or {},
    format = function(self)
      local out = {}
      for _, err in ipairs(self.errors) do
        local path = format_path(err.path)
        local message = path ~= "" and string.format("%s at '%s' (%s)", err.message, path, tostring(err.value)) or
        string.format("%s (%s)", err.message, tostring(err.value))
        table.insert(out, message)
      end
      return table.concat(out, "\n")
    end
  }, {
    __tostring = function(self)
      return self:format()
    end
  })
end

local Schema = {}
Schema.__index = Schema

function Schema:parse(value, opts)
  local ok, res = self:safeParse(value, opts)
  if not ok then error(res:format(), 2) end
  return res
end

function Schema:safeParse(value, opts)
  local ok, result, errtbl = self:_validate(value, opts or {}, {}, {})
  if ok then return true, result end
  local out = ValidationError(errtbl or {})
  return false, out
end

function Schema:test(value, opts)
  local ok = self:_validate(value, opts or {}, {}, {})
  return ok
end

function Schema:type()
  return self._type
end

function Schema:isNullable()
  return self._nullable or false
end

function Schema:isOptional()
  return self._optional or false
end

function Schema:clone()
  local c = shallow_copy(self)
  setmetatable(c, getmetatable(self))
  return c
end

function Schema:nullable(opts)
  local s = self:clone()
  s._nullable = true
  s._nullableMsg = opts and opts.message
  return s
end

function Schema:optional(opts)
  local s = self:clone()
  s._optional = true
  s._optionalMsg = opts and opts.message
  return s
end

function Schema:default(def, opts)
  local s = self:clone()
  s._default = def
  s._defaultMsg = opts and opts.message
  return s
end

function Schema:catch(fallback, opts)
  local s = self:clone()
  s._catch = fallback
  s._catchMsg = opts and opts.message
  return s
end

function Schema:custom(fn, opts)
  local s = self:clone()
  s._custom = fn
  s._customMsg = opts and opts.message
  return s
end

function Schema:transform(fn, opts)
  local s = self:clone()
  s._transform = fn
  s._transformMsg = opts and opts.message
  return s
end

function Z.string(opts)
  local self = setmetatable({
    _type = "string",
    _opts = opts or {},
    _rules = {}
  }, Schema)
  return self
end

function Schema:min(n, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "min",
    arg = n,
    msg = opts and opts.message
  })
  return s
end

function Schema:max(n, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "max",
    arg = n,
    msg = opts and opts.message
  })
  return s
end

function Schema:length(n, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "length",
    arg = n,
    msg = opts and opts.message
  })
  return s
end

function Schema:pattern(pat, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "pattern",
    arg = pat,
    msg = opts and opts.message
  })
  return s
end

function Schema:email(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "email",
    msg = opts and opts.message
  })
  return s
end

function Schema:url(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "url",
    msg = opts and opts.message
  })
  return s
end

function Schema:domain(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "domain",
    msg = opts and opts.message
  })
  return s
end

function Schema:uuid(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "uuid",
    msg = opts and opts.message
  })
  return s
end

function Schema:ip(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "ip",
    msg = opts and opts.message
  })
  return s
end

function Schema:trim(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "trim",
    msg = opts and opts.message
  })
  return s
end

function Schema:lower(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "lower",
    msg = opts and opts.message
  })
  return s
end

function Schema:upper(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "upper",
    msg = opts and opts.message
  })
  return s
end

function Schema:startsWith(prefix, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "startsWith",
    arg = prefix,
    msg = opts and opts.message
  })
  return s
end

function Schema:endsWith(suffix, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "endsWith",
    arg = suffix,
    msg = opts and opts.message
  })
  return s
end

function Schema:includes(substr, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "includes",
    arg = substr,
    msg = opts and opts.message
  })
  return s
end

function Schema:element(schema, opts)
  local s = self:clone()
  s._element = schema
  s._elementMsg = opts and opts.message
  return s
end

function Schema:unique(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "unique",
    msg = opts and opts.message
  })
  return s
end

function Schema:_validate(value, opts, errors, path)
  -- Defensive: ensure errors is always a table
  errors = errors or {}
  path = path or {}
  if self._type == "string" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "string",
            path = path,
            value = value
          }, "Field is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "string" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "string",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected string, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local v = value
    for _, rule in ipairs(self._rules) do
      if rule.name == "min" and #v < rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "min",
            schemaType = "string",
            rule = "min",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("String must be at least %d characters", rule.arg)
          end),
          code = "min",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "max" and #v > rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "max",
            schemaType = "string",
            rule = "max",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("String must be at most %d characters", rule.arg)
          end),
          code = "max",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "length" and #v ~= rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "length",
            schemaType = "string",
            rule = "length",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("String must be exactly %d characters", rule.arg)
          end),
          code = "length",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "pattern" and not string.match(v, rule.arg) then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "pattern",
            schemaType = "string",
            rule = "pattern",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("String must match pattern: %s", rule.arg)
          end),
          code = "pattern",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "email" then
        if not string.match(v, Z._patterns.email) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "email",
              schemaType = "string",
              rule = "email",
              path = path,
              value = v
            }, "Invalid email address"),
            code = "email",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "url" then
        if not string.match(v, Z._patterns.url) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "url",
              schemaType = "string",
              rule = "url",
              path = path,
              value = v
            }, "Invalid URL format"),
            code = "url",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "domain" then
        if not string.match(v, Z._patterns.domain) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "domain",
              schemaType = "string",
              rule = "domain",
              path = path,
              value = v
            }, "Invalid domain name"),
            code = "domain",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "ip" then
        if not string.match(v, Z._patterns.ip) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "ip",
              schemaType = "string",
              rule = "ip",
              path = path,
              value = v
            }, "Invalid IP address"),
            code = "ip",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "uuid" then
        if not string.match(v, Z._patterns.uuid) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "uuid",
              schemaType = "string",
              rule = "uuid",
              path = path,
              value = v
            }, "Invalid UUID format"),
            code = "uuid",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "datetime" then
        if not string.match(v, Z._patterns.datetime) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "datetime",
              schemaType = "string",
              rule = "datetime",
              path = path,
              value = v
            }, "Invalid datetime format"),
            code = "datetime",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "date" then
        if not string.match(v, Z._patterns.date) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "date",
              schemaType = "string",
              rule = "date",
              path = path,
              value = v
            }, "Invalid date format"),
            code = "date",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "time" then
        if not string.match(v, Z._patterns.time) then
          table.insert(errors, make_error({
            message = resolve_message(self, rule, {
              code = "time",
              schemaType = "string",
              rule = "time",
              path = path,
              value = v
            }, "Invalid time format"),
            code = "time",
            path = path,
            value = v
          }))
          return false, nil, errors
        end
      elseif rule.name == "trim" then
        v = v:match("^%s*(.-)%s*$")
      elseif rule.name == "lower" then
        v = string.lower(v)
      elseif rule.name == "upper" then
        v = string.upper(v)
      elseif rule.name == "startsWith" and string.sub(v, 1, #rule.arg) ~= rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "startsWith",
            schemaType = "string",
            rule = "startsWith",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Must start with '%s'", rule.arg)
          end),
          code = "startsWith",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "endsWith" and string.sub(v, -#rule.arg) ~= rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "endsWith",
            schemaType = "string",
            rule = "endsWith",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Must end with '%s'", rule.arg)
          end),
          code = "endsWith",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "includes" and not string.find(v, rule.arg, 1, true) then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "includes",
            schemaType = "string",
            rule = "includes",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Must contain '%s'", rule.arg)
          end),
          code = "includes",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._custom then
      local ok, msg = self._custom(v)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "string",
            path = path,
            value = v
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._transform then v = self._transform(v) end
    return true, v, errors
  elseif self._type == "number" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "number",
            path = path,
            value = value
          }, "Field is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "number" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "number",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected number, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local v = value
    for _, rule in ipairs(self._rules) do
      if rule.name == "min" and v < rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "min",
            schemaType = "number",
            rule = "min",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Number must be at least %d", rule.arg)
          end),
          code = "min",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "max" and v > rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "max",
            schemaType = "number",
            rule = "max",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Number must be at most %d", rule.arg)
          end),
          code = "max",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "positive" and v <= 0 then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "positive",
            schemaType = "number",
            rule = "positive",
            path = path,
            value = v
          }, "Number must be positive"),
          code = "positive",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "negative" and v >= 0 then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "negative",
            schemaType = "number",
            rule = "negative",
            path = path,
            value = v
          }, "Number must be negative"),
          code = "negative",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "integer" and v % 1 ~= 0 then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "integer",
            schemaType = "number",
            rule = "integer",
            path = path,
            value = v
          }, "Number must be an integer"),
          code = "integer",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "between" and (v < rule.arg[1] or v > rule.arg[2]) then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "between",
            schemaType = "number",
            rule = "between",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Number must be between %d and %d", rule.arg[1], rule.arg[2])
          end),
          code = "between",
          path = path,
          value = v
        }))
        return false, nil, errors
      elseif rule.name == "multipleOf" and v % rule.arg ~= 0 then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "multipleOf",
            schemaType = "number",
            rule = "multipleOf",
            path = path,
            value = v,
            arg = rule.arg
          }, function(ctx)
            return string.format("Number must be a multiple of %d", rule.arg)
          end),
          code = "multipleOf",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._custom then
      local ok, msg = self._custom(v)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "number",
            path = path,
            value = v
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._transform then v = self._transform(v) end
    return true, v, errors
  elseif self._type == "boolean" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "boolean",
            path = path,
            value = value
          }, "Field is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "boolean" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "boolean",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected boolean, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local v = value
    if self._custom then
      local ok, msg = self._custom(v)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "boolean",
            path = path,
            value = v
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._transform then v = self._transform(v) end
    return true, v, errors
  elseif self._type == "any" then
    if value == nil and self._default ~= nil then value = self._default end
    if self._nullable and value == nil then return true, nil end
    local v = value
    if self._custom then
      local ok, msg = self._custom(v)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "any",
            path = path,
            value = v
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = v
        }))
        return false, nil, errors
      end
    end
    if self._transform then v = self._transform(v) end
    return true, v, errors
  elseif self._type == "table" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "table",
            path = path,
            value = value
          }, "Field is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "table" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "table",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected table, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local out = {}
    for k, schema in pairs(self._shape) do
      if schema._when then
        local case = schema._when.cases[value[schema._when.field]]
        if case then
          local ok, v = case:_validate(value[k], opts, errors, {table.unpack(path or {}), k})
          if not ok then return false, nil, errors end
          out[k] = v
        else
          table.insert(errors, make_error({
            message = resolve_message(self, nil, {
              code = "when",
              schemaType = "table",
              path = path,
              value = value
            }, "Invalid case for 'when'"),
            code = "when",
            path = path,
            value = value
          }))
          return false, nil, errors
        end
      else
        local ok, v = schema:_validate(value[k], opts, errors, {table.unpack(path or {}), k})
        if not ok then return false, nil, errors end
        out[k] = v
      end
    end
    if self._mode == "strict" then
      for k in pairs(value) do
        if not self._shape[k] then
          table.insert(errors, make_error({
            message = resolve_message(self, nil, {
              code = "unknownKey",
              schemaType = "table",
              path = path,
              value = k
            }, function(ctx)
              return string.format("Unexpected field: %s", tostring(k))
            end),
            code = "unknownKey",
            path = path,
            value = k
          }))
          return false, nil, errors
        end
      end
    elseif self._mode == "strip" then

    elseif self._mode == "loose" then
      for k, v in pairs(value) do if not self._shape[k] then out[k] = v end end
    end
    if self._custom then
      local ok, msg = self._custom(out)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "table",
            path = path,
            value = out
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = out
        }))
        return false, nil, errors
      end
    end
    if self._transform then out = self._transform(out) end
    return true, out, errors
  elseif self._type == "array" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "array",
            path = path,
            value = value
          }, "Array is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "table" or not is_array(value) then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "array",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected array, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local out = {}
    for i, v in ipairs(value) do
      local ok, res = self._element:_validate(v, opts, errors, {table.unpack(path or {}), i})
      if not ok then return false, nil, errors end
      out[i] = res
    end
    for _, rule in ipairs(self._rules) do
      if rule.name == "min" and #out < rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "min",
            schemaType = "array",
            rule = "min",
            path = path,
            value = out,
            arg = rule.arg
          }, function(ctx)
            return string.format("Array must contain at least %d items", rule.arg)
          end),
          code = "min",
          path = path,
          value = out
        }))
        return false, nil, errors
      elseif rule.name == "max" and #out > rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "max",
            schemaType = "array",
            rule = "max",
            path = path,
            value = out,
            arg = rule.arg
          }, function(ctx)
            return string.format("Array must contain at most %d items", rule.arg)
          end),
          code = "max",
          path = path,
          value = out
        }))
        return false, nil, errors
      elseif rule.name == "length" and #out ~= rule.arg then
        table.insert(errors, make_error({
          message = resolve_message(self, rule, {
            code = "length",
            schemaType = "array",
            rule = "length",
            path = path,
            value = out,
            arg = rule.arg
          }, function(ctx)
            return string.format("Array must contain exactly %d items", rule.arg)
          end),
          code = "length",
          path = path,
          value = out
        }))
        return false, nil, errors
      elseif rule.name == "unique" then
        local seen = {}
        for _, v in ipairs(out) do
          if seen[v] then
            table.insert(errors, make_error({
              message = resolve_message(self, rule, {
                code = "unique",
                schemaType = "array",
                rule = "unique",
                path = path,
                value = out
              }, "Array items must be unique"),
              code = "unique",
              path = path,
              value = out
            }))
            return false, nil, errors
          end
          seen[v] = true
        end
      end
    end
    if self._custom then
      local ok, msg = self._custom(out)
      if not ok then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "custom",
            schemaType = "array",
            path = path,
            value = out
          }, msg or "Custom validation failed"),
          code = "custom",
          path = path,
          value = out
        }))
        return false, nil, errors
      end
    end
    if self._transform then out = self._transform(out) end
    return true, out, errors
  elseif self._type == "enum" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "enum",
            path = path,
            value = value
          }, "Enum value is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if not self._lookup[value] then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "invalid",
          schemaType = "enum",
          path = path,
          value = value,
          expected = self._values
        }, function(ctx)
          return string.format("Invalid enum value. Expected one of: %s", table.concat(self._values, ", "))
        end),
        code = "invalid",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  elseif self._type == "literal" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "literal",
            path = path,
            value = value
          }, "Literal value is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if value ~= self._literal then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "invalid",
          schemaType = "literal",
          path = path,
          value = value,
          expected = self._literal
        }, function(ctx)
          return string.format("Expected literal value: %s", tostring(self._literal))
        end),
        code = "invalid",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  elseif self._type == "peripheral" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "peripheral",
            path = path,
            value = value
          }, "Peripheral is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "string" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "peripheral",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected peripheral name, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    if not peripheral then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "notFound",
          schemaType = "peripheral",
          path = path,
          value = value
        }, "Peripheral API not available"),
        code = "notFound",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local p = peripheral.wrap(value)
    if not p then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "notFound",
          schemaType = "peripheral",
          path = path,
          value = value
        }, function(ctx)
          return string.format("Peripheral not found: %s", value)
        end),
        code = "notFound",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    if self._peripheralType and peripheral.getType then
      local t = peripheral.getType(value)
      if t ~= self._peripheralType then
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "wrongType",
            schemaType = "peripheral",
            path = path,
            value = value,
            expected = self._peripheralType,
            received = t
          }, function(ctx)
            return string.format("Expected %s, got %s", self._peripheralType, t or "unknown")
          end),
          code = "wrongType",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    return true, value, errors
  elseif self._type == "color" then
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "color",
            path = path,
            value = value
          }, "Color is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "number" then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "type",
          schemaType = "color",
          path = path,
          value = value,
          received = type(value)
        }, function(ctx)
          return string.format("Expected color value, got %s", type(value))
        end),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    if value < 0 or value > 0xFFFFFF then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "outOfRange",
          schemaType = "color",
          path = path,
          value = value
        }, function(ctx)
          return string.format("Color value out of range: %s", tostring(value))
        end),
        code = "outOfRange",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  elseif self._type == "side" then
    local valid_sides = {
      top = true,
      bottom = true,
      left = true,
      right = true,
      front = true,
      back = true
    }
    if value == nil then
      if self._default ~= nil then value = self._default end
      if value == nil then
        if self._optional then return true, nil end
        table.insert(errors, make_error({
          message = resolve_message(self, nil, {
            code = "required",
            schemaType = "side",
            path = path,
            value = value
          }, "Side is required"),
          code = "required",
          path = path,
          value = value
        }))
        return false, nil, errors
      end
    end
    if self._nullable and value == nil then return true, nil end
    if type(value) ~= "string" or not valid_sides[value] then
      table.insert(errors, make_error({
        message = resolve_message(self, nil, {
          code = "invalid",
          schemaType = "side",
          path = path,
          value = value
        }, function(ctx)
          return string.format("Invalid side value: %s", tostring(value))
        end),
        code = "invalid",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  end
end

function Z.number(opts)
  local self = setmetatable({
    _type = "number",
    _opts = opts or {},
    _rules = {}
  }, Schema)
  return self
end

function Schema:positive(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "positive",
    msg = opts and opts.message
  })
  return s
end

function Schema:negative(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "negative",
    msg = opts and opts.message
  })
  return s
end

function Schema:integer(opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "integer",
    msg = opts and opts.message
  })
  return s
end

function Schema:between(min, max, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "between",
    arg = {min, max},
    msg = opts and opts.message
  })
  return s
end

function Schema:multipleOf(n, opts)
  local s = self:clone()
  s._rules = shallow_copy(self._rules)
  table.insert(s._rules, {
    name = "multipleOf",
    arg = n,
    msg = opts and opts.message
  })
  return s
end

function Z.boolean(opts)
  local self = setmetatable({
    _type = "boolean",
    _opts = opts or {},
    _rules = {}
  }, Schema)
  return self
end

function Z.any(opts)
  local self = setmetatable({
    _type = "any",
    _opts = opts or {},
    _rules = {}
  }, Schema)
  return self
end

function Z.table(shape, opts)
  local self = setmetatable({
    _type = "table",
    _opts = opts or {},
    _shape = shape or {},
    _rules = {},
    _mode = "strip"
  }, Schema)
  return self
end

function Schema:strict(opts)
  local s = self:clone()
  s._mode = "strict"
  s._strictMsg = opts and opts.message
  return s
end

function Schema:loose(opts)
  local s = self:clone()
  s._mode = "loose"
  s._looseMsg = opts and opts.message
  return s
end

function Z.array(element_schema, opts)
  local self = setmetatable({
    _type = "array",
    _opts = opts or {},
    _element = element_schema,
    _rules = {}
  }, Schema)
  return self
end

function Z.enum(values, opts)
  local lookup = {}
  for _, v in ipairs(values) do lookup[v] = true end
  local self = setmetatable({
    _type = "enum",
    _opts = opts or {},
    _values = values,
    _lookup = lookup
  }, Schema)
  return self
end

function Z.literal(lit, opts)
  local self = setmetatable({
    _type = "literal",
    _opts = opts or {},
    _literal = lit
  }, Schema)
  return self
end

function Z.peripheral(type_name, opts)
  local self = setmetatable({
    _type = "peripheral",
    _opts = opts or {},
    _peripheralType = type_name
  }, Schema)
  return self
end

function Z.color(opts)
  local self = setmetatable({
    _type = "color",
    _opts = opts or {}
  }, Schema)
  return self
end

function Z.side(opts)
  local self = setmetatable({
    _type = "side",
    _opts = opts or {}
  }, Schema)
  return self
end

function Z.function_(opts)
  local self = setmetatable({
    _type = "function",
    _opts = opts or {}
  }, Schema)
  function self:_validate(value, opts, errors, path)
    if type(value) ~= "function" then
      table.insert(errors, make_error({
        message = self._opts.message or string.format("Expected function, got %s", type(value)),
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  end
  return self
end
Z["function"] = Z.function_

function Z.custom(fn, opts)
  local self = setmetatable({
    _type = "custom",
    _fn = fn,
    _opts = opts or {}
  }, Schema)
  function self:_validate(value, opts, errors, path)
    local ok, msg = self._fn(value, {
      path = path
    })
    if not ok then
      table.insert(errors, make_error({
        message = self._opts.message or msg or "Custom validation failed",
        code = "custom",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    return true, value, errors
  end
  return self
end

function Z.lazy(fn)
  local schema
  local self = setmetatable({
    _type = "lazy"
  }, Schema)
  function self:_validate(value, opts, errors, path)
    schema = schema or fn()
    return schema:_validate(value, opts, errors, path)
  end
  return self
end

function Schema:pick(fields, opts)
  local shape = {}
  for k in pairs(fields) do if self._shape and self._shape[k] then shape[k] = self._shape[k] end end
  return Z.table(shape, opts)
end

function Schema:omit(fields, opts)
  local shape = {}
  for k, v in pairs(self._shape or {}) do if not fields[k] then shape[k] = v end end
  return Z.table(shape, opts)
end

function Schema:partial(opts)
  local shape = {}
  for k, v in pairs(self._shape or {}) do shape[k] = v:optional() end
  return Z.table(shape, opts)
end

function Schema:required(opts)
  local shape = {}
  for k, v in pairs(self._shape or {}) do
    local nv = shallow_copy(v)
    nv._optional = false
    shape[k] = setmetatable(nv, getmetatable(v))
  end
  return Z.table(shape, opts)
end

function Schema:extend(fields, opts)
  local shape = shallow_copy(self._shape or {})
  for k, v in pairs(fields) do shape[k] = v end
  return Z.table(shape, opts)
end

function Z.merge(a, b, opts)
  local shape = shallow_copy(a._shape or {})
  for k, v in pairs(b._shape or {}) do shape[k] = v end
  return Z.table(shape, opts)
end

function Z.intersection(schemas, opts)
  local self = setmetatable({
    _type = "intersection",
    _schemas = schemas,
    _opts = opts or {}
  }, Schema)
  function self:_validate(value, opts, errors, path)
    local out = {}
    for _, schema in ipairs(self._schemas) do
      local ok, v = schema:_validate(value, opts, errors, path)
      if not ok then return false, nil, errors end
      if type(v) == "table" then
        for k, val in pairs(v) do out[k] = val end
      else
        out = v
      end
    end
    return true, out, errors
  end
  return self
end

function Z.discriminatedUnion(discriminator, schemas, opts)
  local self = setmetatable({
    _type = "discriminatedUnion",
    _discriminator = discriminator,
    _schemas = schemas,
    _opts = opts or {}
  }, Schema)
  function self:_validate(value, opts, errors, path)
    if type(value) ~= "table" then
      table.insert(errors, make_error({
        message = self._opts.message or "Expected table for discriminated union",
        code = "type",
        path = path,
        value = value
      }))
      return false, nil, errors
    end
    local tag = value[self._discriminator]
    for _, schema in ipairs(self._schemas) do
      if schema._shape and schema._shape[self._discriminator] and schema._shape[self._discriminator]._literal == tag then
        return schema:_validate(value, opts, errors, path)
      end
    end
    table.insert(errors, make_error({
      message = self._opts.discriminatorMessage or "Invalid discriminator value",
      code = "discriminator",
      path = path,
      value = tag
    }))
    return false, nil, errors
  end
  return self
end

function Schema:when(field, cases, opts)
  local s = self:clone()
  s._when = {
    field = field,
    cases = cases,
    opts = opts
  }
  return s
end

function Schema:parseAsync(value)
  local ok, res = self:safeParse(value)
  return {
    andThen = function(_, cb)
      if ok then cb(res) end
      return _
    end
  }
end

function Schema:customAsync(fn, opts)
  return self:custom(fn, opts)
end

function Schema:getRules()
  return self._rules or {}
end

function Z.exportSchema(schema)
  return {
    type = schema:type(),
    rules = schema:getRules(),
    isOptional = schema:isOptional(),
    isNullable = schema:isNullable()
  }
end

function Z.importSchema(def)
  local schema = Z[def.type]()
  if def.isOptional then schema = schema:optional() end
  if def.isNullable then schema = schema:nullable() end
  for _, rule in ipairs(def.rules) do schema = schema[rule.name](schema, table.unpack(rule.args or {rule.arg})) end
  return schema
end

function Z.configure(cfg)
  local newConfig = Z._config or {}
  for k, v in pairs(cfg) do newConfig[k] = v end
  Z._config = newConfig
end

function Z.debugSchema(schema, value)
  local success, result = schema:safeParse(value)
  print("Schema Debug Info:")
  print("Type:", schema:type())
  print("Is Optional:", schema:isOptional())
  print("Is Nullable:", schema:isNullable())
  if not success then
    print("\nValidation Errors:")
    for _, error in ipairs(result.errors) do
      print(string.format("- Path: %s\n  Message: %s\n  Code: %s", table.concat(error.path or {}, "."), error.message,
          error.code))
    end
  end
  return success, result
end

Z._metrics = {
  counts = {},
  times = {},
  errors = {}
}
function Z.trackValidation(schemaType, fn)
  local startTime = os.epoch and os.epoch("utc") or os.clock() * 1000
  local success, result = pcall(fn)
  local endTime = os.epoch and os.epoch("utc") or os.clock() * 1000
  Z._metrics.counts[schemaType] = (Z._metrics.counts[schemaType] or 0) + 1
  Z._metrics.times[schemaType] = (Z._metrics.times[schemaType] or 0) + (endTime - startTime)
  if not success then Z._metrics.errors[schemaType] = (Z._metrics.errors[schemaType] or 0) + 1 end
  return success, result
end

Z.EventEmitter = {
  listeners = {},
  on = function(self, event, schema, handler)
    self.listeners[event] = {
      schema = schema,
      handler = handler
    }
  end,
  emit = function(self, event, data)
    local listener = self.listeners[event]
    if listener then
      local success, result = listener.schema:safeParse(data)
      if success then
        listener.handler(result)
      else
        print("Invalid event data:", result:format())
      end
    end
  end
}

Z.StateManager = {
  schemas = {},
  state = {},
  define = function(self, key, schema)
    self.schemas[key] = schema
  end,
  setState = function(self, key, value)
    local schema = self.schemas[key]
    if schema then
      local success, result = schema:safeParse(value)
      if success then
        self.state[key] = result
        return true
      end
      return false, result:format()
    end
    return false, "No schema defined for key: " .. key
  end
}

Z.coerce = {
  string = function(opts)
    return Z.custom(function(value)
      if type(value) == "string" then return true, value end
      if value == nil then return false, "Cannot coerce nil to string" end
      return true, tostring(value)
    end, opts)
  end,
  number = function(opts)
    return Z.custom(function(value)
      if type(value) == "number" then return true, value end
      local n = tonumber(value)
      if n then return true, n end
      return false, "Could not convert to number"
    end, opts)
  end,
  boolean = function(opts)
    return Z.custom(function(value)
      if type(value) == "boolean" then return true, value end
      local truthy, falsy
      if Z._config and Z._config.coerce and Z._config.coerce.boolean then
        truthy = Z._config.coerce.boolean.truthy or {"true", "1", "yes", "y", "on", "enabled"}
        falsy = Z._config.coerce.boolean.falsy or {"false", "0", "no", "n", "off", "disabled"}
      else
        truthy = {"true", "1"}
        falsy = {"false", "0"}
      end
      if value == 1 or value == true then return true, true end
      if value == 0 or value == false then return true, false end
      if type(value) == "string" then
        for _, t in ipairs(truthy) do if value == t then return true, true end end
        for _, f in ipairs(falsy) do if value == f then return true, false end end
      end
      return false, resolve_message(nil, nil, {
        code = "boolean",
        schemaType = "coerce",
        value = value
      }, "Could not convert to boolean")
    end, opts)
  end
}

return Z
