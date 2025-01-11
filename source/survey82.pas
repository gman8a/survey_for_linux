{$F+,O+}
unit survey82;
interface
uses crt,survey0,basics2;

procedure draw;
procedure ascii_in;
procedure ascii_out;
procedure triangle;

implementation

procedure draw;
  var
    i,j,p,no  : integer;
    name      : string[80];
    l,m       : string[80];
    draw_file : text;
    out_file  : text;
    in_file   : text;
    temp      : array[0..40] of string[20];

  begin
    mode('Line Drawing Commands from Template File');
    gotoxy(1,2);
    temp[0]:='NULL';
    if exist('DRAW.LN') then
      begin
        assign(draw_file,'DRAW.LN');
        reset(draw_file);
        i:=0;
        repeat
          readln(draw_file,l);
          if pos('::',l)>0 then
            begin
              j:=pos('::',l);
              s:=copy(l,1,j-1); parse_s; con_flag:=false;
              inc(i); temp[i]:=s;
              if i>18 then gotoxy(40,i-17);
              writeln(i:3,' ',l);
            end;
        until eof(draw_file);
        if i>0 then
          begin
            repeat
              gotoxy(1,21); clreos;
              write('Enter Draw Template No. ? '); j:=0; input_i(j);
            until j<=i;
            s:=temp[j];
          end;
        reset(draw_file);
        if s<>'' then
          begin
            gotoxy(1,2); clreos; writeln;
            for i:=1 to length(s) do s[i]:=upcase(s[i]);
            while not eof(draw_file) and (pos(s,name)=0) do
              readln(draw_file,name);
            if pos(s,name)>0 then
              begin
                write('Enter Drawing Command Point Offset=1 ? ');
                p:=1; input_i(p); writeln;
                assign(out_file,fn3+'X'); rewrite(out_file);
                assign(in_file,fn3+'Z');
                if exist(fn3+'Z') then
                  begin
                    reset(in_file);
                    while not eof(in_file) do
                      begin readln(in_file,l); writeln(out_file,l); end;
                    close(in_file);
                  end;
                writeln(out_file,'87 0 0 0 0 0  ',name);
                writeln;
                writeln(name);
                writeln;
                i:=0;
                while not eof(draw_file) and (pos('::',l)=0) do
                  begin
                    readln(draw_file,l);
                    j:=1; m:='';
                    while (j<=length(l)) and (pos('::',l)=0) do
                      begin
                        if l[j]='#' then
                          begin
                            s:=''; j:=j+1;
                            while (j<=length(l)) and (l[j]<>' ') do
                              begin  s:=s+l[j]; inc(j); end;
                            parse_s; val(s,no,inp_err);
                            if inp_err=0 then str(p+no-1:4,s) else s:='0001';
                            m:=m+s+' ';
                          end
                        else m:=m+l[j];
                        j:=j+1;
                      end;
                    if m<>'' then
                      begin writeln(out_file,m); writeln(m); inc(i); end;
                  end;
                close(out_file);
                if exist(fn3+'Z') then erase(in_file);
                rename(out_file,fn3+'Z');
                writeln;
                writeln('***',i:4,' Drawing Commands Appended to Line File: ',fn3,'Z ***');
              end
            else writeln(^G,'*** Can NOT find Drawing Routine: ',s,' ***');
          end;
        close(draw_file);
      end
    else cnff('DRAW.LN');
  end;

procedure ascii_in;
  var
    afn    : string[25];
    a_f    : text;
    pt_rec : point;
    i,j,k  : integer;
    coor   : array[0..8] of real;
    ffn    : text;
    n      : integer;
 nn,en,eln : integer;

begin
  mode('Get ASCII XYZ Coordinates'); writeln('  Using File: SETTINGS.CFG');
  writeln;
  path:=''; afn:=read_fn('*.DAT',13,8,'ASCII Input',true);
  if afn='' then afn:='NULL';
  if exist(afn) then
    begin
      if exist('SETTINGS.CFG') then
        begin
          assign(ffn,'SETTINGS.CFG'); reset(ffn);
          for i:=1 to 12 do readln(ffn); readln(ffn,n,nn,en,eln); close(ffn);
          writeln('ASCII FORMAT');
          writeln('============');
          writeln('  Total #''s =',n:2);
          writeln('  North Pos.=',nn:2);
          writeln('  East  Pos.=',en:2);
          writeln('  Elev. Pos.=',eln:2);
          writeln('  Description at End');
          writeln;
          assign(a_f,afn); reset(a_f);
          j:=0;
          init_pt_rec(pt_rec);
          writeln; write('      ASCII XYZ Coor. Appended');
          coor[0]:=0;
          while not eof(a_f) do
            begin
              coor[2]:=-9999.111;
              k:=0;
              for i:=1 to n do
                begin {$I-} read(a_f,coor[i]); {$I+}
                      if k=0 then k:=IOResult;
                end;
              readln(a_f,pt_rec.descrip);
              if coor[2]=-9999.111 then k:=-1;
              if k=0 then with pt_rec do
                begin
                  north:=coor[nn];
                  east:=coor[en];
                  elev:=coor[eln];
                  put(no_pts+1,pt_rec); inc(j); write(^M,j:4)
                end;
            end{while};
        end{if exist}
      else cnff('SETTINGS.CFG');
    end{if exist}
  else cnff(afn);
end;

procedure ascii_out;
  var o_f   : text;
      lx,ly : real;
      sort_rec : sort_xyp;
      i : integer;
      fn7 : string[25];
begin
  mode('Make ASCII Point File');
  fn7:=fn2; delete(fn7,length(fn7)-2,3);
  assign(o_f,fn7+'DAT'); rewrite(o_f);
  gotoxy(1,3);
  writeln('Output File Name: ',fn7,'DAT');
  writeln;
  quest(0,0,'[A]ll pts   [N]on-Zero Elev ? ',['A','N'],false);
  lx:=0; ly:=0;
  gotoxy(1,7);
  write('     Points Written');
  if response='N' then
    for i:=1 to no_pts do with sort_rec do
      begin
        get3(i,sort_rec);
        write(^M,i:4);
        if (el<>0) and ((abs(lx-x)>0.0001) or (abs(ly-y)>0.0001)) then
          begin
            get(p,pt_rec);
            writeln(o_f,p:4,' ',x:12:4,' ',y:12:4,' ',el:12:4,'   ',pt_rec.descrip);
            lx:=x; ly:=y;
          end;
      end
  else
    for i:=1 to no_pts do with pt_rec do
      begin
        get(i,pt_rec);
        write(^M,i:4);
        writeln(o_f,i:4,' ',east:12:4,' ',north:12:4,elev:12:4,'   ',descrip);
      end;
  close(o_f);
end;

procedure triangle;
  var
    a,b,c       : real;
    aa,bb,cc,m  : real;
    abp,abm,s   : real;
    asz1        : str16;

function arcsin(a:real):real;
  begin
    if a=0 then arcsin:=0
    else if abs(a-1.0)<1.0e-10 then arcsin:=pi/2
         else if 1/(1/sqr(a)-1)>0 then
                arcsin:=arctan(sqrt(1/(1/sqr(a)-1)))
              else begin
                     writeln(^G,' *** ArcSin Trig. Error ***');
                     arcsin:=0;
                     cogo_err:=true;
                   end;
  end;

procedure error;
  begin
    gotoxy(1,14);
    writeln(^G,'*** Error, Sides Can NOT Form a Triangle ***');
    cogo_err:=true;
  end;

begin
  mode('Compute Solution of Triangle');
  quest(0,0,'  [O]blique   [R]ight  ? ',['O','R'],false);
  gotoxy(1,3);
    if response='R' then
      begin
          writeln('     A                 Right Triangle');
          writeln('     |\');
          writeln('     | \');
          writeln('     |  \');
          writeln('    b|   \ c');
          writeln('     |    \');
          writeln('     |     \');
          writeln('     |______\');
          writeln('    C    a   B');
          a:=0; b:=0; c:=0; aa:=0; asz1:='0';
          gotoxy(24,5); write('Enter  Side a = ?',^H); input_r(a);
          gotoxy(24,6); write('Enter  Side b = ?',^H); input_r(b);
          if a*b=0 then begin gotoxy(24,7); write('Enter  Side c = ?',^H); input_r(c); end;
          if b*c<>0 then
            begin
              a:=b; b:=0;
              gotoxy(40,5); write(^G,a:10:3,'  +++ Sides a & b Switched +++');
              gotoxy(40,6); write(0.0:10:3);
            end;
          if (a*b=0) and (a*c=0) then
            begin gotoxy(24,9);
                  write('Enter Angle A = ?',^H); input_asz(asz1);
                  aa:=asz_rad(asz1);
            end;
          if (a<>0) and (b+c<>0) then
            begin
              if b<>0 then c:=sqrt(a*a+b*b)
              else if c>a then b:=sqrt((c+a)*(c-a))
                   else begin gotoxy(1,14);
                           writeln('*** Error Side c < a ***');
                           cogo_err:=true;
                           exit;
                        end;
              aa:=arctan(a/b);
            end
          else if aa<>0 then
                 begin
                   if a<>0 then begin b:=a/tan(aa); c:=a/sin(aa); end
                   else if b<>0 then begin a:=b*tan(aa); c:=b/cos(aa); end
                        else if c<>0 then begin a:=c*sin(aa); b:=c*cos(aa); end;
                  end;
         gotoxy(1,16);
         writeln('a=',a:11:4,'   A=',rad_asz(aa));
         writeln('b=',b:11:4,'   B=',rad_asz(pi/2-aa));
         writeln('c=',c:11:4,'   C=',rad_asz(pi/2));
         writeln('Area =',a*b/2:10:3);
         roll_real(c);   roll_real(b);               roll_real(a);
         roll_asz('90'); roll_asz(rad_asz(pi/2-aa)); roll_asz(rad_asz(aa));
      end{if response = 'R'}
    else
      begin
          writeln('           A           Oblique Triangle');
          writeln('           /\');
          writeln('          /  \');
          writeln('         /    \');
          writeln('      b /      \ c');
          writeln('       /        \');
          writeln('      /          \');
          writeln('     /____________\');
          writeln('    C      a       B');
          a:=0; b:=0; c:=0; aa:=0; asz1:='0'; bb:=0; cc:=0;
          gotoxy(24,5);  write('Enter  Side a = ?',^H); input_r(a);
          gotoxy(24,6);  write('Enter  Side b = ?',^H); input_r(b);
          gotoxy(24,7);  write('Enter  Side c = ?',^H); input_r(c);
          if (c<>0) and (b<>0) and (a=0) then
            begin a:=c; c:=0;
              gotoxy(40,5); write(^G,a:10:3,'  +++ Sides a & c Switched +++');
              gotoxy(40,7); write(0.0:10:3);
            end
          else
            if (c<>0) and (b=0) and (a<>0) then
              begin b:=c; c:=0;
                gotoxy(40,6); write(^G,b:10:3,'  +++ Sides b & c Switched +++');
                gotoxy(40,7); write(0.0:10:3);
              end;
          if a+c=0 then
            begin a:=b; b:=0;
                gotoxy(40,5); write(^G,a:10:3,'  +++ Sides a & b Switched +++');
                gotoxy(40,6); write(0.0:10:3);
            end;
          if a+b+c=0 then
             begin gotoxy(1,15);
                   writeln(^G,'*** Error,  Must have at Least One Side ***');
                   exit;
             end;
          if a*b*c=0 then
            begin
              if c=0 then
                begin
                  gotoxy(24,9);  write('Enter Angle A = ?',^H); input_asz(asz1);
                  aa:=asz_rad(asz1);
                end;
              if b+c=0 then
                begin
                  gotoxy(24,10); write('Enter Angle B = ?',^H); input_asz(asz1);
                  bb:=asz_rad(asz1);
                end;
              if (a*b<>0) and (aa=0) then
                begin
                  gotoxy(24,11); write('Enter Angle C = ?',^H); input_asz(asz1);
                  cc:=asz_rad(asz1);
                end;
            end;
          if aa*bb*a<>0 then
            begin
              b:=a*sin(bb)/sin(aa);
              cc:=pi-(aa+bb);
              c:=a*sin(cc)/sin(aa);
            end
          else if aa*a*b<>0 then
                 begin
                   bb:=arcsin(b*sin(aa)/a);
                   cc:=pi-aa-bb;
                   c:=a*sin(cc)/sin(aa);
                 end
               else if a*b*cc<>0 then
                      begin
                        abp:=pi-cc;
                        abm:=2*arctan((a-b)*tan(abp/2)/(a+b));
                        aa:=(pi-cc+abm)/2;
                        bb:=pi-aa-cc;
                        c:=a*sin(cc)/sin(aa);
                      end
                    else if a*b*c<>0 then
                           begin
                             s:=(a+b+c)/2;
                             m:=max(a,b); m:=max(m,c);
                             if (a<m) and (b<m) and (a+b<m) then error
                             else if (a<m) and (c<m) and (a+c<m) then error
                                  else if (b<m) and (c<m) and (b+c<m) then error;
                             if cogo_err then exit;
                             aa:=2*arcsin(sqrt((s-b)*(s-c)/b/c));
                             bb:=2*arcsin(sqrt((s-a)*(s-c)/a/c));
                             cc:=pi-aa-bb;
                           end
                         else
                           begin gotoxy(1,15);
                             writeln('*** Error, Not Enough Info. to Solve Triangle ***');
                             exit;
                           end;
         gotoxy(1,16);
         if not cogo_err then begin
           writeln('a=',a:11:4,'   A=',rad_asz(aa));
           writeln('b=',b:11:4,'   B=',rad_asz(bb));
           writeln('c=',c:11:4,'   C=',rad_asz(cc));
           writeln('Area =',b*c*sin(aa)/2:10:3);
           roll_real(c);          roll_real(b);          roll_real(a);
           roll_asz(rad_asz(cc)); roll_asz(rad_asz(bb)); roll_asz(rad_asz(aa));
         end;
      end{if oblique};
end;


end.
