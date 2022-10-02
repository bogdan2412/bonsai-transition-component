open! Core
open! Import

(** The named arguments below each take in a list of CSS classes.

    The component starts off with CSS classes [left].

    Toggling while in [left] state will start the [enter] transition.
    For one frame, the component will have classes [enter_from @ enter_tarnsition].
    For the remainder of the transition, the component will have classes
    [enter_to @ enter_transition].
    Once the transition finishes, the component will have classes [entered].

    Toggling while in [entered] state will start the [leave] transition, which works
    analogously.

    The component is inspired by
    [https://vuejs.org/guide/built-ins/transition.html#css-based-transitions]. *)
val component
  :  enter_transition:string list
  -> enter_from:string list
  -> enter_to:string list
  -> entered:string list
  -> leave_transition:string list
  -> leave_from:string list
  -> leave_to:string list
  -> left:string list
  -> Vdom.Node.t list
  -> Vdom.Node.t Bonsai_toggleable.t Bonsai.Computation.t

(** Same as [component], but allowing for dynamism in the children nodes.

    [component ... children] should be equivalent to
    [component' ... (Bonsai_toggleable.Computation.return children)]. *)
val component'
  :  enter_transition:string list
  -> enter_from:string list
  -> enter_to:string list
  -> entered:string list
  -> leave_transition:string list
  -> leave_from:string list
  -> leave_to:string list
  -> left:string list
  -> Vdom.Node.t list Bonsai_toggleable.t Bonsai.Computation.t
  -> Vdom.Node.t Bonsai_toggleable.t Bonsai.Computation.t
