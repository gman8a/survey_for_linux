program communicator;

{$DEFINE back_ground_spool}

uses crt,comm,commenu,basics2,xception;

var com_str : string;

begin
  if catch(Exception) = ExceptionUsed then
    begin writeln; writeln('*** XCEPTION CAUGHT ***');
      com_IRQ(c1,off); com_IRQ(c2,off);
      exit;
    end;

  screen(white,black);
  writeln('Communicator by Gary Argraves - 8903.04');
  writeln;
  set_com(c1,0); set_com(c2,0);
  com_str:=paramstr(1);

  repeat
    writeln;
    response:=command(com_str);
    if response=' ' then quest2(0,0,'[C]omm   [Plot   [D]one ? ',['P','C','D'],true);
    case response of
      'C':com_menu(com_str);
      'P':plot_menu(paramstr(2),com_str);
    end{case};
  until not (c_ptr[c1].o_que or c_ptr[c2].o_que) and (response='D');
end.