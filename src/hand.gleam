import iv

pub opaque type Hand(card) {
  Hand(cards: iv.Array(card))
}

pub fn new() -> Hand(card) {
  iv.new() |> Hand
}

pub fn contains(hand: Hand(card), card: card) -> Bool {
  iv.contains(hand.cards, card)
}

pub fn from_list(list: List(card)) -> Hand(card) {
  list |> iv.from_list |> Hand
}

pub fn remove(hand: Hand(card), card card) {
  case iv.find_index(hand.cards, fn(x) { x == card }) {
    Ok(index) -> iv.try_delete(hand.cards, index) |> Hand
    Error(_) -> hand
  }
}

pub fn size(hand: Hand(card)) -> Int {
  iv.size(hand.cards)
}

pub fn add(hand: Hand(card), card: card) -> Hand(card) {
  hand.cards |> iv.append(card) |> Hand
}
