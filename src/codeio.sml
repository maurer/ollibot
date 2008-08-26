structure CodeIO = struct

open IntSyn
structure A = Approx
structure E = ExtSyn
structure P = ParsedSyn

val typ_process : Pos.pos -> ExtSyn.typ -> IntSyn.typ = 
 fn pos =>
 let
   val fold_apx = 
    fn A.Unknown _ => raise Global.Error("Unable to infer type", pos)
     | A.Arrow(t1,t2) => T.inj(TArrow(t1, t2))
     | A.Const cid => T.inj(TBase cid)

   val fold_typ = 
    fn E.TBase cid => T.inj(TBase cid)
     | E.TArrow(t1, t2) => T.inj(TArrow(t1, t2))
     | E.TApprox apx => A.fold fold_apx apx 
 in 
   E.T.fold fold_typ
 end

val knd_process : Pos.pos -> ExtSyn.knd -> IntSyn.knd = 
 fn pos =>
 let
   val fold_knd = 
    fn E.KType knd => K.inj(KType knd)
     | E.KArrow(typ, knd) => K.inj(KArrow(typ_process pos typ, knd))
     | E.KPi _ => raise Global.Error("No dependent pi's in kinds", pos)
 in
   E.K.fold fold_knd
 end


val load_file =
 fn filename =>
    let 
      val parse_decl = 
       fn (P.Decl(NONE,e), pos) =>
          let
            val {exp, freevars} = ReconApprox.parsedsyn_to_extsyn e
          in
            print "Anonymous declaration found, ignoring...\n"
          end
        | (P.Decl(SOME s, e), pos) =>
          let
            val {exp, freevars} = ReconApprox.parsedsyn_to_extsyn e
          in
            case exp of 
              ReconApprox.ExpRule _ => 
              print ("Rule " ^ s ^ " found...\n")
            | ReconApprox.ExpType typ => 
              let 
                val typ = typ_process pos typ
                val cid = Sig.install(ConDec{id = s, typ = typ})
              in
                print ("Constant " ^ s ^ " declaration installed...\n")
              end
            | ReconApprox.ExpKind knd => 
              let
                val knd = knd_process pos knd
                val cid = Sig.install(TypDec{id = s, knd = knd})
              in
                print ("Type " ^ s ^ " declaration installed...\n")
              end
            | ReconApprox.ExpTerm _ =>
              print ("Terms cannot be declared, ignoring...")
          end
        | (P.Defn(s, e), pos) =>
           let 
             val {exp, freevars} = ReconApprox.parsedsyn_to_extsyn e
           in
             case exp of
               ReconApprox.ExpType typ =>
               let 
                 val typ = typ_process pos typ
                 val cid = Sig.install(TypAbbrev{id = s, typ = typ, knd = K.inj(KType NONE) (* XXX DANGER DOESN'T HANDLE RULES *)})
               in 
                 print ("Type abbreviation " ^ s ^ " installed...\n")
               end
             | _ => print "Unsupported abbreviation, ignoring..."
           end
      fun load (decl, stream) = 
          case decl of 
            NONE => print ("Done loading " ^ filename ^ "\n")
          | SOME decl =>
            (parse_decl decl; load(ParseBracket.parseonce stream))
      val tokenstream = ParseBracket.tokenize filename
    in 
      Sig.reset();
      load(ParseBracket.parseonce tokenstream) 
      handle Global.Error(msg,pos) =>
             print ("Error : " ^ Pos.toString pos ^ "\n" ^ msg ^ "\n") 
    end

end