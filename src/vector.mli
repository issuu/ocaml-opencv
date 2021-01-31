open Ctypes

val list_of_vector: 'a typ -> 'b ptr -> 'a list
val vector_of_list: 'a typ -> 'a list -> unit ptr
