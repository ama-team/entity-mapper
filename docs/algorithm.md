---
title: Algorithm
---

To start with something, let's explain type system. Every concrete type 
consists of enclosed class and set of attributes. Every attribute, in 
turn, has it's own type, name, and set of settings. Most of the time 
attributes represent the very same concept as the ones defined by 
`attr_accessor`, however, there is also a concept of virtual attributes - 
they are created as a holder for attached type, and this serves for 
non-trivial cases (say, all container types, such as collections). Type 
classes, among other things, include entity factory, normalizer, 
denormalizer, attribute enumerator, attribute extractor and attribute 
injector (those will be discussed in a moment).

When mapper is asked to map input `I` into types `T1...Tn`, it uses 
following algorithm:

- If `I` is not a `T`, then normalize `I` as `I1`, create instance 
`E1`, and denormalize `I1` into `E1`, otherwise assign `I` to `E1`
- Enumerate all attributes of `E1`. Recursively start scenario from
the start for every attribute, validate result, and accumulate results
- If none of attributes have changed, just return `E1`
- If there is at least one changed attribute, create instance `E2` and
set all attributes on it.
- If something went wrong or is impossible, throw mapping error
- If there are more target types specified, catch exception and try
next type

It is important to understand that mapper works only at one level at a
time - denormalization never tries to denormalize entity and it's 
attributes, it's just creates new entity and assigns attribute without
paying attention to attribute contents. It just goes level after level,
reaching the bottom and then rebuilding target entity level by level,
starting with leaves and going closer to root.

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
