---
title: Handlers
---

Handlers are specific logic processors that allow to customize entity 
processing. 

Some common rules apply for all processors: they can be set as block or object
(latter may help in avoiding block hell), they have always accept type instance
(because it's parameters may be resolved to something not yet known at the 
moment of processor definition) and they are wrapped in safety 
wrappers, so invalid signature will be reported, and errors would be wrapped
in description errors with paths where that thing has happened.

## Normalizer

Normalizer is a processor that takes entity and emits low-level representation
of that entity - Hash, Array, String, or something like that. Normalizer can
be set as standalone object or simple block with same signature:

```ruby
normalizer = Object.new.tap do |instance|
  instance.define_singleton_method :normalize do |entity, type, context = nil|
    data = yield(entity, type, context)
    data[:private] = nil
    data[:owner] = data[:owner][:id]
    data
  end
end
```

```ruby
normalizer_block do |entity, type, context = nil|
  # ...
end
```

Normalizer is provided with a block that allows for fallback to default 
processing. This may be used to perform pre- or post-processing.

Default normalizer implementation simply represents all instance variables as
hash.

## Denormalizer

Denormalizer fills blank entity with values from low-level structure. As
with normalizer, it is fed with a block that may be used for fallback 
processing:

```ruby
denormalizer = Object.new.tap do |instance|
  instance.define_singleton_method :denormalize do |entity, input, type, context = nil|
    yield(entity, input, type, context)
    entity.id ||= input[:user_id]
    entity
  end
end
```

```ruby
denormalizer_block do |entity, input, type, context = nil|
  # ...
end
```

Default denormalizer accepts only hash and sets instance variables / calls
setter methods using it's contents.

## Factory

Factory is plain simple and used to create new instances:

```ruby
factory = Object.new.tap do |instance|
  instance.define_singleton_method :create do |type, input = nil, context = nil|
    type.type.new
  end
end
```

```ruby
factory_block do |type, input = nil, context = nil|
  # ...
end
```

## Enumerator

Enumerator is a class that takes entity and returns standard ruby enumerator,
which emits triplets of attribute, value, and context. It allows mapper to
delegate attribute location and allows resolution of complex cases with virtual
types. It is used to inspect entity contents:

```ruby
type.enumerator(entity).each do |attribute, value, context = nil|
  raise context.path.to_s unless attribute.satisfied_by?(value)
end
```

Setting examples:

```ruby
enumerator = Object.new.tap do |instance|
  instance.define_singleton_method :enumerate do |entity, type, context = nil|
    ::Enumerator.new do |y|
      type.attributes.each do |attribute|
        segment = ::AMA::Entity::Mapper::Path::Segment.attribute(attribute.name)
        next_context = context ? context.advance(segment) : nil
        y << [attribute, entity.send(attribute.name), next_context]
      end
    end
  end
end
```

```ruby
enumerator_block do |entity, type, context = nil|
  # ...
end
```

## Injector

Injector is enumerator counterpart: it takes in entity and attribute and sets 
the latter on the former

```ruby
injector = Object.new.tap do |instance|
  instance.define_singleton_method :inject do |entity, type, attribute, value, context = nil|
    entity.send("#{attribute.name}=", value)
  end
end
```

```ruby
injector_block do |entity, type, attribute, value, context = nil|
  # ...
end
```

The argument list is quite huge, but it is still easier that way than dealing
with intermediate object
