import birdie
import decider.{type Decider}
import gleam/list
import gleam/string
import gleeunit
import prng/seed.{type Seed}
import uno

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn setup_test() {
  let state =
    uno()
    |> given([])
    |> when(uno.Start)
    |> then([uno.GameStarted])

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

type Scenario(command, state, event, error) {
  Scenario(
    decider: Decider(command, state, event, error),
    state: state,
    seed: Seed,
    then: List(event),
  )
}

fn given(decider: Decider(command, state, event, error), events: List(event)) {
  let seed = seed.new(1)
  let #(state, seed) = {
    use #(state, seed), event <- list.fold(events, #(
      decider.initial_state,
      seed,
    ))
    decider.evolve(state, event, seed)
  }
  Scenario(decider:, state:, seed:, then: [])
}

fn when(scenario: Scenario(command, state, event, error), command: command) {
  let assert Ok(events) =
    scenario.decider.decide(command, scenario.state, scenario.seed)

  Scenario(..scenario, then: events)
}

fn then(scenario: Scenario(command, state, event, error), events: List(event)) {
  assert scenario.then == events
  let #(state, _seed) = {
    use #(state, seed), event <- list.fold(events, #(
      scenario.state,
      scenario.seed,
    ))
    scenario.decider.evolve(state, event, seed)
  }
  state
}

fn uno() {
  let players = ["Sara", "Rodri", "Gael", "Mario"]
  uno.new(players)
}
