open Ctypes
open Loader
type t =
  | Mat of Mat.t
  | Mat_int32 of Mat_int32.t
  | Unknown of unit Ctypes.ptr

let of_mat mat =
  Mat mat

let to_mat = function
  | Mat mat -> mat
  | _ -> failwith "to_mat"

(* internal functions *)

let __inputarray_kind =
  foreign "inputarray_kind" (ptr void @-> returning int)
let __mat_depth =
  foreign "mat_depth" (ptr void @-> returning int)

let __mat_of_inputarray =
  foreign "mat_of_inputarray" (ptr void @-> returning (ptr void))
let __mat_vector_of_inputarray =
  foreign "mat_vector_of_inputarray" (ptr void @-> returning (ptr void))
let __inputarray_array_length =
  foreign "inputarray_array_length" (ptr void @-> returning int)
let __mat_from_inputarray_array =
  foreign "mat_from_inputarray_array" (ptr void @-> int @-> returning (ptr void))

let extract_mat_from_cmat cmat =
  let mat = Mat.bigarray_of_cmat cmat in
  Mat.copy_cmat_bigarray cmat mat;
  of_mat mat

let extract_cvdata (data : unit ptr) : t =
  match __inputarray_kind data with
    | 1 ->
        begin
          let cmat = __mat_of_inputarray data in
          (* only extract if mat is 8-bit unsigned *)
          match __mat_depth cmat with
            | 0 -> extract_mat_from_cmat cmat
            | _ -> Unknown data
        end
    | _ -> Unknown data

let extract_cvdata_array (data : unit ptr) : t list =
  match __inputarray_kind data with
    | 5 ->
        begin
          let length = __inputarray_array_length data in
          List.fold_left
            begin fun acc index ->
              let cmat = __mat_from_inputarray_array data index in
              let cvdata =
                match __mat_depth cmat with
                  | 0 -> (* 8-bit unsigned *)
                      let mat = Mat.bigarray_of_cmat cmat in
                      Mat.copy_cmat_bigarray cmat mat;
                      of_mat mat
                  | 4 -> (* 32-bit signed *)
                      let mat = Mat_int32.bigarray_of_cmat cmat in
                      Mat_int32.copy_cmat_bigarray cmat mat;
                      Mat_int32 mat
                  | _ -> Unknown cmat in
              cvdata :: acc
            end [] (List.init length (fun x -> length - x - 1))
        end
    | _ -> failwith "unrecognized data, not vector of mat"

let __input_array_of_mat =
  foreign "inputarray_of_mat" (ptr void @-> returning (ptr void))
let __input_array_of_mat_vector =
  foreign "inputarray_of_mat_vector" (ptr void @-> returning (ptr void))

let __create_vector_mat =
  foreign "create_vector_mat" (int @-> returning (ptr void))
let __add_vector_mat =
  foreign "add_vector_mat" (ptr void @-> ptr void @-> returning void)

let pack_cvdata (cvdata : t) : unit ptr =
  match cvdata with
    | Mat mat -> Mat.cmat_of_bigarray mat |> __input_array_of_mat
    | Mat_int32 mat -> Mat_int32.cmat_of_bigarray mat |> __input_array_of_mat
    | Unknown data -> data

let pack_cvdata_post (cvdata : t) (arr : unit ptr) =
  match cvdata with
    | Mat mat ->
        let cmat = __mat_of_inputarray arr in
        Mat.copy_cmat_bigarray cmat mat
    | Mat_int32 mat ->
        let cmat = __mat_of_inputarray arr in
        Mat_int32.copy_cmat_bigarray cmat mat
    | _ -> ()

let pack_cvdata_array_elem = function
  | Mat mat -> Mat.cmat_of_bigarray mat
  | Mat_int32 mat -> Mat_int32.cmat_of_bigarray mat
  | Unknown data -> data

let pack_cvdata_array (cvdata_lst : t list) =
  let vec = __create_vector_mat (List.length cvdata_lst) in
  List.iter (fun cvdata ->
    __add_vector_mat vec (pack_cvdata_array_elem cvdata)) cvdata_lst;
  __input_array_of_mat_vector vec

let pack_cvdata_array_post (cvdata_lst : t list ref) (arr_arr : unit ptr) =
  cvdata_lst := extract_cvdata_array arr_arr

let clone = function
  | Mat mat -> Mat (Mat.clone mat)
  | _ -> failwith "clone non-mat"
