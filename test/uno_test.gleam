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
  let assert Ok(discard) = uno.top_discard(scenario.state)

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

pub fn play_card_test() {
  let card = uno.Card(uno.Yellow, 4)
  let discard = uno.Card(uno.Red, 4)

  let scenario =
    decider()
    |> given([])
    |> when(uno.Start)
    |> evolve

  let state = scenario.state
  let current_player = uno.current_player(state) |> uno.player_name

  let scenario =
    scenario
    |> mutate(uno.add_card_to_current_player_hand(card))
    |> mutate(uno.add_card_to_discard(discard))
    |> when(uno.PlayCard(card))
    |> then([uno.CardPlayed(card), uno.TurnEnded])
    |> evolve

  assert current_player != uno.current_player(scenario.state) |> uno.player_name
  assert scenario.state |> uno.top_discard == Ok(card)
}

fn mutate(
  scenario: Scenario(command, state, event, error),
  fun: fn(state) -> state,
) -> Scenario(command, state, event, error) {
  let state = scenario.state |> fun()
  Scenario(..scenario, state:)
}

pub type Scenario(command, state, event, error) {
  Scenario(
    decider: Decider(command, state, event, error),
    state: state,
    seed: Seed,
    then: List(event),
  )
}

fn given(decider: Decider(command, state, event, error), then: List(event)) {
  let seed = seed.new(1)

  Scenario(decider:, state: decider.initial_state, seed:, then:)
  |> evolve
}

fn when(scenario: Scenario(command, state, event, error), command: command) {
  let assert Ok(then) =
    scenario.decider.decide(command, scenario.state, scenario.seed)

  Scenario(..scenario, then:)
}

fn evolve(scenario: Scenario(command, state, event, error)) {
  let #(state, seed) = {
    use #(state, seed), event <- list.fold(scenario.then, #(
      scenario.state,
      scenario.seed,
    ))
    scenario.decider.evolve(state, event, seed)
  }
  Scenario(..scenario, state:, seed:, then: [])
}

fn then(scenario: Scenario(command, state, event, error), events: List(event)) {
  assert scenario.then == events
  scenario
}

fn decider() {
  let players = ["Sara", "Rodri", "Gael", "Mario"]
  uno.new(players)
}
