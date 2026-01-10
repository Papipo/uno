import decider
import deck.{type Deck}
import gleam/list
import internal
import prng/random
import prng/seed.{type Seed}

type Decider =
  decider.Decider(Command, State, Event, Error)

pub type Command {
  Start
}

pub opaque type State {
  SettingUp(deck: Deck(Card), players: List(Player))
  Playing(deck: Deck(Card), players: List(Player), discard: Deck(Card))
}

pub type Event {
  GameStarted
  // DeckShuffled(seed: Seed)
}

pub type Error {
  AlreadyStarted
}

pub type Player {
  Player(name: String, hand: List(Card))
}

pub type Card {
  Card(color: Color, number: Int)
  Skip(color: Color)
  Reverse(color: Color)
  Draw(color: Color)
  Wild
  WildDraw
}

pub type Color {
  Blue
  Green
  Yellow
  Red
}

const colors = [Blue, Green, Yellow, Red]

const numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]

pub fn new(seed: Seed, players: List(String)) -> Decider {
  let players = list.map(players, Player(name: _, hand: []))
  decider.Decider(
    decide:,
    evolve:,
    initial_state: SettingUp(deck: build_deck(), players:),
    seed:,
  )
}

fn decide(
  command: Command,
  state: State,
  seed: Seed,
) -> Result(List(Event), Error) {
  case state, command {
    SettingUp(..), Start(..) -> Ok([GameStarted])

    Playing(..), Start(..) -> Error(AlreadyStarted)
  }
}

fn evolve(state: State, event: Event, seed: Seed) -> #(State, Seed) {
  case state, event {
    SettingUp(players:, deck:), GameStarted(..) -> {
      let #(players, seed) = internal.list_shuffle(players) |> random.step(seed)
      let assert Ok(#(discard, deck, seed)) = discard_and_deck(deck, seed)
      #(Playing(players:, deck:, discard:), seed)
    }
    Playing(..), GameStarted -> panic as "Already playing"
  }
}

fn build_deck() -> Deck(Card) {
  let zeros = list.map(colors, Card(color: _, number: 0))
  let one_to_nine = {
    use color <- list.flat_map(colors)
    list.map(numbers, Card(number: _, color:))
  }
  let special = {
    use color <- list.flat_map(colors)
    use kind <- list.map([Skip, Reverse, Draw])
    kind(color)
  }

  let wild =
    list.range(1, 4)
    |> list.flat_map(fn(_) { [Wild, WildDraw] })

  [zeros, one_to_nine, one_to_nine, special, special, wild]
  |> list.flatten
  |> deck.from_list
}

fn discard_and_deck(deck: Deck(Card), seed: Seed) {
  let #(deck, seed) = deck.shuffle(deck, seed)

  case deck.draw(deck) {
    Ok(#(Wild, _)) | Ok(#(WildDraw, _)) -> discard_and_deck(deck, seed)
    Ok(#(discard, deck)) -> #(deck.from_list([discard]), deck, seed) |> Ok
    Error(e) -> Error(e)
  }
}

pub fn player_names(state: State) -> List(String) {
  use player <- list.map(state.players)
  player.name
}

pub fn discard(state: State) -> Result(Card, Nil) {
  case state {
    SettingUp(..) -> Error(Nil)
    Playing(discard:, ..) -> discard |> deck.to_list |> list.first
  }
}

pub fn deck_cards(state: State) {
  state.deck |> deck.to_list
}
