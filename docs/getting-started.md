# Getting Started with Zood

This guide will walk you through the process of installing Zood and using it in your ComputerCraft programs. By the end of this guide, you’ll be able to define schemas, validate data, and handle errors with Zood.

---

## Installation

### Step 1: Download Zood

Download the `z.lua` file from the [Zood GitHub repository](https://github.com/yourusername/zood) and place it in your ComputerCraft program's directory.

### Step 2: Include Zood in Your Program

To use Zood in your program, load it using `os.loadAPI`:

```lua
os.loadAPI("z.lua")
```

This will make the Zood library available in your program under the `Z` namespace.

---

## Basic Usage

### Step 1: Define a Schema

A schema defines the structure and constraints of your data. Here’s an example of a schema for a user profile:

```lua
local Z = require("z")

local userSchema = z.table({
  name = z.string(),
  age = z.number():positive(),
  email = z.string():email()
})
```

This schema ensures that:

- `name` is a string.
- `age` is a positive number.
- `email` is a valid email address.

### Step 2: Validate Data

Once you’ve defined a schema, you can use it to validate data. Here’s an example:

```lua
local data = {
  name = "Alice",
  age = 30,
  email = "alice@example.com"
}

local success, result = userSchema:safeParse(data)

if success then
  print("Data is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

If the data is valid, `success` will be `true`, and `result` will contain the validated data. If the data is invalid, `success` will be `false`, and `result` will contain a list of error messages.

---

## Advanced Usage

### Custom Validators

You can add custom validation logic to your schemas. For example, let’s ensure that a string contains only uppercase letters:

```lua
local Z = require("z")

local uppercaseSchema = z.string():custom(function(data)
  return data == string.upper(data), "Value must be uppercase"
end)

local data = "HELLO"
local success, result = uppercaseSchema:safeParse(data)

if success then
  print("Data is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

### Data Transformation

Zood allows you to transform data as it is validated. For example, you can trim whitespace from a string:

```lua
local Z = require("z")

local trimmedSchema = z.string():trim()

local data = "  Hello, World!  "
local success, result = trimmedSchema:safeParse(data)

if success then
  print("Transformed data:", result) -- Output: "Hello, World!"
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

## Next Steps

- Explore the [API Reference](api-reference.md) to learn about all the available methods and features.
- Check out the [Examples](examples.md) for more practical use cases of Zood.

---

## Troubleshooting

If you encounter any issues while using Zood, please [open an issue](https://github.com/yourusername/zood/issues) on GitHub. We’ll be happy to help!
