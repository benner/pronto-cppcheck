# Pronto runner for cppcheck

Pronto runner for [cppcheck](https://cppcheck.sourceforge.io/), command-line
tool to check C/C++ files for style issues following Google's C++ style guide.
[What is Pronto?](https://github.com/mmozuras/pronto)

## Usage

* `gem install pronto-cppcheck`
* `pronto run`
* `PRONTO_CPPCHECK_OPTS="-j 20 --std=c++17 --enable=warning" pronto run`
    for passing CLI options to `cppcheck`

Keep in mind `PRONTO_CPPCHECK_OPTS` is added to the end of existing
(`--template='{file}:{line},{severity},{id}:{message}' --quiet`)
options.

## Contribution Guidelines

### Installation

`git clone` this repo and `cd pronto-cppcheck`

Ruby

```sh
rbenv install 3.1.0 # or newer
rbenv global 3.1.0 # or make it project specific
gem install bundle
bundle install
```

Make your changes

```sh
git checkout -b <new_feature>
# make your changes
bundle exec rspec
gem build pronto-cppcheck.gemspec
gem install pronto-cppcheck-<current_version>.gem
pronto run --unstaged
```

## Changelog

0.1.0 Initial public version.
