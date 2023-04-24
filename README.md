# VistualCall

VistualCall is a gem to help you trace your code and export beautiful vistual call graph.

# Introduction

## Dependency

1. Graphviz

You need to install [Graphviz](https://graphviz.org/) by yourself.

Go to install [graphviz](https://graphviz.org/download/).

## Usage

### 1. Install gem

`gem install vistual_call`

### 2. Only the method needs to be wrapped.


```ruby
require 'vistual_call'

def call_c
end

def call_b
  call_c
end

def call_a
  call_b
end

VistualCall.trace do
  call_a # enter call
end
```

![example](./example/example.png)

The method after each node is call order number. This will help your understand the order of the function call.

## 3. More information

## configuration

```ruby
# you can pass options
VistualCall.trace(options) do
  # run your code here...
end
```

Options:

| name | type | required | explain | example |
| ---- | ---- | ---- | ---- | ---- |
| label | String | true | 标题 | Hello |
| labelloc | Symbol | false | 标题位置:  :top :bottom :center | :top  |
| labeljust | Symbol | false | 标题对齐位置 :left, :center, :right | :center  |
| direction | Symbol| false  | 绘制方向，依次是 :TB(从上到下)，:LR(从左到右,默认方式),:BT(从下到上),:RL(从右到左) | :LR |
| format | String | false  | 输出图片格式，查看 [graphviz 支持输出格式](https://graphviz.org/docs/outputs/) 'png'、'svg'  |  默认 'png' |
| output | String | false | 导出图片绝对路径 | 默认家目录下 `vistual_call_result.png` |
| theme | Symbol | false | 配色主题 :sky, :lemon | 默认 :sky |
| show_dot | boolean | false | 展示 dot 内容 | 默认 false |
| show_order_number | boolean | false | 输出调用序号 | 默认 true |
| jump_list | Array(String) | false | 跳过节点，默认 ["Kernel#class", "Kernel#frozen?"] | - |
| heightlight_match | Regex | false | 默认高亮匹配 label， 默认 /method_missing/ | /method_missing/ |

## LICENSE

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
