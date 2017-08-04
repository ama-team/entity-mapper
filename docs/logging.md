---
title: Logging
---

Mapper can have complex scenarios running under the hood, and sometimes
it is necessary to dive into them to find that your nested type is 
specified incorrectly or somewhere nil is possible, but attribute is 
not set as `nullable`. Mapper logs as much as it can under logger 
provided in context. By default, it is just standard `logger` instance 
that thrashes it's input instantly, but you can easily substitute that
by specifying logger as a keyword parameter:

```ruby
AMA::Entity::Mapper.map(input, type, logger: logger)
AMA::Entity::Mapper.normalize(entity, logger: logger)
```

Logger is available through `context.logger` in custom handlers.
