# Draft warning

This is work-in-progress project, nothing has been finished yet.

# AMA::Entity::Mapper

[![Gem](https://img.shields.io/gem/v/ama-entity-mapper.svg?style=flat-square)](https://rubygems.org/gems/ama-entity-mapper)
[![CircleCI](https://img.shields.io/circleci/project/github/ama-team/entity-mapper/master.svg?style=flat-square)](https://circleci.com/gh/ama-team/entity-mapper/tree/master)
[![Coveralls](https://img.shields.io/coveralls/ama-team/entity-mapper/master.svg?style=flat-square)](https://coveralls.io/github/ama-team/entity-mapper?branch=master)
[![Code Climate](https://img.shields.io/codeclimate/github/ama-team/entity-mapper.svg?style=flat-square)](https://codeclimate.com/github/ama-team/entity-mapper)
[![Scrutinizer](https://img.shields.io/scrutinizer/g/ama-team/entity-mapper/master.svg?style=flat-square)](https://scrutinizer-ci.com/g/ama-team/entity-mapper?branch=master)

This project contains an entity mapper - an API for native data 
structure to custom class and vice versa conversion. You may find it
useful in:

- Deserializing complex structures
- Converting structures to objects that don't have one-to-one relation
- Storing information in parent entity (use hash keys to populate 
objects)
- Deserializing objects that may have different representation

You may find yourself in such a situation when storing data in Chef 
node attributes, building API clients or storing data in database.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ama-entity-mapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ama-entity-mapper

## Usage

Mapper offers simple functionality out-of-the box. You can easily 
restore simple class (provided it has no-args constructor) from hash:

```ruby
require 'ama-entity-mapper'

class User
  attr_accessor :first_name
  attr_accessor :last_name
  attr_accessor :login
end

data = { first_name: 'John', last_name: 'Doe', login: 'john-doe' }

user = AMA::Entity::Mapper.map(data, User)
```

Conversion easily goes the other way as well:

```ruby
data = AMA::Entity::Mapper.map(user, Hash)
```

First bit of magic is seen while working with nested structures. 
Imagine that API responds with hash of lists, oh my:

```yml
winners:
  - first_name: Max
    last_name: Payne
    login: mp
losers:
  - first_name: Nicole
    last_name: Horne
    login: nhorne
```

With mapper, you don't need to iterate this stuff yourself:

```ruby
types = AMA::Entity::Mapper.types
type = types.generic(Hash, Symbol, types.generic(Array, User))
# still hash of arrays, but with users now
data = AMA::Entity::Mapper.map(input, type)
```

Because of `Symbol` specified above, all hash keys would be converted
to symbols.

Further magic is available if one is brave enough to mess from inside
operated classes:

```ruby
class Page
  include AMA::Entity::Mapper::MapperAware
  
  attribute :number, Integer
  attribute :last, [TrueClass, FalseClass]
  attribute :content, types.generic(Array, types.parameter(:T))
end

class User
  include AMA::Entity::Mapper::MapperAware
  
  attribute :login, Symbol, aliases: %i[id user]
  attribute :policy, Symbol, values: %i[read write execute]
  attribute :keys, types.generic(Hash, Symbol, PrivateKey), default: {}
  attribute :last_login, DateTime, nullable: true
end

class PrivateKey
  include AMA::Entity::Mapper::MapperAware
  
  attribute :id, Symbol
  attribute :content, String, sensitive: true
end

data = {
  number: 1,
  last: false,
  content: [
    ron: {
      id: 'ron',
      policy: 'read',
      keys: {
        id_rsa: {
          id: 'id_rsa',
          content: '----BEGIN PRIVATE KEY....'
        }
      }
    }
  ]
}

page = AMA::Entity::Mapper.map(data, types.parameterized(Page, {T: User}))
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, 
and then run `bundle exec rake release`, which will create a git tag for 
the version, push git commits and tags, and push the `.gem` file 
to [rubygems.org](https://rubygems.org).

Dev branch state:

[![CircleCI](https://img.shields.io/circleci/project/github/ama-team/entity-mapper/dev.svg?style=flat-square)](https://circleci.com/gh/ama-team/entity-mapper/tree/dev)
[![Coveralls](https://img.shields.io/coveralls/ama-team/entity-mapper/dev.svg?style=flat-square)](https://coveralls.io/github/ama-team/entity-mapper?branch=dev)
[![Scrutinizer](https://img.shields.io/scrutinizer/g/ama-team/entity-mapper/dev.svg?style=flat-square)](https://scrutinizer-ci.com/g/ama-team/entity-mapper?branch=dev)

## Contributing

Bug reports and pull requests are welcome on GitHub at 
[https://github.com/ama-team/entity-mapper]().

## License

The gem is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
