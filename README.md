# Rack::Inspector

Rack middleware to remotely inspect request and response data for Ruby applications.

## Installation

Add this line to your application's Gemfile:

```
gem 'rack-reporter'
```

And then execute:

```
bundle
```

Or install it yourself as:

```
$ gem install rack-reporter
```

## Usage

Edit your `config.ru` file:

```ruby
# Require inspector middleware
require "rack/inspector"

# Use middleware
use Rack::Inspector

# Run application
run MyApp
```

## Configure

You can configure inspection with options:

```ruby
# Will report all requests
use Rack::Inspector, match_all: true

# Report only specific requests with regular expressions
use Rack::Inspector, match: /api/

# Report requests for multiple patterns
use Rack::Inspector, match: [/api/, /account/]
```

## Testing

Execute test suite with:

```
rake test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2013 Dan Sosedoff <dan.sosedoff@gmail.com>

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.