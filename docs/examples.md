## Real-World Examples

Below are practical examples of how Zood can be used to validate and transform data in real-world scenarios.

---

### Example 1: User Registration Form

Validate a user registration form with fields for `name`, `email`, `age`, and `password`.

```lua
local Z = require("z")

local userSchema = Z.table({
  name = Z.string():min(3, { message = "Name must be at least 3 characters" }),
  email = Z.string():email({ message = "Invalid email address" }),
  age = Z.number():min(18, { message = "You must be at least 18 years old" }),
  password = Z.string():min(8, { message = "Password must be at least 8 characters" })
})

local userData = {
  name = "Alice",
  email = "alice@example.com",
  age = 25,
  password = "secure123"
}

local success, result = userSchema:safeParse(userData)

if success then
  print("User is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 2: Configuration File

Validate a configuration file with settings for `theme`, `notifications`, and `timeout`.

```lua
local Z = require("z")

local configSchema = Z.table({
  theme = Z.string():enum({"light", "dark"}, { message = "Theme must be 'light' or 'dark'" }),
  notifications = Z.boolean(),
  timeout = Z.number():min(1, { message = "Timeout must be at least 1 second" })
})

local configData = {
  theme = "dark",
  notifications = true,
  timeout = 30
}

local success, result = configSchema:safeParse(configData)

if success then
  print("Configuration is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 3: Product Inventory

Validate a product inventory with fields for `id`, `name`, `price`, and `tags`.

```lua
local Z = require("z")

local productSchema = Z.table({
  id = Z.string():length(10, { message = "ID must be exactly 10 characters" }),
  name = Z.string():min(5, { message = "Name must be at least 5 characters" }),
  price = Z.number():positive({ message = "Price must be positive" }),
  tags = Z.array(Z.string())
})

local productData = {
  id = "1234567890",
  name = "Wireless Mouse",
  price = 29.99,
  tags = {"electronics", "accessories"}
}

local success, result = productSchema:safeParse(productData)

if success then
  print("Product is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 4: API Response

Validate an API response containing a list of users.

```lua
local Z = require("z")

local userSchema = Z.table({
  id = Z.string(),
  name = Z.string(),
  email = Z.string():email()
})

local apiResponseSchema = Z.table({
  status = Z.string():enum({"success", "error"}),
  data = Z.array(userSchema)
})

local apiResponse = {
  status = "success",
  data = {
    { id = "1", name = "Alice", email = "alice@example.com" },
    { id = "2", name = "Bob", email = "bob@example.com" }
  }
}

local success, result = apiResponseSchema:safeParse(apiResponse)

if success then
  print("API response is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 5: Survey Form

Validate a survey form with fields for `name`, `age`, `interests`, and `subscribe`.

```lua
local Z = require("z")

local surveySchema = Z.table({
  name = Z.string():min(3, { message = "Name must be at least 3 characters" }),
  age = Z.number():min(18, { message = "You must be at least 18 years old" }),
  interests = Z.array(Z.string()),
  subscribe = Z.boolean()
})

local surveyData = {
  name = "Charlie",
  age = 22,
  interests = {"programming", "gaming"},
  subscribe = true
}

local success, result = surveySchema:safeParse(surveyData)

if success then
  print("Survey is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 6: Nested Configuration

Validate a nested configuration file with settings for `server`, `database`, and `logging`.

```lua
local Z = require("z")

local configSchema = Z.table({
  server = Z.table({
    host = Z.string(),
    port = Z.number():between(1, 65535, { message = "Port must be between 1 and 65535" })
  }),
  database = Z.table({
    name = Z.string(),
    user = Z.string(),
    password = Z.string()
  }),
  logging = Z.table({
    enabled = Z.boolean(),
    level = Z.string():enum({"debug", "info", "warn", "error"})
  })
})

local configData = {
  server = {
    host = "localhost",
    port = 8080
  },
  database = {
    name = "mydb",
    user = "admin",
    password = "secret"
  },
  logging = {
    enabled = true,
    level = "info"
  }
}

local success, result = configSchema:safeParse(configData)

if success then
  print("Configuration is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```

---

### Example 7: E-Commerce Order

Validate an e-commerce order with fields for `orderId`, `items`, `total`, and `shippingAddress`.

```lua
local Z = require("z")

local orderSchema = Z.table({
  orderId = Z.string():length(10, { message = "Order ID must be exactly 10 characters" }),
  items = Z.array(Z.table({
    productId = Z.string(),
    quantity = Z.number():positive({ message = "Quantity must be positive" })
  })),
  total = Z.number():positive({ message = "Total must be positive" }),
  shippingAddress = Z.string():min(10, { message = "Shipping address must be at least 10 characters" })
})

local orderData = {
  orderId = "ORDER12345",
  items = {
    { productId = "PROD1", quantity = 2 },
    { productId = "PROD2", quantity = 1 }
  },
  total = 99.99,
  shippingAddress = "123 Main St, Springfield"
}

local success, result = orderSchema:safeParse(orderData)

if success then
  print("Order is valid!")
else
  print("Validation errors:")
  for _, err in ipairs(result) do
    print(err)
  end
end
```
