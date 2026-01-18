import decider
import deck.{type Deck}
import gleam/list
import gleam/result
import hand.{type Hand}
import internal
import prng/random
import prng/seed.{type Seed}

type Decider =
  decider.Decider(Command, State, Event, Error)

pub type Command {
  Start
  PlayCard(Card)
}

pub opaque type State {
  SettingUp(deck: Deck(Card), players: List(Player))
  Playing(deck: Deck(Card), players: List(Player), discard: Discard)
}

pub type Event {
  DeckShuffled
  PlayerOrderRandomized
  GameStarted
  InitialHandsDrawn
  CardPlayed(Card)
  TurnEnded
}

pub type Error {
  AlreadyStarted
  GameNotStartedYet
  CardNotInHand
}

pub type Player {
  Player(name: String, hand: Hand(Card))
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

pub type Discard {
  Discard(latest: Card, rest: List(Card))
}

const colors: List(Color) = [Blue, Green, Yellow, Red]

const numbers: List(Int) = [1, 2, 3, 4, 5, 6, 7, 8, 9]

pub fn new(players: List(String)) -> Decider {
  let players = list.map(players, Player(name: _, hand: hand.new()))
  decider.Decider(
    decide:,
    evolve:,
    initial_state: SettingUp(deck: build_deck(), players:),
  )
}

fn decide(
  command: Command,
  state: State,
  seed: Seed,
) -> Result(List(Event), Error) {
  case state, command {
    SettingUp(..), Start(..) ->
      Ok([DeckShuffled, PlayerOrderRandomized, InitialHandsDrawn, GameStarted])
    Playing(..), PlayCard(card) -> {
      case current_player(state).hand |> hand.contains(card) {
        True -> [CardPlayed(card), TurnEnded] |> Ok
        False -> Error(CardNotInHand)
      }
    }
    Playing(..), Start(..) -> Error(AlreadyStarted)
    SettingUp(..), PlayCard(_) -> Error(GameNotStartedYet)
  }
}

pub fn current_player(state: State) {
  let assert Ok(player) = state.players |> list.first
  player
}

fn evolve(state: State, event: Event, seed: Seed) -> #(State, Seed) {
  case state, event {
    SettingUp(deck:, ..), DeckShuffled -> {
      let #(deck, seed) = deck.shuffle(deck, seed)
      #(SettingUp(..state, deck:), seed)
    }
    SettingUp(players:, ..), PlayerOrderRandomized -> {
      let #(players, seed) = internal.list_shuffle(players) |> random.step(seed)
      #(SettingUp(..state, players:), seed)
    }
    SettingUp(deck:, players:), InitialHandsDrawn -> {
      let result = {
        use #(deck, players), player <- list.try_fold(players, #(deck, []))
        use #(drawn, deck) <- result.try(deck.draw_many(deck, 7))
        let player = Player(..player, hand: hand.from_list(drawn))
        #(deck, [player, ..players]) |> Ok
      }

      case result {
        Ok(#(deck, players)) -> #(SettingUp(deck:, players:), seed)
        Error(_) -> panic as "Error drawing initial hand"
      }
    }
    SettingUp(players:, deck:), GameStarted(..) -> {
      let assert Ok(#(discard, deck, seed)) = discard_and_deck(deck, seed)

      #(Playing(discard:, deck:, players:), seed)
    }

    Playing(..), CardPlayed(card) -> {
      let assert [current_player, ..players] = state.players
      let hand = hand.remove(current_player.hand, card)
      let current_player = Player(..current_player, hand:)
      let players = [current_player, ..players]
      let discard =
        Discard(latest: card, rest: [state.discard.latest, ..state.discard.rest])
      let state = Playing(..state, discard:, players:)
      #(state, seed)
    }
    Playing(..), TurnEnded -> {
      let assert [current_player, ..rest] = state.players
      let players = list.append(rest, [current_player])
      #(Playing(..state, players:), seed)
    }
    Playing(..), GameStarted
    | Playing(..), DeckShuffled
    | Playing(..), PlayerOrderRandomized
    | Playing(..), InitialHandsDrawn
    -> panic as "Already playing"

    SettingUp(..), CardPlayed(..) | SettingUp(..), TurnEnded(..) ->
      panic as "Not playing yet"
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

fn discard_and_deck(
  deck: Deck(Card),
  seed: Seed,
) -> Result(#(Discard, Deck(Card), Seed), deck.Error) {
  let #(deck, seed) = deck.shuffle(deck, seed)

  case deck.draw(deck) {
    Ok(#(Wild, _)) | Ok(#(WildDraw, _)) -> discard_and_deck(deck, seed)
    Ok(#(discard, deck)) -> #(Discard(discard, []), deck, seed) |> Ok
    Error(e) -> Error(e)
  }
}

pub fn player_names(state: State) -> List(String) {
  use player <- list.map(state.players)
  player.name
}

pub fn top_discard(state: State) {
  case state {
    SettingUp(..) -> Error(GameNotStartedYet)
    Playing(discard:, ..) -> Ok(discard.latest)
  }
}

pub fn deck_cards(state: State) -> List(Card) {
  state.deck |> deck.to_list
}

pub fn players(state: State) -> List(Player) {
  state.players
}

pub fn hand_size(player: Player) -> Int {
  player.hand |> hand.size
}

@internal
pub fn add_card_to_current_player_hand(card: Card) {
  fn(state: State) {
    let assert [current, ..rest] = state.players
    let current = Player(..current, hand: hand.add(current.hand, card))
    let players = [current, ..rest]
    case state {
      SettingUp(..) -> SettingUp(..state, players:)
      Playing(..) -> Playing(..state, players:)
    }
  }
}

@internal
pub fn add_card_to_discard(card: Card) {
  fn(state: State) {
    case state {
      SettingUp(..) -> panic as "Can't add_card_to_discard during setup"
      Playing(discard:, ..) -> {
        let discard = Discard(card, [discard.latest, ..discard.rest])
        Playing(..state, discard:)
      }
    }
  }
}

pub fn player_name(player: Player) -> String {
  player.name
}
