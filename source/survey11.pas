unit survey11;
interface
uses dos,crt,survey0,basics2;

{$I Direct}   { Compiler directives }

{$undef chk_dsk}
{$undef demo}
{$undef key_file}

procedure init_set;
procedure start;
procedure done;
procedure pc_ts_Exit;
procedure pcts_id_tag;

implementation

procedure cursor(i:integer);
  const
    cur_set : array[1..15,1..2] of integer =
      ((0,7),(1,7),(2,7),(3,7),(4,7),(5,7),(6,7),(7,7),(3,4),(2,5),(1,6),
       (7,0),(6,1),(5,2),(4,3));
  begin
    if not (i in [1..15]) then i:=2;

{$if 1=0}
    with regs do begin
      ax:=$0100; { set function } cx:=cur_set[i,1]*256+cur_set[i,2]; {cur val}
    end;
    intr($10,regs); { do it }
{$endif}
  end;

procedure log_settings;
  var
     cur_file : text;
     i,j,k    : integer;
  begin
    pt_rec0.bs_ang:=0;
    i:=99;
    bs_edit:=false;
    as_br_flg:=false;
    recalc:=true;
    EDM_const:=0.5446194; { inches }
    com_drv:=2; { C disk drive }
    f_keys[1]:=' '; f_keys[2]:=' '; f_keys[3]:=' '; f_keys[4]:=' ';
    lst_fn:='FN';
    reg_disp_flg:=true;
    des_disp_flg:=true;
    max_srt_pts:=3200;
    if exist('settings.cfg') then
      begin
        writeln('Using File: SETTINGS.CFG');
        assign(cur_file,'settings.cfg'); reset(cur_file);
        readln(cur_file,i); { cursor }
        readln(cur_file,j); if j>0 then as_br_flg:=true; { angle print type }
        readln(cur_file,j); if j>0 then bs_edit:=true;   { edit back site angle }
        readln(cur_file,j,lst_fn); if j=0 then lst_flag:=false; { printer status }
        readln(cur_file,j); if j=0 then recalc:=false ;  { recalc switch  }
        readln(cur_file,EDM_const);
        readln(cur_file,com_drv);
        read(cur_file,j); if j=0 then reg_disp_flg:=false;
        readln(cur_file,j); if j=0 then des_disp_flg:=false;
        readln(cur_file,f_keys[1]); readln(cur_file,f_keys[2]);
        readln(cur_file,f_keys[3]); readln(cur_file,f_keys[4]);
        readln(cur_file); { ascii-in data }
        readln(cur_file,machine_type,def_term_port);
        readln(cur_file,max_srt_pts);
        close(cur_file);
        while copy(lst_fn,1,1)=' ' do delete(lst_fn,1,1);
        k:=1; repeat lst_fn[k]:=upcase(lst_fn[k]); inc(k); until lst_fn[k]=' ';
        lst_fn:=copy(lst_fn,1,k-1);
        max_srt_pts:= max_srt_pts mod 3201;  { 3200 max }
      end
    else cnff('SETTINGS.CFG');
    cursor(i);
  end;

{ $I PassWord}

procedure pcts_id_tag;
  begin
    WRITELN('PC-TURBO SURVEY V2.51+ 8908.06  SN:8908-');
    WRITELN('by: CompuRight Industries');
    WRITELN('Sandy Hook CT 06482');
    WRITELN('Writen by: Gary L. Argraves');
    WRITELN('Part of the (KAS) collection.');
    writeln;
  end;

procedure signon;

  {$IFDEF chk_dsk}             { check if track 40 head 1 sector 32 exist }
  procedure Chk_KeyDisk;
      function KeyDisk:boolean;
        type regpack = registers; var  regs : RegPack;
        begin
          regs.ax:=$0000; intr($13,regs); { reset floppy }
          with regs do begin ax:=$0401;  cx:=$2720;       dx:=$0100; end;
                                      {  Track^  ^Sector   Head^  ^Drive }
          intr($13,regs);
          if hi(regs.ax)=0 then keyDisk:=true else keydisk:=false;
        end;
      procedure halt_chk;
        begin
          if not keydisk then
            begin
              writeln;
              writeln(^G,'ERROR ==> Unauthorized Copy.');
              writeln('Put the Original PC-TS Distribution Disk in Drive A:');
              halt;  { if not correct disk then halt }
            end;
        end;

    var s,s2:string[20]; i:integer;
    begin {chk_keyDisk};
      if paramCount>2 then
        begin (*******   HALT CHECK for DISK DRIVE A *******)
          s:=paramStr(3);
          for i:=1 to length(s) do s[i]:=chr((ord(s[i]) xor $ff)-100);
          s2:=pw2; i:=length(s2); while s2[i]=' ' do dec(i); s2:=copy(s2,1,i);
          if s<>s2 then halt_chk; end
      else halt_chk;
    end{chk_Keydisk};
  {$ENDIF}

  {$IFDEF  key_file}            { check if PC-TS.SYS file in root dir & hidden }
  procedure key_file(fn:string);
    var k_file : file; fa : word;
    begin
      assign(k_file,fn); getfattr(k_file,fa);
       if not exist(fn) or (fa and 2 = 0) then begin
         writeln(^G,'*** UnAuthorized Copy ***'); halt; end;
    end;
  {$ENDIF}

begin{signon}
  {$IFDEF chk_dsk}             { check if track 40 head 1 sector 32 exist }
    chk_keyDisk;
  {$ENDIF}

  {$IFDEF demo}          { Demo version cau use up to 100 points max .}
    demo:=true;          { default is Demo version }
    if paramCount>1 then { check if not demo password OK }
      begin
        s:=paramStr(2);
        for i:=1 to length(s) do s[i]:=chr((ord(s[i]) xor $ff)-100);
        s2:=pw1; i:=length(s2); while s2[i]=' ' do dec(i); s2:=copy(s2,1,i);
        if s=s2 then demo:=false;
      end;
     if demo then begin
        textcolor(blink+yellow); writeln(^G,'+++ Demo Ver, 100 Pts Available +++');
        textcolor(yellow); writeln;
      end;
  {$ELSE}
    demo:=false;   { Not a demo version }
  {$ENDIF}

  {$IFDEF  key_file}            { check if PC-TS.SYS file in root dir & hidden }
    key_file('\PCTS.SYS');
  {$ENDIF}

  pcts_id_tag;
  screen(white,black);
end;

procedure Open_Pt_File;
  var
    i       : integer;
    sort_rec: sort_xyp;

  procedure make_sort_file;
    var
      i          : integer;
      c          : array[0..3200] of ^sort_xyp;   { 3200 max, Easting coordinates }
      ok         : boolean;
      heap_state : ^integer;

     procedure quicksort(Lo,Hi: integer);
         procedure sort(l,r: integer);
           var i,j : integer;
               x   :real;
           begin
             i:=l; j:=r;
             x:=c[(l+r) div 2]^.x;
             repeat
               while c[i]^.x < x  do inc(i);
               while x < c[j]^.x  do dec(j);;
               if i<=j then
                 begin c[0]:=c[i]; c[i]:=c[j]; c[j]:=c[0];
                       inc(i); dec(j);
                 end;
             until i>j;
             if l<j then sort(l,j);
             if i<r then sort(i,r);
           end;

       begin {quicksort};
         write('...Sorting');
         sort(Lo,Hi);
         write('...Writing: ',fn8);
       end;

    begin
//mark(heap_state);
      if no_pts > max_srt_pts then for i:=0 to max_srt_pts do new(c[i])
      else for i:=0 to no_pts do new(c[i]);
      write('...Loading Pts     ');
      i:=0;
      repeat
        with c[i+1]^ do
          begin
            inc(i); p:=i;
            if i mod 100 = 0 then write(^H^H^H^H,i:4);
            if alt_flag then
              begin
                {$I-} seek(alt_pt_file,i); read(alt_pt_file,alt_pt_rec); {$I+}
                ok:=(IOResult=0);
                with alt_pt_rec do begin x:=alt_x; y:=alt_y; el:=alt_z; end;
              end
            else
              begin
                {$I-} seek(pt_file,i); read(pt_file,pt_rec); {$I+}
                ok:=(IOResult=0);
                with pt_rec do begin x:=east; y:=north; el:=elev; end;
              end;
          end;
      until (i=no_pts) or (not ok) or (i=max_srt_pts);
      write(^H^H^H^H,i:4,'  ');

      if not ok then
        begin
          writeln(^G,no_pts-(i-1):4,'  Pts have been LOST.');
          no_pts:=i-1;
          if alt_flag then
            begin alt_pt_rec0.alt_x:=i-1;
                  seek(alt_pt_file,0); write(alt_pt_file,alt_pt_rec0);
            end
          else
            begin pt_rec0.from_pt:=i-1;
                  seek(pt_file,0); write(pt_file,pt_rec0);
            end;
        end;

        rewrite(sort_file);
        if i=max_srt_pts then
          begin
            quicksort(1,max_srt_pts);
            for i:=0 to max_srt_pts do write(sort_file,c[i]^);
            writeln('  Pts ',max_srt_pts+1:4,'-',no_pts:4,' NOT Sorted');
            for i:=max_srt_pts+1 to no_pts do write(sort_file,c[1]^);
          end
        else
          begin
            quicksort(1,no_pts);
            for i:=0 to no_pts do write(sort_file,c[i]^);
          end;
        writeln;
        reset(sort_file);
//release(heap_state);
    end{make_sort_file};

  begin
    file_flag:=false;
    alt_flag:=false;

    purge_kbd;

    path:='*.PT';
    fn:=paramstr(1);
    if fn='' then fn:='*.PT' else fn:=fn+'.PT';

    if (pos('*',fn)>0) or (pos('?',fn)>0) or (not exist(fn)) then
      fn:=read_fn(fn,13,8,'Coordinate',true);
    writeln;

    if length(fn)>2 then alt_flag:=(copy(fn,length(fn)-1,2)='.A');
    if pos('.',fn)>0 then fn:=copy(fn,1,pos('.',fn)-1);

    if length(fn)>0 then
      begin
        fn2:=fn+'.BAL';
        fn3:=fn+'.LN';
        fn4:=fn+'.LED';
        fn5:=fn+'.AR';
        fn6:=fn+'.PT0';
        fn7:=fn+'.';
        fn8:=fn+'.SRT';

{$if 1=0}
        ed_lfs:=fn+'.*';  { used in editor }

        if fn[2]<>':' then
          begin
            fn7:=last_drv+':'+fn7;  { rotation file, write to ram drive }
            fn8:=last_drv+':'+fn8;
          end
        else
          begin
            fn7[1]:=last_drv;
            fn8[1]:=last_drv;
          end;
{$endif}

        { parse path out of fn7, fn8 }
        i:=length(fn7); repeat dec(i); until (i=0) or (fn7[i]='/');
        if i>0 then delete(fn7,3,i-2);
        i:=length(fn8); repeat dec(i); until (i=0) or (fn8[i]='/');
        if i>0 then delete(fn8,3,i-2);

        if lst_fn<>'FN' then
          begin assign(lst,lst_fn);
                if lst_fn='PRN' then lst_fn:=fn+'.LST';
          end
        else begin lst_fn:=fn+'.LST'; assign(lst,lst_fn); end;
        if exist(lst_fn) then append(lst) else rewrite(lst);

        if alt_flag then
          begin write(' Alternate Pt File.');
                fn:=fn+'.PA'; assign(alt_pt_file,fn);
                {$I-}  reset(alt_pt_file);  {$I+} end
        else begin fn :=fn+'.PT'; assign(pt_file,fn);
                {$I-}  reset(pt_file);  {$I+} end;

        assign(sort_file,fn8);
        if IOresult=0 then { existing point file opened }
          begin
            no_pts:=0;
            get(0,pt_rec0);
            writeln('File Description : ',pt_rec0.descrip);
            alt_pt_rec0.alt_d:=pt_rec0.descrip;
            no_pts:=pt_rec0.from_pt;
            file_flag:=true;
            if no_pts>0 then
              begin
                if max_srt_pts>0 then make_sort_file
                else
                  begin
                    {$I-} reset(sort_file); {$I+}
                    if IOResult>0 then rewrite(sort_file); { no sort file }
                  end;
              end
            else begin rewrite(sort_file); put3(0,sort_rec); end;
            no_pts2:=no_pts;
          end
        else
          begin
            quest(0,0,' Create JOB File (Y/N) ? ',['Y','N'],false); writeln;
            if response='Y' then
              begin
                init_pt_rec(pt_rec0);
                if alt_flag then rewrite(alt_pt_file) else rewrite(pt_file);
                write('Enter JOB Description (20 char) ? ');
                readln(pt_rec0.descrip);
                alt_pt_rec0.alt_d:=pt_rec0.descrip;
                pt_rec0.from_pt:=0;
                pt_rec0.code:=1;
                pt_rec0.bs_ang:=0;
                pt_rec0.f_dist:=0;
                pt_rec0.bs_pt:=0;
                pt_rec0.rod:=0;
                pt_rec0.setup:=true;
                pt_rec0.aszmith:=0;
                no_pts:=0;
                put(0,pt_rec0);
                file_flag:=true;
                rewrite(sort_file); put3(0,sort_rec);
              end
            else begin writeln; fn4:=get_dir(copy(fn,1,1)+'*.P??',false); end;
          end;
      end;
    dig_des:='?';
  end;

procedure start;
  begin
     act_script:=0;    { set these var here to conserve code space }
     act_if[0]:=0;
     act_label:=0;
     if_arr[0,0]:=true;
     learn:=false;
     con_flag:=false;
     but1_flag:=false;
     signon;
     log_settings;
     open_pt_file;
     if alt_flag then recalc:=false;
{$if 1=0}
     {$IFDEF small_edit}
       edcode:=InitBinaryEditor(EdData,$8000,1,1,80,25,false,EdOptIndent+EdOptInsert+EdOptBlock,'',ExitCommands,nil);
     {$ELSE}
       edcode:=InitBinaryEditor(EdData,MaxFileSize,1,1,80,25,false,EdOptIndent+EdOptInsert+EdOptBlock,'',ExitCommands,nil);
     {$ENDIF}
{$endif}

  end;

procedure init_set;
  type reg_rec_type = record p:integer; r:real; a:real; end;
  var
    dig_file  : text;
    f_des     : string[50];
    i,j       : integer;
    reg_file  : file of reg_rec_type;
    reg_rec   : reg_rec_type;
   begin
      option_set:=
      'AdEdDeLlLpLaAaPpOfArCuRtBaPrExLtSeBrVcInPlSoStToSdAmDaTaMsRcSsMcUcPcFwPeUeCcAnGpDxFlScFeReTpQsCo'+
      'BuPs!!MlDmLdMpDcAoRaSaLm||RsRfIfEiElTrLbJpShDrVeEtAiEeCtPfVpNpAsFcFpCl';
     writeln;  textcolor(lightred);
     writeln('Remember to EXit PC-TS before turning computer OFF.');
     textcolor(lightgreen);
     vert_type:='V';
     dig_shape:=false;
     tag_prn(fn+': '+pt_rec0.descrip);
     last_from:=0;
     last_descrip:='?';
     last_dist_type:='H';
     last_alt_loci:=0;
     last_alt_locr:=0;
     last_alt_loca:=0;
     r2_flag:=false; { true if real input with characters }
     add_flag:=-1;
     roll_flag:=true;
     cogo_err:=false;
     con_color:=white;
     for i:=1 to 10 do
       begin
         last_asz[i]:=0;
         last_des[i]:='?';
         last_int[i]:=no_pts;
         last_real[i]:=0;
         last_lin1[i].lt:=0;
         last_lin1[i].pen:=1;
         last_lin1[i].lab:='B';
       end;
     for i:=0 to 100 do
       begin
         last_alt_real[i]:=0;
         last_alt_asz[i]:=0;
         last_alt_int[i]:=1;
       end;
     last_alt_asz[0]:=0;
     int_os:=0;
     real_os:=0;
     asz_os:=0;

{$if 1=0}
     if exist(copy(fn,1,length(fn)-2)+'DES') then
       begin
         assign(led_file,copy(fn,1,length(fn)-2)+'DES'); reset(led_file);
         i:=0;
         for i:=1 to 10 do readln(led_file,last_des[i]);
         readln(led_file,path);
         readln(led_file,ed_lfs);
         readln(led_file,ed_fn);
         close(led_file);
         for i:=2 to 15 do
           if pick_lst[i].p_file=ed_fn then pick_roll(pick_lst[i]);
       end;
     if exist(copy(fn,1,length(fn)-2)+'REG') then
       begin
         assign(reg_file,copy(fn,1,length(fn)-2)+'REG'); reset(reg_file);
         for i:=0 to 100 do
           begin
             read(reg_file,reg_rec);
             last_alt_int[i] :=reg_rec.p;
             last_alt_real[i]:=reg_rec.r;
             last_alt_asz[i] :=reg_rec.a;
           end;
         close(reg_file);
       end;
{$endif}

     for i:=1 to 25 do for j:=1 to 40 do men_arr[i,j]:=0;
     dig_men_flg:=false;
     last_pt_type:=1;

     dig_type:=0;
     writeln;
     xo:=1; yo:=2; eo:=3; no:=4; dx_scale:=100; dy_scale:=100; skew_ang:=0;
{$if 1=0}
     if exist('dig.cfg') then
       begin
         assign(led_file,'dig.cfg'); reset(led_file);
         readln(led_file,i,dig_type,j);
         if i=1 then begin plt_port:=c2; dig_port:=c1; end;
         write('==> Digitizer Type =',dig_type:2,'  ');
         case dig_type of
           0:writeln('NONE');
           1:begin writeln('Houston Instruments'); dig_bytes:=17; end;
           2:begin writeln('SummaGraphics Micro Grid'); dig_bytes:=08; end;
          98:begin
               writeln('BINARY Frame Output');
               readln(led_file,dig_bytes,dig_div_fact);
               for i:=1 to 3 do
                 readln(led_file,dig_98[i,1],dig_98[i,2],dig_98[i,3]);
               readln(led_file,dig_98[4,1],dig_98[4,2]);   { 32768 add }
               readln(led_file,dig_98[5,1],dig_98[5,2]);   { +/- sign  }
               for i:=6 to 8 do
                 readln(led_file,dig_98[i,1],dig_98[i,2],dig_98[i,3]);
               readln(led_file,dig_98[9,1],dig_98[9,2]);
               readln(led_file,dig_98[10,1],dig_98[10,2]);
             end;
          99:begin
               writeln('ASCII Frame Output');
               readln(led_file,dig_bytes,dig_div_fact);
               readln(led_file,dig_99[1],dig_99[2],dig_99[3]);
             end;
         end{case};

        set_com(plt_port,0);
        set_com(dig_port,0);
        com_irq(dig_port,on);
        c_ptr[dig_port].rec_len:=dig_bytes;
        purge(dig_port);
        c_ptr[dig_port].flow:=true;

        for i:=1 to 20 do dig_exit_arr[i]:=0; { init exit array }

         { setup of summa graphics digitizer }
         if j<>0 then { send digitizer setup string }
           begin
             write('==> Sending Digitizer Setup Data.');
             i:=0;
             while not eof(led_file) and (i>=0) do
               begin
                 {$I-} read(led_file,i); {$I+}
                 if IOResult>0 then readln(led_file)
                 else if i=128 then delay(2000) { wait for system resets }
                      else if i>=0 then  com_send(dig_port,chr(i));
               end;

             i:=0; j:=0;  { get exit command str for acad reentey }
             while not eof(led_file) and (i>=0) and (j<20) do
               begin
                 {$I-} read(led_file,i); {$I+}
                 if IOResult>0 then readln(led_file)
                 else if i>=0 then begin inc(j); dig_exit_arr[j]:=i; end;
               end;
             if (i>0) or (j=20) then
               for j:=1 to 20 do dig_exit_arr[j]:=0; { no exit data }

             writeln;
           end{if j}
         else writeln('*** NO Digitizer Setup Data ***');
         close(led_file);

         if (exist('DIG-SET.DAT')) and (dig_type<>0) then
           begin
             assign(led_file,'DIG-SET.DAT');
             reset(led_file);
             readln(led_file,f_des);
             readln(led_file,xo,yo,eo,no,dx_scale,dy_scale,skew_ang);
             close(led_file);
             writeln('==> Digtizer Setup: ',f_des);
             dig_flag:=true;
           end;
       end{if exist}
     else cnff('DIG.CFG');
{$endif}
   end{init-set};

procedure done;
  type reg_rec_type = record p:integer; r:real; a:real; end;
  var i        : integer;
      reg_file : file of reg_rec_type;
      reg_rec  : reg_rec_type;
   begin
{$if 1=0}
     if file_flag then
       begin
         assign(led_file,copy(fn,1,length(fn)-2)+'DES'); rewrite(led_file);
         for i:=1 to 10 do writeln(led_file,last_des[i]);
         writeln(led_file,path);
         writeln(led_file,ed_lfs);
         writeln(led_file,ed_fn);
         close(led_file);
         reset(pick_file); for i:=1 to 15 do write(pick_file,pick_lst[i]);
         close(pick_file);
         assign(reg_file,copy(fn,1,length(fn)-2)+'REG'); rewrite(reg_file);
         for i:=0 to 100 do
           begin
             reg_rec.p:=last_alt_int[i];
             reg_rec.r:=last_alt_real[i];
             reg_rec.a:=last_alt_asz[i];
             write(reg_file,reg_rec);
           end;
         close(reg_file);
         if learn then close(lrn_file);
         if lst_flag then close(lst);
         if plot then
           begin
             mode(' Plot Drawing ');
             writeln('. . .Ready the Plotter System');
           end;
       end;
     writeln('PC-TS DONE');
     releasebinaryeditorheap(EdData);
{$else}
     if file_flag then
       begin
         if learn then close(lrn_file);
         if lst_flag then close(lst);
       end;
     writeln('PC-TS DONE');
{$endif}
   end;

procedure pc_ts_Exit;
   begin
{$if 1=0}
     mode('EXit PC-TS');gotoxy(1,5);
     if c_ptr[plt_port].active then
       begin
         plot:=false;
         writeln(^G,'==> Still Spooling Data,  Purge the Plotter Port.');
         option:='  ';
       end
     else if ModifiedFileBinaryEditor(EdData) then
            begin writeln(^G,'*** Editor File NOT Saved ***'); option:='  '; end
          else
           begin
             if alt_flag then close(alt_pt_file) else close(pt_file);
             if no_pts2>0 then close(sort_file);

             com_irq(plt_port,off);  { shut plotter port down }
             if c_ptr[dig_port].active and (dig_exit_arr[1]>0) then
              begin
                 writeln('==> Sending Digitizer Exit Setup Data');
                 for i:=1 to 20 do
                  if dig_exit_arr[i]=128 then delay(1500)
                  else if dig_exit_arr[i]>0 then com_send(dig_port,chr(dig_exit_arr[i]));
                 delay(1500); { wait for dig exit string to be interrupted sent }
                 plot_menu('','QE ');
                 setIntVec(com_IRQ_no[dig_port],c_ptr[dig_port].c_IRQ_vec);
                 gotoxy(1,wherey+5);
                 writeln('==> COM IRQ for Dig Port Still Enabled.');
               end
             else com_irq(dig_port,off)
           end;
{$endif}
    end;


end.
