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

pub fn deck_suffled_test() {
  let scenario = decider() |> given([uno.DeckShuffled])

  scenario.state
  |> uno.deck_cards()
  |> list.map(string.inspect)
  |> string.join(",")
  |> birdie.snap("Shuffled deck")
}

pub fn player_order_randomized_test() {
  let scenario = decider() |> given([uno.PlayerOrderRandomized])

  uno.player_names(scenario.state)
  |> string.join(",")
  |> birdie.snap("Player order randomized")
}

pub fn game_started_test() {
  let scenario = decider() |> given([uno.GameStarted])
  let assert Ok(discard) = uno.discard(scenario.state)

  discard
  |> string.inspect
  |> birdie.snap("Initial discard")
}

pub fn initial_hands_drawn_test() {
  let scenario = decider() |> given([uno.InitialHandsDrawn])

  assert scenario.state
    |> uno.players()
    |> list.map(uno.hand_size)
    == [7, 7, 7, 7]
}

pub fn setup_test() {
  decider()
  |> given([])
  |> when(uno.Start)
  |> then([
    uno.DeckShuffled,
    uno.PlayerOrderRandomized,
    uno.InitialHandsDrawn,
    uno.GameStarted,
  ])
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

fn decider() {
  let players = ["Sara", "Rodri", "Gael", "Mario"]
  uno.new(players)
}
