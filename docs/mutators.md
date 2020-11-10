# Included Mutators

Muzak includes only three mutators - `Constants.Numbers`, `Constants.Strings` and
`Functions.Rename`. While this is indeed rather limited, it should give some examples of the
benefits of mutation testing.

## `Constants.Numbers`

Mutates any `Integer` or `Float` literals.

#### Original File
```
def do_math(num), do: num + 2 - 0.38
```

#### Generated mutations
```
def do_math(num), do: num + 327_237_729 - 0.38
```

```
def do_math(num), do: num + 2 - 392_763.216_279
```

## `Constants.Strings`

Mutates any string literals.

#### Original File
```
def append(str), do: str <> " added on " <> " a string."
```

#### Generated mutations
```
def append(str), do: str <> "random_string" <> " a string."
```

```
def append(str), do: str <> " added on " <> "random_string"
```

## `Functions.Rename`

Renames any function or macro definition.

#### Original File
```
def add_one(int), do: do_add_one(int)

defp do_add_one(int), do: int + 1
```

#### Generated mutations
```
def random_function_name(int), do: do_add_one(int)

defp do_add_one(int), do: int + 1
```

```
def add_one(int), do: do_add_one(int)

defp random_function_name(int), do: int + 1
```
