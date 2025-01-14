uses dos;

procedure cursor(i:integer);
  const
    cur_set : array[1..15,1..2] of integer =
      ((0,7),(1,7),(2,7),(3,7),(4,7),(5,7),(6,7),(7,7),(3,4),(2,5),(1,6),
       (7,0),(6,1),(5,2),(4,3));
  var regs : registers;

  begin
    if not (i in [1..15]) then i:=2;
    with regs do begin
      ax:=$0100; { set function } cx:=cur_set[i,1]*256+cur_set[i,2]; {cur val}
    end;
    intr($10,regs); { do it }
  end;


  var i,e : integer;
  begin
    writeln('CURSOR');
    i:=2;
    val(paramstr(1),i,e);
    cursor(i);
  end.