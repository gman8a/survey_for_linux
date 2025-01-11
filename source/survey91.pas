unit survey91;
interface
uses crt,dos,basics2,survey0;

{$I Direct}   { Compiler directives }

{$IFDEF vert_profile}        { Verticle Profile, Verticle Curve by Joe Rieng }
PROCEDURE PROFILE;
PROCEDURE VERTPROF;
{$ENDIF}

implementation

{$IFDEF vert_profile}        { Verticle Profile, Verticle Curve by Joe Rieng }
 procedure profile;

  var
    f,pt1,pt2,scale : integer;
    d,s     : real;
    asz     : str16;
    pt_rec  : point;
    ans     : char;
    added   :boolean;

procedure ptenter;                         {to enter station and elevation}
  var
    grd,k,j,dfel,n,e,a,station   : real;
    q,i,t    : integer;
    pt_rec2 : point;
  begin
       writeln;
       writeln('             enter station');
       read(station);
       writeln;
       writeln('enter elevation');
       read(grd);
       with pt_rec2 do begin
         init_pt_rec(pt_rec2);
         descrip :='profile pt';
         if scale = 40 then
           north :=grd*10
         else north :=grd * 5;
         east :=station;
         elev := grd;
         put(no_pts+1,pt_rec2);
        end;                   {with}
     end;                    {if elev - 0}

procedure pro(p1,p2: integer; var d:real; var asz:str16);
  var
    s,grd,k,j,dfel,n,e,a   : real;
    q,i,t    : integer;
    pt_rec,
    pt_rec2 : point;
  begin
    pt_err:=false;
    if (p1<=no_pts) and (p2<=no_pts) then
      begin
        get(p1,pt_rec);
        get(p2,pt_rec2);
        if (pt_rec.elev<>0)and( pt_rec2.elev <> 0) then begin
          added:= true;
          n:=pt_rec2.north-pt_rec.north;
          e:=pt_rec2.east-pt_rec.east;
          q:=1;
          if n>0 then q:=2 else if (n=0) and (e>0) then q:=2;
          if n=0 then a:=pi/2 else a:=arctan(e/n);
           a:=a+q*pi;
           asz:=rad_asz(a);
           d:=sqrt(n*n+e*e);
           if f<>1 THEN begin
             if scale =40 then
             pt_rec.north:=pt_rec.elev*10
           else pt_rec.north:=pt_rec.elev * 5;
          pt_rec.east:=1000;
          PT_REC.FROM_pT:=0;
          PT_REC.BS_pT:=0;
          pt_rec.descrip:='profile';
          put(no_pts+1,pt_rec);
          i:=1;
          f:=1;
         end;
          with pt_rec2 do begin
            from_pt :=0;
            bs_pt := 0;
            aszmith :=0;
            descrip :='profile pt';
            distance :=0;
            if scale = 40 then
               north :=elev*10
            else north :=elev * 5;
            east :=1000+d;
            put(no_pts+1,pt_rec2);
            i:=i+1;
           end;                   {with}
          end;                     {while}
         end                    {if elev - 0}
         else write(^G);
       end;

procedure statn(p1:integer);
  var
    s,grd,k,j,dfel,n,e,a,station   : real;
    q,i,t    : integer;
    pt_rec,
    pt_rec2 : point;
  begin
    pt_err:=false;
    if (p1<=no_pts)  then
      begin
        get(p1,pt_rec2);
        writeln('             enter station');
        read(station);
        with pt_rec2 do begin
          from_pt :=0;
          bs_pt := 0;
          aszmith :=0;
          descrip :='profile pt';
          distance :=0;
          if scale = 40 then
            north :=elev*10
          else north :=elev * 5;
          east :=station;
          put(no_pts+1,pt_rec2);
         end;                   {with}
        end                    {if elev - 0}
        else write(^G);
       end;

  begin                                   {proc profile}
    f:=0;
    mode(' cross section plot system');
    writeln('enter scale "20" for 4v 20h or "40" for 4v 40h ');
    readln(scale);
    write(' type "s" to input station and pt # type "p" for pt to pt     ');
    readln(ans);
    if ans='p' then begin                        {if p}
      write('        Enter FROM Pt# ? ');  pt1:=dig_point;
      while pt2 <>9999 do begin                          {while not 9999}
        write('        Enter TO Pt# ? ');  pt2:=dig_point;
        if (pt1<=no_pts) and (pt2<=no_pts) then
          begin                                               {if pt_no <#pts}
          get(pt1,pt_rec); display_rec(pt1,3,lightgreen,white,pt_rec);
          get(pt2,pt_rec); display_rec(pt2,9,lightblue,lightcyan,pt_rec);
          textcolor(white);
          pro(pt1,pt2,d,asz);
         if added=true then begin
          gotoxy(3,15);   write('Aszmith:  ',asz);
          gotoxy(32,15);  write('Distance: ',d:9:3);
          gotoxy(3,16);   write('Bearing: ',rad_bear(asz_rad(asz)));
        end;
        end                              {if}
       else begin gotoxy(5,16); bad_pt_msg; end;                {while}
      end;
    end else if ans ='s'then begin                                  {if p} {if s}
     while pt1 <> 9999 do begin
       write('   Enter  Pt# ? ');   pt1:=dig_point;
       if pt1<>0 then begin
       if (pt1<=no_pts)  then
        begin                                               {if < #pts}
        get(pt1,pt_rec); display_rec(pt1,3,lightmagenta,white,pt_rec);
        textcolor(white);
        statn(pt1);
       end                                                            {if s}
       else begin gotoxy(5,16); bad_pt_msg; end;                         {while}
     end else ptenter;
   end;
     end;                                                      {IF}
   end;


 procedure vertprof;
 var
   pt_rec2 :point;
   g1,g2 : real;  { grades }
   d     : real;  { distance from g1 grade line }
   e     : real;  { distance from P.V.I. }
   a     : real;  { algebraic differance in g1,g2 }
   l     : real;  { length of curve }
   l2    : real;  { distance form p.v.c. }
   pvi   : real;  { P.V.I. station }
   pvc   : real;  { P.V.C. station }
   elev1  : real;  { P.V.I. elevation }
   elev2 : real;  { P.V.C. elevation }
   elev3 : real;  { elevation on grade line 1 @ distance l2 }
   x,y,t,scale : integer;
begin

  mode(' Vertical Curve Computation ');
  writeln;
  textcolor(lightcyan);
  writeln('ENTER SCALE "40"4-40 "20"4-20');
  readln(scale);
  writeln;
  writeln('Enter Grades (+or- G1% G2%) ? '); readln(g1,g2);
  writeln('Enter Curve Length  (L ft.) ? '); readln(l);
  writeln('Enter P.V.I. Station ? '); read(pvi);
  writeln('  Enter P.V.I. Elevation ? '); readln(elev1);
  t:=25; writeln('Enter Tab Interval (T=25 ft.) ? '); readln(t);
  a:=g1-g2;
  e:=a*l/100/8;
  elev2:=elev1-l/2*g1/100;
  pvc:=pvi-l/2;
  textcolor(yellow);
  writeln(pvc:8:1,elev2:9:2);
  init_pt_rec(pt_rec2);
  with pt_rec2 do begin
  east:=pvc;
  if scale=40 then
  north:=elev2*10
  else north:=elev2*5;
  elev:=elev2;
  descrip :='vert curve';
 end;
  put(no_pts+1,pt_rec2);
  x:=1; y:=7;
  l2:=t-(pvc-t*int(pvc/t));
  repeat
    d:=4*e*sqr(l2/l);
    elev3:=elev2+g1*l2/100;
    gotoxy(x,y); y:=y+1; if y=19 then begin y:=6; x:=x+20; end;


    writeln(pvc+l2:8:1,elev3-d:9:2);

    init_pt_rec(pt_rec2);
    with pt_rec2 do begin
    east:=pvc+l2;
   if scale=40 then
   north:=(elev3-d)*10
   else north:=(elev3-d)*5;
    elev:=elev3-d;
    descrip :='vert curve';
   end;
     put(no_Pts+1,pt_rec2);
    if (l2>l/2-t) and (l2<l/2) then
       begin
         gotoxy(x,y); y:=y+1; if y=19 then begin y:=6; x:=x+20; end;
         writeln(pvi:8:1,elev1-e:9:2);
         init_pt_rec(pt_rec2);
         with pt_rec2 do begin
         east:=pvi;
         elev:=elev1-e;
        if scale =40 then
         north:=elev*10
         else north :=elev*5;
         descrip :='vert curve';
       end;
        put(no_Pts+1,pt_rec2);
       end;
    l2:=l2+t;
  until l2>l;
  elev2:=elev1+l/2*g2/100;
  gotoxy(x,y);
  writeln(pvc+l:8:1,elev2:9:2);
  with pt_rec2 do begin
  east :=pvc+l;
  if scale =40 then
  north:=elev2*10
  else north :=elev2*5;
  elev:=elev2;
  descrip := 'vert curve';
 end;
  put(no_pts+1,pt_rec2);

end;
{$ENDIF}

end.
