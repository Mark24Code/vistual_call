# VistualCall

## 1. Prepation

Need install [Graphviz](https://graphviz.org/) first.


## 2. Example

```ruby
require_relative '../lib/vistual_call'

def call_c
end

def call_b
  call_c
end

def call_a
  call_b
end

VistualCall.trace do
  call_a
end
```

![vistual_call_result](./example/vistual_call_result.png)
