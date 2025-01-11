unit survey31;
interface
uses dos,crt,survey0,basics2;

procedure set_menu(i:integer;  fn:str25);
procedure dig_menu;
procedure vert_curv;
procedure insert;
procedure station;
procedure move;
procedure dig_add;

implementation

procedure set_menu(i:integer;  fn:str25); begin end;
{$if 1=0}
procedure set_menu(i:integer;  fn:str25);
  var
     menu_file    : text;
     x,y          : real;
     old_dig_flag : boolean;
     j            : integer;

procedure load_menu;
  var i,j : integer;
  begin
    writeln;
    if exist(fn+'.LAY') then
      begin
        assign(menu_file,fn+'.LAY');
        reset(menu_file);
        readln(menu_file,box_x,box_y,x_box_size,y_box_size,xo_men,yo_men,skew_men);
        close(menu_file);
        if exist(fn+'.MAT') then
          begin
            assign(menu_file,fn+'.MAT');
            reset(menu_file);
            for i:=1 to box_y do
              begin
                for j:=1 to box_x do read(menu_file,men_arr[j,box_y+1-i]);
                readln(menu_file);
              end;
            writeln('+++ Digitizer Menu File: ',fn,' Loaded +++');
            dig_men_flg:=true;
          end
        else cnff(fn+'.MAT');
      end
    else cnff(fn+'.LAY');
    delay(750);
  end;

   begin
     if i=0 then
       begin
         quest(0,0,'[L]oad Exist Menu   [M]ake New Menu Config.',['L','M'],false);
         if response='L' then i:=99;
         writeln;
       end;
     if i=0 then begin
       mode('Setup Parameters of Digitizer Menu'); writeln;
       gotoxy(1,3);
       write('Enter No. Boxes in X direction ? '); input_i(box_x); writeln;
       write('Enter No. Boxes in Y direction ? '); input_i(box_y); writeln;
       write('Enter X-Box Side Size in Inches  ? '); input_r(x_box_size); writeln;
       write('Enter Y-Box Side Size in Inches  ? '); input_r(y_box_size); writeln;
       writeln;
       old_dig_flag:=dig_flag;
       dig_flag:=true;
       purge(dig_port);
       write(^G,'*** Digitize LOWER LEFT Box Corner ***');  dig_get(last_but,xo_men,yo_men);
       writeln;
       write(^G,'*** Digitize LOWER RIGHT Box Corner ***'); dig_get(last_but,x,y);
       dig_flag:=old_dig_flag;
       x:=x-xo_men; y:=y-yo_men;
       if x<>0 then skew_men:=arctan(abs(y/x)) else skew_men:=pi/2;
       if x<0 then if y>0 then skew_men:=pi-skew_men else skew_men:=pi+skew_men
       else if y<0 then skew_men:=2*pi-skew_men;
       writeln;
       writeln('Skew angle of the Menu = ',rad_asz(skew_men));
       assign(menu_file,fn+'.LAY');
       rewrite(menu_file);
       writeln(menu_file,box_x:4,box_y:4,x_box_size:7:3,y_box_size:7:3,xo_men:8:4,yo_men:8:4,skew_men:11:6);
       close(menu_file);
       load_menu;
     end
     else load_menu; { open menu set file and set current parameters }
   end;
{$endif}

procedure dig_menu;
  begin
    mode('Dig Menu');
    quest(0,0,'  [S]et [T]est ?',['S','T'],false);
    if response='S' then quest(0,0,'  [C]ad [L]egal ?',['C','L'],false);
  end;

procedure vert_curv;
 var
   g1,g2 : real;  { grades }
   d     : real;  { distance from g1 grade line }
   e     : real;  { distance from P.V.I. }
   a     : real;  { algebraic differance in g1,g2 }
   l     : real;  { length of curve }
   l2    : real;  { distance form p.v.c. }
   pvi   : real;  { P.V.I. station }
   pvc   : real;  { P.V.C. station }
   elev  : real;  { P.V.I. elevation }
   elev2 : real;  { P.V.C. elevation }
   elev3 : real;  { elevation on grade line 1 @ distance l2 }
   x,y,t : integer;
begin
  mode(' Vertical Curve Computation ');
  writeln;
  tag_prn(fn+': '+pt_rec0.descrip);

  write('Grades  +/- G1%=? '); input_r(g1);
  write(' G2%=? '); input_r(g2); writeln;
  write('Curve Length  (L ft.) ? '); input_r(l); writeln;
  write('P.V.I. Station ? '); input_r(pvi);
  write('  P.V.I. Elev ? '); input_r(elev); writeln;
  t:=25; write('Tab Interval (T=25 ft.) ? '); input_i(t); writeln;
  a:=g1-g2;
  e:=a*l/100/8;
  elev2:=elev-l/2*g1/100;
  pvc:=pvi-l/2;
  writeln(pvc:8:2,elev2:9:2);
  x:=1; y:=7;
  l2:=t-(pvc-t*int(pvc/t));
  repeat
    d:=4*e*sqr(l2/l);
    elev3:=elev2+g1*l2/100;
    gotoxy(x,y); inc(y); if y=19 then begin y:=6; x:=x+20; end;
    writeln(pvc+l2:8:2,elev3-d:9:2);
    if (l2>l/2-t) and (l2<l/2) then
       begin
         gotoxy(x,y); inc(y); if y=19 then begin y:=6; x:=x+20; end;
         writeln(pvi:8:2,elev-e:9:2);
       end;
    l2:=l2+t;
  until l2>l;
  elev2:=elev+l/2*g2/100;
  gotoxy(x,y);
  writeln(pvc+l:8:2,elev2:9:2);
end;

procedure insert;
  var
    pt     : integer;
    pt_rec : point;
    i      : integer;
    j      : integer;
  begin
    mode('Insert a Pt');
    pt:=9999;
    write('  Enter Pt# to shift down ? '); input_i(pt);
    if pt<=no_pts then
      begin
        gotoxy(1,3); write('...Working');
        j:=no_pts;
        for i:=j downto pt do
          begin
            gotoxy(13,3); write(i:3);
            get(i,pt_rec);
            with pt_rec do
              begin
                if abs(from_pt)>=pt then
                  from_pt:=round(from_pt/abs(from_pt)*(abs(from_pt)+1));
                if bs_pt>=pt then bs_pt:=bs_pt+1;
              end;
            put(i+1,pt_rec);
          end;
        init_pt_rec(pt_rec);
        put(pt,pt_rec);
      end
    else begin gotoxy(5,16); bad_pt_msg; end;
  end;

procedure station;
 var
   p1,p2,cen_pt : integer;
   cw           : boolean;
   sta1,r,r1    : real;
   asz1,asz2    : str16;
   delta,d,s,a  : real;
   pt_rec       : point;
   i            : integer;
   any_str,s2   : str16;
   os           : real;
   si           : integer;

begin
  mode(' Station Computation '); writeln(' ...Press <RETURN> to Quit');
  p1:=9999; os:=0; si:=100;
  gotoxy(5,12); write('Enter  P.C.  Pt# on center line ? '); p1:=dig_point;
  if p1<=no_pts then begin
    gotoxy(5,13); write('Enter  P.T.  Pt# on center line ? '); p2:=dig_point;
    gotoxy(5,14); write('Enter  P.C. Station  (1573.23)  ? '); input_r(sta1);
    men_but:=0;
    gotoxy(5,15); write('Enter Center Pt# (+CW or -CCW)  ? '); cen_pt:=dig_point;
    if men_but=255 then cen_pt:=-cen_pt;
    gotoxy(5,16); write('Enter Offset Distance ( + or -) ? '); input_r(os);
    gotoxy(5,17); write('Enter Station Increment (50,100)? '); input_i(si); si:=abs(si);
    writeln;
    if cen_pt<0 then begin cen_pt:=-cen_pt; cw:=false; end else cw:=true;
    pt_to_pt(cen_pt,p1,r1,asz1);
    pt_to_pt(cen_pt,p2,r,asz2);
  end;
  if (abs(r-r1)<0.0005) and (p1<=no_pts) then begin
    delta:=asz_rad(asz2)-asz_rad(asz1);
    while delta<0 do delta:=delta+2*pi;
    if not cw then delta:=2*pi-delta;
    init_pt_rec(pt_rec);
    with pt_rec do
      begin
        distance:=r+os;
        from_pt:=cen_pt;
        code:=0;
      end;
    d:=0;
    i:=1;
    str(os:6:2,s2);
    while d<delta do
      begin
        s:=int(sta1/si)*si+i*si-sta1; i:=i+1;
        d:=s/r; if d>delta then begin d:=delta; s:=d*r; end;
        if cw then a:=asz_rad(asz1)+d else a:=asz_rad(asz1)-d;
        while a<0 do a:=a+2*pi; while a>2*pi do a:=a-2*pi;
        pt_rec.aszmith:=a;
        str((sta1+s):8:2,any_str);
        pt_rec.descrip:='Sta'+any_str+' OS'+s2;
        calculate(pt_rec);
        put(no_pts+1,pt_rec);
        write(^M,pt_rec.descrip);
      end;
  end
  else begin writeln; writeln(^G,'ERROR ==> Radii are not Equal.'); end;
end;

procedure move;
  var
    p1,p2,p3  : integer;
    pt_rec    : point;
    i         : integer;
  begin
    mode('Allocate & Move Pts');
    writeln('  Total Point in File = ',no_pts:4);
    write('Enter No. of Pts to Append AP=0 ? '); p1:=0; input_i(p1);
    gotoxy(1,4);
    if p1>0 then
      begin
        i:=0;
        init_pt_rec(pt_rec);
        repeat
          i:=i+1;
          put(no_pts+1,pt_rec);
        until p1=i;
        writeln(p1:3,' Pts Appended');
      end
    else writeln('No Pts Appended');
    writeln;
    writeln('Enter Beginning & Ending Pts to be Sequencially Moved ?');
    write('Enter Begin Pt#=0 ? '); p1:=0; input_i(p1); writeln;
    write('Enter  End  Pt#=0 ? '); p2:=0; input_i(p2); writeln;
    write('Enter Move TO: Beginning Pt#=0 ? '); p3:=0; input_i(p3); writeln;
    if (p1>0) and (p2>0) and (p3>0) then
      begin
        quest(0,0,'Is this correct (Y/N) ? ',['Y','N'],false);
        if response='N' then p1:=0;
      end;
    writeln;
    if (p2>=p1) and (p2-p1+p3<=no_pts) and (p1>0) and (p2>0) and (p3>0) and
        ((p3>p2) or (p2-p1+p3<p1)) then
         begin
           for i:=p1 to p2 do
             begin
               get(i,pt_rec);
               if pt_rec.from_pt>=p3+i-p1 then pt_rec.from_pt:=0; { dynamics }
               put(p3+i-p1,pt_rec);
             end;
           flush_pt_file;
           if lst_flag then writeln(lst,'MOVE Pt# ',p1,'-',p2,' to Pt# ',p3);
           recalculate(p3);
         end
      else writeln(^G,'*** Aborted or Pt. Input Error ***');
  end{procedure};

procedure dig_add;
  var
    i        :integer;
  begin
    mode('Add Points with Digitizer');
    gotoxy(1,3);
    if dig_flag then
      begin
        write('Enter Description ? '); readln(dig_des);
        writeln('...Press # Key to END Digitizer Pt. Input');
        last_pt_type:=3; { new points }
        men_but:=0;
        repeat
          i:=dig_point;
        until (last_but=11) or (men_but=11);
        flush_pt_file;
        close(sort_file); reset(sort_file);
      end
    else writeln('...Digitizer Not Setup');
  end;

end.
