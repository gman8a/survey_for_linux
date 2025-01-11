{$F+,O+}
unit survey8;
interface
uses crt,survey0,basics2;

{$I Direct}   { Compiler directives }

procedure road_arc;
procedure snap_arc;
procedure el_trans;

{$IFDEF  contour}             { Semi Automated Contouring with dig by Joe Rieng }
procedure contour;
{$ENDIF}

implementation

procedure road_arc;

var
  pi1,pi2,pi3 : integer;
  r,d1,d2     : real;
  asz1,asz2   : str16;
  a1,a2       : real;
  delta       : real;
  pt_rec      : point;
  road_width  : real;

begin
  mode('Road Arc Auto Pt. Creator'); writeln;
  write('Enter Start C.L. P.I.#1 '); pi1:=dig_point; writeln;
  write('Enter  Mid  C.L. P.I.#2 '); pi2:=dig_point; writeln;
  write('Enter  End  C.L. P.I.#3 '); pi3:=dig_point; writeln;
  write('Enter Arc Radius (0 = quit) ? '); r:=0; input_r(r); writeln;
  write('Enter Road Width RW=50.0 ft.? '); road_width:=50.0; input_r(road_width); writeln;
  if (r>0) and (pi1 <=no_pts) and (pi2 <=no_pts) and (pi3 <=no_pts) then
    begin
{      write('Is the Center Pt. Offset to the Right of Line Start-Mid (Y/N)');
      quest(0,0,' ? ',['Y','N'],false); writeln; }
      pt_to_pt(pi2,pi1,d1,asz1);
      pt_to_pt(pi2,pi3,d2,asz2);
      a1:=asz_rad(asz2)-asz_rad(asz1);
      if a1<0  then a1:=a1+2*pi;
      if a1<pi then response:='N' else response:='Y';
      pt_to_pt(pi1,pi2,d1,asz1);
      init_pt_rec(pt_rec);
      with pt_rec do
        begin from_pt:=pi1; distance:=r;
          if response='Y' then aszmith:=asz_rad(rad_asz(asz_rad(asz1)+pi/2))
          else aszmith:=asz_rad(rad_asz(asz_rad(asz1)+3*pi/2));
          a1:=asz_rad(rad_asz(aszmith+pi));
        end;
      calculate(pt_rec); put(no_pts+1,pt_rec);
      pt_to_pt(pi3,pi2,d2,asz2);
      init_pt_rec(pt_rec);
      with pt_rec do
        begin from_pt:=pi3; distance:=r;
          if response='N' then aszmith:=asz_rad(rad_asz(asz_rad(asz2)+pi/2))
          else aszmith:=asz_rad(rad_asz(asz_rad(asz2)+3*pi/2));
          a2:=asz_rad(rad_asz(aszmith+pi));
        end;
      calculate(pt_rec); put(no_pts+1,pt_rec);
      if abs(asz_rad(asz1)-asz_rad(asz2))>0.0005 then
            begin
              intersection(no_pts-1,no_pts,asz1,asz2,d1,d2);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=no_pts-1;
                end;
              calculate(pt_rec); put(no_pts+1,pt_rec);
              pt_to_pt(pi1,no_pts,d1,asz1);
              set_no_pts(no_pts-3);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=pi1; str(r:8:3,descrip);
                  descrip:='Center R='+descrip+'''';
                end;
              calculate(pt_rec); put(no_pts+1,pt_rec);
              { add PC points }
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  from_pt:=no_pts; aszmith:=a1;
                  distance:=r;
                  str(r:8:3,descrip); descrip:='PC @ CL R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  distance:=r-road_width/2;
                  str(distance:8:3,descrip); descrip:='PC @ In R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  distance:=r+road_width/2;
                  str(distance:8:3,descrip); descrip:='PC @ Out R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  { add PT points }
                  aszmith:=a2;
                  distance:=r;
                  str(r:8:3,descrip); descrip:='PT @ CL R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  distance:=r-road_width/2;
                  str(distance:8:3,descrip); descrip:='PT @ In R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  distance:=r+road_width/2;
                  str(distance:8:3,descrip); descrip:='PT @ Out R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  writeln;
                  writeln('*** 7 Curve Points Added ***');
                  writeln;
                  writeln('+++ Line File Arc Commands +++');
                  writeln;
                  if response='Y' then
                    begin
                      writeln('2 ',no_pts-5:5,no_pts-2:5,no_pts-6:5,' 3 1 P');
                      writeln('2 ',no_pts-4:5,no_pts-1:5,no_pts-6:5,' 0 1 P');
                      writeln('2 ',no_pts-3:5,no_pts-0:5,no_pts-6:5,' 0 1 P');
                      if lst_flag then begin
                        writeln(lst,'2 ',no_pts-5:5,no_pts-2:5,no_pts-6:5,' 3 1 P');
                        writeln(lst,'2 ',no_pts-4:5,no_pts-1:5,no_pts-6:5,' 0 1 P');
                        writeln(lst,'2 ',no_pts-3:5,no_pts-0:5,no_pts-6:5,' 0 1 P');
                      end;
                    end
                  else
                    begin
                      writeln('2 ',no_pts-2:5,no_pts-5:5,no_pts-6:5,' 1 1 P');
                      writeln('2 ',no_pts-1:5,no_pts-4:5,no_pts-6:5,' 0 1 P');
                      writeln('2 ',no_pts-0:5,no_pts-3:5,no_pts-6:5,' 0 1 P');
                      if lst_flag then begin
                        writeln(lst,'2 ',no_pts-2:5,no_pts-5:5,no_pts-6:5,' 1 1 P');
                        writeln(lst,'2 ',no_pts-1:5,no_pts-4:5,no_pts-6:5,' 0 1 P');
                        writeln(lst,'2 ',no_pts-0:5,no_pts-3:5,no_pts-6:5,' 0 1 P');
                      end;
                    end;
                  writeln;
                  writeln(^G,'+++ IMPORT Commands NOW into Desired Line File +++');
                end;
            end
          else begin
                 writeln('*** No Offset Point - Azs1=Asz2 ***');
                 set_no_pts(no_pts-2);
                 cogo_err:=true;
               end;
    end{ not user abort }
  else begin cogo_err:=true; writeln('*** User Aborted ***'); end;
end;

procedure snap_arc;

var
  pi1,pi2     : integer;
  r,d1,d2     : real;
  asz1,asz2   : str16;
  a1,a2       : real;
  delta       : real;
  pt_rec      : point;
  road_width  : real;

begin
  mode('Snap Arc Tangent on 2 Lines'); writeln;
  write('Enter Line#1 '); pi1:=dig_point;
  write('   Enter Aszmith from Pt#',pi1:4,' ? '); input_asz(asz1); writeln;
  write('Enter Line#2 '); pi2:=dig_point;
  write('   Enter Aszmith from Pt#',pi2:4,' ? '); input_asz(asz2); writeln;
  writeln;
  write('Enter Arc Radius (0 = quit) ? '); r:=0; input_r(r); writeln;

  if (r>0) and (pi1 <=no_pts) and (pi2 <=no_pts) then
    begin
      write('Is the Center Pt. Offset to the Right of Line#1 (Y/N)');
      quest(0,0,' ? ',['Y','N'],false); writeln;
      init_pt_rec(pt_rec);
      with pt_rec do
        begin from_pt:=pi1; distance:=r;
          if response='Y' then aszmith:=asz_rad(rad_asz(asz_rad(asz1)+pi/2))
          else aszmith:=asz_rad(rad_asz(asz_rad(asz1)+3*pi/2));
          a1:=asz_rad(rad_asz(aszmith+pi));
        end;
      calculate(pt_rec); put(no_pts+1,pt_rec);
      write('Is the Center Pt. Offset to the Right of Line#2 (Y/N)');
      quest(0,0,' ? ',['Y','N'],false); writeln;
      init_pt_rec(pt_rec);
      with pt_rec do
        begin from_pt:=pi2; distance:=r;
          if response='Y' then aszmith:=asz_rad(rad_asz(asz_rad(asz2)+pi/2))
          else aszmith:=asz_rad(rad_asz(asz_rad(asz2)+3*pi/2));
          a2:=asz_rad(rad_asz(aszmith+pi));
        end;
      calculate(pt_rec); put(no_pts+1,pt_rec);

      if abs(asz_rad(asz1)-asz_rad(asz2))>0.0005 then
            begin
              intersection(no_pts-1,no_pts,asz1,asz2,d1,d2);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=no_pts-1;
                end;
              calculate(pt_rec); put(no_pts+1,pt_rec);
              pt_to_pt(pi1,no_pts,d1,asz1);
              set_no_pts(no_pts-3);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=pi1; str(r:8:3,descrip);
                  descrip:='Center R='+descrip+'''';
                end;
              calculate(pt_rec); put(no_pts+1,pt_rec);
              { add PC points }
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  from_pt:=no_pts; aszmith:=a1;
                  distance:=r;
                  str(r:8:3,descrip); descrip:='P.C. R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  { add PT points }
                  aszmith:=a2;
                  str(r:8:3,descrip); descrip:='P.T. R='+descrip+'''';
                  calculate(pt_rec); put(no_pts+1,pt_rec);
                  writeln;
                  writeln('*** 3 Curve Points Added ***');
                  writeln;
                  writeln('+++ Line File Arc Command +++');
                  writeln;
                  if response='Y' then
                    begin
                      writeln('2 ',no_pts-0:5,no_pts-1:5,no_pts-2:5,' 0 1 P');
                      if lst_flag then
                        writeln(lst,'2 ',no_pts-0:5,no_pts-1:5,no_pts-2:5,' 0 1 P');
                    end
                  else
                    begin
                      writeln('2 ',no_pts-1:5,no_pts-0:5,no_pts-2:5,' 0 1 P');
                      if lst_flag then
                        writeln(lst,'2 ',no_pts-1:5,no_pts-0:5,no_pts-2:5,' 0 1 P');
                    end;
                  writeln;
                  writeln(^G,'+++ IMPORT Command NOW into Desired Line File +++');
                end;
            end
          else begin
                 writeln('*** No Offset Point - Azs1=Asz2 ***');
                 set_no_pts(no_pts-2);
                 cogo_err:=true;
               end;
    end{ not user abort }
  else begin writeln('*** User Aborted ***'); cogo_err:=true; end;
end;

procedure el_trans;
  var
    p1,p2,p3 : integer;
    p4,p5    : integer;
    asz      : str16;
    pt_rec   : point;
    pt_rec2  : point;
    x,y      : real;
    x2,y2    : real;
    xt,yt    : real;
    ang      : real;

  begin
    mode('Translate Elevations Mode'); writeln(' To another Base Datum.');
    write('  Enter FROM: Pt#=1 ? '); p1:=1; input_i(p1);
    write('  Enter TO: Pt#=',no_pts:3,' ? ');  p2:=no_pts; input_i(p2);
    p3:=1;
    gotoxy(1,3);
    writeln(lst);
    writeln(lst,'Translate Elev.     Point Range ',p1:4,' to ',p2:4);
    quest(1,6,'Translate by [P]oint-Point  [N]umber Elev.  [Q]uit ? ',['P','N','Q'],false);
    xt:=0;
    if response='N' then
      begin
        gotoxy(1,8);
        write('Enter Translation Elev. Height =0 (feet) ? '); input_r(xt); writeln;
      end
    else if response='P' then
           repeat
             gotoxy(1,8); clreos;
             p4:=1; p5:=1;
             write('Enter From Translation Pt#=1 ? '); input_i(p4); writeln;
             write('Enter   To Translation Pt#=1 ? '); input_i(p5); writeln;
             write(lst,'   Translate from Pt#',p4:4,' to  Pt#',p5:4);
             get(p4,pt_rec);
             get(p5,pt_rec2);
             xt:=pt_rec2.elev-pt_rec.elev;
             writeln('Delta Elev.=',xt:9:3);
             quest(0,0,'Is this Translation Data correct (Y/N/Quit) ? ',['Y','N','Q'],false);
           until response in ['Y','Q'];
    writeln(lst,'    Delta Elev.=',xt:9:3);
    writeln(lst);
    gotoxy(1,13);
    if (p1>0) and (p1<=no_pts) and (p2>p1) and
       (p2<=no_pts) and (p3<=no_pts) and (response<>'Q') then
      for i:=p1 to p2 do
        begin
          write(^M,'Point #',i:3);
          get(i,pt_rec);
          with pt_rec do
            begin
               elev:=elev+xt;
              rod:=-abs(rod);
            end;
          put(i,pt_rec);
        end;
  end;

{$IFDEF  contour}             { Semi Automated Contouring with dig by Joe Rieng }
procedure contour;
  var
    pt1,pt2 : integer;
    d,s     : real;
    asz     : str16;
    pt_rec  : point;
    no_pts3 : integer;
    cnt     : integer;

  procedure interp;
    var
      grd,k,j,dfel,a   : real;
      v,t              : integer;
      pt_rec0,pt_rec2  : point;  { Joe: pt_rec0 is NOT to be used GLOBALY }

    begin
      pt_err:=false;
      cnt:=0;
      if (pt1<=no_pts) and (pt2<=no_pts) then
        begin
          get(pt1,pt_rec); get(pt2,pt_rec0);
          if (pt_rec.elev<>0) and ( pt_rec0.elev <> 0) then
            begin
              if pt_rec.elev>pt_rec0.elev then
                begin
                  t :=pt2; pt2 :=pt1; pt1 :=t;
                  get(pt2,pt_rec0); get(pt1,pt_rec);
                end;{if find low elev}

              pt_to_pt(pt1,pt2,d,asz); a:=asz_rad(asz);

              dfel :=pt_rec0.elev-pt_rec.elev;            {difference elavation}
              k := pt_rec0.elev;                          {retain high elevation}
              v := trunc(pt_rec.elev);
              if odd(v) then dec(v);                      {even contour interval}
              v := v+2;
              if dfel=0 then grd:=0
              else grd :=d/dfel;       {grd assigned distance per change  1ft diff el.}
              while v<k do begin                  {contour less than high elev.}
                j :=v - pt_rec.elev;
                s :=j * grd;
                init_pt_rec(pt_rec0);              {replace elev pt_rec0 with p.o.c.l.}
                with pt_rec0 do begin
                  from_pt :=pt1;
                  bs_pt   := pt2;
                  aszmith := a;
                  distance:= s;
                  elev    := v;
                  descrip := 'contour';
                  calculate(pt_rec0);
                  put(no_pts+1,pt_rec0);
                  inc(cnt);
                  v :=v+2;
                end;{with}
              end;{while}
            end{if elev - 0}
          else write(^G);
        end;
    end;

  begin
    mode('Interpolate for Contours');
    no_pts3:=no_pts;
    while pt1 <>9999 do begin gotoxy(25,1); clreol;
      write('  Enter FROM '); pt1:=dig_point;
      write('   Enter TO ');  pt2:=dig_point;
      if (pt1<=no_pts) and (pt2<=no_pts) then
        begin
          get(pt1,pt_rec); display_rec(pt1,3,lightred,white,pt_rec);
          get(pt2,pt_rec); display_rec(pt2,9,lightblue,lightcyan,pt_rec);
          textcolor(white); gotoxy(1,15); clreos;
          interp;
          if cnt>0 then begin
            gotoxy(3,15);   write('Aszmith:  ',asz);
            gotoxy(32,15);  write('Distance: ',d:9:3);
            gotoxy(3,16);   write('Bearing: ',rad_bear(asz_rad(asz)));
          end;
          gotoxy(1,18); write(cnt:3,':',(no_pts-no_pts3):3,' Pts Added');
        end
      else begin gotoxy(5,19); bad_pt_msg; end;
    end;
  end{contour};
{$ENDIF}

end.
