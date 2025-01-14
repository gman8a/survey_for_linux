{$F+,O+}
unit commenu;
interface
uses dos,crt,comm,basics2;

var
  plot       : boolean;   { if true go external to plot program }
  def_term_port : integer;

procedure com_menu(com_str:string);
procedure plot_menu(fn:string; com_str:string);
procedure Try_plot(fn:string); { try to Spool a file to the plotter port }
(*
procedure com_config(com_dev:com_port; rec_no:integer); { com port # 1 and 2 }
*)

implementation

procedure xmodem(tport:com_port; var com_str:string);

const
      NUL   =   00;   SOH   = #$01;   EOT   = #$04;   ACK   = #$06;
      TAB   =   09;   LF    = #$0A;   CR    = #$0D;   NAK   = #$15;
      Space = ' ';    DELete = $7F;

      lastbyte = 127;
      timeout  = 256;
      errormax = 5;
      retrymax = 5;                     { 4:PC  8:XT 10:XT 8:AT  10:AT 12:AT 16:386 20:386}
      loopspersec:array[1..8] of longint=(6500,11000,12500,27000,45000,60000,80000,100000);

  var
     WorkFile: file;
     sector : array[0..lastbyte] of byte;

  function ReadLine(seconds:integer): integer;
    var j : longint;
    begin
      j := loopspersec[machine_type] * seconds;
      repeat  j := j-1  until com_chr_ready(tport) or (j = 0);
      if j = 0
        then readline := timeout
        else readline := ord(com_char(tport))
    end;

  procedure SendFile;
    var j, sectornum, counter, checksum : integer;
        filename : string;
        c: char;
        result : integer;

    procedure SendIt;
      var j:integer;
      begin
        sectornum := 1;
        repeat
            counter := 0;
            blockread(WorkFile,sector,1,result);
            repeat
                write(cr,'Sending sector ', sectornum);
                com_send(tport,SOH);  com_send(tport,chr(sectornum));   com_send(tport,chr(-sectornum-1));
                checksum := 0;
                for j:=0 to lastbyte
                  do begin
                       com_send(tport,chr(sector[j]));
                       checksum := (checksum + sector[j]) mod 256
                     end;
                com_send(tport,chr(checksum));
                purge(tport);
                counter := counter + 1;
              until (readline(10) = ord(ack)) or (counter = retrymax);
            sectornum := sectornum + 1
          until (eof(WorkFile)) or (counter = retrymax);
        if counter = retrymax
          then writeln(cr,lf,'No ACK on sector')
          else begin
                 counter := 0;
                 repeat
                     com_send(tport,EOT);
                     counter := counter + 1
                   until (readline(10)=ord(ack)) or (counter=retrymax);
                 if counter = retrymax
                   then writeln(cr,lf,'No ACK on EOT')
                   else writeln(cr,lf,'Transfer complete');
               end;
      end;

  begin
      path:='*.*'; filename:=read_fn('',13,8,'Send',true); writeln;
      if length(filename)>0
        then begin
               if exist(filename) then
                 begin
                   assign(WorkFile,filename); reset(WorkFile);
                   SendIt; close(WorkFile)
                  end
               else cnff(filename);
             end;
  end;

procedure readfile;
  var j, firstchar, sectornum,sectorcurrent, sectorcomp, errors,
      checksum : integer;
      errorflag : boolean;
      filename : string;

  procedure ReceiveIt;
    var j:integer;
    begin
      sectornum := 0;   errors := 0;
      com_send(tport,nak);   com_send(tport,nak);  { send ready characters }
      repeat
          errorflag := false;
          repeat
              firstchar := readline(20)
            until (firstchar in [ord(SOH),ord(EOT),255]) or (firstchar=timeout);
          if firstchar = timeout then
            begin writeln(cr,lf,'Error - No starting SOH'); errorflag:=true; end;
          if firstchar = ord(SOH)
            then begin
                   sectorcurrent := readline(1);      {real sector number}
                   sectorcomp := readline(1);         {+ inverse of above}
                   if (sectorcurrent+sectorcomp)=255  {<-- becomes this #}
                     then begin
                            if (sectorcurrent=(sectornum+1) and $ff)
                              then begin
                                     checksum := 0;
                                     for j := 0 to lastbyte
                                       do begin
                                            sector[j] := readline(1);
                                            checksum := (checksum+sector[j]) and $00FF
                                          end;
                                     if checksum=readline(1)
                                       then begin
                                              blockwrite(WorkFile,sector,1);
                                              errors := 0;
                                              inc(sectornum);
                                              write(cr,'Received sector ',sectornum);
                                              com_send(tport,ack)
                                            end
                                       else begin
                                              writeln(cr,lf,'Checksum error');
                                              errorflag := true
                                            end
                                   end
                              else if (sectorcurrent=sectornum and $ff)
                                     then begin
                                            repeat until readline(1)=timeout;
                                            writeln(cr,lf,'Received duplicate sector ', sectorcurrent);
                                            com_send(tport,ack)
                                          end
                                     else begin
                                            writeln(cr,lf,'Synchronization error');
                                            errorflag := true
                                          end
                          end
                     else begin
                            writeln(cr,lf,'Sector number error');
                            errorflag := true
                          end
                 end;
          if errorflag then begin
                              errors := errors+1;
                              repeat until readline(1)=timeout;
                              com_send(tport,nak)
                            end;
        until (firstchar in [ord(EOT),255]) or (errors = errormax);
      if (firstchar=ord(EOT)) and (errors<errormax)
        then begin
               com_send(tport,ack);
               writeln(cr,lf,'Transfer complete')
             end
        else writeln(cr,lf,'Aborting');
    end;

  begin
    path:='*.*'; filename:=read_fn('',13,8,'Receive',true);
    if length(filename)>0
      then begin
             if exist(filename) then
               quest2(0,0,' Exist, OverWrite (Y/N) ? ',['Y','N'],true);
             if response<>'N' then
             begin
               assign(WorkFile,filename); rewrite(WorkFile);  writeln;
               ReceiveIt; close(WorkFile);
             end;
           end;
  end;

begin{xmodem}
  if c_ptr[tport].use then begin
    com_irq(tport,on);
    c_ptr[tport].hand_shk:=0; { insure no hand shake during transfer }
    response:=command(com_str);
    if response=' ' then quest2(0,0,'[S]end   [R]eceive   [E]xit ? ',['S','R','E'],true);
    case response of 'R':readfile; 'S':sendfile; end{case};
    com_irq(tport,off);
    writeln;
    wait_msg('*** Xmodem DONE *** ');
  end else wait_msg('Port Not Available');
end{xmodem};

procedure com_config(com_dev:com_port; rec_no:integer); { com port # 1 and 2 }
   var
     cfg_file  : file of com_set_rec;
     key       : integer;
     option    : char;
     ln1       : string;
   const
     baud_arr:array[0..7] of longint =(19200,38400,300,600,1200,2400,4800,9600);
     pari_arr:array[0..3] of string[4] =('None','Odd','None','Even');
     hand_arr:array[0..2] of string[18]=('None','X-On/X-Off','Hardware - CTS/RTS');

   begin
    assign(cfg_file,com_cfg_fn);
    if not exist(com_cfg_fn) then
      begin
        rewrite(cfg_file);
        com_record_init; for key:=1 to 30 do write(cfg_file,com_record);
        close(cfg_file);
      end;
    reset(cfg_file);
    seek(cfg_file,rec_no); read(cfg_file,com_record);
    repeat
      clrscr;
      with com_record do begin
        writeln('COM #',ord(com_dev)+1:1,': Setup Menu  Device#',rec_no:2);
        writeln('==================');
        writeln;
        menu_entry('Description : '+dev_des[com_dev],1);
        writeln;

        str(baud_arr[dos_val[com_dev] shr 5]:5,ln1);
        menu_entry('Baud Rate   = '+ln1,1);
        menu_entry('Parity type = '+pari_arr[(dos_val[com_dev] and $18) shr 3],1);
        str(8-((dos_val[com_dev] and $01) xor 1):2,ln1);
        menu_entry('Word Length = '+ln1,1);
        str(1+((dos_val[com_dev] and $04) shr 2):2,ln1);
        menu_entry('Stop Bits   = '+ln1,1);

        writeln;
        if set_str[com_dev]='' then ln1:='null' else ln1:=set_str[com_dev];
        menu_entry('Open Set Str: '+ln1,1);
        menu_entry('Hand Shake  = '+hand_arr[hand_shk[com_dev]],1);
        writeln;
        menu_entry('Keep Parameters',1);

        writeln;
        menu_op2(['B','P','W','S','K','H','D','O']);
        writeln; writeln;
        option:=response;
        case option of
          'B':begin
                for key:=0 to 7 do writeln('F',key+1,' -',baud_arr[key]:5);
                write('Press F1-F8 ? ');
                repeat key:=keyin3; until (key>570) and (key<579);
                key:=key-570;
                dos_val[com_dev]:=(dos_val[com_dev] and $1F)+((key-1) shl 5);
              end;
          'P':begin
                quest2(0,0,'Parity [O]dd [E]ven [N]one ? ',['O','E','N'],false);
                case response of 'N':key:=0; 'E':key:=3; 'O':key:=1; end;
                dos_val[com_dev]:=(dos_val[com_dev] and $E7)+(key shl 3);
              end;
          'W':begin
                quest2(0,0,'Word Length  [7] [8] ? ',['7','8'],false);
                dos_val[com_dev]:=(dos_val[com_dev] and $FC)+(ord(response)-48-5);
              end;
          'S':begin
                quest2(0,0,'Stop Bits [1] [2] ? ',['1','2'],false);
                dos_val[com_dev]:=(dos_val[com_dev] and $FB)+((ord(response)-48-1) shl 2);
              end;
          'H':begin
                 quest2(0,0,'Handskake [N]one  [X]on/off  [H]ardware ? ',['N','X','H'],false);
                 case response of
                   'N':hand_shk[com_dev]:=0;
                   'X':hand_shk[com_dev]:=1;
                   'H':hand_shk[com_dev]:=2;
                 end{case};
              end;
          'D':dev_des[com_dev]:=read_fn(dev_des[com_dev],13,8,'Device Name ',false);
          'O':set_str[com_dev]:=read_fn(set_str[com_dev],591,587,'Setup String (End & <- key) ',false);
        end{case};
      end{with}
    until option='K';
    seek(cfg_file,rec_no); write(cfg_file,com_record); close(cfg_file);
    set_com(com_dev,rec_no);
  end{config_com};

procedure com_menu(com_str:string);
  type
    com_file = record msg_file : text; r_cnt : integer; end;
  var
    option     : char;
    key        : integer;
    rec        : string[255];
    c_f        : array[com_port] of com_file;
    w_port     : com_port;
    t_port     : com_port;
    y,i        : integer;
    time       : string;
    fn         : string;   { FileName string }
    last_r_cnt : integer;

    rec_no     : integer;
    cfg_file   : file of com_set_rec;
    msg_fn     : string;
    con_file   : text;

  const msg='COMDATA';

function  when:string;
   var
     tt,dd : string[10];
     t     : real;
     h,m,s,sh,y,mon,d,dw : word;

  begin
    gettime(h,m,s,sh); getdate(y,mon,d,dw);
    str((int(mon)*100+int(d)+(int(y)-1900)*10000):6:0,dd);
    t:=int(h)*10000+int(m)*100+int(s)+int(sh)/100;
    str(t:9:2,tt);
    if t<10000 then tt:='00'+copy(tt,3,7)
    else if t<100000.0 then tt:='0'+copy(tt,2,8);
    when:=dd+':'+tt;
  end;

  begin{com_menu}
    if c_ptr[plt_port].o_que and (c_ptr[plt_port].hand_shk=2) then
      begin set_int(plt_port,0); { shut transimission off until com work done }
            c_ptr[plt_port].flow:=false;
      end;
    if c_ptr[dig_port].active then
      begin com_IRQ(dig_port,off); c_ptr[dig_port].rec_len:=0; end;

    rec_no:=0;
    for w_port:=c1 to c2 do with c_ptr[w_port] do use:=install and not active;

     repeat
       clrscr;
       write('COM Main Menu   Config Device:',rec_no:2,' -');
       with com_record do writeln(dev_des[c1]:17,dev_des[c2]:16);
       writeln('=============');
       writeln;
       menu_entry('Select Config Device',1);
       menu_entry('Configure Parameters',2);
       menu_entry('Message Receive (Capture Data)',1);
       menu_entry('Display',2);
       menu_entry('Full Duplex Terminal',1);
       menu_entry('Half',2);
       menu_entry('Review Data',1);
       menu_entry('Archive (SAVE Data to File)',2);
       menu_entry('Xmodem File Transfer (CheckSum)',1);
       menu_entry('Exit',1);
       writeln;
       response:=command(com_str); if response=' ' then
       menu_op2(['C','M','A','E','R','S','D','F','H','X']);
       option:=response;
       writeln;
       if option in ['F','H','X'] then
         begin
           response:=command(com_str);
           if response=' ' then response:=chr(def_term_port+48);
           if not (response in ['1','2']) then quest2(0,0,'Port 1/2 ? ',['1','2'],true);
           if response='1' then t_port:=c1 else t_port:=c2;
         end;
       case option of
         'X':xmodem(t_port,com_str);
         'C':begin
               response:=command(com_str); if response=' ' then
                 quest2(0,0,'COM Port # [1] [2] ? ',['1','2'],true);
               if response='1' then com_config(c1,rec_no) else com_config(c2,rec_no);
             end;
 'F','H','D','M':begin
               regs.ah:=$33; regs.al:=1; regs.dl:=0;
               intr($21,regs); { turn ctrl-c cjk off }
               clrscr;
               writeln('MESSAGE  RECEIVE  MODE   Start Time:  ',when);
               writeln('======================');
               writeln;
               writeln(' Press <End> to Exit.');
               writeln;

               for w_port:=c1 to c2 do with c_ptr[w_port] do
                 begin { find out what we can use }
                   write('Com',ord(w_port)+1:1);
                   if not install then write(' NOT'); write(' Install /');
                   if active or not install then write(' NOT'); write(' Available',' ':8);
                   if use then with c_f[w_port] do
                     begin
                       msg_fn:=msg+chr(ord(w_port)+49)+'.msg'; assign(msg_file,msg_fn);
                       if exist(msg_fn) then append(msg_file) else rewrite(msg_file);
                       com_irq(w_port,on);
                       r_cnt:=0;
                     end;
                 end;
               writeln;
               key:=0;
               case option of
                 'F','H':writeln(' TERMINAL MODE');
                     'M':begin y:=wherey;
                           writeln('Records Recieved','COM1:':12,'COM2:':23);
                           writeln; writeln('Last Rec. Time');
                         end;
                     'D':writeln(' DISPLAY MODE');
               end{case};
               assign(con_file,'CON'); rewrite(con_file);
               repeat
                 for w_port:=c1 to c2 do with c_ptr[w_port],c_f[w_port] do
                   if use then begin
                     last_r_cnt:=r_cnt;
                     rec:=com_rec(w_port);
                     if rec<>'' then begin
                       write(c_f[w_port].msg_file,rec);
                       if pos(^M,rec)>0 then inc(r_cnt);
                       case option of
                          'F','H':if w_port=t_port then write(con_file,rec);
                              'D':write(con_file,rec);
                              'M':if r_cnt>last_r_cnt then
                                    begin
                                      time:=when;
                                      if w_port=c1 then gotoxy(29,y) else gotoxy(52,y);
                                      write(r_cnt:5);
                                      if w_port=c1 then gotoxy(24,y+2) else gotoxy(47,y+2);
                                      write(time);
                                    end;
                       end{case};
                     end{if rec<>''};
                   end{if use};

                 if keypressed then begin
                   key:=keyin3;
                   if (option in ['H','F']) and (key<>591) then begin
                     key:=key and $ff;
                     if c_ptr[t_port].use then com_send(t_port,chr(key));
                     if option='H' then begin
                       write(con_file,chr(key)); write(c_f[t_port].msg_file,chr(key));
                       if key=13 then begin
                         write(con_file,^J); write(c_f[t_port].msg_file,^J);
                         if c_ptr[t_port].use then com_send(t_port,^J);
                       end;
                     end{if Half};
                   end;
                 end{if keypressed};

               until key=591;
               close(con_file);
               for w_port:=c1 to c2 do with c_f[w_port],c_ptr[w_port] do
                 if use then begin com_irq(w_port,off); close(msg_file); end;
               regs.ah:=$33; regs.al:=1; regs.dl:=1;
               intr($21,regs); { turn ctrl-c cjk back on }
             end;
         'R':for w_port:=c1 to c2 do with c_f[w_port] do begin
               msg_fn:=msg+chr(ord(w_port)+49)+'.msg';
               if exist(msg_fn) then
                 begin
                   assign(msg_file,msg_fn); reset(msg_file);
                   clrscr;
                   writeln('Review Msg File for Com',ord(w_port)+1:1);
                   writeln('========================');
                   while not eof(msg_file) do
                     begin
                       readln(msg_file,rec); writeln(rec);
                       if keypressed then begin purge_kbd; key:=keyin3; end;
                     end;
                   writeln; wait_msg('=== End Msg. File ===');
                   close(msg_file);
                 end{if exist}
               else wait_msg('No Msg File: '+msg_fn);
             end;
         'A':begin  { rename current message file }
               for w_port:=c1 to c2 do with c_f[w_port] do
                 begin
                   msg_fn:=msg+chr(ord(w_port)+49)+'.msg';
                   if exist(msg_fn) then
                     begin
                       assign(msg_file,msg_fn); reset(msg_file);
                       if not eof(msg_file) then
                         begin close(msg_file);
                           y:=0;
                           repeat { seek last logical file name }
                             y:=y+1;
                             str(y:2,time); if time[1]=' ' then time[1]:='0';
                             fn:=copy(when,1,6)+'C'+chr(ord(w_port)+49)+'.M'+time;
                           until not exist(fn);
                           writeln;
                           repeat
                             path:=''; fn:=read_fn(fn,13,8,'(ex. JONES.SDR)',true);
                             if exist(fn) then writeln(^G,'*** File Exists ***');
                           until not exist(fn);
                           writeln;
                           rename(msg_file,fn);
                         end{if not eof}
                       else begin
                              close(msg_file);
                              wait_msg('NO DATA in Msg File: '+msg_fn);
                            end;
                     end{if exist}
                   else wait_msg('NO Msg File: '+msg_fn);
                 end{for};
             end;
        'S':begin { select COMM config file }
               if exist(com_cfg_fn) then
                 begin
                   assign(cfg_file,com_cfg_fn); reset(cfg_file);
                   for i:=0 to 22 do
                     begin
                       read(cfg_file,com_record);
                       with com_record do writeln(i:3,' -', dev_des[c1]:16,dev_des[c2]:16);
                     end;
                   close(cfg_file);
                   writeln; write('Config Device # ? ');
                   response:=command(com_str);
                   if response=' ' then rec_no:=read_i(0) else rec_no:=ord(response)-48;
                   writeln;
                   if rec_no>29 then rec_no:=0; com_set_rec_no:=rec_no;
                   set_com(c1,rec_no); set_com(c2,rec_no);
                 end
               else begin com_config(c1,rec_no);
                          com_config(c2,rec_no);
                    end;
            end{'S'};
       end{case};
     until option='E'{xit};

     writeln;

     if dig_flag then
       begin set_com(dig_port,0);
             com_irq(dig_port,on);
             c_ptr[dig_port].rec_len:=dig_bytes;
             purge(dig_port);
       end;

     with c_ptr[plt_port] do
       if (port[com_base[plt_port]+ms_p] and ms_DSR=ms_DSR) and (hand_shk=2) and o_que
       then begin set_com(plt_port,0); flow:=true; end;
   end;


procedure plot_menu(fn:string; com_str:string);
begin
  repeat
    clrscr;
    writeln('Plot Drawing'); gotoxy(1,3);
    menu_entry('Make  DRawing.',1);
    menu_entry('Spool DRawing.',2);
    menu_entry('Purge Ports.',1);
    menu_entry('Query Status.',2);
    writeln;
    menu_entry('Exit.',1);
    response:=command(com_str);
    if response=' ' then menu_op2(['M','S','P','Q','E']);
    writeln;
    case response of
       'M':begin Option:='Ex'; Plot:=true; end;
       'S':if not c_ptr[plt_port].active then
             begin try_plot(read_fn(fn,13,8,'Spool',true)); com_str:='Q'; end
           else wait_msg('...Spooling   [P]urge port to STOP.');
       'P':begin
              if c_ptr[plt_port].active then
                begin com_irq(plt_port,off);
                  writeln('*** Plotter Port PURGED ***');
                end;
              if c_ptr[dig_port].active then
                begin com_irq(dig_port,off);
                  dig_flag:=false;
                  screen(white+blink,black);
                  writeln('*** Dig Port OFF (use SD) ***');
                end;
              response:='E';
           end;
       'Q':begin
                writeln;
                writeln('PORT Active Spool   Flow  Buff Cnt  REC left  IN_STAT  Chr_Cnt Rec_Cnt TX_pend');
                writeln('==== ====== ====== ====== ========  ========  =======  ======= ======= =======');
                repeat
                  with c_ptr[plt_port] do
                    writeln('PLOT',active:7,o_que:7,flow:7,out_cnt:9,plt_rec_cnt:9,
                                  in_stat:10,chr_cnt:9,rec_cnt:8,TX_pending:7);
                  with c_ptr[dig_port] do
                    writeln('DIG ',active:7,  ' ':7,flow:7,out_cnt:9,' ':9,
                                  in_stat:10,chr_cnt:9,rec_cnt:8,TX_pending:7);
                  writeln; write('Plot IRQ Restarts =',no_irq_restarts:6);
                  gotoxy(1,wherey-3);
                  fill_bufo(plt_port);
                  response:=command(com_str);
                  if response=' ' then if keypressed then response:=upcase(readkey);
                until response in ['E',^[,'Q'];
           end;
     end{case};
  until response in ['E','M'];
end;

procedure Try_plot(fn:string); { try to Spool a file to the plotter port }
  var dirInfo : searchrec;
   begin with c_ptr[plt_port] do
     if exist(fn) then
       begin
         assign(que_file,fn); reset(que_file);
         set_com(plt_port,com_set_rec_no);
         com_IRQ(plt_port,on);
         findfirst(fn,anyfile,DirInfo);
         plt_rec_cnt:=trunc((dirinfo.size+127)/128);
         o_que:=true;
         writeln('Spooling File: ',fn);
       end
       else cnff(fn);
   end;

begin
  plot:=false;
  def_term_port:=0;
end.
