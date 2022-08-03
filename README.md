# TTEth

![CI](https://github.com/tableturn/tt_eth/actions/workflows/main.yml/badge.svg)

Elixir primitives for Ethereum based development.

## Features

- Ecto compatible Ethereum types.
- A chain client.
- A wrapper around common contract interaction.
- Transaction creation.
- Simple wallet handling.
- Various Ethereum based helper functions.

## Documentation

Generate the package documentation with:

```bash
mix docs
```

## TODO

- Add License.
- Rename the project.
- Add to Hex?
- Add a bunch of documentation.

## Installation

Add the following to your `mix.exs`:

```elixir
def deps do
  [
    {:tt_eth, github: "tableturn/tt_eth"}
  ]
end
```