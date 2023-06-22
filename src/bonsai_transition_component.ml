open! Core
open! Import

module Model = struct
  type t =
    | Left
    | Enter_from
    | Enter_active
    | Entered
    | Leave_from
    | Leave_active
  [@@deriving compare, sexp]
end

module Action = struct
  type t =
    | Toggle
    | Set_state of Bonsai_toggleable.State.t
    | Internal_advance_transition
  [@@deriving sexp_of]
end

let state_machine =
  let%sub.Bonsai state =
    Bonsai.state_machine0
      ~sexp_of_model:[%sexp_of: Model.t]
      ~sexp_of_action:[%sexp_of: Action.t]
      ~equal:[%compare.equal: Model.t]
      ~default_model:Left
      ~apply_action:(fun (_ : Action.t Bonsai.Apply_action_context.t) model action ->
        match action with
        | Toggle ->
          (match model with
           | Left | Leave_from | Leave_active -> Enter_from
           | Entered | Enter_from | Enter_active -> Leave_from)
        | Set_state desired_state ->
          (match model, desired_state with
           | (Left | Leave_from | Leave_active), Untoggled -> model
           | (Entered | Enter_from | Enter_active), Toggled -> model
           | (Entered | Enter_from | Enter_active), Untoggled -> Leave_from
           | (Left | Leave_from | Leave_active), Toggled -> Enter_from)
        | Internal_advance_transition ->
          (match model with
           | Left | Entered -> model
           | Enter_from -> Enter_active
           | Enter_active -> Entered
           | Leave_from -> Leave_active
           | Leave_active -> Left))
      ()
  in
  let%sub.Bonsai () =
    Bonsai.Edge.lifecycle'
      ~after_display:
        (let%map.Bonsai state, inject = state in
         match state with
         | Leave_from | Enter_from -> Some (inject Internal_advance_transition)
         | Left | Entered | Leave_active | Enter_active -> None)
      ()
  in
  let%arr.Bonsai value, inject = state in
  ( { Bonsai_toggleable.value
    ; toggle = (fun () -> inject Toggle)
    ; set_state = (fun state -> inject (Set_state state))
    }
  , `Internal_advance_transition (fun () -> inject Internal_advance_transition) )
;;

let wrap
      ~enter_transition
      ~enter_from
      ~enter_to
      ~entered
      ~leave_transition
      ~leave_from
      ~leave_to
      ~left
      ~model
      ~internal_advance_transition
      children
  =
  let classes =
    match (model : Model.t) with
    | Left -> left
    | Entered -> entered
    | Enter_from -> enter_from @ enter_transition
    | Enter_active -> enter_to @ enter_transition
    | Leave_from -> leave_from @ leave_transition
    | Leave_active -> leave_to @ leave_transition
  in
  Vdom.Node.div
    ~attrs:
      [ Vdom.Attr.classes classes
      ; Vdom.Attr.on_transitionend (fun _ -> internal_advance_transition ())
      ]
    children
;;

let component
      ~enter_transition
      ~enter_from
      ~enter_to
      ~entered
      ~leave_transition
      ~leave_from
      ~leave_to
      ~left
      children
  =
  let%sub.Bonsai model = state_machine in
  let%arr.Bonsai model, `Internal_advance_transition internal_advance_transition =
    model
  in
  let%map.Bonsai_toggleable model = model in
  wrap
    ~enter_transition
    ~enter_from
    ~enter_to
    ~entered
    ~leave_transition
    ~leave_from
    ~leave_to
    ~left
    ~model
    ~internal_advance_transition
    children
;;

let component'
      ~enter_transition
      ~enter_from
      ~enter_to
      ~entered
      ~leave_transition
      ~leave_from
      ~leave_to
      ~left
      children
  =
  let%sub.Bonsai model = state_machine in
  let%sub.Bonsai children = children in
  let%arr.Bonsai model, `Internal_advance_transition internal_advance_transition = model
  and children = children in
  let%map.Bonsai_toggleable model = model
  and children = children in
  wrap
    ~enter_transition
    ~enter_from
    ~enter_to
    ~entered
    ~leave_transition
    ~leave_from
    ~leave_to
    ~left
    ~model
    ~internal_advance_transition
    children
;;
