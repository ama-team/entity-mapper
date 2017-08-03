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
  instance.define_singleton_method :normalize do |entity, type, context|
    data = yield(entity, type, context)
    data[:private] = nil
    data[:owner] = data[:owner][:id]
    data
  end
end
```

```ruby
normalizer_block do |entity, type, context|
  # ...
end
```

Normalizer is provided with a block that allows for fallback to default 
processing. This may be used to perform pre- or post-processing.

Default normalizer implementation simply represents all instance 
variables as hash.

## Denormalizer

Denormalizer returns entity with values from low-level structure. As
with normalizer, it is fed with a block that may be used for fallback 
processing:

```ruby
denormalizer = Object.new.tap do |instance|
  instance.define_singleton_method :denormalize do |input, type, context|
    yield(entity, input, type, context)
    entity.id ||= input[:user_id]
    entity
  end
end
```

```ruby
denormalizer_block do |input, type, context, &block|
  # ...
end
```

Default denormalizer accepts only hash and sets instance variables / calls
setter methods using it's contents.

Common usage for denomralization is input unification:

```ruby
denormalizer_block do |input, type, context, &block|
  input = {} if input.nil?
  input = { name: input } if input.is_a?(String)
  block.call(input, type, context)
end
```

## Factory

Factory is plain simple and used to create new instances:

```ruby
factory = Object.new.tap do |instance|
  instance.define_singleton_method :create do |type, input, context|
    type.type.new
  end
end
```

```ruby
factory_block do |type, input, context|
  # ...
end
```

Default factory creates entity using `Class#new` and sets default 
values for attributes with default values.

## Enumerator

Enumerator is a class that takes entity and returns standard ruby enumerator,
which emits triplets of attribute, value, and segment. It allows mapper to
delegate attribute location and allows resolution of complex cases with virtual
types. It is used to inspect entity contents:

```ruby
type.enumerator(entity).each do |attribute, value, segment|
  local_ctx = context.advance(segment)
  puts "#{local_ctx.path} value: #{value}" 
end
```

Setting examples:

```ruby
enumerator = Object.new.tap do |instance|
  instance.define_singleton_method :enumerate do |entity, type, context = nil|
    ::Enumerator.new do |y|
      type.attributes.each do |attribute|
        segment = ::AMA::Entity::Mapper::Path::Segment.attribute(attribute.name)
        y << [attribute, entity.send(attribute.name), segment]
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
  instance.define_singleton_method :inject do |entity, type, attribute, value|
    entity.send("#{attribute.name}=", value)
  end
end
```

```ruby
injector_block do |entity, type, attribute, value, context|
  # ...
end
```

The argument list is quite huge, but it is still easier that way than dealing
with intermediate object.

## Attribute validator

Allows to validate attribute correctness, returns list of 
violations as strings:

```ruby
validator = Object.new.tap do |instance|
  instance.define_singleton_method :validate do |value, attribute, context|
    return [] if attribute.values.include?(value)
    ["Values #{attribute.values} don't contain #{value}"]
  end
end
```

```ruby
validator_block do |value, attribute, context|
  # ...
end
```

## Entity validator

The very same thing for entities (usually there is no need in that).

```ruby
validator = Object.new.tap do |instance|
  instance.define_singleton_method :validate do |entity, type, context|
    if entity.policy == :read and entity.roles.include?(:admin)
      return ['Something\'s misty here!']
    end
    []
  end
end
```

```ruby
validator_block do |value, attribute, context|
  # ...
end

