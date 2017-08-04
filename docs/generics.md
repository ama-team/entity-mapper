---
title: Parametrized Types (Generics)
---

Amongst other types, there is separate kind of *container* types, with
the most recognizable examples of Enumerable, Array and Hash. It is not
clear how to define types, because one scenario requires Hash values
to be symbol, another one requires them to be integers. To handle this,
concept of parametrized types (or generics), widely known in statically
typed languages, is introduced.

Type may define one or more parameters during it's definition using 
`.parameter()` call. Parameters can be used to substitute types, 
consider following example:


```yml
# input:
pagination:
  number: 3
  total: 271
content:
  - item #1
  - item #2
  - ...
```

```ruby
class Pagination
  attribute :number, Integer
  attribute :total, Integer
end

class Page
  attribute :pagination, Pagination
  attribute :content, [Enumerable, T: parameter(:E)]
end
```

What has happened there? Page `:content` attribute has been declared
with type Enumerable, and it's parameter `T` had been substituted with
Page parameter `E`. To finalize this up, resolve page parameters in 
mapping definition:

```ruby
AMA::Entity::Mapper.map(input, [Page, E: Person])
```

In fact, parameters are resolved with type collections rather than
singular types, so this is perfectly valid (and, in fact, the only way
to allow nils in array):

```ruby
AMA::Entity::Mapper.map(input, [Enumerable, T: [Float, Integer, NilClass]])
```
