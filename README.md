# Draft warning

This is work-in-progress project, nothing has been finished yet.

# AMA::Entity::Mapper

[![Gem][shields.gem]][gem]
[![CircleCI][shields.circleci.master]][circleci.master]
[![Coveralls][shields.coveralls.master]][coveralls.master]
[![Code Climate][shields.codeclimate]][codeclimate]
[![Scrutinizer][shields.scrutinizer.master]][scrutinizer.master]

This project contains an entity mapper - an API for native data 
structure to custom class and vice versa conversion. You may find it
useful in:

- Deserializing complex structures
- Converting structures to objects that don't have one-to-one relation
- Retrieving entity information from it's path (e.g. inferring parent hash
keys as entity attribute)
- Deserializing objects that may have different representation (e.g. from 
hash or string)

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

Mapper is created to map data from one type to another. There are no hard 
bounds in this, conversion may be done with any types as long as rough corners
are handled by corresponding handlers (more on that later). 
Let's start with easy object to hash and vice versa conversion:

```ruby
require 'ama-entity-mapper'

class User
  attr_accessor :first_name
  attr_accessor :last_name
  attr_accessor :login
end

data = { first_name: 'John', last_name: 'Doe', login: 'john-doe' }

user = AMA::Entity::Mapper.map(data, User)

restored_data = AMA::Entity::Mapper.map(user, Hash)
```

This is, of course, terribly simple; the real power shows up in nested
structure processing. Imagine an API that responds with hash of lists:

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

End developer would like to receive all keys as symbols, and denormalize User
objects. To do so, you should specify target type parameters:

```ruby
# still hash of arrays, but with users now
data = AMA::Entity::Mapper.map(input, [Hash, K: Symbol, V: [Array, T: User]])
```

Basically it means 'map input data to hash with symbol keys and values as 
arrays of User instances'. K, V and T are predefined type parameters, and
Array and Hash mappings were added automatically.

The next desired action would be to map some input structure into nested
custom classes. This is possible with custom mappings, with easiest way to 
specify them via custom DSL:

```ruby
class Page
  include AMA::Entity::Mapper::DSL
  
  attribute :number, Integer
  attribute :last, TrueClass, FalseClass
  # Substituting array's parameter T with page class parameter E,
  # so content is not Array<Array.T>, but Array<Page.E>
  attribute :content, [Array, T: parameter(:E)]
end

class User
  include AMA::Entity::Mapper::DSL
  
  attribute :login, Symbol
  attribute :policy, Symbol
  attribute :keys, [Hash, K: Symbol, V: PrivateKey], default: {}
  attribute :last_login, DateTime
end

class PrivateKey
  include AMA::Entity::Mapper::DSL
  
  attribute :id, Symbol
  # sensitive attributes may be restored from incoming data, but are ignored
  # when mapped into another type
  attribute :content, String, sensitive: true
end

data = {
  number: 1,
  last: false,
  content: [
    ron: {
      id: 'charlie-the-unicorn',
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

page = AMA::Entity::Mapper.map(data, [Page, E: User])
```

Last thing to say is that attributes, in fact, may have several possible types,
and `#map` method accepts several types as well:

```ruby
result = AMA::Entity::Mapper.map(data, TrueClass, FalseClass)
```

This would try to map data to TrueClass, and, if it fails - to FalseClass.

That's the crash course, most probably you've already got what you need.
If that's not enough, full documentation is available at 
[GitHub Pages][doc].

## Development

After checking out the repo, run `bin/setup` to install dependencies. 
Then, run `rake test` to run the tests. If you have 
[Allure report generator][allure] on your machine, you may run 
`rake test:with-report` to generate report after test run.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, 
and then run `bundle exec rake release`, which will create a git tag for 
the version, push git commits and tags, and push the `.gem` file 
to [rubygems.org][rubygems].

Dev branch state:

[![CircleCI][shields.circleci.dev]][circleci.dev]
[![Coveralls][shields.coveralls.dev]][coveralls.dev]
[![Scrutinizer][shields.scrutinizer.dev]][scrutinizer.dev]

## Contributing

Bug reports and pull requests are welcome on GitHub at 
[https://github.com/ama-team/entity-mapper]().

## License

The gem is available as open source under the terms of the 
[MIT License][mit-license].

  [mit-license]: http://opensource.org/licenses/MIT
  [repository]: https://github.com/ama-team/entity-mapper
  [doc]: https://ama-team.github.io/entity-mapper
  [rubygems]: https://rubygems.org
  [allure]: https://github.com/allure-framework/allure2
  [shields.scrutinizer.master]: https://img.shields.io/scrutinizer/g/ama-team/entity-mapper/master.svg?style=flat-square
  [shields.scrutinizer.dev]: https://img.shields.io/scrutinizer/g/ama-team/entity-mapper/dev.svg?style=flat-square
  [shields.coveralls.master]: https://img.shields.io/coveralls/ama-team/entity-mapper/master.svg?style=flat-square
  [shields.coveralls.dev]: https://img.shields.io/coveralls/ama-team/entity-mapper/dev.svg?style=flat-square
  [shields.circleci.master]: https://img.shields.io/circleci/project/github/ama-team/entity-mapper/master.svg?style=flat-square
  [shields.circleci.dev]: https://img.shields.io/circleci/project/github/ama-team/entity-mapper/dev.svg?style=flat-square
  [shields.codeclimate]: https://img.shields.io/codeclimate/github/ama-team/entity-mapper.svg?style=flat-square
  [shields.gem]: https://img.shields.io/gem/v/ama-entity-mapper.svg?style=flat-square
  [scrutinizer.master]: https://scrutinizer-ci.com/g/ama-team/entity-mapper?branch=master 
  [scrutinizer.dev]: https://scrutinizer-ci.com/g/ama-team/entity-mapper?branch=dev
  [coveralls.master]: https://coveralls.io/github/ama-team/entity-mapper?branch=master
  [coveralls.dev]: https://coveralls.io/github/ama-team/entity-mapper?branch=dev
  [circleci.master]: https://circleci.com/gh/ama-team/entity-mapper/tree/master 
  [circleci.dev]: https://circleci.com/gh/ama-team/entity-mapper/tree/dev
  [codeclimate]: https://codeclimate.com/github/ama-team/entity-mapper
  [gem]: https://rubygems.org/gems/ama-entity-mapper
