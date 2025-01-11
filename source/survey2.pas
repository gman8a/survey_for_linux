unit survey2;
interface
uses dos,crt,survey0,basics2;

procedure lrn_end;
procedure menu;
procedure browse;
procedure pt_pt;
procedure shell;

implementation

procedure shell;
  var i:integer;
Begin
  mode('SHELL to DOS');
{$if 1=0}
  flush_pt_file;
  write('  Enter DOS Command > ');
  if (copy(shell_str,1,3)<>'ell') and (shell_str<>'') then
    begin s:=shell_str; write(shell_str); end
  else begin s:=''; key:=0; get_no_str; end;
  writeln;
  if s='' then writeln('  Type  EXIT  to Return to PC-Turbo Survey')
  else s:='/C '+s;
  i:=pos('%1',s);
  if i>0 then begin delete(s,i,2); insert(copy(fn,1,length(fn)-3),s,i); end;
  exec(chr(com_drv+65)+':\command.com',s);
  with regs do begin ax:=$0100; cx:=$107; end; { set cursor back to 2 value }
  intr($10,regs); { do cursor set it }
{$endif}
End;

procedure lrn_end;
  begin if learn then close(lrn_file); learn:=false; end;

procedure menu;
  var i,j,k,l  : integer;
  menu_no      : integer;
  help_file    : text;
  x,y          : real;
  con_file     : text;
  w_str        : str16; { work string }

procedure help;
  var a       : string[110];  { read line from help file }
      help_cnt: integer;
      ln_cnt  : integer;
  begin
    mode('PC-TS HELP');  write('  ...Wait');
    clreos;
    if exist('HELP.DOC') then
      begin
        assign(help_file,'HELP.DOC'); reset(help_file);
        assign(con_file,'/dev/stdout'); rewrite(con_file);
        help_cnt:=0;
        ln_cnt:=0;
        gotoxy(1,1);
        while (not eof(help_file)) and (help_cnt<=menu_no) do
          begin
            readln(help_file,a);
            if pos('::',a)>0 then
              begin inc(help_cnt); if help_cnt=menu_no then clreol; end;
            if help_cnt=menu_no then
              begin
                writeln(con_file, a + chr(13) );
                ln_cnt:=ln_cnt+1;
                if (ln_cnt=24) and (menu_no>1) then
                  begin
                    textcolor(cyan); write(press,^M); ln_cnt:=keyin;
                    textcolor(yellow);
                    clreol;
                    ln_cnt:=0;
                  end;
              end;
          end;
        close(help_file);
        close(con_file);
        textcolor(cyan);
      end
    else cnff('HELP.DOC');
  end;

  begin
    menu_no:=1; script_no:=0; shell_str:='';
      repeat
        gotoxy(1,25); clreol;
        screen(black,white); write(' ',copy(when,1,19),' ');
        screen(white,red);   write(' ',copy(fn,1,length(fn)-3),' ');
        textbackground(green);
        write(' ReCalc:'); if recalc   then write('ON') else write('OFF');
        write(' Prn:');    if lst_flag then write('ON ') else write('OFF ');
        textbackground(black); write(' No_Pts=',no_pts);
        textbackground(blue);
//        if c_ptr[plt_port].o_que then write(' Spool:',plt_rec_cnt,' ');
        screen(blink+cyan,black);
        if cogo_err then
          begin
            write(' COGO-ERR');
            if lst_flag then
              begin
                  write(lst,'COGO-ERR');
                  if act_script>0 then write(lst,' *** SCRIPT CANCELED ***');
                  writeln(lst);
              end;
            while (act_script>0) and not learn do
              begin close(script_file[act_script]); dec(act_script); end;
            act_if[0]:=0;
            act_script:=0;
            con_flag:=false;
          end;
        if learn then write(' LEARN ')
        else if act_script>0 then write(' SCRIPT ');
        if act_if[act_script]>0 then
          if else_arr[act_script,act_if[act_script]] then write(' ELSE-L',act_if[act_script])
          else write(' THEN-L',act_if[act_script]);
        cogo_err:=false;
        textcolor(yellow);
        gotoxy(73,25); write('?/Help');
        con_color:=white;
        option:='  ';
        {num_lock(off);}
{$if 1=0}
        purge(dig_port);
        if act_script=0 then
          repeat fill_bufo(plt_port);
          until com_chr_ready(dig_port) or keypressed;
        if dig_flag and com_chr_ready(dig_port) then
          begin
            dig_get(i,x,y);
            if (men_but_flg) and (men_but<60) then
              option:=copy(option_set,(men_but-1)*2+1,2);
          end
        else
{$endif}
          begin
            i:=0; j:=0;
            i:=keyin;
            if (i=47) or (i=63) then { ? or / }
              begin gotoxy(1,19); clreos;
                    writeln('F1-10 1st set      <Ctrl>F1-10 2nd      <Alt>F1-10 3rd     <Shift>F1-10 4th');
                    screen(yellow,blue);
                    for k:=1 to 10 do write(' F',k,' ':5);
                    gotoxy(1,21); screen(lightgreen,black);
                    for k:=1 to 4 do writeln(f_keys[k]);
                    screen(white,black); write('Press ?-key for HELP.');
              end
            else
              begin gotoxy(73,25); clreol; textcolor(white); write('Key: ',upcase(chr(i))); end;

            if (i<570) { and not (i in [47,63]) } then j:=keyin;
            if j>570 then i:=j;
            write(upcase(chr(j)));

            if ((i>595) and (i<626)) or ((i>570) and (i<581)) then
              begin k:=0; j:=0;
                    case i of
                      571..580:l:=1;
                      606..615:l:=2;
                      616..625:l:=3;
                      596..605:l:=4;
                    end{case};

                    { if i<581 then l:=1 else if i<616 then l:=2 else l:=3; }

                    case l of 1:i:=i-570; 2:i:=i-605; 3:i:=i-615; 4:i:=i-595; end{case};
                    repeat inc(k);
                      if f_keys[l][k] in ['A'..'Z','|'] then inc(j);
                    until (j=2*i) or (k>=length(f_keys[l]));
                    if j=2*i then { yes we have a function key }
                      begin i:=ord(f_keys[l][k-1]);
                            j:=ord(f_keys[l][k]);
                      end
                    else i:=32;
                    if (i=82) and (j=83) then
                      val(copy(f_keys[l],k+1,2),script_no,l)
                    else if (i=83) and (j=72) then {chk SHell }
                      begin
                        w_str:=copy(f_keys[l],k+1,10); k:=0;
                        repeat inc(k);
                        until (w_str[k] in ['A'..'Z','|']) or (k>=length(w_str));
                        if not (w_str[k] in ['A'..'Z','|']) then inc(k);
                        shell_str:=copy(w_str,1,k-1);
                      end;
              end
            else if (i in [47,63]) and (j in [47,63])  then
              begin menu_no:=1; help;
                    screen(white,black); write('Enter HELP Screen No. ? ');
                    menu_no:=read_i(1);
                    if menu_no>1 then help;
              end;
            if (i<256) and (j<256) then
              begin
                option[1]:=upcase(chr(i));
                if j<91 then option[2]:=chr(j+32) else option[2]:=chr(j);
              end;
          end;
      until pos(option,option_set)>0;
      gotoxy(1,24);
  end;

procedure browse;
  var
    pt,i   : integer;
    pt_rec : point;
    key    : integer;
    all    : boolean;
const
    c      : array[1..4] of integer = (3,10,14,12);

begin
  all:=false;
  pt:=1;
  repeat
    mode('BROWSE Points');
    write('  Enter Pt# ? ');
    input_i(pt);
    screen(lightcyan,black);
    write('  <ESC>=Exit, <TAB>=New Pt#  <SPACE>=mode');
    repeat
      gotoxy(1,2); clreos;
      if all then begin
        for i:=pt to pt+3 do
          if (i<=no_pts) and (pt>=1) then
            begin
              get(i,pt_rec);
              display_rec(i,2+(i-pt)*6,c[i+1-pt],white,pt_rec);
            end;
        key:=keyin;
        case key of
           585:pt:=pt-4;
           593:pt:=pt+4;
           592:pt:=pt+1;
           591:pt:=no_pts-3;
           584:pt:=pt-1;
           583:pt:=1;
            32:all:=not all;
         end{case};
         if pt>no_pts then pt:=no_pts-3;
      end
      else begin
        screen(yellow,black);
        writeln('PT#  Fr_Pt BS_pt SU    Description        Northing     Easting      Elev.');
        writeln('==== ===== ===== == ==================== =========== =========== ===========');
        screen(white,black);
        for i:=pt to pt+20 do
          if (i<=no_pts) and (pt>=1) then
            begin
              get(i,pt_rec);
              gotoxy(1,i-pt+4);
              with pt_rec do begin
                write(i:4,from_pt:6,bs_pt:6);
                if setup=true then write('Y':3) else write('N':3);
                write(descrip:21,north:12:3,east:12:3,elev:12:3);
              end;
            end;
        key:=keyin;
        case key of
           585:pt:=pt-21;
           593:pt:=pt+21;
           592:pt:=pt+1;
           591:pt:=no_pts-20;
           584:pt:=pt-1;
           583:pt:=1;
            32:all:=not all;
         end{case};
         if pt>no_pts then pt:=no_pts-21;
      end;
      if pt<1 then pt:=1;
    until key in [27,9];
  until key<>9;
end;

procedure pt_pt;
  var
    pt1,pt2 : integer;
    d       : real;
    asz     : str16;
    pt_rec  : point;

  begin
    mode('Point/Point Calculation');
      pt1:=9999; pt2:=9999;
      write('  Enter FROM '); pt1:=dig_point; { input_i(pt1); }
      write('   Enter TO ');  pt2:=dig_point; { input_i(pt2); }
      if (pt1<=no_pts) and (pt2<=no_pts) then
        begin
          get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
          get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
          textcolor(white);
          pt_to_pt(pt1,pt2,d,asz);
          gotoxy(3,15);   write('Aszmith:  ',asz);
          gotoxy(32,15);  write('Distance: ',d:10:4);
          gotoxy(3,16);   write('Bearing: ',rad_bear(asz_rad(asz)));
          roll_asz(asz);
          roll_real(d);
          if lst_flag then
            writeln(lst,' Pt#',pt1:4,' Pt#',pt2:4,'  Az:',asz,'  D=',d:10:4,'  Bear:',rad_bear(asz_rad(asz)));
        end
      else begin gotoxy(5,16); bad_pt_msg; cogo_err:=true; end;
  end;

end.
