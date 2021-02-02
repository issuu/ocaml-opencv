open Ctypes
open Bigarray

type t =
  | Mat of Mat.t
  | Unknown of unit ptr

val of_mat : (int, int8_unsigned_elt, c_layout) Genarray.t -> t
val to_mat : t -> (int, int8_unsigned_elt, c_layout) Genarray.t

val of_mat_int32 : (int32, int32_elt, c_layout) Genarray.t -> t
val to_mat_int32 : t -> (int32, int32_elt, c_layout) Genarray.t

val clone : t -> t

val pack_cvdata: t -> unit ptr
val pack_cvdata_post: t -> unit ptr -> unit
val extract_cvdata: unit ptr -> t
val pack_cvdata_array: t list -> unit ptr
val pack_cvdata_array_post: t list ref -> unit ptr -> unit
