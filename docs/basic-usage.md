---
title: Basic Usage
---

Entity mapper is quite simple from the inside. Basically it acts in following
way:

- Validate that provided types are resolved and create a context
- Accept an entity
- With next type in type list:
    - If entity is not of that target type, normalize it down to basic 
      structure and then denormalize result into instance of target type
    - Take the original entity or denormalized result and repeat the 
      procedure with every attribute
    - If error is raised, suppress it
- If result is acquired, return it
- Else raise last error

So it's basically an horrific recursion machine. It already knows how to 
work with basic types, how to decompose arbitrary class into Hash of 
attribute, how to create new instance given a class (yes, just call
`#new()`) and that methods like `#fuu=(value)` are setters, and you can
map hash into entity of specific type with ease:

```ruby
class Person
  attr_accessor :first_name
  attr_accessor :last_name
  
  def name=(name)
    @first_name, @last_name = name.split(/\s+/)
  end
end

input = { name: 'Stephen Fry' }
person = AMA::Entity::Mapper.map(input, Person)
```

`.map(input, *types, **context)` is used to map entities from one 
type to another automatically. `.normalize(input, **context)` method 
is used to break entity into the primitive types - hashes, strings, symbols,
floats, etc.:

```ruby
normalized = AMA::Entity::Mapper.normalize(person)
normalized[:first_name] == 'Stephen'
normalized[:last_name] == 'Fry'
```

Mapper understands nested types as well, however, it may require
developer to hint it about used types:

```ruby
input = {
  created_by: 'Bill Lawrence',
  stars: ['Zack Braff', 'Sarah Chalke']
}

scrubs = AMA::Entity::Mapper.map(input, [Hash, K: Symbol, V: Person])
```

In this example developer is explicitly telling the Mapper that
hash keys have to be symbols, and values have to be persons. Please 
note the array notation - it is required so mapper would combine this
as a single type.

However, chances are end developer would like to deal with `Series`
class instance rather than hash. This is possible as well - with some
hints again:

```ruby
class Series
  include AMA::Entity::Mapper::DSL
  
  attribute :created_by, Person
  attribute :stars, [Enumerable, T: Person]
end

scrubs = AMA::Entity::Mapper.map(input, Series)
puts scrubs.created_by.first_name # Bill 
```

`attribute` method registers attribute information within a type. By
default, it is required to specify attribute name and at least one
type (yeah, there may be several), but it also has a set of options:

- :nullable (default: true), whether that attribute may be represented
  by a `nil`
- :default (default: nil), default value for attribute
- :values (default: []), allowed ste of values for attribute
- :sensitive (default: false), forces attribute to be omitted during 
  normalization
- :virtual (default: false), forces attribute to be ignored
- :aliases (default: []), set of other names attribute may be given

So more complex example may look like that:

```ruby
class Account
  attribute :id, Symbol, aliases: %i[user_id login]
  attribute :role, Symbol, values: %i[admin writer reader], default: :reader
  attribute :metadata, [Hash, K: Symbol, V: Symbol], default: {}
  attribute :active, TrueClass, FalseClass, default: true
  attribute :last_login, DateTime, nullable: true
end
```

Please feel free to note that:

- :active attribute specifies two types (thanks to ruby that doesn't 
  have bool type)
- only :id attribute is required to be present in structure being 
  denormalized
- if structure contains `user_id` entry - that would work as well
(however, having both `id` and `user_id` would result in `id` winning 
the priority race)

Last but not least: attribute has `attr_accessor` semantics, so,
after you've called attribute, you already have setter and getter.

## Multiple types

So, what about multiple types? Basically, mapper takes all the
specified types and tries to use them one by one. As soon as error
is hit, it will try next, and so on. So given the following example:

```ruby
class Post
  attribute :title, String
  attribute :type, Symbol, values: %i[post repost advertisement]
  attribute :content, String
  attribute :reporter, Author, Integer
end

class JsonProblem
  attribute :title, String
  attribute :type, String, default: 'about:blank'
  attribute :status, Integer
  attribute :detail, String, nullable: true
  attribute :instance, String, nullable: true
  attribute :origin, Author, Integer
end

input = {
  title: 'Server has vanished',
  type: 'about:blank',
  origin: 'frontend-01.company.com',
  status: '500'
}

response = AMA::Entity::Mapper.map(input, Post, JsonProblem)
```

mapper will do following things

- Try to map data into Post
  - Start mapping Post attributes
  - Try to map origin into Author and fail
  - Try to map origin into Integer and fail
- Try to map data into JsonProblem
  - Start mapping JsonProblem attributes
  - Fail on mapping status into Integer
- Raise last exception

## Handlers

If none of the above fully solved your case, it's time to mess with 
handlers.

Handlers are specific objects that process specific part of domain,
like:

- Enumerate all entity attributes
- Set attribute on entity
- Create entity
- Normalize entity

Handlers are very specific, so [standalone page](handlers) has been
allocated to describe their principles.
