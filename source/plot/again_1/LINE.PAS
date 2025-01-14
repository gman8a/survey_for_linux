var co : text;

procedure line(lt,pen:integer; lw,x:real);
begin
  pen:=(abs(pen) mod 4) + 1 ;
  writeln(co,'SP',pen:2,';');
  writeln(co,'LT ',lt:2,',',lw:6:2,';');
  writeln(co,'PU ',x:7:2,',-5000;');
  writeln(co,'PD ',x:7:2,',0;');
end;


var lt   : integer;
    lw,x : real;

begin
  assign(co,'COM1'); rewrite(co);
  writeln(co,^[,'.(  ',^[,'.P3;  IN; DF;');
  writeln(co,',SP1;');
  x:=-10000;
  for lt:=-7 to 7 do
    begin
      lw:=4;
      repeat
          x:=x+150;
          line(lt,lt,lw,x);
          write(^M,'LT=',lt:2,'  LW=',lw:6:2);
          lw:=lw-0.333;
      until lw<0.3;
    end;
  writeln(co,'PU -10000,-6000;');
  writeln(co,^[,'.)');
  close(co);
end.
