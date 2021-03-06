Require Import List.
Require Import BinPosDef.

Require Import compcert.lib.Integers.
Require Import common.HaskellValues.

Require Import GHC.CmmExpr.
Require Import GHC.CmmType.
Require Import GHC.CmmMachOp.

Require Import CmmType_sem.

(* Remove the following imports when we switch to comcert memory *)
Require Import compcert.common.Values.
Require Import heap.

(* FIXME: Implement all literals *)
Definition cmmLitDenote (l : CmmLit) : hval :=
  match l with
  | CmmInt n width => match width with
                      | W64 => HSint (Int64.repr n)
                      | _ => HSundef
                      end
  | _ => HSundef
  end.

Definition moDenote (mo : MachOp) (ps : list hval) : hval :=
  match mo,ps with
  | MO_Add W64, v1::v2::nil => HaskellVal.add v1 v2
  | MO_Sub W64, v1::v2::nil => HaskellVal.sub v1 v2
  | MO_Eq W64, v1::v2::nil => HaskellVal.cmp Ceq v1 v2
  | MO_Ne W64, v1::v2::nil => HaskellVal.cmp Cne v1 v2
  | MO_Mul W64, v1::v2::nil => HaskellVal.mul v1 v2
  | _, _ => HSundef
  end.

Definition from_block (b : block) : ptr :=
  pred (Pos.to_nat b).

Definition from_CmmType (t: CmmType) (v: cmmTypeDenote t) : hval :=
  (match t return cmmTypeDenote t -> hval with
   | CT_CmmType BitsCat W64 => fun v => HSint v
   | _ => fun _ => HSundef
   end) v.

Definition read_heap (p : hval) (h : heap) : option hval :=
  match p with
  | HSptr blk _ => match lookup (from_block blk) h with (* ignore offset for now *)
                   | None => None
                   | Some v => match v with
                               | existT t' v' => Some (from_CmmType t' v')
                               end
                   end
  | _ => None
  end.

(* FIXME: Implement all expressions *)
Fixpoint cmmExprDenote (h : heap) (e : CmmExpr) : hval :=
  match e with
  | CE_CmmLit l => cmmLitDenote l
  | CE_CmmLoad e' t => match read_heap (cmmExprDenote h e') h with
                       | None => HSundef
                       | Some v => v
                       end
  | CE_CmmMachOp mo ps => moDenote mo (List.map (cmmExprDenote h) ps)
  | _ => HSundef
  end.
