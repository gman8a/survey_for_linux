{$F+,O+}
unit survey6;
interface
uses crt,survey0,basics2;

{$I Direct}   { Compiler directives }

{$IFDEF DXF} procedure make_dxf; {$ENDIF}

procedure revise_pt; { deletes point pts from file }

implementation

{$IFDEF DXF}
procedure make_dxf;
var
  pt_rec : point;
  i      : integer;
  DXF_file :text;
  p1,p2    : integer;

begin
   mode(' Make DXF file ');
   write(' Enter Starting pt#=1 ? '); p1:=1; input_i(p1);
   write('Enter Ending pt#=',no_pts:4,' ? '); p2:=no_pts; input_i(p2);
   assign(DXF_file,copy(fn7,3,length(fn7)-2)+'DXF');
   rewrite(DXF_file);
   writeln(DXF_file,0:3);
   writeln(DXF_file,'SECTION');
   writeln(DXF_file,2:3);
   writeln(DXF_file,'ENTITIES');
   gotoxy(1,3); write('     Points Converted');
   for i:=p1 to p2 do
     begin
       get(i,pt_rec);
       write(^M,i:4);
       with pt_rec do
         begin
           writeln(DXF_file,0:3);
           writeln(DXF_file,'POINT');
           writeln(DXF_file,8:3);
           writeln(DXF_file,0:1);
           writeln(DXF_file,10:3);
           writeln(DXF_file,east:12:4);
           writeln(DXF_file,20:3);
           writeln(DXF_file,north:12:4);

           writeln(DXF_file,0:3);
           writeln(DXF_file,'TEXT');
           writeln(DXF_file,8:3);
           writeln(DXF_file,0:1);
           writeln(DXF_file,10:3);
           writeln(DXF_file,east+1.6:12:4);
           writeln(DXF_file,20:3);
           writeln(DXF_file,north+1.6:12:4);
           writeln(DXF_file,40:3);
           writeln(DXF_file,4.5:5:2);
           writeln(DXF_file,1:3);
           writeln(DXF_file,i);

           writeln(DXF_file,0:3);
           writeln(DXF_file,'LINE');
           writeln(DXF_file,8:3);
           writeln(DXF_file,0:1);
           writeln(DXF_file,10:3);
           writeln(DXF_file,east-1.2:12:4);
           writeln(DXF_file,20:3);
           writeln(DXF_file,north:12:4);
           writeln(DXF_file,11:3);
           writeln(DXF_file,east+1.2:12:4);
           writeln(DXF_file,21:3);
           writeln(DXF_file,north:12:4);

           writeln(DXF_file,0:3);
           writeln(DXF_file,'LINE');
           writeln(DXF_file,8:3);
           writeln(DXF_file,0:1);
           writeln(DXF_file,10:3);
           writeln(DXF_file,east:12:4);
           writeln(DXF_file,20:3);
           writeln(DXF_file,north-1.2:12:4);
           writeln(DXF_file,11:3);
           writeln(DXF_file,east:12:4);
           writeln(DXF_file,21:3);
           writeln(DXF_file,north+1.2:12:4);
         end;
     end;
   writeln(DXF_file,0:3);
   writeln(DXF_file,'ENDSEC');
   writeln(DXF_file,0:3);
   writeln(DXF_file,'EOF');
   close(DXF_file);
end;
{$ENDIF}

procedure revise_pt; { deletes point pts from file }
  var
    pt     : integer;
    p1,p2  : integer;
    dir    : char;
    i      : integer;
    pt_rec : point;
    cbs,cfp: boolean;
    cdes   : boolean;
    csu,crod : boolean;
    cbsa     : boolean;
    nbsa     : real;
    nfp,nbs: integer;
    ndes   : string[20];
    nsu    : boolean;
    nrod   : real;
    lp     : integer;   { low pt }
    asz    : str16;

  begin
    mode('Change Pt Data'); write('  No_Pts = ',no_pts:4);
    quest(1,2,'[S]tep Forward  [E]nter Pt#  [M]ass  [Q]uit  ? ',['S','E','M','Q'],false);
    dir:=response;
    lp:=10000;
 if response<>'Q' then begin
    quest(1,3,'Change FROM:Pt# (Y/N) ? ',['Y','N'],false);
    if response='Y' then cfp:=true else cfp:=false;
    if cfp then begin write('  New FROM:Pt# ? '); nfp:=0; input_i(nfp); end;

    quest(1,4,'Change   BS:Pt# (Y/N) ? ',['Y','N'],false);
    if response='Y' then cbs:=true else cbs:=false;
    if cbs then begin write('  New   BS:Pt# ? '); nbs:=0; input_i(nbs); end;

    quest(1,5,'Change   Setup  (Y/N) ? ',['Y','N'],false);
    if response='Y' then csu:=true else csu:=false;
    if csu then begin quest(0,0,'  New Setup (Y/N) ? ',['Y','N'],false);
                      if response='N' then nsu:=false else nsu:=true;
                end;

    quest(1,6,'Change Descrip. (Y/N) ? ',['Y','N'],false);
    if response='Y' then cdes:=true else cdes:=false;
    if cdes then begin write('  New  Descrip.? '); readln(ndes); end;

    quest(1,7,'Change    Rod   (Y/N) ? ',['Y','N'],false);
    if response='Y' then crod:=true else crod:=false;
    if crod then begin write('     New Rod   ? '); nrod:=0; input_r(nrod); end;

    quest(1,8,'Change BS_Angle (Y/N) ? ',['Y','N'],false);
    if response='Y' then cbsa:=true else cbsa:=false;
    if cbsa then begin write('  New BS_Angle ? '); input_asz(asz); end;
    nbsa:=asz_rad(asz);

    if dir<>'M' then
      begin
        gotoxy(1,10); write(' Enter Pt# ? '); pt:=0; input_i(pt);
        repeat
          if (pt<=no_pts) and (pt>0) then
            begin
              get(pt,pt_rec);
              display_rec(pt,10,lightgray,white,pt_rec);
              gotoxy(1,19); clreol;
              quest(5,17,'Change this point (Y/N) ? ',['Y','N'],true);
              if response='Y' then with pt_rec do
                begin
                  if cdes then descrip:=ndes;
                  if cbs then bs_pt:=nbs;
                  if cfp then from_pt:=nfp;
                  if crod then rod:=nrod;
                  if csu then setup:=nsu;
                  if cbsa then bs_ang:=nbsa;
                  put(pt,pt_rec);
                  if pt<lp then lp:=pt;
                  gotoxy(5,19); write('*** Point Changed ***');
                  delay(1000);
                end{if response=Y}
              else begin gotoxy(5,19); write('*** Point NOT Changed ***'); end;
            end{if pt<=no_pts and pt>0}
          else begin gotoxy(5,19); bad_pt_msg; end;
          if response='Y' then
            case dir of
              'S':pt:=pt+1;
              'E':begin gotoxy(1,10); clreol; write(' Enter Pt# ? '); input_i(pt); end;
            end{case};
        until (response<>'Y') or (pt>no_pts) or (pt<1);
      end{if dir='M'}
    else {mass delete}
      begin
        gotoxy(1,10); write('Enter Change From Pt# ? '); input_i(p1);
        gotoxy(1,11); write('Enter Change UpTo Pt# ? '); input_i(p2);
        gotoxy(1,13);
        if (p1>0) and (p2>0) and (p2>=p1) and (p2<=no_pts) then
          for i:=p1 to p2 do with pt_rec do
            begin
              get(i,pt_rec);
              if cdes then descrip:=ndes;
              if cbs then bs_pt:=nbs;
              if cfp then from_pt:=nfp;
              if crod then rod:=nrod;
              if csu then setup:=nsu;
              if cbsa then bs_ang:=nbsa;
              put(i,pt_rec);
              if i<lp then lp:=i;
              write(^M,'Pt#',i:4,' Changed');
            end;
      end{mass delete};
    if recalc then recalculate(pt);
    flush_pt_file;
 end{if response<>'Q'};
end;

end.
