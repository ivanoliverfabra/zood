# Welcome to Zood

Zood is a Lua library for **ComputerCraft** that provides a powerful and flexible way to validate and transform data structures. Inspired by **Zod** for TypeScript, Zood brings type safety and schema validation to Lua, making it easier to handle complex data in your ComputerCraft programs.

---

## Features

- **Type Validation**: Ensure data matches expected types (e.g., strings, numbers, tables).
- **Custom Validators**: Add custom validation logic to suit your needs.
- **Data Transformation**: Transform data as it is validated (e.g., trim strings, convert case).
- **Error Handling**: Detailed error messages for debugging and validation failures.
- **Schema Composition**: Combine schemas to create complex validation rules.

---

## Installation

To use Zood in your ComputerCraft programs, download the `z.lua` file and include it in your project:

```lua
wget https://raw.githubusercontent.com/ivanoliverfabra/zood/main/lib/minified.lua
```

---

## Quick Start

Here’s a quick example of how to use Zood to validate a table:

```lua
local z = require("z")

-- Define a schema
local schema = z.table({
  name = z.string(),
  age = z.number():positive(),
  email = z.string():email()
})

-- Data to validate
local data = {
  name = "Alice",
  age = 30,
  email = "alice@example.com"
}

-- Validate the data
local success, result = schema:safeParse(data)

if success then
  print("Data is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

## Why Use Zood?

- **Type Safety**: Ensure your data adheres to expected formats and structures.
- **Readable Code**: Define schemas in a clean and declarative way.
- **Error Handling**: Get detailed error messages when validation fails.
- **Extensibility**: Add custom validators and transformations to fit your use case.

---

## Documentation

- [Getting Started](getting-started.md): Learn how to install and use Zood.
- [API Reference](api-reference.md): Explore the full API and available methods.
- [Examples](examples.md): See practical examples of Zood in action.

---

## Contributing

Contributions are welcome! If you’d like to contribute to Zood, please read our [Contributing Guide](CONTRIBUTING.md).

---

## License

Zood is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.
