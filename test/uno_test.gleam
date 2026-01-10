import birdie
import decider.{type Decider}
import gleam/list
import gleam/string
import gleeunit
import prng/seed.{type Seed}
import uno

fn verify(
  scenario scenario: Scenario(command, state, event),
  decider decider: Decider(command, state, event, error),
  seed seed: Seed,
) -> #(state, Seed) {
  let #(state, seed) = {
    use #(state, seed), event <- list.fold(scenario.given, #(
      decider.initial_state,
      seed,
    ))
    decider.evolve(state, event, seed)
  }
  let assert Ok(events) = decider.decide(scenario.when, state, seed)
  assert events == scenario.then

  use #(state, seed), event <- list.fold(events, #(state, seed))
  decider.evolve(state, event, seed)
}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn setup_test() {
  let players = ["Sara", "Rodri", "Gael", "Mario"]
  let seed = seed.new(1)
  let decider = uno.new(players)

  let #(state, _seed) =
    Scenario(name: "setup test", given: [], when: uno.Start, then: [
      uno.GameStarted,
    ])
    |> verify(decider, seed)

  uno.player_names(state)
  |> string.join(",")
  |> birdie.snap("Randomized players")

  let assert Ok(discard) = uno.discard(state)
  birdie.snap(discard |> string.inspect, "Initial discard")

  uno.deck_cards(state)
  |> list.map(string.inspect)
  |> string.join(",")
  |> birdie.snap("Randomized deck")
}

type Scenario(command, state, event) {
  Scenario(name: String, given: List(event), when: command, then: List(event))
}
