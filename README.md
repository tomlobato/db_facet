# DbFacet

DbSpider crawls into a database and generates a Hash structure representing the data and its entity relations.
The Hash structure can be read by DbSpiderWeaver to insert data into the database again.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'db_facet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install db_facet

## Usage

Here is a smaple class using db_facet.  
It "clones" an user account with all its dependencies to a fresh new user.

```ruby
class ExportImport

  INCLUDE_TEMPLATE_MODELS = %w(
    User
    Album
    Photo
    Video
    Invoice    
  )
  
  def initialize template_user_id, new_attrs
    @template_user_id = template_user_id
    @new_attrs = new_attrs.deep_dup
  end
  
  def build 
    seed = fetch_seed @template_user_id
    tmp_user = build_user

    override_seed! seed, overrides(tmp_user)
    new_user_id = save! seed

    User.find new_user_id
  end

  private

  def template_overrides user
    @new_attrs.merge!(
      profile_theme: 34
    )

    # children overrides
    @new_attrs.merge!(
      lang_config: {locale: 'fr'},
      invoices: lambda {|data| data[:cc_end] = nil }
    )
    
    @new_attrs
  end

  def build_user
    user.new
  end
  
  # db_facet interface

  def fetch_seed template_user_id
    # You could cache the generated data structure if using 
    # it often and it is viable to clear when changed.
    # Rails.cache.fetch "export-import-seed-#{template_user_id}" do
      DbSpider.new(User.find(template_user_id), INCLUDE_MODELS).spide
    #end
  end

  def override_seed! seed, overrides
    DbSpiderRootMerger.new(seed).merge! overrides
  end

  def save! seed
    DbSpiderWeaver.new(seed, timer: true).weave!
  end
end
```

## Hash structure

```yml
{
  class_name:  'User',
  data: {name: 'Chuck Norris!'},
  reflections: {
    albuns: [
      {
        class_name:  'Albuns',
        data: {name: 'Day off 2017/02'},
        reflections: {
          photos: ...

```

## Classes descriptions

- DbSpider            - Crawls db and generates the Hash structure.
- DbSpiderReaderNode  - Wrapper for an AR model record.
- DbSpiderNodeSet     - Proxy class to instantiate and reuse DbSpiderReaderNode`s.
- DbSpiderWeaver      - Reads the Hash structure generated by DbSpider and INSERTS`s into the database.
- DbSpiderWriterNode  - Wrapper for a node generated by DbSpiderReaderNode.
- DbSpiderRootMerger  - Apply a diff to the Hash structure. Accepts a simplified data structure as parameter.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomlobato/db_facet.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

