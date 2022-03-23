# Bgzfrb

pure ruby bgzip reader.
currenty, index is not supported.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bgzfrb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bgzfrb

## Usage

TODO: Write usage instructions here
```ruby
require 'bgzrfb'
fname = 'a.vcf.gz'
BGZF::Reader.open(fname) do |f|
  f.each_line do |line|
    print line
  end
end
```
