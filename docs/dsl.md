---
title: DSL In Detail
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

Attributes have following options:

- :nullable (default: true), whether that attribute may be represented
  by a `nil`
- :default (default: nil), default value for attribute
- :values (default: []), allowed ste of values for attribute
- :sensitive (default: false), forces attribute to be omitted during 
  normalization
- :virtual (default: false), forces attribute to be ignored
- :aliases (default: []), set of other names attribute may be given

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

Parameters may be resolved with singular or multiple types:

```ruby
Mapper.map(input, [CustomClass, T: [TrueClass, FalseClass, NilClass]])
```

## Handlers

Handlers are custom logic processors for described type. There are following
handler types:

- Factory, creates new instances
- Normalizer, converts class instance into low-level data structure
- Denormalizer, populates empty instance using low-level data structure
- Enumerator, enumerates attributes for specified entity
- Extractor, extracts entity attributes out of low-level type
- Injector, injects attributes in specified entity

They may be set as objects or blocks using corresponding setters:

```ruby
factory = factory_object
denormalizer_block do
  # ...
end
```

The specific interfaces of handlers are described on 
[corresponding page](handlers), the need for them is explained on [algorithm]()
page.
