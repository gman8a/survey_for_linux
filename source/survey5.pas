unit survey5;
interface
uses dos,crt,survey0,basics2;

procedure compare;
procedure side_shot(ver:integer; ss_des:string); { version 1,2,3,4 }

implementation

procedure compare;
 var
   nd,ed,d1     : real;
   asz1       : str16;
   pt_rec     : point;
   pt_rec2    : point;
   p1,p2      : integer;
   bear       : str16;
   sum_n,sum_e: real;
   pt_cnt     : integer;

begin
   mode('Compare Coordinates');
   sum_n:=0; sum_e:=0; pt_cnt:=0;
   repeat
     go_write(1,16,'Enter 1st ');   p1:=9999; p1:=dig_point;
     write('  Enter 2nd '); p2:=9999; p2:=dig_point;
     gotoxy(45,wherey);
     if (p1<=no_pts) and (p2<=no_pts) then
       begin
          get(p1,pt_rec);
          get(p2,pt_rec2);
          pt_cnt:=pt_cnt+1;
          nd:=pt_rec.north-pt_rec2.north;
          ed:=pt_rec.east-pt_rec2.east;
          sum_n:=sum_n+nd; sum_e:=sum_e+ed;
          pt_to_pt(p1,p2,d1,asz1);
          if not as_br_flg then bear:=rad_bear(asz_rad(asz1)) else bear:=asz1;
          writeln('N',nd:10:4,'  E',ed:10:4);
          gotoxy(46,wherey);
          writeln(bear,'   ',d1:10:4);
          roll_real(d1);
          roll_asz(asz1);
          if lst_flag then
            begin
              writeln(lst,'   PT#',p1:4,' is North',nd:10:4,'  East',ed:10:4,' from PT#',p2:4);
              writeln(lst,'   PT#',p1:4,'   ',bear,'   ',d1:10:4,'    PT#',p2:4);
              writeln(lst);
            end;
       end;
     gotoxy(1,wherey); clreos;
     gotoxy(1,25); writeln; writeln;
     if pt_cnt>0 then
      begin
        gotoxy(1,19);
        writeln('Point Count =',pt_cnt:3);
        writeln('Sum Northing =',sum_n:11:4,'   Sum Easting =',sum_e:11:4);
        writeln('Average North=',sum_n/pt_cnt:11:4,'   Average East=',sum_e/pt_cnt:11:4);
        roll_real(-sum_n/pt_cnt); roll_real(-sum_e/pt_cnt);
        if lst_flag and ((p1>no_pts) or (p2>no_pts)) then
          begin
            writeln(lst,'Compare Coor. Pt Cnt=',pt_cnt:3);
            writeln(lst,'  Sum Northing =',sum_n:11:4,'   Sum Easting =',sum_e:11:4);
            writeln(lst,'  Average North=',sum_n/pt_cnt:11:4,'   Average East=',sum_e/pt_cnt:11:4);
          end;
      end;
   until (p1>no_pts) or (p2>no_pts);
end;

procedure side_shot(ver:integer; ss_des:string); { version 1,2,3,4 }
   { 1-Side-Shot  2-TOPO   3-Quick Shot   4-Map_chk   5-Field Elev. }
var
   b,a    : str16;
   p1,i   : integer;
   d      : real;
   pt_rec : point;
   pt_rec2: point;
   bs     : integer;
   x,y    : integer;
   des    : str20;
   vert   : str16;
   va     : real;
   r      : real;
   last_fp: integer;
   ow_pt  : integer;

  procedure get_from;
    begin
      write('   FROM:Pt#',p1:4,' ? ');
      wherexy(x,y);
      repeat gotoxy(x,y); input_i(p1); until p1<=no_pts;
      gotoxy(x-7,y); write(p1:4);
    end;

  procedure get_bs;
    begin
      write('   BSPt#',bs:4,' ? ');
      wherexy(x,y);
      repeat gotoxy(x,y); input_i(bs); until bs<=no_pts;
      gotoxy(x-7,y); write(bs:4);
    end;

begin
  mode('Side Shot Pt Data Entry: '+ss_des); writeln;
  if lst_flag then writeln(lst,'SIDE SHOT: '+ss_des);
  if no_pts=0 then exit;
  p1:=1; bs:=0; r:=0; des:='?';
  de_display:=0;
  repeat
    gotoxy(1,4); clreol;
    ow_pt:=1;
    if ver=5 then begin write('Elev. Over Write Pt# ? '); input_i(ow_pt); end;
  until ow_pt<=no_pts;

  case ver of
    2,3,5:begin get_from; get_bs; end;
        4:begin get_from; bs:=p1-1; last_dist_type:='H'; end; { map_chk mode }
  end{case};
  last_fp:=0;

  repeat
    gotoxy(50,1); write('<RETURN> Dist. to Exit');
    gotoxy(1,17);
    write('Pt#'); if ver=5 then write(ow_pt:4) else write(no_pts+1:4);
    case ver of
       1:begin get_from; get_bs; end;
   2,3,5:write('   FROM:Pt#',p1:4,'   BSPt#',bs:4);
       4:begin
          if (dist_type<>'H') and (last_fp>0) then
            begin p1:=no_pts; bs:=last_fp; end;
          write('   FROM:Pt#',p1:4);
          get_bs;
         end;
    end{case};

    last_fp:=p1;
    write('   Descrip: ');
    if ver<>5 then begin
      input_des(des); writeln;
      write('Enter angle (A,R,L) ');
      case pt_rec0.code of
         0:write('Azimuth? ');
         1:write(' Right ? ');
         2:write('  Left ? ');
      end{case};
      input_asz(a);
      if a<>'' then writeln
      else begin write('   Enter Bearing ? '); input_bear(b); writeln; end;
    end
    else begin
      get(ow_pt,pt_rec2);
      des:=pt_rec2.descrip;
      input_des(des); writeln;
      a:=rad_asz(0);
    end;

    if ver=4 then write('Enter Horz. Dist. (Hold) ? ')
    else begin
           write('Enter Dist. (R,P,E,H) ');
           case last_dist_type of
             'R':write(' Rod ? ');
             'P':write('Prism? ');
             'E':write(' EDM ? ');
             'H':write('Horz.? ');
           end{case};
         end;
    if ver=5 then d:=100 else d:=0;
    input2_r(d);

    if ver<>4 then begin
      if dist_type=' ' then dist_type:=last_dist_type;
      last_dist_type:=dist_type;
    end;

    if (bs>p1) and (d<>0) and (ver<>5) then with pt_rec2 do  { protect bs pt }
      begin
        get(bs,pt_rec2);
        from_pt:=-abs(from_pt);
        put(bs,pt_rec2);
      end;

    va:=pi/2;
    init_pt_rec(pt_rec);
    pt_rec.f_dist:=d;
    if (d<>0) and ((ver=2) or (dist_type in ['R','P','E'])) or (ver=5) then
      begin
        if vert_type='V' then write('  Vert_Ang ? ') else write('  Del_El ? ');
        input_vert(vert,d,last_dist_type);
        if vert<>'' then va:=asz_rad(vert);
        if va>pi then va:=2*pi-va;
        case dist_type of
          'R':begin pt_rec.f_dist:=d+200000.0; d:=d*sqr(sin(va)); end;
          'P':begin pt_rec.f_dist:=-d; d:=d*sin(va); end;
          'E':begin
                 pt_rec.f_dist:=d+100000.0;
                 d:=sqrt(sqr(d)-sqr(EDM_const)*sqr(sin(va)))+EDM_const*cos(va);
                 d:=d*sin(va);
              end;
        end{case};
        write('  Dist.=',d:8:3);
      end{if dist_type};
    roll_real(d);

    if ver in [2,5] then begin
      writeln;
      write('    Rod=',r:5:2,' ? ');  wherexy(x,y); input_r(r);
      gotoxy(x-8,y); write(r:5:2);
    end;

    with pt_rec do
      begin
        code:=pt_rec0.code;
        vert_ang:=va;
        distance:=d;
        from_pt:=p1;
        descrip:=des;
        if a<>'' then aszmith:=asz_rad(a)
        else begin aszmith:=bear_rad(b); code:=0; end;
        if code>0 then
          begin
            hz_ang:=aszmith;
            bs_pt:=bs;
          end;
        rod:=r;
      end;
    calculate(pt_rec);

    if ver=5 then write('  New Elev=',pt_rec.elev:7:2);
    writeln; clreos; gotoxy(1,25); for i:=1 to 5 do writeln;

    if d<>0 then
      begin
        if lst_flag then with pt_rec do begin
           writeln(lst,' Pt#',p1:5,'  ',rad_bear(aszmith),'  ',d:8:3,'  Pt# ',no_pts+1,descrip:22);
           writeln(lst,north:18:3,east:12:3,elev:8:2);
        end;
        if ver=5 then with pt_rec do
          begin
            va:=elev;
            get(ow_pt,pt_rec);
            elev:=va; descrip:=des; rod:=0;
            put(ow_pt,pt_rec);
            ow_pt:=ow_pt+1;
          end
        else put(no_pts+1,pt_rec);
      end;
 until (d=0) or (p1<1) or (p1>no_pts) or (ow_pt>no_pts);
end;

end.
