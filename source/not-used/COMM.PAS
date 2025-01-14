unit comm;
interface
uses dos,crt;

type
  switch   = (on,off);
  com_port = (c1,c2);                                  { Communication Ports }
  c_rec  = record
                ii_ptr    : integer;                   { incoming char. }
                io_ptr    : integer;                   { buffered char. }
                bufi      : array[0..2047] of byte;    { com in buffer }
                in_cnt    : integer;                   { no of char in buf }
                in_stat   : boolean;                   { buffer status  }
                chr_cnt   : byte;                      { used for rec cnt }
                rec_cnt   : integer;                   { records in buffer CR }
                rec_len   : integer;                   { # bytes/record 0=CR LF }

                oi_ptr    : integer;                   { incoming char. }
                oo_ptr    : integer;                   { buffered char. }
                bufo      : array[0..2047] of byte;    { com out buffer }
                out_cnt   : integer;
                que_file  : file;                      { output disk que file }
                o_que     : boolean;                   { true if out date qued }
                TX_pending: boolean;                   { true if TX_IRQ did not send char }

                c_IRQ_vec : pointer;                   { the old interupt vec }
                ident     : byte;                      { interupt reason }
                lin_stat  : byte;                      { line status }
                mod_stat  : byte;                      { modem status }
                install   : boolean;                   { true if com port exist }
                active    : boolean;                   { true if com port in use }
                use       : boolean;                   { if true then use this port }
                flow      : boolean;                   { type of flow control }
                hand_shk  : byte;                      { type of hand shake }
                x_off_to_on : boolean;                 { ready to send x-on }
                x_off,x_on  : boolean;                 { IRQ flow control var's }
          end;

  com_set_rec = record
                dos_val  : array[com_port] of byte;        { dos com setup value }
                dev_des  : array[com_port] of string[14];  { device description }
                set_str  : array[com_port] of string[16];  { setup string }
                hand_shk : array[com_port] of byte;        { type of hand shake }
             end;

const
  ie_p       = 1;   { interupt enable com port}
  ie_RD      = 1;   { interupt enable Recieve interupt }
  ie_TX      = 2;   { interupt enable Transmit interupt }
  ie_LS      = 4;   { interupt enable Line Stat Int. }
  ie_MS      = 0{8};   { interupt enable Modem Stat Int. }
  id_p       = 2;   { interupt identity port }
  id_NP      = 1;   { interupt Not Pending }
  id_RD      = 4;   { char recieved }
  id_TX      = 2;   { transmit register empty }
  id_LS      = 6;   { line status }
  id_MS      = 0;   { modem status }

  mc_p       = 4;   { modem control port }
  mc_DTR     = 1;   { modem control Data Terminal Ready }
  mc_RTS     = 2;   { modem control Request to Send }
  mc_Ring    = 4;   { enable ring }
  mc_RD      = 8;   { enable data receive}
  ms_p       = 6;   { modem stat port }
  ms_CTS     = 16;  { clear to send }
  ms_DSR     = 32;  { data set ready }
  ms_RI      = 64;  { ring indicator }
  ms_CD      = 128; { Carrier Detect }

  lc_p       = 3;   { line control port }
  ls_p       = 5;   { line stat port }
  ls_OR      = 2;   { Over Run }
  ls_PE      = 4;   { Parity Error }
  ls_FE      = 8;   { Framing Error }
  ls_BI      = 16;  { Break interupt }
  ls_THRE    = 32;  { Transmit holding register empty }
  com_IRQ_no : array[com_port] of byte = ($0C,$0B); { com int no's }

var
  com_base  : array[com_port] of integer absolute $0040:0000;
  c_ptr     : array[com_port] of c_rec;
  com_dev   : com_port;
  dig_port  : com_port;
  plt_port  : com_port;
  com_cfg_fn: string[15];
  no_irq_restarts : longint;   { no of transmitter IRQ restarts }
  com_set_rec_no  : integer;   { device no. use by try_plot }
  dig_flag   : boolean;        { digitizer connected and functioning }
  dig_bytes  : integer;        { number of bytes per dig frame }
  com_record : com_set_rec;    { current com set up values }
  plt_rec_cnt: integer;        { no of 128 bytes rec. left to spool }

procedure com_IRQ(com_dev:com_port; s:switch);      { turn the port IRQ on/off }
function  com_chr_ready(com_dev:com_port):boolean;  { check if char. ready }
function  com_xmit_empty(com_dev:com_port):boolean; { check if tranmit buf empty }
function  com_char(com_dev:com_port):char;          { get a com char }
procedure com_send(com_dev:com_port; ch:char);      { send a com char }
function  com_rec(com_dev:com_port):string;         { get a com record, CR }
procedure purge(com_dev:com_port);                  { purge input buffer }
procedure set_com(com_dev:com_port; rec_no:integer);{ com port # 1 and 2 }
procedure set_int(com_dev:com_port; enable:byte);   { enable com interupt  }
procedure fill_bufo(com_dev:com_port);              { back ground spooling }
procedure com_record_init;  { set default 9600 None 8 bit 1 stop  X-on/off }

implementation

procedure Int_handler(Flags,cs,ip,ax,bx,cx,dx,si,di,ds,es,bp:word); interrupt;
  begin
    port[$20]:=$0B;  { ask 8259 interupt level }
    if port[$20] and $10 <> 0 then com_dev:=c1 else com_dev:=c2;
    c_ptr[com_dev].ident:=port[com_base[com_dev]+id_p];
    with c_ptr[com_dev] do
      if ident and id_NP = 0 then
        case ident of
           id_RD:begin
                   bufi[ii_ptr]:=port[com_base[com_dev]];
                   case bufi[ii_ptr] and $7f of
                      13:if rec_len=0 then inc(rec_cnt);
                      19:if flow and (hand_shk=1) then { multi X-OFF }
                           begin set_int(com_dev,ie_RD); flow:=false; end;
                      17:if not flow and (hand_shk=1) then { multi X-ON }
                           begin set_int(com_dev,ie_RD+ie_TX); flow:=true; end;
                   end{case};
                   ii_ptr:=(ii_ptr+1) mod sizeof(bufi);
                   in_stat:=true;
                   case rec_len of
                         0:if not (o_que and x_off and (bufi[ii_ptr] in [17,19])) then
                             begin
                               inc(in_cnt);
                               if in_cnt=$600 then { send a single x_off }
                                 begin x_off:=true;
                                       x_off_to_on:=true;
                                       set_int(com_dev,ie_RD+ie_TX);
                                 end;
                             end;
                      else begin
                             chr_cnt:=(chr_cnt+1) mod rec_len;
                             if chr_cnt=0 then inc(rec_cnt);
                           end;
                     end{case};
                 end;
           id_TX:if x_off then begin port[com_base[com_dev]]:=19; x_off:=false; end
                 else if x_on then begin port[com_base[com_dev]]:=17; x_on:=false; end
                      else if out_cnt>0 then
                             begin
                               port[com_base[com_dev]]:=bufo[oo_ptr];
                               oo_ptr:=(oo_ptr+1) mod sizeof(bufo);
                               dec(out_cnt); TX_pending:=false;
                             end
                           else TX_pending:=true;
           id_LS:lin_stat:=port[com_base[com_dev]+ls_p];
           id_MS:begin mod_stat:=port[com_base[com_dev]+ms_p];
                   if hand_shk=2 then
                       case mod_stat and ms_DSR of
                          $00:if flow then
                                begin
                                  set_int(com_dev,ie_RD+ie_MS);
                                  flow:=false;
                                end;
                       ms_DSR:if not flow then
                                begin
                                  set_int(com_dev,ie_RD+ie_TX+ie_MS);
                                  flow:=true;
                                end;
                       end{case};
                 end;
        end{if case};
    port[$20]:=$20;     { EOI for Com IRQ on 8259 $20 }
  end;

function com_chr_ready(com_dev:com_port):boolean; { check if char. ready }
  begin com_chr_ready:=c_ptr[com_dev].in_stat; end;

function com_xmit_empty(com_dev:com_port):boolean; { check if tranmit buf empty }
  begin with c_ptr[com_dev] do com_xmit_empty:=(out_cnt<sizeof(bufo)); end;

function com_char(com_dev:com_port):char; { get a com1 char }
  begin with c_ptr[com_dev] do
        if active then
          begin repeat until com_chr_ready(com_dev); { wait for IRQ character }
            com_char:=chr(bufi[io_ptr]);
            io_ptr:=(io_ptr+1) mod sizeof(bufi);
            dec(in_cnt);
            in_stat:=(io_ptr<>ii_ptr);
            if not in_stat and x_off_to_on then
              begin x_on:=true;
                    x_off_to_on:=false;
                    set_int(com_dev,ie_RD+ie_TX);
              end;
          end
        else com_char:=^@;
  end;

procedure com_TX_irq_restart(com_dev:com_port);    { restart the transmitter }
  begin with c_ptr[com_dev] do
    if flow and TX_pending then { the last TX_IRQ is NOT used if no Buff char. }
      begin inc(no_irq_restarts); set_int(com_dev,ie_RD+ie_TX+ie_MS); end;
  end;

procedure com_send(com_dev:com_port; ch:char); { send a com char }
  begin
    repeat until com_xmit_empty(com_dev);
    with c_ptr[com_dev] do
       begin
         bufo[oi_ptr]:=ord(ch);
         oi_ptr:=(oi_ptr+1) mod sizeof(bufo);
         inc(out_cnt);
         com_TX_irq_restart(com_dev);
       end;
  end;

function com_rec(com_dev : com_port):string;
  var rec:string;
      i:integer;
  begin with c_ptr[com_dev] do if active then
        begin
          rec:='';
          if rec_len=0 then begin
            while com_chr_ready(com_dev) and (length(rec)<255) and
                  (rec[length(rec)]<>^M) do rec:=rec+com_char(com_dev);
            if rec[length(rec)]=^M then dec(rec_cnt);
          end
          else begin for i:=1 to rec_len do rec:=rec+com_char(com_dev);
                 dec(rec_cnt);
               end;
        end{if};
    com_rec:=rec;
  end;

procedure purge(com_dev:com_port);  { purge input buffer }
  var c:char;
    begin with c_ptr[com_dev] do
      if active then begin
        while in_stat do c:=com_char(com_dev);
        rec_cnt:=0; chr_cnt:=0;
        io_ptr:=0; ii_ptr:=0; in_cnt:=0;
      end;
    end;

procedure com_rec_init(com_dev:com_port);
  begin with c_ptr[com_dev] do
    begin
      ii_ptr:=0;   io_ptr:=0;     rec_cnt:=0;     chr_cnt:=0;
      oi_ptr:=0;   oo_ptr:=0;     out_cnt:=0;     rec_len:=0;    in_cnt:=0;
      flow:=false; active:=false; in_stat:=false; o_que:=false;
      TX_pending:=true; x_off:=false; x_on:=false; x_off_to_on:=false;
    end;
  end;

procedure set_int(com_dev:com_port; enable:byte); { enable com interupt  }
     begin
       { Reset Div_Latch_Acc_Bit for Int_Enable_Reg access for xmt/rcv }
       port[com_base[com_dev]+lc_p]:=port[com_base[com_dev]+lc_p] and $7f;
       port[com_base[com_dev]+ie_p]:=enable;
     end;

procedure set_mod(com_dev:com_port; enable:byte);
     begin port[com_base[com_dev]+mc_p]:=enable; end;

procedure IRQ_bit_mask(com_dev:com_port; s:switch); { Enable interrupts on 8259 }
   const msk_val : array[com_port] of byte = ($EF, $F7);
     begin
       if s=off then  { get current mask & restore with com IRQ mask }
            port[$21]:=port[$21] and msk_val[com_dev]
       else port[$21]:=port[$21] or ($FF xor msk_val[com_dev]);
     end;

procedure com_IRQ(com_dev:com_port; s:switch);
  var i : integer;
  begin with c_ptr[com_dev] do
    if (s=on) and install and not active then
      begin
         getIntVec(com_IRQ_no[com_dev],c_IRQ_vec);    { save current int vec }
         setIntVec(com_IRQ_no[com_dev],@Int_Handler); { Set New Int_handler vec address }
         com_rec_init(com_dev);                       { reset var's }
         set_mod(com_dev,mc_DTR+mc_RTS+mc_RD);        { put station on line }
         active:=true;
         hand_shk:=com_record.hand_shk[com_dev];
         case hand_shk of
         0,1:flow:=true;
           2:if port[com_base[com_dev]+ms_p] and ms_DSR=ms_DSR then flow:=true;
         end{case};
         set_int(com_dev,0);        delay(200);       { Disable all 8250 IRQ }
         set_int(com_dev,ie_RD);                      { enable com interrupts }
         IRQ_bit_mask(com_dev,off); delay(200);       { un-mask com IRQ }
         with com_record do for i:=1 to length(set_str[com_dev]) do
                              com_send(com_dev,set_str[com_dev][i]);
      end
    else if (s=off) and active then
           begin
             IRQ_bit_mask(com_dev,on);
             set_int(com_dev,0);                       { Disable all 8250 IRQ }
         {    set_mod(com_dev,0);  } { leave on line } { Disable modem control lines }
             if o_que then close(que_file);            { close spooler input file }
             com_rec_init(com_dev);                    { reset assoc. var's }
             setIntVec(com_IRQ_no[com_dev],c_IRQ_vec); { Restore old IRQ Vec address }
           end;
   end{com_IRQ_driver};

procedure fill_bufo(com_dev:com_port);
  var result : integer;
   begin with c_ptr[com_dev] do
       if o_que and (out_cnt=0) then
         if not eof(que_file) then
           begin
             fillchar(bufo[0],2048,^@);              { put 0's in buff }
             blockread(que_file,bufo[0],16,result);  { get disk file data }
             if result<16 then inc(result);          { last partial record }
             out_cnt:=$80*result;                    { no. char to transmit }
             plt_rec_cnt:=plt_rec_cnt-result;        { no. rec's left to read }
             oo_ptr:=0;
             com_TX_irq_restart(com_dev);
           end
         else com_IRQ(com_dev,off);
   end;

procedure com_record_init;  { set default 9600 None 8 bit 1 stop  X-on/off }
  var p:com_port;
  begin for p:=c1 to c2 do with com_record do
    begin dos_val[p]:=$E3; dev_des[p]:='Null'; set_str[p]:=''; hand_shk[p]:=1; end;
  end;

procedure com_set(com_dev:com_port); { baud, parity, word length, stop bits }
  const                      { 19.2  38.4  300    600   1200  2400  4800  9600 }
    baud:array[0..7] of word=($0006,$0003,$0180, $00C0,$0060,$0030,$0018,$000C);
  begin
     inline($FA); { stop interupts }
     { access baud rate divisor & set parity/word length/stop bits }
     port[com_base[com_dev]+lc_p]:=$80 or (com_record.dos_val[com_dev] and $1f);
     {set baud rate}
     portw[com_base[com_dev]]:=baud[com_record.dos_val[com_dev] shr 5];
     { Reset Div_Latch_Acc_Bit for Int_Enable_Reg access for xmt/rcv }
     port[com_base[com_dev]+lc_p]:=port[com_base[com_dev]+lc_p] and $7f;
     inline($FB); { reenable interupts }
  end;

procedure read_com_setup(rec_no:integer);
  var cfg_file : file of com_set_rec;
  begin assign(cfg_file,com_cfg_fn); {$I-} reset(cfg_file); {$I+}
        if IOResult=0 then begin
          seek(cfg_file,rec_no); read(cfg_file,com_record); close(cfg_file);
        end;
  end;

procedure set_com(com_dev:com_port; rec_no:integer); { com port # 1 and 2 }
  begin
    read_com_setup(rec_no); write('==> ');
    with c_ptr[com_dev] do
      if install and not active then com_set(com_dev) else write('Can NOT ');
    writeln('Init.COM',ord(com_dev)+1,'  Dev#',rec_no:2,com_record.dev_des[com_dev]:16);
    delay(400);
  end;

begin
  c_ptr[c1].install:=(com_base[c1]=$03F8);    { check if COM port exist }
  c_ptr[c2].install:=(com_base[c2]=$02F8);
  com_rec_init(c1);                           { Set assoc. COM IRQ var's }
  com_rec_init(c2);
  no_irq_restarts:=0; { the no. of times the Tranmiter IRQ was restarted }

  com_record_init;                            { set port DOS setup var's }
  com_set_rec_no:=0;                          { Default Device No. }
  com_cfg_fn:='COMM.CFG';                     { Default Device File Name }
  read_com_setup(0);                          { Check for file defaults  }

  plt_port:=c1;                               { default port assignments }
  plt_rec_cnt:=0;     { for display of No. of 128 byte record left to Spool }

  dig_flag:=false;    { if digitizer connected and and IRQ driver ON }
  dig_bytes:=0;       { number of bytes per frame for the digitizer }
  dig_port:=c2;
end.
