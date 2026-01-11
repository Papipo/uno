# Gleam UNO implementation using the decider pattern

Ideas, doubts and possible refactors.

## Setup and Start

Should the setup be extracted into its own lifecycle and removed from `State`?

## Wrap state

Should the different states have an extra layer of wrapping?
This allows to extract functions and cleanup the main `decide` function `case`

This also allows to split commands and events per state, thus removing lots of invalid calls

## Event errors

Is it the right approach to panic on `evolve`? I assume that a given command will always yield only valid events.
So when calling `evolve` we shouldn't be defensive, right?

## Rulesets

I'd like cards themselves to define if they can be played or not and what effect they have.
A bit like in a CCG/TCG, where cards have requirements, costs, etc.
This allows having different versions of the game, even provide rules as data on initialisation.

## Command validation

How are commands validated? A client should be able to know if a card is playable.
This opens up the possibility to provide instant feedback on which
cards in your hand can be player (by greying out the other ones for example), thus sharing code
between the backend and the frontend, and not having to send requests to the BE to ask it if a card
can be played.