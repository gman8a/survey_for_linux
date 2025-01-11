unit survey1;
interface
uses crt,survey0,basics2;

procedure balance;
procedure rot_tran;
procedure curve;

implementation

procedure curve;
  var
    r,d,l  : real;
    c,m,a  : real;
    t      : real;
    ca     : real;
    s      : str16;
  begin
     mode(' Curve Calculation ');
     write('  ...Press <RETURN> for unknown variables.');
     gotoxy(1,3);
     d:=0; t:=0; c:=0; r:=0; l:=0; s:='';
     write('Enter Curve Radius R=? '); input_r(r);   writeln;
     write('Enter Delta Angle  D=? '); input_asz(s); writeln;
     write('Enter Arc Length   L=? '); input_r(l);   writeln;
     if s<>'' then d:=asz_rad(s);
     if (r<>0) and (l<>0) then d:=l/r else if (l<>0) and (d<>0) then r:=l/d;
     if r*d=0 then
       begin
         write('Enter Chord Length C=? '); input_r(c); writeln;
         if (r<>0) and (c<>0) and (sqr(r)>=sqr(c/2)) then
           begin m:=sqrt(sqr(r)-sqr(c/2)); d:=2*arctan(c/2/m); end
         else if (d<>0) and (c<>0) then r:=c/2/sin(d/2)
              else begin
                     write('Enter Tangent Dist T=? '); input_r(t); writeln;
                     if (t<>0) and (r<>0) then d:=2*arctan(t/r)
                     else if (t<>0) and (d<>0) then r:=t/tan(i/2);
                   end;
       end;
     c:=r*sin(d/2)*2;
     l:=r*d;
     if (t=0) then t:=r*tan(d/2);
     if (sqr(r)>=sqr(c/2)) then m:=sqrt(sqr(r)-sqr(c/2));
     a:=sqr(r)*d/2;
     ca:=a-(c/2*m);
     writeln;
     writeln('Arc Radius =',r:10:4); roll_real(r);
     writeln('Delta Ang  =',rad_asz(d)); roll_asz(rad_asz(d));
     writeln('Arc Length =',l:10:4); roll_real(l);
     writeln('Chord Len  =',c:10:4); roll_real(l);
     writeln('Tangent    =',t:10:4); roll_real(t);
     writeln('Arc Area   =',a:10:4);
     writeln('Chord Area =',ca:10:4);
  end;

procedure balance;
  var
    i,j,k,l,q : integer;
    k2        : integer;
    pt_rec    : point;
    pt_rec2   : point;
    pt_rec3   : point;
    p         : array[1..250] of integer;
    d,d2      : real;
    asz,asz2,
    asz3      : str16;
    tot_dis   : real;
    tot_ver   : real;
    tot_ang   : real;
    lat,dep   : real;
    vert      : real;
    hz_dis    : real;
    vt_dis    : real;
    l_t_pt      : integer;
    ang_err     : real;
    clock_wise  : char;
    mult_ln_flg : boolean;
    mult_ln_cnt : integer;
    err         : boolean;
    last_el     : real;
    err_chk     : boolean;
    no_ang_bal  : array[0..100] of integer;
    adj_ang     : boolean;
    open        : boolean;

procedure print_data;  { print output }
  var  str2 : string[2];
         k,i: integer;
  begin
    if lst_flag then
      begin
        writeln(lst,'PT# to PT#         Angle  *Hold    Bearing    Distance      North       East');
        writeln(lst,'====   ====      ==========       =========  ==========  ========== ===========');
        for k:=1 to j do begin
          get(p[k],pt_rec); if pt_rec.code=2 then str2:='L ' else str2:='R ';
          for i:=1 to no_ang_bal[0] do if no_ang_bal[i]=p[k] then str2[2]:='*';

          if k=1 then
            with pt_rec do writeln(lst,' ':4,p[k]:7,' ':45,north:11:4,' ',east:11:4)
          else with pt_rec do
            begin pt_to_pt(p[k-1],p[k],d,asz);
              writeln(lst,p[k-1]:4,p[k]:7,rad_asz(hz_ang):14,str2:2,
                      rad_bear(asz_rad(asz)):16,d:12:4,' ',north:11:4,' ',east:11:4);
            end{if else};
        end{for};
        for k:=1 to 79 do write(lst,'-'); writeln(lst);
      end;
  end;

  begin
    mode('COMPASS Rule Balance');
    write('   0=Thru,  -Pt=Hold Angle,  Closing Angle Pt.Dist.=0.00');

  if not alt_flag then begin

    textcolor(cyan);
    quest(1,2,'Closed Loop Y/N ? ',['Y','N'],false);
    if response='Y' then open:=false else open:=true;
    quest(0,0,'  Clock-Wise Y/N ? ',['Y','N'],false);
    clock_wise:=response;
    quest(0,0,'  ERRor Chk. Y/N ? ',['Y','N'],false);
    if response='Y' then err_chk:=true else err_chk:=false;
    write('  CLOSE-TO '); l:=9999; l:=dig_point;

    for k2:=0 to 100 do no_ang_bal[k2]:=0;
    gotoxy(1,8);  for k2:=1 to 80 do write('-');
    gotoxy(1,15); for k2:=1 to 80 do write('-');
    mult_ln_flg:=false; err:=false; j:=0; k:=0;
    if (l<1) or (l>no_pts) then err:=true;

    repeat
      repeat
        j:=j+1;
        if (j=1) and not open then k:=l
        else
          if not mult_ln_flg then
            begin
              gotoxy(5,14); clreol; textcolor(white);
              write('Enter Trav. Station ',j:2,' ');
              k:=9999; k:=dig_point; if k=9999 then err:=true; { exit condition }
            end;
        if k=0 then
          repeat
            gotoxy(36,14); clreol; write('Thru '); l_t_pt:=dig_point;
            mult_ln_flg:=true;
          until l_t_pt>mult_ln_cnt;
        if mult_ln_flg then
          begin k:=mult_ln_cnt+1;
                if k=l_t_pt then mult_ln_flg:=false;
          end;
        if abs(k)>no_pts then
          begin gotoxy(50,14); bad_pt_msg; delay(800);
                mult_ln_flg:=false; j:=j-1;
          end
        else if k<0 then
               begin inc(no_ang_bal[0]);
                     no_ang_bal[no_ang_bal[0]]:=abs(k);
               end;
      until (k<=no_pts) or err;

      if not err then begin
        get(abs(k),pt_rec); display_rec(abs(k),3,lightgray,white,pt_rec);
        gotoxy((((j-1) mod 14)+1)*5,9+(j-1) div 14);
        textcolor(white); write(k:4);
        k:=abs(k); p[j]:=k;
        with pt_rec do
        if   err_chk and (k<>l) and
            ((((j>1) and (abs(from_pt)<>p[j-1])) or
              ((j=2) and open and (bs_pt=0)) or
              ((j>2) and (bs_pt<>p[j-2]))) or not setup)
        then begin
               gotoxy(1,19); clreos; writeln('Traverse Pt ERRORs:',^G);
               mult_ln_flg:=false;
               if setup<>true then
                 write('Pt#',k,' is NOT a SETUP Pt.');
               if (j>1) and (abs(from_pt)<>p[j-1]) then
                 write('  Pt#',k,' is NOT FROM Pt# ',p[j-1]);
               if (j>2) and (abs(bs_pt)<>p[j-2]) then
                 write('  Pt#',k,' does NOT BS Pt# ',p[j-2]);
               if (j=2) and open and (bs_pt=0) then
                 write('  Pt#',k,' must have BS Pt# > 0');
               j:=j-1;
             end
        else mult_ln_cnt:=k;
      end{if not err};
    until ((l=k) and (j>1)) or (err);

    if lst_flag then writeln(lst,' ':26,'>>> RAW Traverse Data <<<'); print_data;

(**********************************************************************)

k2:=0; { close direction pt for open loops. }
if not err then begin
  repeat
    tot_dis:=0; tot_ver:=0; tot_ang:=0; { figure total distance traversed }
    for i:=2 to j-1 do
      begin
        get(p[i],pt_rec); get(p[i-1],pt_rec2);
        tot_dis:=tot_dis+pt_rec.distance;
        tot_ver:=tot_ver+abs(pt_rec.elev-pt_rec2.elev);
        if open or (i>2) then { figure total angle turned }
          case pt_rec.code of
            0,1:if pt_rec.bs_ang<pt_rec.hz_ang then
                  tot_ang:=tot_ang+pt_rec.hz_ang-pt_rec.bs_ang
                else tot_ang:=tot_ang+pt_rec.hz_ang-pt_rec.bs_ang+2*pi;
              2:if pt_rec.bs_ang>pt_rec.hz_ang then
                  tot_ang:=tot_ang+pt_rec.bs_ang-pt_rec.hz_ang
                else tot_ang:=tot_ang+pt_rec.bs_ang-pt_rec.hz_ang+2*pi;
          end{case};
      end;

    get(p[j-1],pt_rec2); get(p[j],pt_rec); get(p[2],pt_rec3);
    lat:=pt_rec.north-pt_rec2.north;
    dep:=pt_rec.east -pt_rec2.east;
    vert:=pt_rec.elev-pt_rec2.elev;  if abs(vert)<0.001 then vert:=0.001;
    pt_to_pt(p[j],p[j-1],d,asz);     if  d<0.00001 then  d:=0.00001;

    for k:=3 to 7 do begin gotoxy(1,k); clreol; end;
    gotoxy(1,4); textcolor(yellow);
    with pt_rec do
      writeln('Pt#',p[j]:4,'  Des:',descrip:20,'    N',north:11:4,'    E',east:11:4,'   el',elev:9:3);
    with pt_rec2 do
      writeln('Pt#',p[j-1]:4,'  Des:',descrip:20,'    N',north:11:4,'    E',east:11:4,'   el',elev:9:3);
    writeln(' ':38,'===========     ','===========','     =========');
    writeln('Traverse Errors ---->',' ':9,'Latitude',lat:11:4,'  Dep',dep:11:4,'  dEl',vert:9:3);

    if open then
      begin
        if k2=0 then
          begin gotoxy(1,14); textcolor(white); clreol;
            write('Enter Closing Direction Pt?  From Pt# ',p[j]:2,' To ');
            k2:=dig_point;
            with pt_rec3 do pt_to_pt(abs(from_pt),abs(bs_pt),d2,asz2);
            pt_to_pt(p[j],k2,d2,asz3); write('     Asz: ',asz3);
          end;
        ang_err:=(asz_rad(asz3)-asz_rad(rad_asz(asz_rad(asz2)+tot_ang)))/(j-2-no_ang_bal[0]);
      end
    else
      begin
        if clock_wise='Y' then ang_err:= ((j-1)*pi-tot_ang)/(j-3-no_ang_bal[0])
        else ang_err:=((j-5)*pi-tot_ang)/(j-3-no_ang_bal[0]);
      end;

      gotoxy(1,16); clreos; textcolor(lightgreen);
      gotoxy(3,16);   write('Aszmith:  ',asz);
      gotoxy(3,17);   write('Bearing: ',rad_bear(asz_rad(asz)));
      gotoxy(35,16);  write('Closure: ',d:9:3);
      gotoxy(34,17);  write('Traverse: ',tot_dis:9:3);
      gotoxy(34,18);  write('Accuracy: ',tot_dis/d:9:0);
      gotoxy(60,17);  write('Total-Vert:',tot_ver:9:3);
      gotoxy(60,18);  write('Vert. Acc.:',tot_ver/vert:9:0);

      gotoxy(1,20); write('Angle Error=',rad_asz(abs(ang_err)),' per Angle.');
      quest(0,0,'  Balance Angles (Y/N) ? ',['Y','N'],false);
      if response='Y' then
        begin
          for i:=2 to j-1 do with pt_rec do
            begin
              adj_ang:=true;
              for k:=1 to no_ang_bal[0] do
                if no_ang_bal[k]=p[i] then adj_ang:=false;
              if (i>2) or open then
                begin
                  get(p[i],pt_rec);
                  if adj_ang then
                    case code of
                      0,1:hz_ang:=hz_ang+ang_err;
                        2:hz_ang:=hz_ang-ang_err;
                    end{case};
                  hz_ang:=asz_rad(rad_asz(hz_ang+2*pi));
                  if code=0 then code:=1;
                  put(p[i],pt_rec);
                end;
            end;
          recalculate(1);
          if lst_flag then writeln(lst,' ':17,'>>> Traverse Data with Balanced Angles <<<');
          print_data;
        end;
  until response='N';

  quest(1,21,'Balance Trav. using above Closure Error (Y/N) ? ',['Y','N'],false);
    if response='Y' then
      begin
        quest(1,22,'Balance Elevations ? ',['Y','N'],false);
        gotoxy(10,24); write('Calculating ...Please wait');

        hz_dis:=0;         { Balance Traverse - Compass Rule }
        vt_dis:=0;
        for i:=2 to j-1 do
          begin
            get(p[i],pt_rec);
            get(p[i-1],pt_rec2);
            if i=2 then last_el:=pt_rec2.elev;
            hz_dis:=hz_dis+pt_rec.distance;
            vt_dis:=vt_dis+abs(pt_rec.elev-last_el);
            last_el:=pt_rec.elev;
            with pt_rec do
              begin
                north:=north+ lat*hz_dis/tot_dis;
                east :=east + dep*hz_dis/tot_dis;
                if (elev<>0) and (tot_ver>0) and (response='Y') then
                  elev :=elev +vert*vt_dis/tot_ver;
              end;
            put(p[i],pt_rec);
          end;

        for i:=2 to j-1 do { Figure new Aszmith and Distance }
          begin
            pt_to_pt(p[i-1],p[i],d,asz);
            get(p[i],pt_rec);
            with pt_rec do
              begin
                aszmith:=asz_rad(asz);
                distance:=d;
                code:=0;
                if response='Y' then rod:=-rod;
                bs_ang:=0;
              end;
            put(p[i],pt_rec);
          end;
        recalculate(1);
        for i:=1 to j-1 do { protect traverse }
          begin
            get(p[i],pt_rec);
            pt_rec.from_pt:=-abs(pt_rec.from_pt);
            put(p[i],pt_rec);
          end;
        flush_pt_file;
        if lst_flag then writeln(lst,' ':25,'>>> Traverse Data BALANCED <<<');
        print_data;
      end;
  end{if not err};
  end { if not alt_flag }
  else begin writeln; writeln(^G,'Can NOT Balance Alternate Point File.'); end;
  end;

procedure rot_tran;

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
    resp2    : char;

  begin
    mode('Rotate (CCW)/Translate Mode'); writeln(' ==> TRANS. is Completed First.');
    write('  Enter FROM: Pt#=1 ? '); p1:=1; input_i(p1);
    write('  Enter TO: Pt#=',no_pts:3,' ? ');  p2:=no_pts; input_i(p2);
    gotoxy(1,3);
    write('Enter Rotate About Pt#=1 ? '); p3:=1; input_i(p3);
    gotoxy(1,4);
    write('Enter Rotation Angle (DDD-MM-SS) ? ');
    input_asz(asz);
    if asz<>'' then ang:=asz_rad(asz)*180/pi else ang:=0;
    asz:=rad_asz(asz_rad(asz));
    writeln(lst);
    writeln(lst,'Rotate/Translate    Point Range ',p1:4,' to ',p2:4);
    writeln(lst,'   Rotate about Pt#',p3:4,'   ',asz);
    quest(1,6,'Translate by [P]oint-Point  [N]orth/East distance  [Q]uit ? ',['P','N','Q'],false);
    xt:=0; yt:=0;
    if response='N' then
      begin
        gotoxy(1,8);
        write('Enter North Translation=0 (feet) ? '); input_r(yt); writeln;
        write('Enter  East Translation=0 (feet) ? '); input_r(xt);
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
             xt:=pt_rec2.east-pt_rec.east;
             yt:=pt_rec2.north-pt_rec.north;
             writeln('XT=',xt:9:3,'  YT=',yt:9:3);
             quest(0,0,'Is this translation data correct (Y/N/Quit) ? ',['Y','N','Q'],false);
             resp2:=response;
           until response in ['Y','Q'];
    writeln; quest(0,0,'Rotate Zero (0,0) Coordinates (Y/N) ? ',['Y','N'],false);
    writeln(lst,'    XT=',xt:9:3,'  YT=',yt:9:3);
    writeln(lst);
    get(p3,pt_rec);
    x:=pt_rec.east;
    y:=pt_rec.north;
    gotoxy(1,13);
    if (p1>0) and (p1<=no_pts) and (p2>=p1) and
       (p2<=no_pts) and (p3<=no_pts) and (resp2<>'Q') then begin
      for i:=p1 to p2 do
        begin
          write(^M,'Point #',i:3);
          get(i,pt_rec);
          if (pt_rec.north<>0) or (pt_rec.east<>0) or (response='Y') then
            with pt_rec do
              begin
                x2:=east+xt;
                y2:=north+yt;
                rotate(x2,y2,x,y,ang);
                east:=x2;
                north:=y2;
(*                code:=0;   *)
                from_pt:=-abs(from_pt);
                put(i,pt_rec);
              end;
        end;
     recalculate(p2+1);
    end;
  end;


end.

