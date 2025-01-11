{$F+,O+}
unit survey83;
interface
uses crt,survey0,basics2;

procedure field_cad;  { Converts Coded Field Book Notes into a LINE File }

implementation

procedure field_cad;

const
  no_markers   = 100;    { max no. of markers KEY WORDS pre-defined in file MARKER.KEY}
  no_ref_lines =  17;    { number of referance lines that can be run at once }
  no_pts_line  =  40;    { max number of points in one multi line }
  mark_prefix  = '.';    { prexfix char. to marker code }
  no_key_lines =  70;    { no. of key lines using words to ref. lines }

type
    line_rec   = record
                   des    : string[11];           { descrip. of line }
                   look   : integer;              { line type number }
                   cnt    : integer;              { no. of pts used in line }
                   arr    : array[1..no_pts_line] of integer; { the pt no.s }
                 end;

    marker_key = record
                   m_code :integer;        { marker code number }
                   k_word :string[5];      { key word string    }
                 end;

    line_key   = record
                   refno      : integer;  { ref. no. }
                   ln_t       : integer;  { line type }
                   start_word : string[6];
                   end_word   : string[7];
                 end;

    dbl_char = string[2];

var
      i,j      : integer;         { general use }
      pt_rec   : point;

      mfn      : string;          { marker file name }
      lfn      : string;          { line output file name }
      m_file   : text;            { marker input file handle }
      l_file   : text;            { line file OUTPUT handle }

      d        : string[20];      { description str to be parsed }
      code     : string[2];       { command code with parameter }
      pt,p1,p2 : integer;         { point range to process }

      last_ln_key : string[7];

      mul_ln   : array[0..no_ref_lines] of line_rec;   { multi line variables }
      mark_arr : array[1..no_markers]   of marker_key; { KEY WORD Markers }
      line_arr : array[1..no_key_lines] of line_key;   { Key word lines }

  function mark_encode:char;   { find matching key words and return Marker Code Char }
    var i:integer;
      begin
        i:=0; mark_encode:=' ';
        repeat inc(i);
          with mark_arr[i] do
            if (pos(k_word,d)>0) and (m_code<>255) then
              begin
                case m_code of
                    0..9:mark_encode:=chr(48+m_code);
                  10..35:mark_encode:=chr(55+m_code);
                    else mark_encode:=' ';
                end{case};
                i:=no_markers; { set exit condition }
              end;
        until (i=no_markers) or (mark_arr[i].m_code=255);
      end;

  function line_encode:dbl_char;   { find matching key words & return Line Ref#:Ltype }
    type str1 = string[1];
    var  i    : integer;

    function hex(n:integer):str1; var c1:str1;
      begin
        case n of 0..9:str(n:1,c1); 10..34:c1:=chr(55+n); else c1:='0'; end{case};
        hex:=c1;
      end;

      begin   line_encode:='  '; last_ln_key:='';

        i:=0;
        repeat inc(i);        { LOOK for ALL END LINE CODES FIRST }
          with line_arr[i] do
            if (pos(end_word,d)>0) and (refno<>255) then
              begin line_encode:=hex(refno)+'9';
                    last_ln_key:=end_word;
                    i:=no_key_lines;    { set exit condition }
              end;
        until (i=no_key_lines) or (line_arr[i].refno=255);

        if last_ln_key='' then
          begin
            i:=0;
            repeat inc(i);
              with line_arr[i] do
                if (pos(start_word,d)>0) and (refno<>255) then
                  begin line_encode:=hex(refno)+hex(ln_t);
                        last_ln_key:=start_word;
                        i:=no_key_lines;  { set exit condition }
                  end;
            until (i=no_key_lines) or (line_arr[i].refno=255);
          end{if};

      end{line_encode};

  function decode(c:char; alt_c:integer):integer;
    begin
      if code[2] in ['0'..'9'] then decode:=ord(code[2])-48
      else if (code[2]>='A') and (code[2]<=c) then decode:=ord(code[2])-55
           else decode:=alt_c;
    end;

  procedure reset_ln(line:integer);
    begin with mul_ln[line] do
      begin cnt:=no_pts_line; repeat arr[cnt]:=0; dec(cnt); until cnt=0; end;
    end;

  procedure do_line(line,lt:integer; dbl_del:boolean);
    begin with mul_ln[line] do
      begin
        inc(cnt); arr[cnt]:=pt;                       { add point to array  }
        if cnt=1 then                                { start of line }
          begin
            look:=decode('D',lt);                    { try to get a look }
            des:=d;                                  { save entire description }
            if (decode('@',99)<99) or dbl_del then   { Do NOT delete letters, might be part of Des. Key}
              delete(d,1,1);
          end
        else if (code[2]='9') or
                ((code[2]=code[1]) and (code[2] in ['=','+','-','*','/','X','Y','O']) ) then
               begin                                 { check END LINE commands }
                 delete(d,1,1);                      { delete END character }
                 writeln(l_file,'1 ',arr[1]:4,arr[2]:5,'0':5,look:5,'1':5,' n','Line: ':13,des);
                 j:=2;
                 while arr[j+1]>0 do          { do 7 command for rest of pts }
                   begin
                     writeln(l_file,'7 ',arr[j]:4,arr[j+1]:5,arr[j+2]:5,arr[j+3]:5,arr[j+4]:5,' n');
                     j:=j+4;
                   end;
                 writeln(l_file);
                 reset_ln(line);
               end
             else { delete repeating looks so they will NOT plot with markers }
               if (decode('@',99)<99) or dbl_del then delete(d,1,1);
        delete(d,1,1)  { delete the line command }
      end;
    end;

  procedure do_marker;
    var
      marker   : integer;             { the decoded marker number }
      m_str    : string;              { line read from marker file }
      pt_str   : string[4];           { point no. for marker insertion }
      flag     : boolean;

    procedure put_marker_ln;
      begin
        str(pt:4,pt_str);             { convert point no. for str insertion }
        while pos('#',m_str)>0 do     { replace # with point no. }
          begin
            insert(pt_str,m_str,pos('#',m_str));
            delete(m_str,pos('#',m_str),1);
          end;
        if pos('+',m_str)>0 then      {   use field des. if summonsed '+' }
          begin                       { if no field des. then use standard }
            while (length(d)>0) and (d[1]=' ') do delete(d,1,1);
            if d<>'' then m_str:=copy(m_str,1,pos('+',m_str)-1)+d
            else delete(m_str,pos('+',m_str),1);
          end;
        writeln(l_file,m_str);
      end;

    begin   { filter marker commands out }
      marker:=decode('Z',9);            { which marker ? }
      reset(m_file);
      repeat                            { find it in marker file }
        readln(m_file,m_str);
        if m_str[1]='3' then dec(marker);
      until (marker<0) or eof(m_file);
      if marker<0 then put_marker_ln;   { write first line }
      flag:=true;
      while not eof(m_file) and flag do
        begin                           { check if more line to make marker }
          readln(m_file,m_str);
          if m_str[1]<>'3' then put_marker_ln else flag:=false;
        end;
      close(m_file);
    end;


(**************   M A I N   F I E L D  C A D   ******************)
  begin
    mode('Field Cad Line File Conversion'); writeln;

    if exist('marker.key') then  (********  GET MARKER KEY WORDS  ********)
      begin
        for i:=1 to no_markers do with mark_arr[i] do   { reset array }
          begin m_code:=255; k_word:=' '; end;
        assign(m_file,'MARKER.KEY'); reset(m_file);
        i:=0;
        while not eof(m_file) do
          begin
            inc(i);
            with mark_arr[i] do
              begin
                readln(m_file,m_code,d);
                while (length(d)>0) and (d[1]=' ') do delete(d,1,1);
                for j:=1 to length(d) do d[j]:=upcase(d[j]);
                if d<>'' then begin k_word:=d; write(d:8); end
                else begin m_code:=255; dec(i); end;
              end;
          end;
        writeln; writeln(i:4,' Marker Key Words');
        close(m_file);
      end else begin cnff('MARKER.KEY'); exit; end;

      writeln;
      if exist('Line.key') then   (*******  GET LINE KEY WORDS  ********)
      begin
        for i:=1 to no_key_lines do with line_arr[i] do   { reset array }
          begin refno:=255; ln_t:=255; start_word:=' '; end_word:=' '; end;
        assign(m_file,'LINE.KEY'); reset(m_file);
        i:=0;
        while not eof(m_file) do
          begin
            inc(i);
            with line_arr[i] do
              begin
                readln(m_file,refno,ln_t,d); d:=d+' ';
                while (length(d)>0) and (d[1]=' ') do delete(d,1,1);
                for j:=1 to length(d) do d[j]:=upcase(d[j]);
                if d<>'' then
                  begin start_word:=copy(d,1,pos(' ',d)-1);
                        delete(d,1,pos(' ',d));

                        while (length(d)>0) and (d[1]=' ') do delete(d,1,1);
                        end_word:=copy(d,1,pos(' ',d)-1);

                        for j:=1 to length(start_word) do
                          if not (start_word[j] in ['A'..'Z']) then start_word[j]:=' ';
                        for j:=1 to length(end_word) do
                          if not (end_word[j] in ['A'..'Z']) then end_word[j]:=' ';

                        write(start_word:8,end_word:8);
                  end
                else begin ln_t:=255; refno:=255; dec(i); end;
              end;
          end;
        writeln; writeln(i:4,' Line Key Words');
        close(m_file);
      end else begin cnff('LINE.KEY'); exit; end;

    writeln;
    path:=''; mfn:=read_fn('marker.ln0',13,8,'Marker Templete',false);

    if exist(mfn) then
      begin
        writeln; writeln;
        path:='';
        lfn:=read_fn(copy(fn,1,pos('.',fn))+'LNZ',13,8,'Output to Line ',false);
        write('----> ':7);
        if lfn='' then begin writeln('NO Field Cad Conversion'); exit; end;
        assign(l_file,lfn);
        if exist(lfn) then begin  writeln('Appending'); append(l_file); end
        else begin writeln('Creating'); rewrite(l_file); end;

        writeln;
        write('Enter Starting PT#=1 ? ');     p1:=1;       input_i(p1);
        write('Ending PT#=':14,no_pts,' ? '); p2:=no_pts;; input_i(p2);
        writeln;
        writeln;
        writeln(l_file);
        writeln(l_file,'99 0 0 0 0 0  FIELD CAD CONVERSION  Pt#s',p1:4,'-',p2:4,'   ',when);

        assign(m_file,mfn);
        for i:=0 to no_ref_lines do reset_ln(i);   { initialize variables }

        if (p1>0) and (p2<=no_pts) and (p1<=p2) then
          for pt:=p1 to p2 do
            begin
              get(pt,pt_rec);

              d:=pt_rec.descrip;
              while (length(d)>0) and (d[1]=' ') do delete(d,1,1);
              for j:=1 to length(d) do d[j]:=upcase(d[j]);
              d:=d+'    ';

              write(^M); clreol; write(pt:4,'  ',d);

              code:=copy(d,1,2);
              case code[1] of { check for line codes }
                 '=','0':do_line(0,0,false);   { solid  }
                 '+','1':do_line(1,1,false);   { dash }
                 '-','2':do_line(2,2,false);   { dash-dash }
                 '*','3':do_line(3,3,false);   { long dashed }
                 '/','4':do_line(4,4,false);   { dotted }
                 'O','5':do_line(5,10,false);  { Stone wall }
                 'X','6':do_line(6,11,false);  { Fence }
                 'Y','7':do_line(7,12,false);  { Stone wall with Fence }
                 else { Look for Line Key Words }
                   begin
                     code:=line_encode;
                     if code<>'  ' then
                       begin
                         d:=code+' '+d;  { space line code from description }
                         if code[1]<='9' then val(code[1],j,i) else j:=ord(code[1])-55;
                         do_line(j,0,true);
                         delete(d,1,1);
                         delete(d,pos(last_ln_key,d),length(last_ln_key));
                       end;
                   end;
              end{case};

              j:=pos(mark_prefix,d);

              if j in [1..4] then
                begin code:=copy(d,j,2); delete(d,1,j+1); end;

              if (j in [1..4]) and (decode('Z',99)<99) then do_marker
              else
                begin code:=mark_prefix+mark_encode;
                      if code[2]<>' ' then do_marker;
                end;

          end{for pt};

        writeln(l_file,'99 0 0 0 0 0  END FIELD CAD  Pt#s',p1:4,'-',p2:4);
        close(l_file);

      end else cnff(mfn);

  end{field cad};


end.
