local Z = require("z")

local function assert_eq(a, b, msg)
  if a ~= b then error((msg or "") .. " Expected: " .. tostring(b) .. ", got: " .. tostring(a), 2) end
end

local function assert_true(a, msg)
  assert_eq(a, true, msg)
end
local function assert_false(a, msg)
  assert_eq(a, false, msg)
end

local results = {}
local function test(name, fn)
  local ok, err = pcall(fn)
  local result
  if ok then
    result = {
      name = name,
      ok = true
    }
    print("[PASS]", name)
  else
    result = {
      name = name,
      ok = false,
      err = err
    }
    print("[FAIL]", name, "\n ", err)
  end
  table.insert(results, result)
end

-- STRING
test("Z.string basic", function()
  assert_true(Z.string():test("abc"))
  assert_false(Z.string():test(123))
end)

test("Z.string min/max/length", function()
  assert_true(Z.string():min(2):test("ab"))
  assert_false(Z.string():min(3):test("ab"))
  assert_true(Z.string():max(3):test("abc"))
  assert_false(Z.string():max(2):test("abc"))
  assert_true(Z.string():length(3):test("abc"))
  assert_false(Z.string():length(2):test("abc"))
end)

test("Z.string pattern/email", function()
  assert_true(Z.string():pattern("^%d+$"):test("123"))
  assert_false(Z.string():pattern("^%d+$"):test("abc"))
  assert_true(Z.string():email():test("a@b.com"))
  assert_false(Z.string():email():test("notanemail"))
end)

test("Z.string trim/lower/upper", function()
  assert_eq(Z.string():trim():parse("  hi  "), "hi")
  assert_eq(Z.string():lower():parse("HI"), "hi")
  assert_eq(Z.string():upper():parse("hi"), "HI")
end)

test("Z.string startsWith/endsWith/includes", function()
  assert_true(Z.string():startsWith("foo"):test("foobar"))
  assert_false(Z.string():startsWith("bar"):test("foobar"))
  assert_true(Z.string():endsWith("bar"):test("foobar"))
  assert_false(Z.string():endsWith("foo"):test("foobar"))
  assert_true(Z.string():includes("oo"):test("foobar"))
  assert_false(Z.string():includes("baz"):test("foobar"))
end)

-- NUMBER

test("Z.number basic", function()
  assert_true(Z.number():test(5))
  assert_false(Z.number():test("5"))
end)

test("Z.number min/max/between", function()
  assert_true(Z.number():min(2):test(3))
  assert_false(Z.number():min(4):test(3))
  assert_true(Z.number():max(3):test(3))
  assert_false(Z.number():max(2):test(3))
  assert_true(Z.number():between(2, 4):test(3))
  assert_false(Z.number():between(4, 5):test(3))
end)

test("Z.number positive/negative/integer/multipleOf", function()
  assert_true(Z.number():positive():test(1))
  assert_false(Z.number():positive():test(0))
  assert_true(Z.number():negative():test(-1))
  assert_false(Z.number():negative():test(1))
  assert_true(Z.number():integer():test(2))
  assert_false(Z.number():integer():test(2.5))
  assert_true(Z.number():multipleOf(2):test(4))
  assert_false(Z.number():multipleOf(2):test(5))
end)

-- BOOLEAN

test("Z.boolean basic", function()
  assert_true(Z.boolean():test(true))
  assert_true(Z.boolean():test(false))
  assert_false(Z.boolean():test(1))
end)

-- ANY

test("Z.any basic", function()
  assert_true(Z.any():test("anything"))
  assert_true(Z.any():test(123))
end)

-- TABLE

test("Z.table basic", function()
  local schema = Z.table({
    a = Z.string(),
    b = Z.number()
  })
  assert_true(schema:test({
    a = "hi",
    b = 2
  }))
  assert_false(schema:test({
    a = 2,
    b = "hi"
  }))
end)

test("Z.table strict/loose/strip", function()
  local schema = Z.table({
    a = Z.string()
  }):strict()
  assert_false(schema:test({
    a = "hi",
    b = 2
  }))
  schema = Z.table({
    a = Z.string()
  }):loose()
  assert_true(schema:test({
    a = "hi",
    b = 2
  }))
  schema = Z.table({
    a = Z.string()
  })
  assert_true(schema:test({
    a = "hi",
    b = 2
  }))
end)

test("Z.table pick/omit/partial/required/extend", function()
  local base = Z.table({
    a = Z.string(),
    b = Z.number()
  })
  assert_true(base:pick({
    a = true
  }):test({
    a = "hi"
  }))
  assert_false(base:pick({
    a = true
  }):test({
    b = 2
  }))
  assert_true(base:omit({
    b = true
  }):test({
    a = "hi"
  }))
  assert_true(base:partial():test({}))
  assert_false(base:required():test({}))
  assert_true(base:extend({
    c = Z.boolean()
  }):test({
    a = "hi",
    b = 2,
    c = true
  }))
end)

test("Z.merge/intersection", function()
  local a = Z.table({
    a = Z.string()
  })
  local b = Z.table({
    b = Z.number()
  })
  assert_true(Z.merge(a, b):test({
    a = "hi",
    b = 2
  }))
  local i = Z.intersection({a, b})
  assert_true(i:test({
    a = "hi",
    b = 2
  }))
end)

-- ARRAY

test("Z.array basic", function()
  assert_true(Z.array(Z.number()):test({1, 2, 3}))
  assert_false(Z.array(Z.number()):test({1, "a", 3}))
end)

test("Z.array min/max/length/unique", function()
  assert_true(Z.array(Z.number()):min(2):test({1, 2}))
  assert_false(Z.array(Z.number()):min(3):test({1, 2}))
  assert_true(Z.array(Z.number()):max(2):test({1, 2}))
  assert_false(Z.array(Z.number()):max(1):test({1, 2}))
  assert_true(Z.array(Z.number()):length(2):test({1, 2}))
  assert_false(Z.array(Z.number()):length(1):test({1, 2}))
  assert_true(Z.array(Z.number()):unique():test({1, 2}))
  assert_false(Z.array(Z.number()):unique():test({1, 1}))
end)

-- ENUM/LITERAL

test("Z.enum/literal", function()
  assert_true(Z.enum({"a", "b"}):test("a"))
  assert_false(Z.enum({"a", "b"}):test("c"))
  assert_true(Z.literal("foo"):test("foo"))
  assert_false(Z.literal("foo"):test("bar"))
end)

-- DISCRIMINATED UNION
test("Z.discriminatedUnion", function()
  local S = Z.discriminatedUnion("type", {Z.table({
    type = Z.literal("a"),
    value = Z.string()
  }), Z.table({
    type = Z.literal("b"),
    value = Z.number()
  })})
  assert_true(S:test({
    type = "a",
    value = "hi"
  }))
  assert_true(S:test({
    type = "b",
    value = 2
  }))
  assert_false(S:test({
    type = "c",
    value = true
  }))
end)

-- LAZY (recursive)
test("Z.lazy", function()
  local Cat
  Cat = Z.lazy(function()
    return Z.table({
      name = Z.string(),
      children = Z.array(Cat):optional()
    })
  end)
  assert_true(Cat:test({
    name = "root",
    children = {{
      name = "leaf"
    }}
  }))
end)

-- CUSTOM
test("Z.custom", function()
  local S = Z.custom(function(v)
    return v == 42, "Must be 42"
  end)
  assert_true(S:test(42))
  assert_false(S:test(41))
end)

-- COERCE
test("Z.coerce", function()
  assert_true(Z.coerce.string():test(123))
  assert_true(Z.coerce.number():test("123"))
  assert_true(Z.coerce.boolean():test("true"))
  assert_false(Z.coerce.boolean():test("nope"))
end)

-- FUNCTION
test("Z.function", function()
  assert_true(Z["function"]():test(function()
  end))
  assert_false(Z["function"]():test(123))
end)

-- CONDITIONAL (when)
test("Z.table:when", function()
  local S = Z.table({
    type = Z.enum({"user", "admin"}),
    permissions = Z.table({}):when("type", {
      user = Z.table({
        canRead = Z.boolean()
      }),
      admin = Z.table({
        canRead = Z.boolean(),
        canWrite = Z.boolean()
      })
    })
  })
  assert_true(S:test({
    type = "user",
    permissions = {
      canRead = true
    }
  }))
  assert_true(S:test({
    type = "admin",
    permissions = {
      canRead = true,
      canWrite = false
    }
  }))
  assert_false(S:test({
    type = "admin",
    permissions = {
      canRead = true
    }
  }))
end)

-- ASYNC (stub)
test("Z.parseAsync", function()
  local S = Z.string()
  local called = false
  S:parseAsync("hi"):andThen(function(res)
    called = true
  end)
  assert_true(called)
end)

-- SERIALIZATION
test("Z.exportSchema/importSchema", function()
  local S = Z.string():min(2):max(5)
  local def = Z.exportSchema(S)
  local S2 = Z.importSchema(def)
  assert_true(S2:test("abc"))
  assert_false(S2:test("a"))
end)

-- DEBUG/CONFIG/METRICS
test("Z.debugSchema", function()
  local S = Z.string():min(2)
  local ok, res = Z.debugSchema(S, "a")
  assert_false(ok)
end)

test("Z.configure", function()
  Z.configure({
    messages = {
      type = {
        string = "Custom!"
      }
    }
  })
  assert_eq(type(Z._config), "table")
end)

test("Z.trackValidation", function()
  local S = Z.string():min(2)
  local ok, _ = Z.trackValidation("string", function()
    return S:parse("abc")
  end)
  assert_true(ok)
end)

-- COMPUTERCRAFT: Peripheral, Color, Side
test("Z.peripheral", function()
  if peripheral then
    -- Only run if in ComputerCraft
    pcall(shell.run, "attach", "left", "monitor")
    assert_true(Z.peripheral():test(peripheral.getNames()[1] or "left")) -- may fail if no peripherals
  end
end)

test("Z.color", function()
  assert_true(Z.color():test(0xFFFFFF))
  assert_false(Z.color():test(-1))
end)

test("Z.side", function()
  assert_true(Z.side():test("left"))
  assert_false(Z.side():test("notaside"))
end)

test("Z.configure", function()
  Z.configure({
    messages = {
      string = {
        min = "Custom!"
      }
    }
  })
  assert_eq(type(Z._config), "table")
  assert_eq(Z._config.messages.string.min, "Custom!")
end)

print("\nAll tests completed.")

local file = fs.open("zood_test.log", "w")
for _, result in ipairs(results) do
  file.write(
      "[" .. (result.ok and "PASS" or "FAIL") .. "] " .. result.name .. (result.err and " " .. result.err or "") .. "\n")
end
file.close()

