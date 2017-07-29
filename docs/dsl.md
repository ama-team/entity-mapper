---
title: DSL in detail
---

To add mapper support in your classes, you need to include DSL module:

```ruby
class User
  include AMA::Entity::Mapper::DSL
end
```

After that you can specify attributes, parameters and handlers via added
methods. Also, `#bound_type()` class method will be defined that will return
current class mapping.

## Attributes

Attributes are specified via 
`#attribute(name:Symbol, *types:Class|module|Type, **options)` method:

```ruby
attribute :password, String, sensitive: true
```

You can specify arbitrary amount of types in case attribute may be one of
several classes:

```ruby
attribute :disabled, TrueClass, FalseClass
```

Attribute options, at the moment of writing, are `sensitive` and `virtual`.
Sensitive attributes are included when mapped to specified type, but excluded
when mapped from specified type. That allows to read you some private content
but be sure that is never persisted. Virtual attribute is completely excluded
from direct processing and intended to be used as type holder for custom 
handlers.

Attribute declaration creates corresponding getter and setter.

## Parameters

Parameters are defined by simple `#parameter(id:Symbol)` method. They are used
to specify attribute type that is not yet known:

```ruby
attribute :value, parameter(:T)
```

After that parameter can be configured during type specification:

```ruby
Mapper.map(input, [CustomClass, T: Integer])
```

At the moment of writing, parameter could be resolved only to single type. This
is a known issue that should be fixed in later releases.

## Handlers

Handlers are custom logic processors for described type. There are following
handler types:

- Factory, creates new instances
- Normalizer, converts class instance into low-level data structure
- Denormalizer, populates empty instance using low-level data structure
- Enumerator, enumerates attributes for specified entity
- Extractor, extracts entity attributes out of low-level type
- Acceptor, accepts and sets attributes for specified entity

They may be set as objects or blocks using corresponding setters:

```ruby
factory = ->(*) { target_class.new }
normalizer = normalizer_factory
denormalizer = lambda do
  # ...
end
enumerator = lambda do
  # ...
end
extractor = lambda do
  # ...
end
acceptor = lambda do
  # ...
end
```

The specific interfaces of handlers are described on 
[corresponding page](handlers), the need for them is explained on [algorithm]()
page.
