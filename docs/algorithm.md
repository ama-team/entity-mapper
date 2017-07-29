---
title: Algorithm
---

To start with something, let's explain type system. Every concrete type 
consists of enclosed class and set of attributes. Every attribute, in 
turn, has it's own type, name, and set of settings. Most of the time 
attributes represent the very same concept as the ones defined by 
`attr_accessor`, however, there is also a concept of virtual attributes - 
they are created as a holder for attached type, and this serves for 
non-trivial cases (say, all collections). Type classes, among other 
things, include entity factory, normalizer, denormalizer, attribute
enumerator, attribute extractor and attribute acceptor (those will be 
discussed in a moment).

When mapper is asked to map input `I` into types `T1...Tn`, it uses 
following algorithm:

- If `I` satisfies `T`, return `I` as is
- Normalize I, then create instance E1 and denormalize 
intermediate value into it
- If E1 satisfies T, return it
- Create dummy entity E2, enumerate all attributes on E1, and for every
attribute apply the same procedure and set it on E2
- If E2 satisfies T, return it
- Throw mapping exception because there are no options left
- If there are more target types specified, catch exception and try
next type

*E satisfies T* actually means that E is nil or E responds true for 
`.is_a?` call, and every enumerated attribute of E satisfies it's type.
Normalization is a process of breaking entity down to primitive values,
while denormalization is the opposite. So, in a nutshell, mapper tries to 
coerce types to intermediate structure consisting only of primitives, to
create target type from it - this is much simpler than trying to do direct
conversions. Every operation specified above is applied only to currently
processed entity, so long chain like "Array of Hashes of Integers" would
be mapped to "Set of Hashes of Integers" in a single operation, without
even reaching any hash.

Because some of those operations may get tricky (treating every class as a 
bag of instance variables is bad idea, because Set would be normalized as
two-level hash instead of array), they are not made by mapper directly, but
rather by type helpers mentioned above:

- Factory allows new entity creation
- Normalizer and denormalizer speak for themselves
- Enumerator enumerates attributes of passed entity
- Extractor extracts attributes out of normalized object
- Acceptor takes created entity on creation and accepts attribute values,
setting them on passed entity

*Those are described in detail on [handlers]() page.*

This allows mapper to never know real classes structure, delegating all
weird work onto specific types. The concrete type class provides reasonable 
defaults for helpers that won't be changed in most cases, however, as 
specified above, collections need some special treatment, which is easily
targeted by such scheme. Default types (Hash, Enumerable, Set) are already
bundled in.

Whenever mapper receives a request for mapping, it analyzes which type it
has got, and uses proper algorithm for it. Primitives are mostly just passed
through, if class is not registered as entity, defaults are used, otherwise
it's definition is fetched from registry.

One more thing to explain is parametrized types and Any type. In many cases
you may not know concrete type until the moment you need to map structure -
for example, you can't hardcode type of array contents. To deal with cases 
like this, you may define parametrized type:

```ruby
class Container
  attribute(:value, parameter(:T))
end
```

This means that container will contain some other type, which is not yet
known. However, mapping requires every type to be concrete, so you need
to resolve that parameter before mapping:

```ruby
AMA::Entity::Mapper.map(input, [Container, T: Integer])
```

By default, if some parameter is not resolved before mapping, it is 
auto-resolved with Any type (see below). You may force Mapper to raise 
error in such case by turning strict mode on:

```ruby
# results in AMA::Entity::Mapper::Exception::ComplianceError
AMA::Entity::Mapper.map(input, Container, strict: true)
```

Finally, `AMA::Entity::Mapper::Type::Any::INSTANCE` may be used to 
define a wildcard type - it would match anything, so you can prevent
specific branches from processing:

```ruby
type = [Container, T: AMA::Entity::Mapper::Type::Any::INSTANCE]
integer = AMA::Entity::Mapper.map({ value: 1 }, type)
symbol = AMA::Entity::Mapper.map({ value: :symbol }, type)
```