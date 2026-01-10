import gleam/float
import gleam/list
import prng/random

pub fn list_shuffle(list: List(a)) {
  random.float(0.0, 1.0)
  |> random.fixed_size_list(list.length(list))
  |> random.map(fn(random_list) {
    list.zip(random_list, list)
    |> do_list_shuffle_by_pair_indexes()
    |> shuffle_pair_unwrap_loop([])
  })
}

fn shuffle_pair_unwrap_loop(list: List(#(Float, a)), acc: List(a)) {
  case list {
    [] -> acc
    [elem_pair, ..enumerable] ->
      shuffle_pair_unwrap_loop(enumerable, [elem_pair.1, ..acc])
  }
}

fn do_list_shuffle_by_pair_indexes(list_of_pairs: List(#(Float, a))) {
  use a_pair, b_pair <- list.sort(list_of_pairs)
  float.compare(a_pair.0, b_pair.0)
}
