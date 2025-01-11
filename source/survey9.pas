unit survey9;
interface
uses crt,survey0,basics2;

procedure learn_init;
procedure run;
procedure reg_flip;
procedure iff;
procedure if_else;
procedure jump;

implementation

procedure learn_init;
  var des : string[70];
      fn  : str16;
  begin
    mode('LEARN Mode Initiation');
    gotoxy(1,3);
    if act_script=0 then
      if not learn then
        begin
          writeln;
          path:=''; fn:=read_fn('*.LRN',13,8,'Script WRITE',true);
          if fn='' then fn:='LEARN';
          i:=pos('.',fn); if i>0 then fn:=copy(fn,1,i-1);
          fn:=fn+'.LRN';
          response:='Y';
          if exist(fn) then
            begin
              writeln;
              writeln('*** Script File ',fn,' ALREADY Exist ***');
              quest(0,0,'Erase and Re-Write Script file (Y/N) ? ',['Y','N'],false);
              writeln;
            end;
          if response='Y' then
            begin
              assign(lrn_file,fn); rewrite(lrn_file);
              writeln; write('Enter Function Description: '); readln(des);
              writeln(lrn_file,des);
              learn:=true;
              act_label:=0;
            end
          else writeln(^G'+++ NOT in Learn Mode +++');
        end
      else writeln(^G,'*** Learn Mode ALREADY Active ***')
    else writeln(^G,'*** Can Not LEARN when Script Active ***');
  end;


procedure run;

 var i:integer;
     des : string[70];
     p_file : array[0..40] of string[20];

procedure pick;
  var
    pick_file : text;
    j         : integer;
  begin
    write('  Pick File: SCRIPT.FIL');
    screen(white+blink,black);
    write('   Press  Alt-EX  to EXit & abort Script');
    screen(white,black);
    s:='';
    gotoxy(1,2);
    if exist('SCRIPT.FIL') then
      begin
        i:=0; p_file[0]:='';
        assign(pick_file,'SCRIPT.FIL');
        reset(pick_file);
        repeat
          readln(pick_file,s); des:=s;
          while (length(s)>0) and (s[1]=' ') do delete(s,1,1);
          s:=s+' '; j:=pos(' ',s);
          if j>1 then
            begin
              inc(i); p_file[i]:=copy(s,1,j-1);
              if i>18 then gotoxy(40,i-17); clreol;
              writeln(i:3,' ',des);
            end;
        until eof(pick_file);
        close(pick_file);
        if i>0 then
          begin
            repeat
              gotoxy(1,21); clreos;
              write('Enter Script File  No. ? '); j:=0;
              if script_no in [1..i] then j:=script_no else input_i(j);
            until j<=i;
            s:=p_file[j];
          end;
        gotoxy(1,2); clreos;
        if s<>'' then writeln('Script File: ',s);
      end
    else cnff('SCRIPT.FIL');
  end;

  begin
    mode('Run Script');
    pick;
    if s='' then
      begin
        gotoxy(1,3); clreos;
        s:=get_dir('*.lrn',false);
        writeln; write('Enter Script File Name: ? ');
        s:=''; key:=0; get_no_str;
        writeln; writeln;
      end;
    i:=pos('.',s); if i>0 then s:=copy(s,1,i-1);
    s:=s+'.LRN';
    if exist(s) then
      begin
        act_script:=act_script+1;
        act_if[act_script]:=0;
        if_arr[act_script,0]:=true;
        assign(script_file[act_script],s);
        reset(script_file[act_script]);
        readln(script_file[act_script],des);
        writeln;
        writeln('==== Function: ',des,' ====');
        if lst_flag then
          writeln(lst,'RUN SCRIPT FILE: ',s,'  Function: ',des);
      end
    else cnff(s);
  end;

procedure reg_flip;
  var r   : real;
      asz : str16;

begin
  mode('Flip Storage Register Data');
  gotoxy(1,3);
  writeln('Use  Alt F1-F10  to  STORE ADD SUBTRACT DATA   <Return> to Continue');
  quest(1,6,'[Y]es    [N]o   ? ',['Y','N'],false);
  if response='Y' then roll_int(1) else roll_int(0);
  quest(1,7,'[R]ight  [L]eft ? ',['R','L'],false);
  if response='R' then roll_asz('90') else roll_asz('270');
  roll_flag:=false;
  repeat
    gotoxy(1,9); clreol; write('Enter '); i:=dig_point;
    writeln; write('   ',i:10);
  until i=9999;
  repeat
    gotoxy(1,12); clreol; write('Enter Angle ? ');
    asz:=''; input_asz(asz);
    writeln; clreol; write('   ',asz);
  until asz='';
  repeat
    gotoxy(1,15); clreol; write('Enter Real# ? ');
    r:=0; input_r(r);
    writeln; write('   ',r:11:3);
  until r=0;
  roll_flag:=true;
end;

procedure iff;
  var
    r,r2  : real;
    i,i2  : integer;
    a,a2  : real;
    asz   : str16;
    if_op : char;
    x,y   : byte;
    result: boolean;
    opt1  : char;

procedure get_if_op;
  begin
    x:=wherex;
    quest(0,0,' =EQ  >GT  <LT  ]GE  [LE  :NE ? ',['=','>','<','[',']',':'],false);
    gotoxy(x,wherey); clreol; if_op:=response;
    write('  ');
    case if_op of
      '=':write('=');
      '>':write('>');
      '<':write('<');
      ']':write('>=');
      '[':write('<=');
      ':':write('<>');
    end{case};
    write('  ?',^H);
  end;

function compare(r1,r2:real):boolean;
  begin
    compare:=false;
    case if_op of
      '=':if abs(r1-r2)<0.00005 then compare:=true;
      '>':if r1>r2  then compare:=true;
      '<':if r1<r2  then compare:=true;
      ']':if r1>=r2 then compare:=true;
      '[':if r1<=r2 then compare:=true;
      ':':if r1<>r2 then compare:=true;
    end{case};
  end;

begin
  mode('IF Statement for Learn');
  quest(1,3,'Compare  [R]eals  [I]nteger  [A]zimuths  [E]xit ? ',['R','I','A','E'],false);
  opt1:=response;
  gotoxy(1,5); write('IF  ?',^H);
  case opt1 of
     'R':begin
           r:=0; r2:=0; input_r(r); get_if_op; input_r(r2);
           result:=compare(r,r2);
         end;
     'A':begin
           a:=0;  input_asz(asz);  a:=asz_rad(asz);
           get_if_op;
           a2:=0; input_asz(asz); a2:=asz_rad(asz);
           result:=compare(a,a2);
         end;
     'I':begin
           i:=0; i2:=0; input_i(i); get_if_op; input_i(i2);
           result:=false;
           case if_op of
             '=':if i=i2 then result:=true;
             '>':if i>i2 then result:=true;
             '<':if i<i2 then result:=true;
             ']':if i>=i2 then result:=true;
             '[':if i<=i2 then result:=true;
             ':':if i<>i2 then result:=true;
           end{case};
         end;
  end{case};
  writeln('  ',result);
  if opt1<>'E' then
    begin
      if learn and (act_script=0) then result:=true;
      act_if[act_script]:=act_if[act_script]+1;
      if_arr[act_script,act_if[act_script]]:=result;
      else_arr[act_script,act_if[act_script]]:=not result;
    end;
end;

procedure if_else;
  begin
    case trunc(pos(option,option_set)/2)+1 of
      65:begin
           mode('ENDIF');
           if act_if[act_script]>0 then { END IF }
             begin
               if learn and (act_script=0) then
                 write(lrn_file,'~',act_if[act_script]:1);
               act_if[act_script]:=act_if[act_script]-1;
             end;
         end;
      66:begin
           mode('ELSE');
           if act_if[act_script]>0 then  { ELSE Marker }
             begin
               if learn and (act_script=0) then
                 begin
                   write(lrn_file,'~',chr(act_if[act_script]+64):1);
                   else_arr[act_script,act_if[act_script]]:=true;
                 end;
               if_arr[act_script,act_if[act_script]]:=false; { to eat up ELSE characters }
             end;
         end;
    end{case};
  end;

procedure jump;
  var
    ch    : char;
    lab   : char;
    i     : integer;
    found : boolean;

  label
       top_read;

  begin
    case trunc(pos(option,option_set)/2)+1 of
      68:begin  {Label JUMP}
           mode('LABEL For JUMP Transfer in Script');
           writeln('  Current LABEL No.=',act_label:2);
           if learn and (act_script=0) then
             begin
               act_label:=act_label+1;
               write(lrn_file,^K,act_label:1);
               gotoxy(1,3); writeln('JUMP LABEL Number = ',act_label:2);
             end;
         end;
      69:begin
            mode('JUMP Transfer in Script');
            quest(1,3,'JUMP to LABEL No. (1-9) ? ',['1'..'9'],false);
            if act_script>0 then
              begin
                gotoxy(1,4); writeln('Searching AHEAD for LABEL No. ',response);
                lab:=' ';
                i:=1;
                ch:=' ';
                found:=false;
top_read:     while not found  and  not eof(script_file[act_script]) do
                  begin
                    read(script_file[act_script],ch);
                    if pos(ch,^K+'~')>0 then read(script_file[act_script],lab);
                    case ch of
                      '~':if act_if[act_script]=ord(lab)-48 then act_if[act_script]:=act_if[act_script]-1;
                      ^K :if lab=response then found:=true;
                    end{case};
                  end;
                i:=i+1;
                if not found and (i=2) then
                  begin
                    reset(script_file[act_script]);
                    writeln('...From Script TOP DOWN');
                    goto top_read;
                  end;
                if found then
                  begin
                    writeln('LABEL FOUND ...Continuing at Label No. ',response);
                    act_label:=act_label-1;
                  end
                else
                  begin
                    writeln(^G,'*** ERROR, Can NOT find LABEL ***');
                    writeln('+++ Now Exiting ALL Script Levels +++');
                    cogo_err:=true;
                  end;
              end;
         end;
    end{case};
  end;

end.
