unit basics3; { Only Stuff that is repetivly called by program }
interface

{$I Direct}   { Compiler directives }

{$IFDEF back_ground_spool}    { so we use basics2 & NOT use communication }
  uses dos,crt,xception,comm; { so that we do not have useless objeck code }
{$ELSE}
  uses dos,crt,xception;
{$ENDIF}

type
  all_char = set of ' '..'}';
var
  DirInfo     : SearchRec;
  regs        : Registers;
  response    : char;      { response to quest }
  lst_flag    : boolean;   { it true send data to lst device }
  lst         : text;      { output list text to this file or DOS handle }
  lst_fn      : string[25];{ could be PRN or any DOS Handle or File Name }
  last_drv    : char;      { last logical DOS disk Drive on system }
  log_drv     : integer;   { current logged disk drive }
  next_drv    : integer;   { used to determine the loged drive }
  exception   : target;    { jump use Throw & Catch routine }
  machine_type: byte;      { used by Xmodem file transfer for loop cnt }
  path        : string;    { used by read_fn & get_dir & simple }
  last_fn_spec: string;    { used by read_fn & get_dir & simple }
  no_dir_files: integer;   { get_dir will set the no. of file matches here }
  option      : string[2]; { Main Program Main Option Codes }
  base_time   : real;      { used in PC clock elsaped timer routine }
  add_time    : real;      { used in PC clock elsaped timer routine }
  laps_time   : real;      { used in PC clock elsaped timer routine }
  t_state     : boolean;   { used in PC clock elsaped timer routine }
  com_drv     : integer;   { disk drive where COMMAND.COM is located for SHELLing }

procedure tag_prn(s:string);
procedure cnff(s:string); {can not find file}
procedure clreos;
function  when:string;
function  exist(fn:string):boolean;
function  Keyin3: integer;   { Single-Key Input Routine (MSDOS/PCDOS) }
procedure quest2(x,y :integer; q_line:string; q_set:all_char; next_ln:boolean);
function  max(r1,r2:real):real;
function  min(r1,r2:real):real;
function  get_dir(fn:string; pick:boolean):string;
procedure whereXY(var x,y:integer);
procedure go_write(x,y:integer; s:string);
procedure screen(tc,tbg:integer);
procedure msg(i:integer; s:string);
procedure purge_kbd;
procedure wait_msg(s:string);
function  read_i(i:integer):integer;
function  read_fn(s:string; endc,delc:integer; des:string; get_dir_flg:boolean):string;
function  command(var cs:string):char;

procedure timer_reset;
function  timer:real;
procedure timer_stop;
procedure timer_go;

procedure shell(s:string);
procedure menu_entry(s:string; side:byte);
procedure menu_op(op_set:all_char);
procedure alarm(p,n:integer); { sound alarm }

procedure input_r(var r:real);
procedure input(var r:real; f,d:integer);

function pw(b,n:real):real;
function rt(b,n:real):real;

implementation

function pw(b,n:real):real;
  begin if b=0 then pw:=0 else pw:=exp(ln(b)*n); end;  {  b^ n     }
function rt(b,n:real):real;
  begin if b=0 then rt:=0 else rt:=exp(ln(b)/n); end;  {  b^(1/n)  }

procedure input_r(var r:real);
  var r_hold  : real;
      s       : string[30];
      key     : integer;
      j,k,x,y : integer;
      inp_err : integer;

  procedure chk_no_err;
    begin
      if inp_err<>0 then
        begin
           gotoxy(x,y);
           write(' ':trunc(min(k,15)));
           gotoxy(x,y);
           sound(150); delay(65); nosound;
        end;
      s:=''
    end;

  procedure get_no_str;
    begin
      while key<>13 do begin
          if (key in [32..128]) and (length(s)<25) then
            begin s:=s+chr(key);
                  if length(s)<15 then write(chr(key));
            end;
          if (key=8) and (length(s)>0) then
            begin delete(s,length(s),1); write(^H,' ',^H); end;
          key:=keyin3;
      end;
    end;

  begin
     r_hold:=r;
     whereXY(x,y);
     repeat
         s:='';
         key:=keyin3;
         get_no_str;
         k:=length(s);
         for j:=k downto 1 do if s[j]=' ' then delete(s,j,1);
         val(s,r,inp_err);
         if (s='') and (inp_err>0) then begin inp_err:=0; r:=r_hold; end;
         chk_no_err;
     until inp_err=0;
  end;

procedure input(var r:real; f,d:integer);
  begin write(r:f:d,' ? '); input_r(r); end;

procedure alarm(p,n:integer); { sound alarm }
  begin
    repeat sound(1000); delay(p); sound(1200); delay(p); dec(n); until n=0;
    nosound;
  end;

procedure shell(s:string);
  begin
    write('SHELL to DOS');
    if s='' then begin write('   Enter DOS Command > ');readln(s); end;
    writeln;
    if s='' then writeln('Type  EXIT  to Return to FCP')
    else s:='/C '+s;
    exec(chr(com_drv+65)+':\command.com',s);
    with regs do begin ax:=$0100; cx:=$107; end; { set cursor back to 2 value }
    intr($10,regs); { do cursor set it }
  end;

procedure menu_entry(s:string; side:byte);
    begin
      if side>1 then gotoxy(45,wherey-1) else gotoxy(9,wherey);
      screen(cyan,black);   write('[');
      screen(yellow,black); write(s[1]);
      screen(cyan,black);   writeln(']',copy(s,2,71));
      screen(white,black);
    end;

procedure menu_op(op_set:all_char);
  begin
    writeln; screen(yellow,black);
    quest2(0,0,'Option ? ',op_set,true);
    screen(cyan,black);
  end;

function sec_time:real; var h,m,s,sh:word;
  begin gettime(h,m,s,sh); sec_time:=h*3600+m*60+s+sh/100; end;
procedure timer_reset;
   begin add_time:=0; laps_time:=0; t_state:=false; end;
function  timer:real;
  begin
    if t_state then begin laps_time:=sec_time-base_time+add_time; timer:=laps_time; end
    else timer:=laps_time;
  end;
procedure timer_stop;  begin add_time:=timer; t_state:=false; end;
procedure timer_go;    begin base_time:=sec_time; t_state:=true; end;

procedure whereXY(var x,y:integer); begin x:=wherex; y:=wherey; end;
procedure go_write(x,y:integer; s:string); begin gotoxy(x,y); write(s); end;
procedure screen(tc,tbg:integer); begin textcolor(tc); textbackground(tbg); end;
procedure purge_kbd; var c:char; begin while keypressed do c:=Readkey; end;
function  max(r1,r2:real):real; begin if r1>r2 then max:=r1 else max:=r2; end;
function  min(r1,r2:real):real; begin if r1<r2 then min:=r1 else min:=r2; end;
procedure cnff(s:string); begin writeln(^G,' Can NOT Find File: ',s); end;

function exist(fn:string):boolean; var s : searchrec;
  begin findfirst(fn,anyfile,s); exist:=((dosError=0) and (s.attr<>$10)); end;

procedure wait_msg(s:string);
  begin quest2(0,0,s+' ...Any Key',[' '..'~',^M],true); end;

function command(var cs:string):char;
    begin if cs<>'' then begin command:=upcase(cs[1]); delete(cs,1,1) end
          else command:=' ';
    end;

function read_fn(s:string; endc,delc:integer; des:string; get_dir_flg:boolean):string;

   function get_dir_fn:boolean;
     begin
       if get_dir_flg and (pos('*',s)+pos('?',s)>0) then
         begin s:=get_dir(s,true);
               path:='';
               get_dir_fn:=((s<>'') and (s[length(s)]<>'\'));
         end
       else get_dir_fn:=false;
     end;

  var key,i : integer;
  begin { may be used to get any string input }
    repeat
      if not get_dir_fn then begin
        screen(white,black); write(des); if endc=13 then write(' File: ');
        screen(black,white); write(s);
        key:=keyin3;
        if (key<>endc) and (key<>delc) and (key<>591) and (key<>587) then
          begin for i:=1 to length(s) do write(^H,' ',^H); s:='' end;
        while (key<>endc) and (key<>591) do begin
            if (key in [27,21]) and (endc=13) then
              begin read_fn:=''; screen(white,black); exit; end;
            if (key<>delc) and (key<>587) then
              begin
                if key<256 then begin s:=s+chr(key); write(chr(key)); end;
              end
            else if length(s)>0 then
                   begin delete(s,length(s),1); write(^H,' ',^H); end;
            key:=keyin3;
        end;
        screen(white,black);
        if endc=13 then for i:=length(s) downto 1 do
          begin s[i]:=upcase(s[i]); if s[i]=' ' then delete(s,i,1); end;
        if s='' then s:=path;
        if s[length(s)] in [':','\'] then s:=s+'*.*';
        if pos('*',s)+pos('?',s)=0 then begin read_fn:=s; exit; end;
      end
      else begin read_fn:=s; exit; end;
    until false;
  end;

function read_i(i:integer):integer;
  var ns  : string[15];
     j,e  : integer;
     key  : char;
  begin ns:=''; key:=readkey;
    while key<>^M do begin
        if key in [' '..'}'] then begin ns:=ns+key; write(key); end;
        if (key=^H) and (length(ns)>0) then
          begin delete(ns,length(ns),1); write(^H,' ',^H); end;
        key:=readkey;
    end;
    val(ns,j,e); if e=0 then read_i:=j else read_i:=i;
  end;

procedure tag_prn(s:string);
  procedure t_line;
    var i:integer;
    begin for i:=1 to 75 do write(lst,'='); writeln(lst); end;
  begin
     if lst_flag then begin t_line; writeln(lst,s,'  ',when); t_line; end;
  end;

procedure  msg(i:integer; s:string);
 var x,y : integer;
   begin
     whereXY(x,y); gotoxy(i,25); textbackground(black); clreol;
     screen(white,green); write(' ',s,' ');
     screen(white,black); gotoxy(x,y);
   end;

{----------------------------------------------------------------------}
{             Keyin :       Key input from keyboard                    }
{----------------------------------------------------------------------}
  Function Keyin3: integer;   { Single-Key Input Routine (MSDOS/PCDOS) }
    Var   Ch    : char;
     Begin {$IFDEF back_ground_spool}
             while not keypressed do fill_bufo(plt_port);
           {$ENDIF}
           ch:=readkey; keyin3 := ord(ch);
           if Ch=^@ then
              begin                    { If extended key type get }
                ch:=ReadKey;           { get next key in          }
                keyin3 := 512 + ord(ch);
                if ch='-' then throw(exception); { alt-X key }
              end;

     End;

procedure quest2(x,y:integer; q_line:string; q_set:all_char; next_ln:boolean);
  var i : integer;
  begin
    if x*y>0 then gotoxy(x,y);
    clreol; write(q_line);
    repeat
      for i:=1 to 10 do begin sound(900+i*50); delay(7); end; nosound;
      response:=upcase(chr(keyin3));
    until response in q_set;
    write(response);
    if next_ln then writeln;
  end;

procedure clreos;
  var i,x,y : integer;
  begin
    whereXY(x,y); clreol;
    for i:=y+1 to 25 do begin gotoxy(1,i); clreol; end;
    gotoxy(x,y);
  end;

function  when:string;
  Const
    DayName: Array [1..7] Of String[3]=
      ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    MonName: Array [1..12] Of String[3]=
      ('Jan','Feb','Mar','Apr','May','Jun','Jul',
       'Aug','Sep','Oct','Nov','Dec');

  Var
    h,m,s,sh,
    y,mon,d,dw : word;
    ap         : string[2];
    i          : string[4];

 Function V2(I:Integer):String;
    Begin V2:=Chr(48+I Div 10)+Chr(48+I Mod 10); End;

  begin
    gettime(h,m,s,sh); getdate(y,mon,d,dw);
    AP:='am';    If H>11 Then AP:='pm';
    H:=H Mod 12; If H=0 Then H:=12;
    str(y:4,i);
    when:=v2(h)+':'+v2(m)+ap+' '+dayname[dw+1]+', '+monname[mon]+' '+v2(d)+', '+i;
  End;

function get_dir(fn:string; pick:boolean):string;
  type
    sort_rec = record fname : string[12]; dir_pos : byte; end;

  var i,j        : integer;
      files_size : longint;
      fn_arr     : array[0..255] of sort_rec;
      fnp        : string; { the path of the file spec }

   procedure sort_fn(no_files:integer);   { quick sort routine }
      var
        h,i,j,l   : integer;  { pointers }
        swap_flag : boolean;

    begin{sort_c}
           i:=trunc(no_files/2);
           repeat
             for h:=1 to i do
               repeat
                 j:=h; l:=h+i; swap_flag:=false;
                 repeat
                   if fn_arr[l].fname< fn_arr[j].fname then
                     begin fn_arr[0]:=fn_arr[l]; fn_arr[l]:=fn_arr[j];
                           fn_arr[j]:=fn_arr[0];  swap_flag:=true;
                     end;
                   j:=l; l:=l+i;
                 until l>no_files;
               until not swap_flag;
             i:=trunc(i/2);
           until i=0;
    end{sort_fn};

  begin
    files_size:=0;

    screen(white,black); writeln; writeln('File Spec: ',fn);

    fnp:=fn; { parse the path of fn }
    while (not (fnp[length(fnp)] in ['\',':'])) and (length(fnp)>0) do
      delete(fnp,length(fnp),1);

    last_fn_spec:=fn;
    for i:=1 to 80 do write('-');
    j:=0; findfirst(fn,anyfile,DirInfo);     { set up sort array }
    while (DosError=0) and (j<255) do
      begin
        inc(j); files_size:=files_size+DirInfo.Size;
        with fn_arr[j] do begin fname:=copy(DirInfo.name,1,12); dir_pos:=j; end;
        findnext(dirInfo);
      end;
    no_dir_files:=j;
    if j>1 then sort_fn(j);                  { write the parital sorted list }
    i:=0;
    while i<j do
      begin
        inc(i); write(fn_arr[i].fname:12);
        screen(black,white); write(i:3); screen(white,black);
        if i mod 5 = 0 then writeln else write(' ');
      end;
    while DosError=0 do                      { write remaining unsorted files }
      begin
        inc(j); files_size:=files_size+DirInfo.Size;
        write(copy(DirInfo.name,1,12):12);
        screen(black,white); write(j:3); screen(white,black);
        if j mod 5 = 0 then writeln else write(' ');
        findnext(dirInfo);
      end;
    if j mod 5<>0 then writeln; for i:=1 to 80 do write('-');
    write(j:3,' File(s)    Size=',files_size:7,' bytes ');

    if pick then
      begin
        screen(black,white); write(' Enter PICK No. ? '); i:=read_i(0);
        if abs(i)>j then j:=0 else j:=abs(i);
        case j of
               0:get_dir:='';
          1..255:begin
                     findfirst(fnp+fn_arr[j].fname,anyfile,DirInfo);
                     if DirInfo.attr=$10 then get_dir:=fnp+fn_arr[j].fname+'\'
                     else get_dir:=fnp+fn_arr[j].fname;
                 end;
            else begin findfirst(fn,anyfile,DirInfo);
                   while j>1 do begin findnext(dirInfo); dec(j); end;
                   if DirInfo.attr=$10 then get_dir:=fnp+dirinfo.name+'\'
                   else get_dir:=fnp+copy(DirInfo.name,1,12);
                 end;
        end{case}
      end else get_dir:='';
    screen(white,black); writeln; writeln;
  end;

begin
  directVideo:=false;
  lst_flag:=true;
  assign(lst,'PRN'); rewrite(lst);             { open printer list device }

  with regs do begin ax:=$0100; cx:=$107; end; { set cursor back to 2 value }
  intr($10,regs); { do cursor set it }

  com_drv:=2; { where command.com is located }

  with regs do { get the last DOS disk drive (only need to do this one time) }
    begin AX:=$1900; MSDos(Regs); log_drv:=al; { get current logged drive }
      next_drv:=0;
      repeat inc(next_drv);
        AX:=$0E00; DX:=next_drv; MSDos(Regs);  { Set Drive }
        AX:=$1900; MSDos(Regs);                { Get default drive }
      until  lo(AX)<>next_drv;
      AX:=$0E00; DX:=log_drv; MSDos(Regs);     { ReSet Logged Drive }
      last_drv:=chr(next_drv+64);
    end;

  machine_type:=1; { IBM-PC 4.77 Mhz }
  last_fn_spec:='*.*';  path:='';
end.
