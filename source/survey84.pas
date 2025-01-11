{$F+,O+}
unit survey84;
interface
uses crt,survey0,basics2;

procedure descrip_ed;
procedure find;

implementation

procedure descrip_ed;
  var
   pt     : integer;
   pt_rec : point;
   des2   : string[20];

  begin
    mode('Edit Pt Descriptions    Alt-X to Exit');
    pt:=1;

    gotoxy(40,3); write('Enter Ed Pt#= ',pt,' '); input_i(pt);
    repeat

      if (pt>0) and (pt<=no_pts) then
        begin
          get(pt,pt_rec); des2:=pt_rec.descrip;
          display_rec(pt,9,cyan,lightcyan,pt_rec);
          gotoxy(59,9);  input_des(pt_rec.descrip);
          if des2<>pt_rec.descrip then put(pt,pt_rec);
          inc(pt);
        end;
    until (pt>no_pts) or (pt<1);
  end;

procedure find;
  var
    p1,p2,p3 : integer;
    bs,i     : integer;
    r,d,x,a1 : real;
    e,de     : real;
    des      : str20;

    asz1,asz2: str16;
    asz3,asz4: str16;

    sort_rec : sort_xyp;

  begin
    mode('FInd Proximity Pts');
    write('   Enter Set Up_'); p1:=0; p1:=dig_point;
    write('   Back Site_');    bs:=1; bs:=dig_point;
    writeln;

    write('Proximity Distance= 100 ? '); r:=100; input_r(r);
    write('   Enter Low=1 ? '); p2:=1;       input_i(p2);
    write('  Upper=',no_pts,' ? ');      p3:=no_pts;  input_i(p3);
    writeln;

    write('Elev.Datum=0 ? ');  e:=0; de:=10; input_r(e);
    if e<>0 then begin write('  Elev.Prox.=10 ? '); input_r(de); end;
    write('   Description: ');  des:=''; input_des(des);
    for i:=1 to length(des) do des[i]:=upcase(des[i]);

    writeln;
    writeln;

    pt_found_sort:=0;
    if (p1<=no_pts) and (p1>0) then
      begin
        get(p1,pt_rec);
        x:=pt_rec.east;
        with pt_rec do find_xy(east,north,r);
        if pt_found_sort>0 then
          begin
            repeat  { find first point in range }
              get3(pt_found_sort,sort_rec);
              if abs(sort_rec.x-x)<=r then dec(pt_found_sort);
            until (pt_found_sort=0) or (abs(sort_rec.x-x)>r);
            inc(pt_found_sort);

            pt_to_pt(p1,bs,d,asz2);  { get back sight aszmith }
            if lst_flag then
              begin
                writeln(lst,'FIND PROX.  SetUp_Pt:',p1,'  BS_Pt:',bs,'  Prox.Dist.=',r:8:2,'  Pt Range=',p2,'-',p3);
                writeln(lst,'Pt#':4,'HZ-Ang Right':14,'Distance':10,'Bear / Azimuth':17,'Elevation':12,'Description':13);
                writeln(lst,'===':4,'============':14,'========':10,'==============':17,'=========':12,'===========':13);
              end;

            writeln('Pt#':4,'HZ-Ang Right':14,'Distance':10,'Bear / Azimuth':17,'Elevation':12,'Description':13);
            writeln('===':4,'============':14,'========':10,'==============':17,'=========':12,'===========':13);
            clreos;

            repeat
              get3(pt_found_sort,sort_rec);
              get(sort_rec.p,pt_rec);
              if (sort_rec.p<=p3) and (sort_rec.p>=p2) then
                begin
                  with pt_rec do for i:=1 to length(descrip) do
                    descrip[i]:=upcase(descrip[i]);
                  pt_to_pt(p1,sort_rec.p,d,asz1);
                  if d<=r then with pt_rec do
                    if (des='?') or (pos(des,descrip)>0) then
                      if (e=0) or ((e-de<=elev) and (e+de>=elev)) then
                        begin
                          asz4:=asz1;  { azmiuth to pt }
                          if not as_br_flg then asz4:=rad_bear(asz_rad(asz4));
                          a1:=asz_rad(asz1)-asz_rad(asz2);
                          while a1<0 do a1:=a1+2*pi;
                          asz3:=rad_asz(a1);              { Hz-ang to pt }
                          writeln(sort_rec.p:4,'  ',asz3,d:10:3,' ':3,asz4:14,elev:11:2,'   ',descrip);
                          if lst_flag then
                            writeln(lst,sort_rec.p:4,'  ',asz3,d:10:3,' ':3,asz4:14,elev:11:2,'   ',descrip);
                        end;
                end;
              inc(pt_found_sort);
            until (pt_found_sort>no_pts) or (abs(pt_rec.east-x)>r);
          end;
      end;

  end{find};


end.
