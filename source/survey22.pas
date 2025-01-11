unit survey22;
interface
uses crt,survey0,basics2;

procedure line_line;
procedure line_arc;
procedure arc_arc;
procedure offset;
procedure Line_arc_Tan;

implementation

procedure line_line;
  var
    pt1,pt2   : integer;
    d1,d2     : real;
    asz1,asz2 : str16;
    pt_rec    : point;

  begin
    if option='Ll' then mode('Line/Line Intersection')
      else  mode('Line/Point Perpendicular');
    pt1:=9999; pt2:=9999;
    write('   Enter Line#1 ');  pt1:=dig_point; (* input_i(pt1); *)
    if option='Ll' then write('   Enter Line#2 ? ')
    else write('  Perpendicular  ');
    pt2:=dig_point;  (* input_i(pt2); *)
    if (pt1<=no_pts) and (pt2<=no_pts) then
      begin
        get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
        get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
        gotoxy(5,15); clreol;
        write('Enter Aszmith from Pt#',pt1:4,' ? '); input_asz(asz1);
        if option='Ll' then
          begin
            gotoxy(5,16); clreol;
            write('Enter Aszmith from Pt#',pt2:4,' ? '); input_asz(asz2);
          end
        else asz2:=rad_asz(asz_rad(asz1)+pi/2); { perpendicular }
        intersection(pt1,pt2,asz1,asz2,d1,d2);
        if lst_flag then
          begin
            if option='Ll' then write(lst,'Line/Line:') else write(lst,' Pt./Line:');
            writeln(lst,' Pt#',pt1:4,'  Az:',asz1:13,' D=',d1:9:3);
            writeln(lst,' Pt#':14,pt2:4,'  Az:',asz2:13,' D=',d2:9:3);
          end;
        init_pt_rec(pt_rec);
        with pt_rec do
          begin
           aszmith:=asz_rad(asz1); distance:=d1;
           from_pt:=pt1; descrip:='Line Intersection';
          end;
        ask_add(pt_rec);
        init_pt_rec(pt_rec);
        with pt_rec do
          begin
            aszmith:=asz_rad(asz2); distance:=d2;
            from_pt:=pt2; descrip:='Line Intersection';
          end;
        ask_add(pt_rec);
      end
    else begin gotoxy(5,16); bad_pt_msg; cogo_err:=true; end;
  end;

procedure line_arc;
  var
    pt1,pt2    : integer;
    d1,d2,d3   : real;
    asz1,asz2  : str16;
    r          : real;
    pt_rec     : point;

  begin
    mode('Line/Arc Intersection');
    pt1:=9999; pt2:=9999;
    write('     Enter Line ');    pt1:=dig_point;    { input_i(pt1); }
    write('  Enter Arc center '); pt2:=dig_point; { input_i(pt2); }
    if (pt1<=no_pts) and (pt2<=no_pts) then
      begin
        get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
        get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
        gotoxy(5,15); clreol;
        write('Enter Aszmith from Pt#',pt1:4,' ? ');
        input_asz(asz1); pt_rec.aszmith:=asz_rad(asz1);
        gotoxy(5,16);
        write('Enter Arc Radius ? ');
        input_r(r);
        asz2:=rad_asz(asz_rad(asz1)+pi/2);
        intersection(pt1,pt2,asz1,asz2,d1,d2);
        if abs(d2-r)<0.0005 then  { one tangent intersection }
          begin
            init_pt_rec(pt_rec);
            with pt_rec do
              begin
                aszmith:=asz_rad(asz1); distance:=d1;
                from_pt:=pt1; descrip:='Line/Arc Intersect';
              end;
            ask_add(pt_rec);
          end
        else if d2<r then
               begin
                 d3:=sqrt(r*r-d2*d2);
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(asz1); distance:=d1-d3;
                     if distance<0 then
                       begin
                         aszmith:=asz_rad(rad_asz(aszmith+pi));
                         distance:=-distance;
                       end;
                     from_pt:=pt1; descrip:='Line/Arc Intersect';
                   end;
                 ask_add(pt_rec);
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(asz1); distance:=d1+d3;
                     from_pt:=pt1; descrip:='Line/Arc Intersect';
                   end;
                 ask_add(pt_rec);
               end
             else begin cogo_err:=true; write('  *** No Line-Arc Intersection ***'); end;
      end
    else begin gotoxy(5,16); bad_pt_msg; cogo_err:=true; end;
  end;

procedure arc_arc;
  var
    p,pt1,pt2  : integer;
    d1,d2,d3   : real;
    asz1,asz2  : str16;
    r1,r2,a    : real;
    pt_rec     : point;

  begin
    mode('Arc/Arc Intersection');
    pt1:=9999; pt2:=9999;
    write('      Enter Arc#1 center '); pt1:=dig_point; { input_i(pt1); }
    write('  Arc#2 center ');     pt2:=dig_point; { input_i(pt2); }
    if (pt1<=no_pts) and (pt2<=no_pts) then
      begin
        get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
        get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
        gotoxy(5,15); write('Enter Arc#1 Radius ? '); input_r(r1);
        gotoxy(5,16); write('Enter Arc#2 Radius ? '); input_r(r2);
        if r2>r1 then
          begin
            a:=r1; r1:=r2; r2:=a;
            p:=pt1; pt1:=pt2; pt2:=p;
          end;
        pt_to_pt(pt1,pt2,d1,asz1);
        if (abs(d1+r2-r1)<0.0005) or (abs(d1-r2-r1)<0.0005) then
          begin  { one intersection at tangant }
            init_pt_rec(pt_rec);
            with pt_rec do
              begin
                aszmith:=asz_rad(asz1); distance:=r1;
                from_pt:=pt1; descrip:='Arc/Arc Intersect';
              end;
              ask_add(pt_rec);
          end
        else if (d1-r2<r1) and (d1+r2>r1) then
               begin  { 2 intersection }
                 d2:=(d1+r1+r2)/2;
                 d3:=(d2-d1)*(d2-r1)/(d1*r1); { SIN^2(.5A) }
                 d2:=1-d3;                    { COS^2(.5A) };
                 a:=arctan(sqrt(d3/d2))*2;
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(rad_asz(asz_rad(asz1)+a));
                     distance:=r1;
                     from_pt:=pt1; descrip:='Arc/Arc Intersect';
                   end;
                 ask_add(pt_rec);
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(rad_asz(asz_rad(asz1)-a));
                     distance:=r1;
                     from_pt:=pt1; descrip:='Arc/Arc Intersect';
                   end;
                 ask_add(pt_rec);
               end
             else begin cogo_err:=true; write('  *** No Arc-Arc Intersection ***'); end;
      end
    else begin cogo_err:=true; gotoxy(5,16); bad_pt_msg; end;
  end;

procedure offset;
  var
    pt1,pt2   : integer;
    asz1,asz2 : str16;
    d1,d2     : real;
    pt_rec    : point;

  begin
    mode('Offset Point Calculation');
    pt1:=9999; pt2:=9999;
    write('   Enter Line#1 '); pt1:=dig_point;   { input_i(pt1); }
    write('   Enter Line#2 '); pt2:=dig_point;   { input_i(pt2); }
    if (pt1<=no_pts) and (pt2<=no_pts) then
      begin
        get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
        get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
        gotoxy(3,15); clreol;
        write('Enter Aszmith from Pt#',pt1:4,' ? '); input_asz(asz1);
        init_pt_rec(pt_rec);
        with pt_rec do
          begin
            gotoxy(46,15); write('Offset ? '); input_r(distance);
            quest(63,15,'Side R/L ? ',['R','L'],false);
            if response='R' then aszmith:=asz_rad(rad_asz(asz_rad(asz1)+pi/2))
            else aszmith:=asz_rad(rad_asz(asz_rad(asz1)+3*pi/2));
            roll_asz(rad_asz(aszmith));
            from_pt:=pt1;
          end;
          calculate(pt_rec);
          put(no_pts+1,pt_rec);
          gotoxy(3,16); clreol;
          write('Enter Aszmith from Pt#',pt2:4,' ? '); input_asz(asz2);
        init_pt_rec(pt_rec);
        with pt_rec do
          begin
            gotoxy(46,16); write('Offset ? '); input_r(distance);
            quest(63,16,'Side R/L ? ',['R','L'],false);
            if response='R' then aszmith:=asz_rad(rad_asz(asz_rad(asz2)+pi/2))
            else aszmith:=asz_rad(rad_asz(asz_rad(asz2)+3*pi/2));
            roll_asz(rad_asz(aszmith));
            from_pt:=pt2;
          end;
          calculate(pt_rec);
          put(no_pts+1,pt_rec);
          if abs(asz_rad(asz1)-asz_rad(asz2))>0.0005 then
            begin
              intersection(no_pts-1,no_pts,asz1,asz2,d1,d2);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=no_pts-1;
                end;
              calculate(pt_rec);
              put(no_pts+1,pt_rec);
              pt_to_pt(pt1,no_pts,d1,asz1);
              set_no_pts(no_pts-3);
              init_pt_rec(pt_rec);
              with pt_rec do
                begin
                  aszmith:=asz_rad(asz1); distance:=d1;
                  from_pt:=pt1; descrip:='Offset';
                end;
              ask_add(pt_rec);
            end
          else begin
                 gotoxy(5,17);
                 write('*** No Offset Point - Azs1=Asz2 ***');
                 set_no_pts(no_pts-2);
                 cogo_err:=true;
               end;
      end
    else begin gotoxy(5,16); bad_pt_msg; cogo_err:=true; end;
  end;

procedure Line_arc_Tan;
  var
    pt1,pt2    : integer;
    d1,r       : real;
    asz1,asz2  : str16;
    pt_rec     : point;
    d2,a       : real;
  begin
    mode('Line/Arc Tangent Point');
    pt1:=9999; pt2:=9999;
    write('  Enter Tangent Line ');       pt1:=dig_point; { input_i(pt1); }
    write('  Enter Arc center ');   pt2:=dig_point; { input_i(pt2); }
    if (pt1<=no_pts) and (pt2<=no_pts) then
      begin
        get(pt1,pt_rec); display_rec(pt1,3,lightgray,white,pt_rec);
        get(pt2,pt_rec); display_rec(pt2,9,cyan,lightcyan,pt_rec);
        gotoxy(5,16);
        write('Enter Arc Radius ? ');
        input_r(r);
        pt_to_pt(pt1,pt2,d1,asz1);
        if abs(d1-r)<0.0005 then  { one tangent intersection }
          begin
            gotoxy(5,17);
            write('*** The point is on the Arc. ***');
          end
        else if d1>r then
               begin
                 d2:=sqrt(d1*d1-r*r);
                 a:=arctan(r/d2);    { angle }
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(rad_asz(asz_rad(asz1)+a));
                     distance:=d2;
                     from_pt:=pt1; descrip:='Line/Arc Tangent';
                   end;
                 ask_add(pt_rec);
                 init_pt_rec(pt_rec);
                 with pt_rec do
                   begin
                     aszmith:=asz_rad(rad_asz(asz_rad(asz1)-a+2*pi));
                     distance:=d2;
                     from_pt:=pt1; descrip:='Line/Arc Tangent';
                   end;
                 ask_add(pt_rec);
               end
             else begin cogo_err:=true; write('  *** No Line-Arc Tangent Points ***'); end;
      end
    else begin gotoxy(5,16); bad_pt_msg; cogo_err:=true; end;
  end;

end.
