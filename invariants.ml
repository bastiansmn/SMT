open Printf

(* Définitions de terme, test et programme *)
type term = 
 | Const of int
 | Var of int
 | Add of term * term
 | Mult of term * term

type test = 
 | Equals of term * term
 | LessThan of term * term

let tt = Equals (Const 0, Const 0)
let ff = LessThan (Const 0, Const 0)
 
type program = {nvars : int; 
                inits : term list; 
                mods : term list; 
                loopcond : test; 
                assertion : test}

let x n = "x" ^ string_of_int n

(* Question 1. Écrire des fonctions `str_of_term` et `str_of_test` qui
   convertissent des termes et des tests en chaînes de caractères du
   format SMTLIB.

  Par exemple, str_of_term (Var 3) retourne "x3", str_of_term (Add
   (Var 1, Const 3)) retourne "(+ x1 3)" et str_of_test (Equals (Var
   2, Const 2)) retourne "(= x2 2)".  *)
let rec str_of_term t =
  match t with
  | Const(i) -> string_of_int i
  | Var(i) -> x i
  | Add(t1, t2) -> "(+ " ^ (str_of_term t1) ^ " " ^ (str_of_term t2) ^ ")"
  | Mult(t1, t2) -> "(* " ^ (str_of_term t1) ^ " " ^ (str_of_term t2) ^ ")"

let str_of_test t =
  match t with
  | Equals(t1, t2) -> "(= " ^ str_of_term t1 ^ " " ^ str_of_term t2 ^ ")"
  | LessThan(t1, t2) -> "(< " ^ str_of_term t1 ^ " " ^ str_of_term t2 ^ ")"

let str_of_nottest t =
  match t with 
  | Equals(t1, t2) -> "(<> " ^ str_of_term t1 ^ " " ^ str_of_term t2 ^ ")"
  | LessThan(t1, t2) ->"(>= " ^ str_of_term t1 ^ " " ^ str_of_term t2 ^ ")"

let string_repeat s n =
  Array.fold_left (^) "" (Array.make n s)

(* Question 2. Écrire une fonction str_condition qui prend une liste
   de termes t1, ..., tk et retourne une chaîne de caractères qui
   exprime que le tuple (t1, ..., tk) est dans l'invariant.  Par
   exemple, str_condition [Var 1; Const 10] retourne "(Invar x1 10)".
   *)
let str_condition l = 
  let rec repeat l r =
    match l with 
    | [] -> r ^ ")"
    | e::l -> repeat l (r ^ " " ^ (str_of_term e))
  in match l with 
  | e::l -> repeat (e::l) "(Invar "
  | _ -> failwith ("Term expected") 

(* Question 3. Écrire une fonction str_assert_for_all qui prend en
   argument un entier n et une chaîne de caractères s, et retourne
   l'expression SMTLIB qui correspond à la formule "forall x1 ... xk
   (s)".

  Par exemple, str_assert_forall 2 "< x1 x2" retourne : "(assert
   (forall ((x1 Int) (x2 Int)) (< x1 x2)))".  *)

let str_assert s = "(assert " ^ s ^ ")"

let str_assert_forall n s =
  let rec aux i =
    if i <= n then (" (x" ^ (string_of_int i) ^ " Int)") ^ (aux (i+1))
    else ""
  in str_assert ("(forall (" ^ aux 1 ^ ")" ^ s ^ ")") ;;


let rec string_of_vars i n =
      if i <= n then " x" ^ (string_of_int (i)) ^ (string_of_vars(i+1)(n)) 
      else ""


(* Question 4. Nous donnons ci-dessous une définition possible de la
   fonction smt_lib_of_wa. Complétez-la en écrivant les définitions de
   loop_condition et assertion_condition. *)

let smtlib_of_wa p = 
  let declare_invariant n =
    "; synthèse d'invariant de programme\n"
    ^"; on déclare le symbole non interprété de relation Invar\n"
    ^"(declare-fun Invar (" ^ string_repeat "Int " n ^  ") Bool)" in
  let loop_condition p =
    match p with
    | { nvars=n; mods=mods; loopcond=lc } -> 
    let temp = "\n\t(=> (and (Invar" ^ string_of_vars 1 n ^") " ^ str_of_test lc ^") " ^ str_condition mods ^ ")" in
    "; la relation Invar est un invariant de boucle\n"
    ^(str_assert_forall n temp) in
  let initial_condition p =
    "; la relation Invar est vraie initialement\n"
    ^str_assert (str_condition p.inits) in
  let assertion_condition p =
    match p with 
    | { nvars=n; loopcond=lc; assertion=assertion } ->
    let temp = "\n\t(=> (and (Invar" ^ string_of_vars 1 n ^") " ^ str_of_nottest lc ^") " ^ (str_of_test assertion) ^ ")" in
    "; l'assertion finale est vérifiée\n"
    ^(str_assert_forall n temp) in
  let call_solver =
    "; appel au solveur\n(check-sat-using (then qe smt))\n(get-model)\n(exit)\n" in
  String.concat "\n" [declare_invariant p.nvars;
                      initial_condition p;
                      loop_condition p;
                      assertion_condition p;
                      call_solver]

let p1 = {nvars = 2;
          inits = [(Const 0) ; (Const 0)];
          mods = [Add ((Var 1), (Const 1)); Add ((Var 2), (Const 3))];
          loopcond = LessThan ((Var 1),(Const 3));
          assertion = Equals ((Var 2),(Const 9))}

(* Question 5. Vérifiez que votre implémentation donne un fichier
   SMTLIB qui est équivalent au fichier que vous avez écrit à la main
   dans l'exercice 1. Ajoutez dans la variable p2 ci-dessous au moins
   un autre programme test, et vérifiez qu'il donne un fichier SMTLIB
   de la forme attendue. *)

let p2 = {
  nvars = 3;
  inits = [Const 0; Const 0; Const 10];
  mods=[Add(Var(1), Const(1)); Add(Var(2), Const(2)); Add(Var(3), Const(1))];
  loopcond = LessThan(Mult(Const(2),Var(1)),Var(3));
  assertion = LessThan ((Var 1),(Var 2));
}


let () = Printf.printf "%s" (smtlib_of_wa p2)