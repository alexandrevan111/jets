---
title: jets import:rails
reference: true
---

## Usage

    jets import:rails

## Description

Imports rails project in the rack subfolder.

Imports a Rails application into a Jets project and configures it for [Mega Mode](http://rubyonjets.com/docs/rails-support/).

## Example

    jets import:rails http://github.com/tongueroo/demo-rails.git

## More Examples

    jets import:rails tongueroo/demo-rails # expands to github
    jets import:rails git@github.com:tongueroo/demo-rails.git
    jets import:rails /path/to/folder/demo-rails

## Options

```
[--submodule], [--no-submodule]  # Imports the project as a submodule
```

