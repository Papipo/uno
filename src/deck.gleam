import internal
import prng/random
import prng/seed

pub type Error {
  EmptyDeck
}

pub opaque type Deck(a) {
  Deck(cards: List(a))
}

pub fn to_list(deck: Deck(a)) -> List(a) {
  deck.cards
}

pub fn from_list(list: List(a)) -> Deck(a) {
  Deck(list)
}

pub fn shuffle(deck: Deck(a), seed: seed.Seed) -> #(Deck(a), seed.Seed) {
  let #(cards, seed) =
    deck.cards
    |> internal.list_shuffle
    |> random.step(seed)

  #(Deck(cards), seed)
}

pub fn draw(deck: Deck(a)) {
  case deck.cards {
    [card, ..rest] -> Ok(#(card, Deck(rest)))
    [] -> Error(EmptyDeck)
  }
}
