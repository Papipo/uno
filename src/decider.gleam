import prng/seed.{type Seed}

pub type Decider(command, state, event, error) {
  Decider(
    decide: fn(command, state, Seed) -> Result(List(event), error),
    evolve: fn(state, event, Seed) -> #(state, Seed),
    initial_state: state,
  )
}
