open Bigarray
open Ctypes_static

type cmat = unit ptr

type t =
  | CV_8U of (int, int8_unsigned_elt, c_layout) Genarray.t
  | CV_32S of (int32, int32_elt, c_layout) Genarray.t

(** [create ()] is a fresh mat of type [CV_8U]. *)
val create : unit -> t

(** [create_int32 ()] is a fresh mat of type [CV_32S]. *)
val create_int32 : unit -> t

(** [clone src] is a fresh mat containing the same data as
    [src], but with a different underlying array so that the
    new mat is independent from [src]. *)
val clone : t -> t

val cmat_of_bigarray: t -> cmat
val bigarray_of_cmat: cmat -> t
val copy_cmat_bigarray: cmat -> t -> unit
