unit survey0;
interface
uses crt,dos,basics2;

var
 dig_flag      : boolean;        { digitizer connected and functioning }
 def_term_port : integer;

{$I SURVEYV}
{$I SURVEY00}

procedure mode(m_line:string);
  begin
    clrscr; gotoxy(1,1); screen(red,green);
    write(m_line); screen(white,black);
    if act_script>0 then
      begin
        textcolor(blink+cyan);
        write(' SCRIPT-L',act_script:1,' ');
        textcolor(cyan); con_color:=cyan;
      end;
    if learn then
      begin
        textcolor(blink+lightgreen);
        write(' LEARN ');
        textcolor(lightgreen); con_color:=lightgreen;
      end;
    if act_if[act_script]>0 then
      begin
        textcolor(blink+yellow);
        if else_arr[act_script,act_if[act_script]] then  write(' ELSE-L',act_if[act_script]:1)
        else write(' THEN-L',act_if[act_script]:1);
        textcolor(yellow); con_color:=yellow;
      end;
  end;

procedure rotate(var x,y:real; x2,y2:real; rot_ang:real);
 var r,th :real;  { rotates Local rot_ang }
  begin
    x:=x-x2;
    y:=y-y2;
    r:=sqrt(x*x+y*y);  { rotate coordinates }
    if x<>0 then th:=arctan(abs(y/x)) else th:=pi/2;
    if x<0 then if y>0 then th:=pi-th else th:=pi+th
    else if y<0 then th:=2*pi-th;
    x:=cos(rot_ang*pi/180+th)*r;  { translate }
    y:=sin(rot_ang*pi/180+th)*r;
    x:=x+x2;
    y:=y+y2;
  end;

procedure roll_real(r:real);
  begin
    if last_alt_locr>0 then real_os:=trunc(int((last_alt_locr-1)/10)*10);
    case add_flag of
         0:last_alt_real[last_alt_locr]:=r;
       1,2:begin
             if add_flag=2 then r:=-r;
             last_alt_real[last_alt_locr]:=last_alt_real[last_alt_locr]+r;
           end;
       3,4:begin
             if add_flag=4 then if r<>0 then r:=1/r else r:=1;
             last_alt_real[last_alt_locr]:=last_alt_real[last_alt_locr]*r;
           end;
    end{case};
    last_alt_locr:=0;
    if roll_flag then
      begin
        for j:=10 downto 2 do last_real[j]:=last_real[j-1];
        last_real[1]:=abs(r);
      end;
  end;

procedure roll_int(i:integer);
  var i2 : real;
  begin
    if last_alt_loci>0 then int_os:=trunc(int((last_alt_loci-1)/10)*10);
    case add_flag of
         0:last_alt_int[last_alt_loci]:=i;
       1,2:begin
             if add_flag=2 then i:=-i;
             last_alt_int[last_alt_loci]:=last_alt_int[last_alt_loci]+i;
           end;
       3,4:begin
             i2:=i;
             if add_flag=4 then if i<>0 then i2:=1/i else i2:=1;
             last_alt_int[last_alt_loci]:=round(last_alt_int[last_alt_loci]*i2);
           end;
    end{case};
    add_flag:=-1;
    last_alt_loci:=0;
    if roll_flag then
      begin
        for j:=9 downto 2 do last_int[j]:=last_int[j-1];
        last_int[1]:=i; last_int[10]:=no_pts;
      end;
  end;

procedure get_no_str;
  begin
    while key<>13 do begin
        if (key in [32..128]) and (length(s)<25) then
          begin s:=s+chr(key);
                if length(s)<15 then write(chr(key));
          end;
        if (key=8) and (length(s)>0) then
          begin delete(s,length(s),1); write(^H,' ',^H); end;
        key:=keyin;
    end;
    s2:=s;
  end;

procedure chk_no_err;
  begin
    if inp_err<>0 then
      begin msg(40,'? '+s2); gotoxy(x,y);
         write(' ':trunc(min(k,15)));
         gotoxy(x,y);
         sound(150); delay(65); nosound;
      end;
    s:=''
  end;

procedure store_msg; { display store meggage }
  begin str(key-615:1,s2);
        s2:=' '+^X+' F'+s2;
        if act_script=0 then s2:=s2+^G;
        case add_flag of
          0:msg(29,'Put'+s2);
          1:msg(29,'Add'+s2);
          2:msg(29,'Sub'+s2);
          3:msg(29,'Mul'+s2);
          4:msg(29,'Div'+s2);
        end{case}
  end;

function keyin3:integer;
  var k:integer;
  begin
    repeat k:=keyin; until k in [32,42,43,45,47..57,61,65,76,82,97,108,114];
    keyin3:=k;
  end;

procedure get_3key;
  var x,y :integer;
      i: integer;
  begin
    whereXY(x,y);
    s2:='Put '; if (key=7) or (key=593) then s2:='Get ';
    if key=614 then msg(29,'No_Pts-???') else msg(29,s2+^X+' F???');
    gotoxy(37,25);
    {num_lock(on);}
    s2:='';
    for i:=1 to 3 do begin s2:=s2+chr(keyin3); write(s2[length(s2)]); end;
    gotoxy(x,y);
  end;

procedure get_register;
  var i:integer;
  begin
    get_3key;
    if (key<>7) and (key<>593) then
      begin
        add_flag:=0;
        if pos('+',s2)>0 then add_flag:=1
        else if pos('-',s2)>0 then add_flag:=2
             else if pos('*',s2)>0 then add_flag:=3
                  else if pos('/',s2)>0 then add_flag:=4;
      end;
    for i:=length(s2) downto 1 do
      if s2[i] in ['+','-','=','/','*',' '] then delete(s2,i,1);
  end;

procedure parse_s;
  begin
   k:=length(s); for j:=k downto 1 do if s[j]=' ' then delete(s,j,1);
   con_flag:=true;
  end;

procedure reset_con;
  begin con_flag:=false; screen(con_color,black); end;

procedure get_key1;
  begin key:=keyin; s:=''; screen(black,white); end;

procedure write_real;
  begin str(r2:11:4,s); write(r2:10:4); end;

procedure input_r(var r:real);
  var r_hold : real;
  begin
     r_hold:=r;
     whereXY(x,y);
     if not keypressed and reg_disp_flg then begin
       gotoxy(1,22); screen(cyan,black); clreos;
       for m:=1 to 10 do write(real_os+m:5,'   ');
       gotoxy(1,23); clreos; screen(white,red);
       for j:=real_os+1 to real_os+10 do begin write(last_alt_real[j]:7:1); gotoxy(wherex+1,23); end;
       gotoxy(1,24); textbackground(blue);
       for j:=1 to 10 do begin write(last_real[j]:7:1); gotoxy(wherex+1,24); end;
     end;
     gotoxy(x,y);
     add_flag:=-1;
     repeat
       repeat
         get_key1;
         case key of
           571..580:begin r2:=last_real[key-570]; write_real; end;
           596..605:begin r2:=last_alt_real[key-595+real_os]; write_real;
                    end; { Shft f1-f10   Recall }
           616..625:begin last_alt_locr:=key-615+real_os;
                          add_flag:=(add_flag+1) mod 5;
                          store_msg;
                    end; { Alt  f1-f10   Store  }
             16,585:begin {Page Up}
                       get_register; val(s2,last_alt_locr,j);
                       if (j>0) or (last_alt_locr>100) then last_alt_locr:=0;
                    end;
              7,593:begin {Page Down }
                      get_register; val(s2,j,m);
                      if (m=0) and (j>0) then
                        r2:=last_alt_real[j] else r2:=0;
                      write_real;
                    end;
           else get_no_str;
         end{case};
       until (key<>16) and (key<>585) and (key<616);
       if not r2_flag then
         begin parse_s; val(s,r,inp_err);
               if (s='') and (inp_err>0) then begin inp_err:=0; r:=r_hold; end;
               chk_no_err;
               if inp_err=0 then roll_real(r);
         end;
     until (inp_err=0) or r2_flag;
     reset_con;
  end;

procedure input2_r(var r:real);
  var r_hold : real;
  begin
     r_hold:=r;
     r2_flag:=true;
     repeat
       input_r(r);
       dist_type:=' ';
       k:=length(s);
       for i:=1 to k do s[i]:=upcase(s[i]);
       for i:=1 to k do
         if s[i] in ['R','P','E','H','B'] then {Rod Prisim Edm Horz or Hold}
           begin dist_type:=s[i]; s[i]:=' '; end;
       parse_s; val(s,r,inp_err);
       if (s='') and (inp_err>0) then begin inp_err:=0; r:=r_hold; end;
       chk_no_err;
     until inp_err=0;
     reset_con;
     r2_flag:=false;
  end;

procedure display_int;
    begin
      whereXY(x,y);
      if not keypressed and reg_disp_flg then begin
        gotoxy(1,22); screen(cyan,black); clreos;
        for m:=1 to 10 do write(int_os+m:5,'   ');
        screen(white,red); gotoxy(1,23);
        for j:= int_os+1 to int_os+10 do
          begin write(last_alt_int[j]:5,' '); gotoxy(wherex+2,23); end;
        gotoxy(1,24); textbackground(blue);
        for j:= 1 to 10 do
          begin write(last_int[j]:5,' '); gotoxy(wherex+2,24); end;
      end;
      gotoxy(x,y);
   end;

procedure first_key_action;
  begin
      repeat
         get_key1;
         case key of
           571..580:begin j:=last_int[key-570]; str(j:5,s); write(j:4); end;
           606..615:begin j:=no_pts-key+605; { ctrl F1-F10 Recall }
                          if key=615 then j:=no_pts;
                          if key=614 then
                            begin get_register; val(s2,j,m);
                                  j:=no_pts-j;
                            end;
                          if j>0 then begin str(j:5,s); write(j:4); end;
                    end;
           596..605:begin j:=last_alt_int[key-595+int_os]; str(j:5,s); write(j:4);
                    end; { Shft f1-f10   Recall }
           616..625:begin last_alt_loci:=key-615+int_os;
                          add_flag:=(add_flag+1) mod 5;
                          store_msg;
                    end; { Alt  f1-f10   Store  }
             16,585:begin {pageUp}
                       get_register; val(s2,last_alt_loci,j);
                       if (j>0) or (last_alt_loci>100) then last_alt_loci:=0;
                    end;
              7,593:begin {page down }
                      get_register; val(s2,j,m);
                      if (m=0) and (j>0) then j:=last_alt_int[j]
                      else j:=9999;
                      str(j:5,s); write(j:4);
                    end;
           else get_no_str;
         end{case};
      until (key<>16) and (key<>585) and (key<616);
  end;

procedure input_i(var i:integer);
  var i_hold,p : integer;
  begin
    i_hold:=i;
    display_int;
    repeat
      first_key_action;
      p:=pos('B',s); if p=0 then p:=pos('b',s);
      if p>0 then begin dist_type:='B'; s[p]:=' '; end;
      parse_s;
      val(s,i,inp_err);
      if (s='') and (inp_err>0) then begin inp_err:=0; i:=i_hold; end;
      chk_no_err;
    until inp_err=0;
    roll_int(i);
    reset_con;
  end;

procedure input_des(var des:str20);
  var
    key  : integer;
    pos  : integer;
    pos2 : integer;
    x,y,j: integer;
    i    : integer;
    r,r2 : real;
    des2 : string[8];

     procedure move_pos;
       begin
         if pos<1 then pos:=1 else if pos>20 then pos:=20;
         gotoxy(x+pos-1,y);
       end;

  procedure display_des;
    var j:integer;
     begin
          gotoxy(68,22); clreos; writeln(' ',^X,'F1-9 Save');
          for j:=1 to 9 do
           begin
             if j=4 then gotoxy(1,24)
             else if j=7 then gotoxy(1,25);
             screen(white,red);
             if j=9 then textbackground(green);
             write(last_des[j]);
             textbackground(black);
             i:=length(last_des[j]);
             while i<23 do begin write(' '); inc(i); end;
             if j=3 then write('Cursor Keys')
             else if j=6 then write('TAB-Clear');
           end;
         write('F10-Roll');
         screen(con_color,black);
     end;

  procedure shorten;
    begin while des[length(des)]=' ' do delete(des,length(des),1); end;

  begin
   whereXY(x,y);
   repeat
     last_des[9]:=des; last_des[10]:=''; if des_disp_flg then display_des;
     pos:=1; move_pos; write(des); move_pos;
     repeat
       while length(des)<20 do des:=des+' ';
       key:=keyin;
       case key of
           32..126:begin
                     des[pos]:=chr(key);
                     write(chr(key));
                     pos:=pos+1;
                     move_pos;
                   end;
                  8:if pos>1 then
                       begin
                          pos:=pos-1;
                          delete(des,pos,1);
                          move_pos;
                          write(copy(des,pos,21-pos),' ');
                          move_pos;
                        end;
                  595:begin
                          delete(des,pos,1);
                          write(copy(des,pos,21-pos),' ');
                          move_pos;
                       end;
                 594:begin {insert }
                       insert(' ',des,pos);
                       write(copy(des,pos,21-pos));
                       move_pos;
                     end;
                 589:begin inc(pos); move_pos; end; { right }
                 587:begin dec(pos); move_pos; end; { left }
                 583:begin pos:=1; move_pos end; { home }
                 591:begin  { end }
                       pos:=20;
                       while (des[pos]=' ') and (pos>1) do pos:=pos-1;
                       pos:=pos+1;
                       move_pos;
                     end;
                 580:begin { roll description }
                        shorten;
                        last_des[9]:=des;
                        for j:=10 downto 2 do last_des[j]:=last_des[j-1];
                        last_des[1]:=last_des[10];
                        display_des;
                        move_pos;
                     end;
            596..604:begin  { Save Description in Storage }
                       shorten;
                       last_des[key-595]:=des;
                       display_des;
                       move_pos;
                     end;
          9,571..579:begin if key=9 then key:=580;
                        des:=last_des[key-570];
                        pos:=1; move_pos;
                        while pos<21 do begin write(' '); inc(pos); end;
                        pos:=1; move_pos; write(des);
                        move_pos;
                     end;
              593,18:begin { ^R or page down }
                       pos2:=pos; pos:=1; r:=0;
                       repeat
                         move_pos; clreol; write('Real# ? ');
                         r2:=r; r:=0; input_r(r);
                       until r=0;
                       str(r2:11:2,des2);
                       while des2[1]=' ' do delete(des2,1,1);
                       insert(des2,des,pos2);
                       move_pos; clreol; write(des); move_pos;
                     end;
       end{case};
     until key=13;
     shorten;
     if des='' then des:='?';
     if (des[1]=':') or (des[1]=';') then con_flag:=true;
   until (des[1]<>':') and (des[1]<>';');
   reset_con;
   gotoxy(1,22); clreos;
   gotoxy(x+20,y);
  end;


{ ************** BEARING - ASZMITH  Transformation Functions ************** }

function Asz_Rad (asz: str16)  : real;

  var
    i,j,k    : integer;
    a1,a2    : integer;
    a3,a4    : real;
    //ch       : char;

  procedure chk_asz_err;
    begin if j>0 then asz_err:=true; end;

  begin
    asz_err:=false;
    a1:=0; a2:=0; a3:=0;
    while copy(asz,1,1)=' ' do delete(asz,1,1);  { leading spaces }
    if length(asz)>0 then
      begin
        while copy(asz,length(asz),1)=' ' do delete(asz,length(asz),1); { trailing }
        for i:=1 to length(asz) do if not (asz[i] in ['-','.','0'..'9',' ']) then asz_err:=true;
        if (asz[1]='-') or (asz[length(asz)]='-') then asz_err:=true;
        if not asz_err then
          begin
            i:=pos('-',asz);
            if i>0 then
              begin
                k:=i-1;
                while (copy(asz,k,1)=' ') and (k>1) do k:=k-1;
                val(copy(asz,1,k),a1,j); chk_asz_err;
                delete(asz,1,i);
                while copy(asz,1,1)<'0' do delete(asz,1,1);
                i:=pos('-',asz);
                if i>0 then
                  begin
                    k:=i-1;
                    while (copy(asz,k,1)=' ') and (k>1) do k:=k-1;
                    val(copy(asz,1,k),a2,j); chk_asz_err;
                    delete(asz,1,i);
                    while copy(asz,1,1)<'0' do delete(asz,1,1);
                    val(asz,a3,j); chk_asz_err;
                  end
                else begin val(asz,a2,j); chk_asz_err; end;
              end
            else begin val(asz,a1,j); chk_asz_err; end;
          end;
      end
    else asz_err:=true;
    if asz_err then begin a4:=0; write(^G); end
    else a4:=(a1+a2/60+a3/3600)*pi/180;
    while a4>2*pi do a4:=a4-2*pi;
    asz_rad:=a4;
  end;

function Bear_Rad(bear :str16) : real;
  var
    a1 : real;
    i  : integer;
  begin
    asz_err:=false;
    for i:=1 to length(bear) do bear[i]:=upcase(bear[i]);
    if length(bear)>2 then
      if (bear[1] in ['0'..'9']) and (bear[2] in ['0'..'9']) and
         (bear[3] in ['0'..'9']) then
           case bear[1] of
              '1':bear[1]:='\';
              '2':bear[1]:=']';
              '3':bear[1]:='[';
              '4':bear[1]:='=';
             else bear[1]:='\';
           end{case};
    i:=pos('.',bear);
    if (i>0) and (pos('-',bear)=0) then
      begin
        bear[i]:='-';
        if length(bear)>i+2 then
          if bear[i+3] in ['0'..'9'] then insert('-',bear,i+3);
      end;
    if pos('=',bear)>0 then bear:=bear+'NW'
    else if pos('\',bear)>0 then bear:=bear+'NE'
         else if pos('[',bear)>0 then bear:=bear+'SW'
              else if pos(']',bear)>0 then bear:=bear+'SE';
    for i:=length(bear) downto 1 do
      if bear[i] in ['=','\','[',']'] then delete(bear,i,1);
    for i:=1 to length(bear) do
      if not (bear[i] in ['-','.','S','N','E','W','0'..'9',' ']) then asz_err:=true;
    if (pos('N',bear)=0) and (pos('S',bear)=0) then asz_err:=true;
    if (pos('E',bear)=0) and (pos('W',bear)=0) then asz_err:=true;
    if not asz_err then
      begin
        if pos('N',bear)>0 then if pos('E',bear)>0 then a1:=0 else a1:=-2*pi
        else if pos('E',bear)>0 then a1:=-pi else a1:=pi;
        for i:=1 to length(bear) do if bear[i]>'9' then bear[i]:=' ';
        bear_rad:=abs(asz_rad(bear)+a1);
        if asz_err then bear_rad:=0;
      end
    else bear_rad:=0;
  end;

function Rad_Asz (rad: real)   : str16;
  var
    a1,a2  : integer;
    a3,a4  : real;
    a5,a6  : integer;
    p1,p2,
    p5,p6  : string[6];

  begin
    if rad<0 then rad:=rad+2*pi;
    a4:=rad*(180/pi);
    a1:=trunc(a4);
    a2:=trunc((a4-a1)*60);
    a3:=(a4-a1-a2/60)*3600;
    if a3-trunc(a3)>=0.995 then begin a5:=trunc(a3)+1; a6:=0; end
    else begin a5:=trunc(a3); a6:=round((a3-a5)*100); end;
    if a5>=60 then begin inc(a2); a5:=a5-60; end;
    if a2>=60 then begin inc(a1); a2:=a2-60; end;
    while a1>=360 do a1:=a1-360;
    str(a1,p1); str(a2,p2); str(a5,p5); str(a6,p6);
    while length(p1)<3 do p1:=' '+p1;
    while length(p2)<2 do p2:=' '+p2;
    while length(p5)<2 do p5:=' '+p5;
    while length(p6)<2 do p6:='0'+p6;
    rad_asz:=p1+'-'+p2+'-'+p5+'.'+p6;
  end;

procedure roll_asz(s:str16);
  var i : byte;
  begin
    if last_alt_loca<>0 then asz_os:=trunc(int((last_alt_loca-1)/10)*10);
    if s<>'' then
      begin last_asz[10]:=asz_rad(s);
            if not asz_err then begin
              case add_flag of
                1:last_alt_asz[last_alt_loca]:=last_alt_asz[last_alt_loca]+last_asz[10];
                2:last_alt_asz[last_alt_loca]:=last_alt_asz[last_alt_loca]-last_asz[10]+2*pi;
                3:last_alt_asz[last_alt_loca]:=last_alt_asz[last_alt_loca]*last_asz[10]*180/pi;
                4:if last_asz[10]<>0 then
                    last_alt_asz[last_alt_loca]:=last_alt_asz[last_alt_loca]/last_asz[10]/180*pi;
                else last_alt_asz[last_alt_loca]:=last_asz[10];
              end{case};
              last_alt_asz[last_alt_loca]:=asz_rad(rad_asz(last_alt_asz[last_alt_loca]));
              last_alt_loca:=0;
            end;
      end
    else asz_err:=false;
    if not asz_err and (s<>'') and roll_flag then
      begin
        for i:=9 downto 2 do last_asz[i]:=last_asz[i-1];
        last_asz[1]:=last_asz[10];
      end;
  end;

function Rad_Bear(rad: real)  : str16;
  var
    p1,p2 : char;
  begin
    if rad<=pi/2 then
      begin p1:='N'; p2:='E' end
    else if rad<=pi then
           begin p1:='S'; p2:='E'; rad:=pi-rad; end
         else if rad<=3*pi/2 then
                begin p1:='S'; p2:='W'; rad:=rad-pi end
              else begin p1:='N'; p2:='W'; rad:=2*pi-rad; end;
    rad_bear:=p1+rad_asz(rad)+p2;
  end;

procedure ptpt(x1,y1,x2,y2: real;  var d:real; var asz:str16);
var
    n,e,a   : real;
    q       : integer;
  begin
        n:=y2-y1;
        e:=x2-x1;
        q:=1;
        if n>0 then q:=2 else if (n=0) and (e>0) then q:=2;
        if n=0 then a:=pi/2 else a:=arctan(e/n);
        a:=a+q*pi;
        asz:=rad_asz(a);
        d:=sqrt(n*n+e*e);
  end;

procedure input_vert(var ss:str16; d:real; dist_type:char);
  var
      a,v,de    : real;
      x,y,i,j,k : integer;

  begin
    vert_type2:=' ';
    msg(40,'Delta_el Vert_ang');
    whereXY(x,y); screen(black,white);
    repeat
      asz_err:=false;
      j:=wherex; gotoxy(x,y); for k:=x to j-1 do write(' ');
      gotoxy(x,y);
      key:=0; s:=''; get_no_str; ss:=s;
      for i:=1 to length(ss) do ss[i]:=upcase(ss[i]);
      i:=pos('V',ss);
      if i>0 then vert_type:='V'
      else begin i:=pos('D',ss); if i>0 then vert_type:='D'; end;
      if i>0 then delete(ss,i,1);
      i:=pos('A',ss); if i>0 then begin vert_type2:='A'; delete(ss,i,1); end;
      case vert_type of
        'D':begin
               if d>0 then
                 begin
                   val(ss,de,i);
                   if (i>0) and (ss<>'') then asz_err:=true
                   else if (i=0) or (ss='') then
                          begin
                            v:=pi/2;
                            if ss='' then de:=de_display;
                            if dist_type='H' then v:=arctan(abs(de/d))
                            else if d>de then v:=arctan(abs(de/sqrt(d*d-de*de)));
                            if de>0 then v:=pi/2-v else v:=v+pi/2;
                            ss:=rad_asz(v);
                          end;
                 end
               else ss:=rad_asz(pi/2);
            end;
        'V':begin
              if ss<>'' then a:=asz_rad(ss) else asz_err:=false;
              if asz_err then msg(40,^G+'? '+s);
            end;
      end{case};
      con_flag:=true;
    until not asz_err;
    reset_con;
  end;

procedure input_BEAR(var ss:str16);
  var
      a:real;
      x,y,j,k : integer;
  begin
    whereXY(x,y); screen(black,white);
    repeat
      j:=wherex; gotoxy(x,y); for k:=x to j-1 do write(' ');
      gotoxy(x,y);
      key:=0; s:=''; get_no_str; ss:=s;
      if ss<>'' then a:=bear_rad(ss) else asz_err:=false;
      if asz_err then msg(40,^G+'? '+s);
      con_flag:=true;
    until not asz_err;
    reset_con;
  end;

{ ************ END of Bearing - Aszmith  Transform Functions ************** }

procedure init_pt_rec(var pt_rec:point);
  begin
    with pt_rec do
      begin
        from_pt:=0;
        bs_pt:=0;
        bs_ang:=0;
        f_dist:=0;
        hz_ang:=0;
        code:=0;
        descrip:='?';
        Setup:=false;
        aszmith:=0;
        distance:=0;
        north:=0;
        east:=0;
        hi:=0;
        vert_ang:=pi/2;
        rod:=0;
        elev:=0;
      end;
  end;

procedure get3(pt:integer; var sort_rec:sort_xyp);
  begin
    if pt<=no_pts then
      begin
        seek(sort_file,pt);
        read(sort_file,sort_rec);
      end;
  end;

procedure put3(pt:integer; sort_rec:sort_xyp);
  begin
    seek(sort_file,pt);
    write(sort_file,sort_rec);
  end;

procedure add3(x1,y1,e1: real; p1:integer);
  var
    sort_rec : sort_xyp;
   begin
      with sort_rec do begin x:=x1; y:=y1; el:=e1; p:=p1; end;
      put3(p1,sort_rec);
   end;

procedure get(pt:integer; var pt_rec:point);
  begin
    if pt<=no_pts then
      begin
        if demo and (pt>100) then  (* demo version *)
          begin pt:=1; clrscr;
                writeln(^G,'*** DEMO VERSION 100 POINT LIMIT ***');
                halt;
          end;
        if alt_flag then
          begin seek(alt_pt_file,pt); read(alt_pt_file,alt_pt_rec);
                init_pt_rec(pt_rec);
                with pt_rec,alt_pt_rec do
                  begin north:=alt_y; east:=alt_x;
                        elev:=alt_z; descrip:=alt_d;
                        if pt=0 then from_pt:=round(alt_x);
                  end;

          end
        else begin seek(pt_file,pt); read(pt_file,pt_rec); end;
      end;
  end;

procedure set_no_pts(i:integer);
   begin
     no_pts:=i;
     pt_rec0.from_pt:=no_pts;
     alt_pt_rec0.alt_x:=no_pts;
     if alt_flag then
          begin seek(alt_pt_file,0); write(alt_pt_file,alt_pt_rec0); end
     else begin seek(pt_file,0);     write(pt_file,pt_rec0); end;
   end;

procedure put(pt:integer; pt_rec:point);
  begin
    if pt<no_pts+2 then
      begin
        if alt_flag then
          begin seek(alt_pt_file,pt);
                with pt_rec,alt_pt_rec do
                  begin
                    alt_x:=east; alt_y:=north;
                    alt_d:=descrip; alt_z:=elev;
                    if pt=0 then alt_x:=from_pt;
                  end;
                write(alt_pt_file,alt_pt_rec);
          end
        else begin seek(pt_file,pt); write(pt_file,pt_rec); end;
        if pt=no_pts+1 then
          begin
            if dig_shape then with pt_rec do
              writeln(inf,east:10:4,north:10:4,'   ',descrip);
            set_no_pts(no_pts+1);
            with pt_rec do add3(east,north,elev,no_pts);
          end;
      end;
  end;

procedure add(e,n,el:real);  { add a point to the file }
     var
       pt_rec : point;
     begin
       init_pt_rec(pt_rec);
       with pt_rec do
         begin
           north:=n; east:=e; elev:=el; descrip:='Dig.Pt.-'+dig_des;
           put(no_pts+1,pt_rec);
         end;
     end;

procedure Pt_to_Pt(p1,p2: integer; var d:real; var asz:str16);
  var pt_rec,pt_rec2 : point;
  begin
    get(p1,pt_rec); get(p2,pt_rec2);
    ptpt(pt_rec.east,pt_rec.north,pt_rec2.east,pt_rec2.north,d,asz);
  end;


procedure dig_get(var but:integer; var x,y:real);
  var
    t     : string[25];
    s     : array[1..25] of byte;
    i,j   : integer;
    err   : integer;
    b     : byte;
    x1,y1 : real;
    mb2   : integer;
    k     : real;
begin
  men_key_but:=9998;
  men_but_flg:=false;
  msg(66,'Key Pt# NOW'); { purge_kbd; }
  repeat until (keypressed or ((act_script>0) and not con_flag))
               {or com_chr_ready(dig_port)};
  if keypressed or ((act_script>0) and not con_flag) then
    begin k:=whereX; mb2:=9999; input_i(mb2);
          if (dist_type='B') or but1_flag then
            begin men_but_flg:=true;
                  men_but:=mb2;
                  while whereX>k do write(^H,' ',^H);
                  but1_flag:=false;
                  dist_type:=' ';
            end;
          men_key_but:=mb2;
          but:=0; x:=123456.78; y:=x;
          exit;
    end;
{$if 1=0}
  if dig_flag then begin
    t:=com_rec(dig_port);
    for i:=1 to dig_bytes do
      begin s[i]:=ord(t[i]); t[i]:=chr(s[i] and $7F); end;
    but:=0;
    case dig_type of
      1:begin  { houston Instruments }
          val(copy(t,04,5),x,err);
          val(copy(t,11,5),y,err);
          y:=(y+1)/1000;  { in case 0,0 inches pinged }
          x:=(x+1)/1000;
        end;
      2:begin   { Summa Graphics }
         i:=(s[3] and $3f)+((s[4] and $3f) shl $06)+((s[5] and $07) shl $0c);
         x:=i; if s[5] and 8=8 then x:=x+32768.0; x:=x/1000;
         if s[5] and 16=16 then x:=-x;
         i:=(s[6] and $3f)+((s[7] and $3f) shl $06)+((s[8] and $07) shl $0c);
         y:=i; if s[8] and 8=8 then y:=y+32768.0; y:=i/1000;
         if s[8] and 16=16 then y:=-y;
       end;
     98:begin   { BINARY Format }
         i:=0;
         for j:=1 to 3 do
           if dig_98[j,1]<>0 then
             if dig_98[j,3]<0 then
               i:=i+((s[dig_98[j,1]] and dig_98[j,2]) shr (-dig_98[j,3]))
             else
               i:=i+((s[dig_98[j,1]] and dig_98[j,2]) shl dig_98[j,3]);
         x:=i;
         if dig_98[4,1]<>0 then
           if s[dig_98[4,1]] and dig_98[4,2]=dig_98[4,2] then x:=x+32768.0;
         x:=x/dig_div_fact;
         if dig_98[5,1]<>0 then
           if s[dig_98[5,1]] and dig_98[5,2]=dig_98[5,2] then x:=-x;
         i:=0;
         for j:=6 to 8 do
           if dig_98[j,1]<>0 then
             if dig_98[j,3]<0 then
               i:=i+((s[dig_98[j,1]] and dig_98[j,2]) shr (-dig_98[j,3]))
             else
               i:=i+((s[dig_98[j,1]] and dig_98[j,2]) shl dig_98[j,3]);
         y:=i;
         if dig_98[9,1]<>0 then
           if s[dig_98[9,1]] and dig_98[9,2]=dig_98[9,2] then y:=y+32768.0;
         y:=y/dig_div_fact;
         if dig_98[10,1]<>0 then
           if s[dig_98[10,1]] and dig_98[10,2]=dig_98[10,2] then y:=-y;
       end;
     99:begin  { ASCII Format }
          val(copy(t,dig_99[1],dig_99[3]),x,err);
          val(copy(t,dig_99[2],dig_99[3]),y,err);
          y:=(y+1)/dig_div_fact;  { in case 0,0 inches pinged }
          x:=(x+1)/dig_div_fact;
        end;
    end{case};
    if dig_men_flg then
      begin
        x1:=(x-xo_men);  { translate to menu coordinate system }
        y1:=(y-yo_men);
        rotate(x1,y1,0,0,360.0-skew_men*180/pi);
        x1:=x1/x_box_size;
        y1:=y1/y_box_size;
        if (x1>=0) and (x1<=box_x) and
           (y1>=0) and (y1<=box_y) then
          begin
            men_but_flg:=true;
            men_x:=trunc(x1)+1;
            men_y:=trunc(y1)+1;
            men_but:=men_arr[men_x,men_y];
          end;
      end;
  end
  else 
{$endif}

    begin x:=0; y:=0; but:=1; end;
  purge_kbd;
end;

function but1:integer;  { get button from digitizer }
  var
    e,n : real;
  begin
    write('?'); but1_flag:=true;
    repeat dig_get(last_but,e,n); until last_but<12;
    write(^H);
    if not men_but_flg then begin
       but1:=last_but;
       case last_but of
         0..9:write(last_but:1);
           10:write('*');
           11:write('#');
       end{case};
    end
    else begin
        but1:=men_but;
        write(men_but);
    end;
    but1_flag:=false;
  end;

function but2:integer;
  var i,j:integer;
  begin
    i:=but1;
    if men_but_flg then but2:=men_but
    else begin j:=but1;
               if men_but_flg then but2:=men_but
               else but2:=10*i+j;
         end;
  end;

function dig_num:integer;
  begin dig_num:=10*but1+but1; end;


procedure find_xy(var x,y:real; range:real); {search sorted point file for match}
  var
  left,right : integer;
    i,j      : integer;
    r        : real;
    d,dl     : real;
    asz      : str16;
    sort_rec : sort_xyp;
    p1       : integer;

  procedure chk_closest(j:integer);
    begin
      if j>0 then
        begin
          get3(j,sort_rec); r:=sort_rec.x-x;
          d:=1.0e6;
          if abs(r)<range then
            begin
              ptpt(x,y,sort_rec.x,sort_rec.y,d,asz);
              if d<dl then begin p1:=j; dl:=d; end;
            end;
        end;
    end;

  begin{find}

    left:=1; right:=no_pts2;
    repeat
      i:=(left+right) shr 1;
      chk_closest(i);
      if r>range then right:=i-1
      else if r<-range then left:=i+1
           else if d>=range then inc(left);
    until (left>right) or (d<range);

    dl:=10000;
    if left<=right then
      for j:=i-15 to i+15 do if j<=no_pts2 then chk_closest(j);

    for j:=no_pts downto no_pts2 do chk_closest(j); { check newly added points }

    if dl<range then
      begin
        get3(p1,sort_rec);
        pt_found_sort:=p1;
        x:=sort_rec.x;
        y:=sort_rec.y;
        pt_found:=sort_rec.p;
        for i:=0 to 10 do begin sound(3000+i*200); delay(7); end;
        nosound;
      end
    else pt_found:=0;
  end{find_xy};

procedure display_pt_type;
   begin
      case last_pt_type of
         1:msg(1,'Exist Pt');
         2:msg(1,'New/Exist Pt');
         3:msg(1,'New Pt');
      end{case};
   end;

procedure get_xy(var x,y:real);
  var
    flag1 : boolean;
    d1,a1 : real;
    x1,y1 : real;

  begin
    flag1:=false;
    repeat
      repeat
        display_pt_type;
        case men_but of
          10,11:msg(42,'Last Pt.');
            255:msg(42,'Negative');
        end{case};
        dig_get(last_but,x,y);
        if (men_but_flg) and (men_but in [1,2,3]) then last_pt_type:=men_but;
      until not men_but_flg;

      x1:=x-xo; y1:=y-yo;
      d1:=sqrt(sqr(x1)+sqr(y1));
      if x1<>0 then a1:=arctan(abs(y1/x1)) else a1:=pi/2;
      if x1<0 then if y1>0 then a1:=pi-a1 else a1:=pi+a1
      else if y1<0 then a1:=2*pi-a1;
      a1:=a1-skew_ang*pi/180;
      x:=eo+cos(a1)*d1*dx_scale;
      y:=no+sin(a1)*d1*dy_scale;
      pt_found:=0;
      if men_key_but<>9998 then flag1:=true
      else begin
        if ((last_but in [1,2]) or (last_pt_type in [1,2])) and
            (not men_but_flg) then
            if last_but<>3 then find_xy(x,y,dx_scale/25);
        if ((last_but=1) or ((last_pt_type=1) and (last_but<>3))) and (not men_but_flg) then
          begin
            if pt_found>0 then flag1:=true
            else begin
                   for i:=0 to 10 do begin sound(900+i*100); delay(7); end;
                   nosound;
                 end;
          end
        else flag1:=true;
      end;
    until flag1=true;
  end;

function dig_point:integer;  { get point from digitizer }
  var
    e,n : real;
    i,j : integer;
  begin
    if wherex>=72 then writeln; write('PT#?');
    display_int;
    inp_err:=1;    { set input err }

    if (act_script>0) and not con_flag then
      begin
        add_flag:=-1;
        first_key_action; if s='' then s:='9999';
        parse_s; ; val(s,i,inp_err); chk_no_err;
        reset_con;
        if inp_err=0 then roll_int(i) else con_flag:=true;
      end;

    if inp_err<>0 then
      begin
        get_xy(e,n);
        if men_key_but<>9998 then dig_point:=men_key_but
        else begin
          write(^H);
          if pt_found=0 then
            begin add(e,n,0.0); write(no_pts:4); dig_point:=no_pts; roll_int(no_pts); end
          else
            begin write(pt_found:4); dig_point:=pt_found; roll_int(pt_found); end;
          write(' ');
        end;
      end
    else dig_point:=i;
    reset_con;
  end;

procedure write_dig(var p:integer; s:str25);
  begin write(s); p:=dig_point; end;

procedure input_asz(var s:str16);
  var
      x,y     : integer;
      x1,y1,
      x2,y2,d : real;
      i,j,k   : integer;
     p1,p2    : integer;
     flag     : boolean;
     a        : real;
     ss       : str16;

procedure chk_angle;
  var j: integer;
   procedure set_code(j,i:integer);
     begin if j>0 then begin pt_rec0.code:=i; delete(s,j,1); end; end;

  begin
    if pt_rec0.code>=0 then   { check right or left for hz_ang input }
      begin
        for j:=1 to length(s) do s[j]:=upcase(s[j]);
        set_code(pos('L',s),2);
        set_code(pos('R',s),1);
        set_code(pos('A',s),0);
      end;
  end;

function get_asz:integer;
  begin
    s2:=''; i:=0;
    msg(40,'Right Left Az');
    repeat
      case key of
        32..57,76,65,97,
        82,114,108:begin inc(i); s2:=s2+' '; s2[i]:=chr(key); write(s2[i]); end;
             8:if i>0 then begin delete(s2,i,1); dec(i); write(^H,' ',^H); end;
      end{case};
     if key<>13 then key:=keyin;
    until key=13;
    key:=0; s:=s2;
    chk_angle;
    get_asz:=1; d:=0; asz_err:=false;
    if s<>'' then
      begin if s[1]='-' then begin delete(s,1,1); get_asz:=-1; end;
            d:=asz_rad(s);
      end;
  end;

  begin
    whereXY(x,y);
    if reg_disp_flg then begin
      gotoxy(1,22); screen(cyan,black); clreol;
      for m:=1 to 10 do write(asz_os+m:4,' ':3);
      gotoxy(1,23); clreol; screen(white,red);
      for j:=asz_os+1 to asz_os+10 do
        begin write(copy(rad_asz(last_alt_asz[j]),1,6)); gotoxy(wherex+1,23); end;
      gotoxy(1,24); textbackground(black); clreol; textbackground(blue);
      for j:=1 to 9 do
        begin write(copy(rad_asz(last_asz[j]),1,6)); gotoxy(wherex+1,24); end;
      write(' Pt/Pt'); reset_con; write(' B-Bearing'); gotoxy(x,y);
    end;
    reset_con;
    add_flag:=-1;
    flag:=false;
    asz_err:=false;
    repeat
      j:=wherex; gotoxy(x,y); for k:=x to j-1 do write(' '); gotoxy(x,y);
      con_flag:=flag;
      repeat
        key:=keyin;
        case key of
          596..605:begin s:=rad_asz(last_alt_asz[key-595+asz_os]); write(s);
                      pt_rec0.code:=0;
                      end; { Shft f1-f10   Recall }
          606..615:begin { ctrl recall ask r,l,a }
                      s:=rad_asz(last_alt_asz[key-605+asz_os]); write(s);
                      msg(40,'R L A ?');
                      quest(0,0,'?'+^H,['R','L','A'],false);
                      pt_rec0.code:=pos(response,'ARL')-1
                   end;
          616..625:begin last_alt_loca:=key-615+asz_os;
                         add_flag:=(add_flag+1) mod 5;
                         store_msg;
                      end; { Alt  f1-f10   Store  }
          571..579:begin s:=rad_asz(last_asz[key-570]); write(s);
                     pt_rec0.code:=0;
                   end;
             98,66:begin
                     Write('Brg?'); input_bear(s);
                     if s<>'' then
                       begin
                         s:=rad_asz(bear_rad(s));
                         pt_rec0.code:=0;
                       end;
                   end;
               580:begin
                      gotoxy(1,21); clreol;
                      last_pt_type:=1;
                      write_dig(p1,'Enter ');
                      con_flag:=flag;
                      write_dig(p2,'  Enter ');
                      pt_to_pt(p1,p2,d,ss);
                      write('  ',ss,'   +/- Angle ? ');
                      j:=wherex;
                      con_flag:=flag;
                      repeat
                        gotoxy(j,wherey); clreol; key:=0; a:=get_asz*d;
                        if asz_err then msg(40,'? '+s);
                        con_flag:=true;
                      until not asz_err;
                      s:=rad_asz(asz_rad(ss)+a);
                      gotoxy(x,y); write(s);
                      pt_rec0.code:=0;
                   end;
            16,585:begin {pageUp}
                      get_register; val(s2,last_alt_loca,j);
                      if (j>0) or (last_alt_loca>100) then last_alt_loca:=0;
                   end;
             7,593:begin {page down }
                     get_register;
                     pt_rec0.code:=0; s:=s2; chk_angle;
                     val(s,j,m);
                     if (m=0) and (j>0) then s:=rad_asz(last_alt_asz[j])
                     else s:=rad_asz(0);
                     write(s);
                   end;
          else a:=get_asz; { a will be +1 or -1 }
        end{case};
      until (key<>16) and (key<>585) and (key<616);
      roll_asz(s);
      if asz_err then flag:=true;
    until not asz_err;
    reset_con;
    whereXY(x,y); gotoxy(1,22); clreos; gotoxy(x,y);
  end;

procedure Intersection(p1,p2:integer; var a1,a2:str16; var d1,d2 :real);
  var
    d,r   : real;
    r1,r2 : real;
    asz   : str16;
  begin
    pt_err:=false;
    if (p1<=no_pts) and (p2<=no_pts) then
      begin
        pt_to_pt(p1,p2,d,asz);
        r :=asz_rad(asz);
        r1:=asz_rad(a1);
        r2:=asz_rad(a2);
        if r1<>r2 then
          begin
            d1:=d*sin(r2-r-pi)/sin(r1-r2);
            d2:=d*sin(r-r1)/sin(r1-r2);
            if d1<0 then begin d1:=-d1; a1:=rad_asz(asz_rad(a1)+pi); end;
            if d2<0 then begin d2:=-d2; a2:=rad_asz(asz_rad(a2)+pi); end;
          end
        else begin d1:=0; d2:=0; end;
      end
    else pt_err:=true;
  end;

procedure bad_pt_msg;
  begin writeln(' BAD PT#, No_Pts=',no_pts:4,' Pts.',^G); end;

function tan(a:real):real; begin tan:=sin(a)/cos(a); end;

procedure Calculate(var pt_rec:point);
  var
    pt_rec2  : point;
    de,a,a1  : real;
    asz      : str16;

  begin
    pt_err:=false;
    get(abs(pt_rec.from_pt),pt_rec2);
      if (pt_rec.from_pt>0) and (pt_rec.from_pt<=no_pts) then
        with pt_rec do
          begin
(*            if bs_pt=pt_rec2.from_pt then a:=pt_rec2.aszmith-pi
            else
  *)
                 begin
                   if bs_pt<>0 then pt_to_pt(from_pt,abs(bs_pt),a,asz)
                   else asz:='0';     { due north back sight }
                   a:=asz_rad(asz);   { back site aszmith }
                 end;
            if bs_pt=0 then a:=0;
            while a<0 do a:=a+2*pi;
            if code=0 then  { figure hz_ang right off bs_ang=0 }
              begin
                a1:=abs(a-aszmith);
                if a>aszmith then hz_ang:=2*pi-a1 else hz_ang:=a1;
              end
            else { figure aszmith from hz_ang }
              begin
                 if code=1 then a1:=a+hz_ang-bs_ang else a1:=a-hz_ang+bs_ang;
                 while a1<0 do a1:=a1+2*pi;
                 while a1>2*pi do a1:=a1-2*pi;
                 aszmith:=a1;
              end;
            north:=pt_rec2.north+cos(aszmith)*distance;
            east :=pt_rec2.east +sin(aszmith)*distance;
          end{with pt_rec}
          else pt_err:=true;
      if (pt_rec.rod>0) and (pt_rec.from_pt<>0) then with pt_rec do
        begin
          de:=tan(abs(vert_ang-pi/2))*distance;
          if vert_ang>pi/2 then de:=-de;
          elev:=pt_rec2.elev+pt_rec2.hi-rod+de;
        end;
  end;

procedure ReCalculate(start_pt : integer);
  var
    i        : integer;
    pt_rec   : point;
  begin
    if not recalc then exit;
    pt_err:=false;
    if (start_pt<=no_pts) and (start_pt>0) then
      begin
{        gotoxy(73,25); textcolor(blink+cyan); write('...WAIT'); }
        screen(white,yellow); gotoxy(59,24); clreol;
        screen(white+blink,yellow); write(' ReCalc');
        screen(white,yellow); write(' Pt# ',start_pt,'-');
        for i:=start_pt to no_pts do if i>1 then
            begin
              get(i,pt_rec);
              calculate(pt_rec);
              put(i,pt_rec);
              write(i:4,^H^H^H^H);
            end;
      screen(white,black);
      if lst_flag then writeln(lst,'  ReCalc Pt# ',start_pt,'-',no_pts);
      end
    else pt_err:=true;
  end;

procedure display_rec(pt,pos,c1,c2:integer; pt_rec:point);
  var
    i : integer;
    pt_rec3 : point;
    a,a1    : real;
    asz     : str16;
    de      : real;  { delta elevation }

  begin
    for i:=pos to pos+4 do begin gotoxy(1,i); clreol; end;
    with pt_rec do
      begin
        textcolor(c1);
        go_write(03,pos,'Pt#:');
        go_write(13,pos,'FromPt#:');
        go_write(27,pos,'BSPt#:');
        go_write(38,pos,'SetUp:');
        go_write(50,pos,'Descrip:');
        gotoxy(03,pos+1);   for i:=1 to 77 do write('=');
        gotoxy(03,pos+2);
        if code=0 then write('A') else write('a'); write('zimuth:');
        gotoxy(03,pos+3);  write('Bearing:');
        gotoxy(03,pos+4);
        if code>0 then write('H') else write('h'); write('orzAng:');
        if (bs_edit) or (bs_ang>0) then
          begin gotoxy(3,pos+1);  write(' BS-Ang:  '); end;
        go_write(27,pos+2,'Distance:');
        go_write(28,pos+3,'VertAng:');
        go_write(29,pos+4,'F_Dist:');
        go_write(51,pos+2,'Rod:');
        go_write(51,pos+3,'dEl:');
        go_write(52,pos+4,'HI:');
        go_write(63,pos+2,'North:');
        go_write(64,pos+3,'East:');
        go_write(64,pos+4,'Elev:');
        textcolor(c2);
        gotoxy(7,pos);     write(pt:3);
        gotoxy(21,pos);    write(From_Pt:3);
        gotoxy(33,pos);    write(bs_pt:3);
        gotoxy(45,pos);    if setup then write('YES') else write('NO');
        gotoxy(59,pos);    write(descrip);
        gotoxy(13,pos+2);  write(rad_asz(aszmith));
        gotoxy(12,pos+3);  write(rad_bear(aszmith));
        gotoxy(13,pos+4);  write(rad_asz(hz_ang));
        if (bs_edit) or (bs_ang>0) then
          begin
            gotoxy(13,pos+1);  write(rad_asz(bs_ang),' ');
          end;
        gotoxy(25,pos+4); case code of 0,1:write('R'); 2:write('L'); end;
        gotoxy(38,pos+2);  write(Distance:9:3);
        gotoxy(37,pos+3);  write(rad_asz(Vert_Ang));
        gotoxy(37,pos+4);
        if f_dist>=200000.0 then write('R',f_dist-200000.0:9:3)
        else if f_dist>=100000.0 then write('E',f_dist-100000.0:9:3)
             else if f_dist<0 then write('P',-f_dist:9:3)
                  else write('H',f_dist:9:3);
        if (* (rod>0)  and *) (vert_ang>0) then
          begin
            de:=tan(abs(vert_ang-pi/2))*distance;
            if vert_ang>pi/2 then de:=-de;
          end
        else de:=0;
        gotoxy(56,pos+2);  write(Rod:5:2);
        gotoxy(55,pos+3);  write(dE:6:2); de_display:=de;
        gotoxy(56,pos+4);  write(HI:5:2);
        gotoxy(69,pos+2);  write(North:11:4);
        gotoxy(69,pos+3);  write(East:11:4);
        gotoxy(69,pos+4);  write(Elev:11:4);
      end;
  end;

procedure modify_rec(pt,pos,c1,c2,c3:integer; var pt_rec:point);
  var
    i,key         : integer;
    asz,bear,vert : str16;
    setup2        : string[3];
    pt_rec2       : point;
    sort_rec      : sort_xyp;
    de,gen,gen2   : real;
    va1           : real; { 1st vert_ang of the average process }

begin
  repeat
    display_rec(pt,pos,c1,c2,pt_rec);
    textcolor(c3);
    with pt_rec do
      begin
        if pt>0 then
          repeat
            repeat
              gotoxy(21,pos); input_i(from_pt);
              if from_pt>=pt then
                begin
                  gotoxy(1,pos+7); clreol; textcolor(green);
                  write(^G,'From_Pt Should Be < ',pt:4,'.');
                  cogo_err:=true;
                  textcolor(c3);
                end;
            until from_pt<=no_pts; (* from_pt<pt; *)
            if from_pt<>0 then
              begin
                get(abs(from_pt),pt_rec2);
                de:=de_display;
                display_rec(from_pt,pos-6,Lightgray,White,pt_rec2);
                de_display:=de;
                textcolor(c3);
                response:='Y';
              end;
          until (from_pt<1) or (response='Y');
        last_from:=from_pt;
        if (option='Ad') and (from_pt>0) and (setup=true) then
          begin
            bs_pt:=abs(pt_rec2.from_pt);
            gotoxy(33,pos); write(bs_pt:3);
          end;
        if (pt>0) and (code>=0) then
            repeat
              gotoxy(33,pos); input_i(bs_pt);
              if bs_pt>no_pts then
                begin
                  gotoxy(1,pos+7); clreol; textcolor(green);
                  write(^G,'BS_Pt Must Be <',no_pts+1:4,'.');
                  textcolor(c3);
                end;
            until bs_pt<=no_pts;
            pt_rec0.bs_pt:=bs_pt;
        gotoxy(1,pos+7); clreol;
        gotoxy(45,pos);
        case upcase(chr(keyin)) of
          'Y':setup:=true;
          'N':setup:=false;
        end{case};
        if setup then setup2:='YES' else setup2:='NO ';
        write(setup2);
        pt_rec0.setup:=setup;
        gotoxy(59,pos);  input_des(descrip);
        last_descrip:=descrip;
        if from_pt>0 then  { get aszmith }
          begin
            if code=0 then
              begin
                pt_rec0.code:=code;
                gotoxy(12,pos+2); input_asz(asz);
                if asz<>'' then aszmith:=asz_rad(asz);
                gotoxy(12,pos+3); input_bear(bear);
                if bear<>'' then
                  begin pt_rec0.code:=0;
                        aszmith:=bear_rad(bear);
                  end;
                pt_rec0.aszmith:=aszmith;
                code:=pt_rec0.code;
                if code>0 then hz_ang:=aszmith;
              end
            else  { get angle turned right/left from back sight = 0 degress }
              begin
                pt_rec0.code:=code;
                gotoxy(13,pos+4); input_asz(asz);
                if asz<>'' then
                  if pt_rec0.code=0 then
                    begin
                      code:=0;
                      aszmith:=asz_rad(asz);
                      pt_rec0.aszmith:=aszmith;
                    end
                  else
                    begin  { switch to aszmith for newly added points }
                      hz_ang:=asz_rad(asz);
                      code:=pt_rec0.code;
                      pt_rec0.hz_ang:=hz_ang;
                    end;
                if (bs_edit) and (code>0) then
                  begin
                    gotoxy(13,pos+1); input_asz(asz);
                    if asz<>'' then bs_ang:=asz_rad(asz);
                    pt_rec0.bs_ang:=bs_ang;
                  end;
              end;
          end{if from_pt>0};

     i:=pt_rec0.code;
     de:=0;
     va1:=0;
     repeat  { for averageing the distance }
        pt_rec0.code:=1;
        gotoxy(37,pos+2);
        gen:=distance;
        write(last_dist_type,' ');
        msg(1,'Prism Rod Horz. Edm'); input2_r(distance);
        gotoxy(1,25); clreol;
        if abs(gen-distance)>0.0005 then f_dist:=distance;
        if dist_type=' ' then dist_type:=last_dist_type;
        last_dist_type:=dist_type;
        if dist_type in ['R','P','E'] then
          begin
            gotoxy(40,15); msg(1,'"A" to Average Dist.');

            if vert_type='V' then gotoxy(37,pos+3) else gotoxy(55,pos+3);
            input_vert(vert,distance,last_dist_type);
            if vert_type2='A' then pt_rec0.code:=0;

            if vert<>'' then vert_ang:=asz_rad(vert);
            if vert_ang>pi then vert_ang:=2*pi-vert_ang;
            if (va1=0) or (pt_rec0.code=0) then
              begin va1:=vert_ang; gen2:=f_dist; end;
            case dist_type of
              'R':begin distance:=distance*sqr(sin(vert_ang)); f_dist:=f_dist+200000.0; end;
              'P':begin distance:=distance*sin(vert_ang); f_dist:=-f_dist; end;
              'E':begin
                    distance:=sqrt(sqr(distance)-sqr(EDM_const)*sqr(sin(vert_ang)))+
                    EDM_const*cos(vert_ang);
                    distance:=distance*sin(vert_ang);
                    f_dist:=f_dist+100000.0;
                  end;
            end{case};
          end{if distance in R,P,E};
        roll_real(distance);
        if (lst_flag) and (de=0) then write(lst,'Pt#',pt:3);
        if pt_rec0.code=0 then
          begin de:=distance; gotoxy(1,15); clreol;
                write('Reduced Dist.=',de:9:3);
                if lst_flag then write(lst,'RD1=':6,de:9:3);
          end;
     until pt_rec0.code<>0;
     pt_rec0.code:=i;
     gotoxy(1,16); clreol; write('Reduced Dist.=',distance:9:3);
     if lst_flag then begin
                        if de<>0 then write(lst,'RD2=':6,distance:9:3)
                        else write(lst,'RD2=':21,distance:9:3);
                      end;
     if de<>0 then
       begin gen:=abs(distance-de);
             distance:=(de+distance)/2;
             vert_ang:=va1;
             f_dist:=gen2;
             gotoxy(1,17); clreol;
             writeln('Average Dist.=',distance:9:3);
             gotoxy(26,16); write('Diff=',gen:6:3);
             if lst_flag then write(lst,'AD=':6,distance:9:3,'RD2-RD1=':11,gen:6:3);
       end;
     if lst_flag then writeln(lst);

        gotoxy(56,pos+2); input_r(rod); pt_rec0.rod:=rod;
        if rod=0 then begin gotoxy(69,pos+4); input_r(elev); end;

        if vert_type='V' then gotoxy(37,pos+3) else gotoxy(55,pos+3);
        input_vert(vert,distance,'H');
        if vert<>'' then vert_ang:=asz_rad(vert);
        if vert_ang>pi then vert_ang:=2*pi-vert_ang;

        if setup then begin gotoxy(56,pos+4); input_r(hi); end;
        if from_pt=0 then
          begin
            textcolor(white);
            gotoxy(1,22); clreos; writeln;
            write(^G,'F9-Dig.Pt  F10-Enter Pt');
            repeat key:=keyin; until (key=579) or (key=580);
            case key of
              580:begin
                    msg(1,'Enter Pt');
                    gotoxy(69,pos+2);  input_r(north);
                    gotoxy(69,pos+3);  input_r(east);
                  end;
              579:begin
                    if dig_flag then
                      begin
                        get_xy(east,north);
                        gotoxy(69,pos+2);  write(north:10:3);
                        gotoxy(69,pos+3);  write(east:10:3);
                      end
                    else msg(1,'Dig.NOT Set');
                  end;
            end{case};
          end;
      end{with pt_rec};
    calculate(pt_rec);
    display_rec(pt,pos,c1,c2,pt_rec);
    quest(5,19,'Data O.K. (Y/N/Quit/Another) ? ',['Y','N','Q','A'],true);
    if response='N' then last_dist_type:='H';
  until response in ['Y','Q','A'];
  if response in ['Y','A'] then
    begin
      if pt_rec.from_pt>=pt then pt_rec.from_pt:=0;
      put(pt,pt_rec);
      if (pt_rec.code>0) and (pt_rec.bs_pt>pt_rec.from_pt) then
        begin
          get(pt_rec.bs_pt,pt_rec2);
          pt_rec2.from_pt:=-abs(pt_rec2.from_pt);
          put(pt_rec.bs_pt,pt_rec2);
        end;
      flush_pt_file;
      go_write(5,19,'==> Pt Added/Changed');
      if lst_flag then with pt_rec do
        writeln(lst,'ADD Pt#',pt:4,from_pt:6,bs_pt:6,descrip:21,north:12:3,east:12:3,elev:8:2);
      if pt<no_pts then recalculate(pt);
    end
  else go_write(5,19,'==> Pt NOT Added/Changed');
  de_display:=0;
end;

procedure add_pt(pt_rec:point);
  begin
      mode('Add Point Mode');
      modify_rec(no_pts+1,9,cyan,LightCyan,white,pt_rec);
  end;

procedure over_pt(pt:integer; pt_rec:point);
  begin
    mode('OverWrite Point Mode');
    modify_rec(pt,9,cyan,LightCyan,white,pt_rec);
  end;

procedure edit_pt;
  var
    pt_rec    : point;
    pt        : integer;

  begin
    mode('Edit Point Mode');
    last_dist_type:='H';
    write('  Enter Pt# ? ');
    pt:=9999;
    input_i(pt);
    repeat
      if pt<=no_pts then
        begin
          get(pt,pt_rec);
          modify_rec(pt,9,cyan,Lightcyan,white,pt_rec);
        end
      else begin gotoxy(5,16); bad_pt_msg; end;
      pt:=pt+1;
    until (pt>no_pts) or (response<>'A');
  end;

procedure ask_add(pt_rec:point);
  var pt:integer;
  begin
    calculate(pt_rec); roll_real(pt_rec.distance);
    display_rec(no_pts+1,15,lightgray,white,pt_rec);
    screen(blink+red,black);
    quest(25,1,' [A]dd  [O]verwrite  [C]ontinue ? ',['A','O','C'],true);
    textcolor(green);
    case response of
      'A':add_pt(pt_rec);
      'O':begin
            repeat
              gotoxy(25,1); clreol;
              write('Enter Over-Write Pt# ? '); input_i(pt);
            until pt<=no_pts;
            over_pt(pt,pt_rec);
          end;
    end;
  end;

procedure add_point;
  begin
    repeat
      init_pt_rec(pt_rec);
      with pt_rec do
        begin
          from_pt:=last_from;
          bs_pt  :=pt_rec0.bs_pt;
          rod    :=pt_rec0.rod;
          bs_ang :=pt_rec0.bs_ang;
          code   :=pt_rec0.code;
          setup  :=pt_rec0.setup;
          descrip:=last_descrip;
          if code=0 then aszmith:=pt_rec0.aszmith;
          if no_pts=0 then aszmith:=pi;
        end;
      add_pt(pt_rec);
    until response<>'A';
  end;

begin
 dig_flag :=false;

end.
