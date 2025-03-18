# API Reference

## BaseSchema

### `BaseSchema.new(type, fields, optional, default, validate, transform, error)`

Creates a new schema instance.

- **type**: The type of the schema (e.g., "string", "number").
- **fields**: A table of fields that the schema will have.
- **optional**: If the schema is optional.
- **default**: The default value of the schema.
- **validate**: A function that validates the schema.
- **transform**: A function that transforms the schema.
- **error**: The error message that will be thrown if the schema is invalid.

### `BaseSchema:parse(data)`

Parses data and throws an error if invalid.

- **data**: The data to parse.
- **returns**: The parsed data.

### `BaseSchema:safeParse(data)`

Parses data without throwing an error.

- **data**: The data to parse.
- **returns**: A boolean indicating success, and a table of errors if unsuccessful.

### `BaseSchema:nullable()`

Marks the schema as optional.

- **returns**: The schema instance for chaining.

### `BaseSchema:default(value)`

Sets a default value for the schema.

- **value**: The default value.
- **returns**: The schema instance for chaining.

### `BaseSchema:validate(func)`

Sets a custom validation function.

- **func**: The validation function.
- **returns**: The schema instance for chaining.

### `BaseSchema:error(message)`

Sets a custom error message.

- **message**: The error message.
- **returns**: The schema instance for chaining.

## Primitive Schemas

### `Z.string(props)`

Creates a string schema.

- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

### `Z.number(props)`

Creates a number schema.

- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

### `Z.boolean(props)`

Creates a boolean schema.

- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

## Compound Schemas

### `Z.table(fields, props)`

Creates a table schema.

- **fields**: A table of fields for the schema.
- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

### `Z.array(elementSchema, props)`

Creates an array schema.

- **elementSchema**: The schema for the array elements.
- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

## Complex Schemas

### `Z.union(schemas, props)`

Creates a union schema.

- **schemas**: A table of schemas to union.
- **props**: Additional properties for the schema.
- **returns**: The schema instance for chaining.

## Helper Functions

Zood provides a variety of helper functions to add constraints and transformations to your schemas. These functions can be chained together to create complex validation rules.

All helper functions return the schema instance for chaining. Here are some examples of how to use them:

```lua
-- A string that is trimmed, lowercase, between 5 and 20 characters, with a default value of "hello"
local schema = Z.string():trim():lower():min(5):max(20):default("hello")
```

All helper functions take an optional `props` argument, which can be used to specify custom error messages. For example:

```lua
-- A custom error message
local schema = Z.string():min(5, { message = "String must be at least 5 characters long" })
-- %s will be replaced with the actual value
local schema = Z.string():min(5, { message = "String must be at least 5 characters long, recieved %s." })
-- A function that returns the error message
local schema = Z.string():min(5, { message = function(value) return "String must be at least 5 characters long, recieved " .. value end })
```

---

### `:min(value, props)`

Sets a minimum value or length for the schema.

- **`value`**: The minimum value (for numbers) or length (for strings/arrays).
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.number():min(10) -- Number must be at least 10
local schema = Z.string():min(5)  -- String must be at least 5 characters long
```

---

### `:max(value, props)`

Sets a maximum value or length for the schema.

- **`value`**: The maximum value (for numbers) or length (for strings/arrays).
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.number():max(100) -- Number must be at most 100
local schema = Z.string():max(20)  -- String must be at most 20 characters long
```

---

### `:length(value, props)`

Sets an exact length for the schema.

- **`value`**: The exact length (for strings/arrays).
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():length(10) -- String must be exactly 10 characters long
```

---

### `:email(props)`

Validates that a string is a valid email address.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():email() -- Must be a valid email address
```

---

### `:url(props)`

Validates that a string is a valid URL.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():url() -- Must be a valid URL
```

---

### `:pattern(pattern, props)`

Validates that a string matches a regex pattern.

- **`pattern`**: The regex pattern to match.
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():pattern("^[A-Z]+$") -- String must contain only uppercase letters
```

---

### `:positive(props)`

Validates that a number is positive.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.number():positive() -- Number must be greater than 0
```

---

### `:negative(props)`

Validates that a number is negative.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.number():negative() -- Number must be less than 0
```

---

### `:between(min, max, props)`

Validates that a number or string length is between two values.

- **`min`**: The minimum value or length.
- **`max`**: The maximum value or length.
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.number():between(10, 100) -- Number must be between 10 and 100
local schema = Z.string():between(5, 20)  -- String length must be between 5 and 20
```

---

### `:trim(props)`

Trims whitespace from a string.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():trim() -- Trims leading and trailing whitespace
```

---

### `:lower(props)`

Converts a string to lowercase.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():lower() -- Converts string to lowercase
```

---

### `:upper(props)`

Converts a string to uppercase.

- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():upper() -- Converts string to uppercase
```

---

### `:enum(values, props)`

Validates that a value is one of the specified values.

- **`values`**: A table of allowed values.
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():enum({"red", "green", "blue"}) -- Value must be "red", "green", or "blue"
```

---

### `:custom(func, props)`

Adds a custom validation function to the schema.

- **`func`**: The custom validation function. It should return `true` if the data is valid, or `false` and an error message if invalid.
- **`props`**: Optional properties, such as a custom error message.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():custom(function(data)
  return data == "secret", "Value must be 'secret'"
end)
```

---

### `:nullable()`

Marks the schema as optional. If the data is `nil`, it will be considered valid.

- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():nullable() -- String is optional
```

---

### `:default(value)`

Sets a default value for the schema. If the data is `nil`, the default value will be used.

- **`value`**: The default value.
- **Returns**: The schema instance for chaining.

**Example**:

```lua
local schema = Z.string():default("unknown") -- Default value is "unknown"
```

## Extra Functions

### `Z.toTable(schema)`

Converts a schema to a table.

- **schema**: The schema to convert.
- **returns**: A table representation of the schema.

### `Z.toJSON(schema)`

Converts a schema to a JSON string.

- **schema**: The schema to convert.
- **returns**: A JSON string representation of the schema.

### `Z.toFile(schema, name, type)`

Writes a schema to a file.

- **schema**: The schema to write.
- **name**: The name of the file.
- **type**: The file type ("json" or "lua").
