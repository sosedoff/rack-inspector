# Rack::Inspector

Rack middleware for remote request/response inspection in real-time.

[![Build Status](https://travis-ci.org/sosedoff/rack-inspector.png?branch=master)](https://travis-ci.org/sosedoff/rack-inspector)
[![Code Climate](https://codeclimate.com/github/sosedoff/rack-inspector.png)](https://codeclimate.com/github/sosedoff/rack-inspector)

## Overview

This middleware provides a capability to stream request/response data directly
into [redis](http://redis.io) using pubsub. All request data is also stored in a separate list.
Its designed to simplify API troubleshooting on staging/test servers. 
You can hook up anything that supports redis lists or pubsub to monitor activity.

Supports matching by:

- Request path
- Request method
- Response code (200, 400, etc)

Check out a simple UI built in node.js for examples: [rack-inspector-ui](https://github.com/sosedoff/rack-inspector-ui)

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

## Configuration

You can configure inspection with options:

```ruby
# Will report all requests by default
use Rack::Inspector

# Report if path matches
use Rack::Inspector, path: /api/
use Rack::Inspector, path: [/api/, /account/]

# Report if request method matches
use Rack::Inspector, method: "POST"
use Rack::Inspector, method: ["POST", "PUT"]

# Report if response status code matches
use Rack::Inspector, status: 404
use Rack::Inspector, status: [400, 401, 403, 404]
```

Setup redis connection:

```ruby
# Provide a different redis client instance
use Rack::Inspector, redis: Redis.new(host: "HOST")

# Or using environment variable
# export REDIS_INSPECT_URL=redis://user:password@host:port/
use Rack::Inspector
```

## Payloads

Each payload is a JSON-encoded object and has the following structure:

```json
{
  "id": "500b1a1f-da82-4672-b54c-ee22687eabb7",
  "app": "rack-inspector",
  "host": "Dan-Sosedoffs-MacBook-Pro.local",
  "request_method": "GET",
  "path": "/hello",
  "status": 200,
  "timestamp": "2013-09-17 23:35:32 UTC",
  "request": {
    "query_string": "",
    "params": {},
    "body": "",
    "env": {
      "REQUEST_METHOD": "GET",
      "SERVER_NAME": "foobar.com",
      "SERVER_PORT": "80",
      "QUERY_STRING": "",
      "PATH_INFO": "/hello",
      "rack.url_scheme": "http",
      "HTTPS": "off",
      "SCRIPT_NAME": "",
      "CONTENT_LENGTH": "0",
      "rack.request.query_string": ""
    }
  },
  "response": {
    "status": 200,
    "headers": {
      "Content-Type": "text/html"
    },
    "body": "OK"
  }
}
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