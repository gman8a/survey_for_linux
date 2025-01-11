unit survey92;
interface

{$I Direct}   { Compiler directives }

uses crt,dos,basics2,survey0;

{$IFDEF acad_script} procedure lnj; {$ENDIF}

implementation

{$IFDEF acad_script}
PROCEDURE LNJ;

 var   {  PTF : file  of point ;
         apf : file of alt_pt;}
         COUNT,n,CNTER    :integer;
         nn   :integer;
         pt_rec    :point;
     {    apt   :altpt;    }
         op :   string[85];
         inp:   string[85];
         EXT,SCR:   STRING[3];
         lnf     :string[40];
         any_str : string;
         CHR: CHAR;
         scale:real;
         outf:  TEXT;
         LN: TEXT;
         NOTES: TEXT;
         Q,T:CHAR;
         A : INTEGER;
         B : INTEGER;
         C : INTEGER;
         D,SET_MRK : INTEGER;
         LSTE,E : INTEGER;
         LSTD,F,G,H,I,J,K : INTEGER;
         wdth : integer;
         CN: REAL;
         CE:REAL;
         SN:REAL;
         SE:REAL;
         EN:REAL;
         EE:REAL;
         LIT1,big:string[255];
         lit:STRING[2];
         LAB:STRING[20];
         newlay,Z:INTEGER;
         X:CHAR;
         done:BOOLEAN;
         fn9 : string;
         lit2: string[1];
         lnt  : integer;
         didit :boolean;

 procedure pntf;
       var
       {   ptf:file of point;}
          pt_rec:point;


procedure cnglay;
        begin
          writeln(outf,'layer');
          writeln(outf,'set');
          writeln(outf,newlay);
          writeln(outf,'');
        end;

 procedure pt_lab;
     BEGIN
        newlay:=12;
        cnglay;
        j:=1;
        WHILE j< no_pts do
        begin
             write(^M,j:5);
             k:=j;
             get(k,pt_rec);
             didit:=false;
   repeat
     lnt:=length(pt_rec.descrip);
     lit2:=copy(pt_rec.descrip,1,1);
     if lit2=' ' then  begin
     delete(pt_rec.descrip,1,1);
       end
     else didit:=true;
     until didit;




             writeln(outf,'INSERT');
              WRITELN(OUTF,'PTL');
              WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
              WRITELN(OUTF,SCALE:3:2);
              WRITELN(OUTF,SCALE:3:2);
              WRITE(OUTF,'0 ');
         WRITELN(OUTF,PT_REC.DESCRIP);
         WRITELN(OUTF,PT_REC.ELEV:3:2);
          Writeln(outf,K:1);
         j:=j+1;
        END;
      END;





 PROCEDURE DRAW_MARK;
 BEGIN
       newlay:=12;
       cnglay;
          get(F,pt_rec);
          WRITELN(OUTF,'INSERT');
          CASE SET_MRK OF                                 {case e}
             0: WRITELN(OUTF,'DRAW\CRSHR');
             1: WRITELN(OUTF,'DRAW\X');
             2: WRITELN(OUTF,'DRAW\SQ');
             3: WRITELN(OUTF,'DRAW\OCT');
             4: WRITELN(OUTF,'DRAW\TRI');
             5: WRITELN(OUTF,'DRAW\DBLTRI');
             6: WRITELN(OUTF,'DRAW\CIRCLE');
             7: WRITELN(OUTF,'DRAW\NRTH');
             8: WRITELN(OUTF,'DRAW\NRTH');
             9: WRITELN(OUTF,'DRAW\NMRK');
             10: WRITELN(OUTF,'DRAW\UP');
             11: WRITELN(OUTF,'DRAW\TREED');
             12: WRITELN(OUTF,'DRAW\EVER');
             13: WRITELN(OUTF,'DRAW\HEAPST');
             14: WRITELN(OUTF,'DRAW\FP');
           END;                                          {end case e}
              WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
              WRITELN(OUTF,SCALE:3:2);
              WRITELN(OUTF,SCALE:3:2);
              WRITE(OUTF,'0');
         Writeln(outf,' ');


 END;                           {PROCEDURE DRAW_MARK}





PROCEDURE TRAVST;
          BEGIN
             IF E=10 THEN
            WRITELN(OUTF,'(LOAD "STW ")(ST)');
             n:=b;
               WHILE N<=C-1 DO BEGIN
                 get(n,pt_rec);
                 CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                 get(n+1,pt_rec);
                 SE:=pt_rec.EAST;SN:=pt_rec.NORTH;
               {  IF ((SQRT(SQR(SE-CE)+SQR(SN-CN)))>12) OR (E<>10) THEN BEGIN}
                    IF (COUNT = 1)and(e<>11) THEN BEGIN
                      WRITELN(OUTF,CE:6:4,',',CN:6:4);
                      writeLN(OUTF,SE:6:4,',',SN:6:4);
                     END;
                     IF (COUNT=1)and(e=11) THEN  BEGIN
                         WRITELN(OUTF,CE:6:4,',',CN:6:4);
                         writeLN(OUTF,SE:6:4,',',SN:6:4);
                     END;
                       IF COUNT >1 THEN
                         writeLN(OUTF,SE:6:4,',',SN:6:4);
                       COUNT:=COUNT+1;
                {  END;  }
                    n:=N+1;
                 END;

                                      END;

PROCEDURE TRAVST1;
                         BEGIN
                                IF E=10 THEN
                                 WRITELN(OUTF,'(LOAD "STW ")(ST)');
                                 n:=b;
                                 WHILE N>=c+1 do BEGIN
                                 get(n,pt_rec);
                                  CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                                   get(n-1,pt_rec);

                                  SE:=pt_rec.EAST;SN:=pt_rec.NORTH;

                             {   IF ((SQRT(SQR(SE-CE)+SQR(SN-CN)))>12) OR (E<>(10)OR(11))  THEN BEGIN}
                                        IF COUNT = 1 THEN BEGIN

                                            WRITELN(OUTF,CE:6:4,',',CN:6:4);
                                            writeLN(OUTF,SE:6:4,',',SN:6:4);
                                           END;
                                                  IF COUNT >1 THEN
                                         writeLN(OUTF,SE:6:4,',',SN:6:4);
                                         COUNT:=COUNT+1;
                                     { END;}
                                    n:=N-1;
                                      END;

              END;








PROCEDURE STONE;




   BEGIN                              {procedure stone}

               CASE E OF
               10:BEGIN
                   newlay:=e;
                   cnglay;

                       CASE A OF
                          0,1:BEGIN
                        get(b,pt_rec);
                          CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                           get(c,pt_rec);
                          SE:=pt_rec.EAST;SN:=pt_rec.NORTH;
                          {  IF (SQRT(SQR(SE-CE)+SQR(SN-CN)))>12 THEN BEGIN}
                            WRITELN(OUTF,'(LOAD "STW ")(ST)');
                              WRITELN(OUTF,CE:6:4,',',CN:6:4);
                              writeLN(OUTF,SE:6:4,',',SN:6:4);
                             {END;}

                         END;
                     4,5:BEGIN

                                 COUNT:=1;
                              if C>B then  BEGIN

                              travst; END
                             else if B>C then BEGIN
                               travst1;   END;
  END;                                  END;
                                 write(OUTF,' ');




                       END;
                    11:BEGIN
                        newlay:=e;
                        cnglay;
                      WRITELN(OUTF,'(LOAD "BW")','(BW)');
                   CASE A OF
                 0,1:BEGIN
                    get(b,pt_rec);
                     WRITE(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                      get(c,pt_rec);
                    write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                    END;
                4,5:BEGIN
                                 COUNT:=1;
                              if C>B then  BEGIN
                              travst; END
                             else if B>C then BEGIN
                               travst1;   END;

                    END;
                   END;     {  write(OUTF,' ');  }
                   write(OUTF,' ');

                   END;
     END;
              CASE A OF
                         6,7:
                         BEGIN

                       CASE LSTE OF
                       10:   BEGIN
                             WRITELN(OUTF,'(LOAD "STW ")(ST)');
                               get(b,pt_rec);

                              CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                              write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                                 get(c,pt_rec);
                              SE:=pt_rec.EAST;SN:=pt_rec.NORTH;
                           {    IF  (SQRT(SQR(SE-CE)+SQR(SN-CN)))>12 THEN }
                                write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                               {ELSE WRITELN (OUTF,'');}
                                IF D>0 THEN BEGIN
                                  get(d,pt_rec);
                                  CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                                 {   IF  (SQRT(SQR(SE-CE)+SQR(SN-CN)))>12 THEN }
                                      write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                                        {ELSE WRITELN (OUTF,'');}
                                      END;
                                        IF E>0 THEN BEGIN
                                       get(e,pt_rec);
                                   SE:=pt_rec.EAST;SN:=pt_rec.NORTH;
                                       { IF  (SQRT(SQR(SE-CE)+SQR(SN-CN)))>12 THEN }
                                      write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                                          {ELSE WRITELN( OUTF,'');}
                                       END;
                                      IF F>0 THEN BEGIN
                                      get(f,pt_rec);
                                      CE:=pt_rec.EAST;CN:=pt_rec.NORTH;
                                      {  IF  (SQRT(SQR(SE-CE)+SQR(SN-CN)))>12 THEN }
                                         write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                                         {ELSE WRITELN( OUTF,'');}
                                       END;
                  {            write(OUTF,' ');    }

                          write(OUTF,' ');
                      END;
                11:BEGIN
                      WRITELN(OUTF,'(LOAD "BW ")(BW)');

                    get(b,pt_rec);
                  write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                    get(c,pt_rec);
                 write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                 IF D>0 THEN BEGIN
                  get(d,pt_rec);
                 write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
                 END;
                 IF E>0 THEN BEGIN

                     get(e,pt_rec);
               write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
               END;
               IF F>0 THEN BEGIN
                  get(f,pt_rec);
               write(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4,' ');
               END;

         {                 write(OUTF,' '); }
                writeLN(OUTF,'');
            END;
     END;
                     END;
     END;
   end;
  pROCEDURE GO;
    VAR
     SC:INTEGER;
  begin

{           assign(PTF,inp);}
{$I-}   (*  reset(PTF){$I+};*)


    READLN(LN,A,B,C,D,E,F,G,H,I,J);
    SC:=B;
    SCALE:=SC/100;
    SET_MRK:=1;
    WRITELN(OUTF,'(LOAD"SETLT")');
    WRITELN(OUTF,'(SETLT)');
    WRITELN(OUTF,SC);
    nn:=0;
    CNTER:=1;
    IF G=1 THEN  PT_LAB;
  while not eof(LN) do
  begin                                              {while NOT EOF}
     {$I-} readln(LN,A,B,C,D,E,F,LAB); {$I+}
     if ioresult<>0 then
       begin readln(ln); writeln(' File Read Error Ignored'); a:=99; end;
     didit:=false;
   repeat
     lnt:=length(lab);
     lit2:=copy(lab,1,1);
     if lit2=' ' then  begin
     delete(lab,1,1);
  end
     else didit:=true;
     until didit;


     WRITE(^M,CNTER:5);
     CNTER:=CNTER+1;
     CASE A OF                                           {case}
        0,1:BEGIN                                        {begin 0,1 line}
           LSTE:=E;
           LSTD:=D;
           CASE D OF
             1:BEGIN F:=B; DRAW_MARK; END;
             2:BEGIN F:=C; DRAW_MARK; END;
             3:BEGIN F:=B; DRAW_MARK; F:=C; DRAW_MARK; END;

            END;
           CASE E OF                                        {case e}
              0,
              1,
              2,
              3,
              4,
              5,
              6,
              7,
              8,13: BEGIN                   {linetype 0-8}
                   newlay:=e;
                   cnglay;
                   IF E=13 THEN BEGIN
                    WRITELN(OUTF,'(LOAD"DBLN")(DB)');
                    WRITELN(OUTF,WDTH);
                    END
                   else
                   WRITELN(OUTF,'LINE');
                   get(b,pt_rec);
                   WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                   get(c,pt_rec);
                   WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                   WRITELN(OUTF,'');
                  END;                                     {end linetype 0-8}
             10,11:STONE;
            END;                                           {end case e}
            END;                                          {end line o,1}
        2:BEGIN                                         {arc}
              WRITELN(OUTF,'ARC');
              WRITELN(OUTF,'C');
                   get(d,pt_rec);
              WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                   get(c,pt_rec);
              WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                      get(b,pt_rec);
              WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);

           END;                                            {end arc}

        3:BEGIN                                            {markers}
           newlay:=12;
           cnglay;
            IF B=0 THEN
                     SET_MRK:=E
            ELSE BEGIN

                     get(b,pt_rec);
                 WRITELN(OUTF,'INSERT');
                 CASE E OF                                 {case e}
                   0: WRITELN(OUTF,'DRAW\CRSHR');
                   1: WRITELN(OUTF,'DRAW\X');
                   2: WRITELN(OUTF,'DRAW\SQ');
                   3: WRITELN(OUTF,'DRAW\OCT');
                   4: WRITELN(OUTF,'DRAW\TRI');
                   5: WRITELN(OUTF,'DRAW\DBLTRI');
                   6: WRITELN(OUTF,'DRAW\CIRCLE');
                   7: WRITELN(OUTF,'DRAW\NRTH');
                   8: WRITELN(OUTF,'DRAW\NRTH');
                   9: WRITELN(OUTF,'DRAW\NMRK');
                  10: WRITELN(OUTF,'DRAW\UP');
                   11: WRITELN(OUTF,'DRAW\TREED');
                   12: WRITELN(OUTF,'DRAW\EVER');
                   13: WRITELN(OUTF,'DRAW\HEAPST');
                   14: WRITELN(OUTF,'DRAW\FP');
                 END;                                          {end case e}
               WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
               WRITELN(OUTF,SCALE:3:2);
               WRITELN(OUTF,SCALE:3:2);
               WRITE(OUTF,C);
               Writeln(outf,' ');
               WRITELN(OUTF,'INSERT');
               WRITELN(OUTF,'DRAW\NMRK');
               WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
               WRITELN(OUTF,SCALE:3:2);
               WRITELN(OUTF,SCALE:3:2);
               WRITE(OUTF,C);
               if lab='' then
                writeLN(outf,' ')
               ELSE WRITELN(OUTF,' ',LAB);
             END;                              {IF B=0}
          END;                                {end markers}

        4,5,10:BEGIN                             {begin trav line}
                 CASE D OF
                 1:BEGIN F:=B; DRAW_MARK; END;
                 2:BEGIN F:=C; DRAW_MARK; END;
                 3:BEGIN
                   IF C<B THEN BEGIN
                       F:=C; K:=B;   END
                   ELSE BEGIN F:=B; K:=C; END;
                    while F<>K do  BEGIN   DRAW_MARK;   F:=F+1;  END;
                  END;
                  END;
                 LSTD:=D;
                 LSTE:=E;   COUNT:=1;
                 CASE E OF                             {case e}
                   0,
                   1,
                   2,
                   3,
                   4,
                   5,
                   6,
                   7,
                   8,13: BEGIN                   {begin linetype 0-8}
                         newlay:=e;
                         cnglay;
                          IF E=13 THEN BEGIN
                    WRITELN(OUTF,'(LOAD"DBLN")(DB)');
                    WRITELN(OUTF,WDTH);
                    END  else
                          IF A=10 THEN WRITELN(OUTF,'PLINE')
                         ELSE WRITELN(OUTF,'LINE');
                         if C>B then  BEGIN
                             travst;  END
                         else if B>C then BEGIN
                             travst1;   END;
                         WRITELN(OUTF,'');
                       END;                   {end linetype 0-8}
                   10,
                   11:STONE;
                    END;                                                     {case e}
                  END;                                                 {trav line}
          8,9:begin                                {begin words}
               LIT:='**';
               REPEAT readln (ln,big);
                  z:=length (big);
                  if z>1 THEN lit:=copy(big,Z-1,2) ;
                  LIT1 :=COPY(BIG,1,Z-2);
                  IF pos('//',LIT)=0 THEN  WRITELN(NOTES,BIG)
                  ELSE WRITELN(NOTES,LIT1);
               until pos('//',lit)>0;
               WRITELN(NOTES,'');
               WRITELN(NOTES,'');
              end;                                     {end words}
          86:repeat readln(ln,big); while big[1]=' ' do delete(big,1,1);
             until (pos('87',copy(big,1,4))>0)  or eof(ln);
        6,7:BEGIN                                              {multi}
               if lstd=3 then begin
                  if a<>0 then begin f:=a; draw_mark; end;
                  if b<>0 then begin f:=b; draw_mark; end;
                  if c<>0 then begin f:=c; draw_mark; end;
                  if d<>0 then begin f:=d; draw_mark; end;
                  if f<>0 then begin f:=e; draw_mark; end;
                end;

               IF LSTE=11 THEN STONE
               ELSE IF LSTE=10 THEN STONE
               ELSE BEGIN
                 get(b,pt_rec);
                   IF LSTE=13 THEN BEGIN
                    WRITELN(OUTF,'(LOAD"DBLN")(DB)');
                    WRITELN(OUTF,WDTH);
                    END  ELSE
                 WRITELN(OUTF,'LINE');
                 WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                 get(c,pt_rec);
                 WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                 IF D>0 THEN BEGIN
                 get(d,pt_rec);                    {if}
                 WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
                END;                                             {end if}
               IF E>0 THEN BEGIN                                 {if}
                get(e,pt_rec);
                WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
               END;                                           {end if}
               IF F>0 THEN BEGIN                               {if}
                get(f,pt_rec);
                WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
               END;                                               {end if}
               WRITELN(OUTF,'');
          END;
         END;                          {muti line}
     20:BEGIN                                              {multi}
           done:=false;
           WRITELN(OUTF,'PLINE');
          repeat
           if b or c or d or f or e =-1 then done:=true;
           if b>0 then begin
             get(b,pt_rec);
             WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
           end;
           if c>0 then begin
             get(c,pt_rec);
             WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
           end;
           IF D>0 THEN BEGIN
             get(c,pt_rec);                       {if}
             WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
           END;                                             {end if}
           IF E>0 THEN BEGIN                                 {if}
             get(e,pt_rec);
             WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
           END;                                           {end if}
           IF F>0 THEN BEGIN                               {if}
             get(f,pt_rec);
             WRITELN(OUTF,pt_rec.EAST:6:4,',',pt_rec.NORTH:6:4);
           END;                                               {end if}
           if not done then
           readln(LN,A,B,C,D,E,F,LAB);
          until done;
          WRITELN(OUTF,'');
        END;                          {muti line}
      16:      IF B=-1 THEN WDTH:=C;

     END;                      {case a}
   END;        {while not eof}
   close(outf);
   CLOSE (LN);
   CLOSE(NOTES);
 end;  {go procedure}
BEGIN                             {MAIN LINE PNTF}
   GO;
END;

begin
     n:=0;                            {main program}

     any_str:=get_dir(fn3+'?',false);
     writeln;
     write('LAST CHARACTER OF LINE FILE:',FN3);
     QUEST(0,0,' ? ',[' ','0'..'9','A'..'Z','a'..'z'],false); writeln;
     WRITELN; WRITELN; CLREOS;    WRITELN(FN3+RESPONSE);

     IF EXIST(FN3+RESPONSE) THEN
     BEGIN
       ASSIGN(LN,FN3+RESPONSE); {$I-} reset(LN){$I+};

       if ioresult<>0 then
       writeln(FN3+RESPONSE,'DOES NOT EXIST')
       ELSE
         begin
           ASSIGN(NOTES,'NOTES.LNF'); REWRITE(NOTES);
           fn9:=copy(fn,1,pos('.',fn))+'SCR'; assign(outf,fn9); REWRITE(OUTF);
           pntf;
         end;

     END;
end{autocad script};
{$ENDIF}

end.