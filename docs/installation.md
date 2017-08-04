---
title: Installation
---

Installation is terribly simple - it's a gem, after all. You can either
install it manually

```bash
gem ama-entity-mapper
```

or leave it up do Bundler:

```bash
echo "gem 'ama-entity-mapper'" >> Gemfile
bundle install
```

All what's left is to require the gem in code and start using it:

```ruby
require 'ama-entity-mapper'

# ...

value = AMA::Entity::Mapper.map(input, type)
```
