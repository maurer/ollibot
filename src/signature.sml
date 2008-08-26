

functor Signat(I : INT_SYN) = struct

structure I = I

local
  structure Str = struct type ord_key = string val compare = String.compare end
  structure MapS = SplayMapFn(Str)
  structure MapC = SplayMapFn(I.Cid)
  val map_forward : I.cid MapS.map ref = ref MapS.empty
  val map_backward : string MapC.map ref = ref MapC.empty
  val signat : I.signat ref = ref I.sgnEmpty
in
fun string_to_cid s = MapS.find(!map_forward, s)
fun cid_to_string c = MapC.lookup(!map_backward, c)
fun lookup c = I.sgnLookup(!signat, c)
fun install dec = 
    let 
      val name = I.dec_id dec
      val (newsig, cid) = I.sgnAdd(!signat,dec)
    in 
      map_forward := MapS.insert(!map_forward, name, cid);
      map_backward := MapC.insert(!map_backward, cid, name);
      signat := newsig;
      cid
    end
fun reset() = (map_forward := MapS.empty; map_backward := MapC.empty; signat := I.sgnEmpty)
end (* local *)

end

structure Sig = Signat(IntSyn)