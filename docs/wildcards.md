---
title: Wildcards (Any Type)
---

Sometimes it is necessary not to do processing at all. to do so, use
`Any` type:

```ruby
wildcard = AMA::Entity::Mapper::Type::Any::INSTANCE
type = [Enumerable, T: [Float, Integer, wildcard, NilClass]]

AMA::Entity::Mapper.map(input, type)
```

Please note that `Any` doesn't match nils. If you need to match nils, 
just add `NilClass` to type collection.
