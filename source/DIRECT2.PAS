(***  This file should be reviewed for type of PC-TS compilization desired.  ***)

{$DEFINE back_ground_spool}    { keyin3 with call fill_obuff, Keyin all ready does }
{$UNDEF  small_edit}          { about a 16,200 byte edit file size }

{$UNDEF  legal_descrip}       { include legal description dig link }
{$DEFINE  make_line}           { make a line file with digitizer or but commands }
{$unDEF  DXF}                 { ACAD DXF drawing format point & ID output}
{$DEFINE  SDR2}                { SDR2 data transform and point file conversion }

{$unDEf  demo}                { demo version upto 100 points max .}
{$unDEF  key_file}            { check if PC-TS.SYS file in root dir & hidden }
{$UNDEF  chk_dsk}             { check if track 40 head 1 sector 32 exist }

{$unDEF  acad_script}         { LNJ ACAD script line files drawing by Joe Rieng }
{$UNDEF  vert_profile}        { Verticle Profile, Verticle Curve   by Joe Rieng }
{$DEFINE  contour}             { Semi Automated Contouring with dig by Joe Rieng }


(*
{$DEFINE back_ground_spool}   { keyin3 with call fill_obuff }
{$DEFINE small_edit}          { about a 16,200 byte edit file size }

{$UNDEF  legal_descrip}       { include legal description dig link }
{$UNDEF  make_line}           { make a line file with digitizer or but commands }
{$UNDEF  DXF}                 { ACAD DXF drawing format point & ID output}
{$UNDEF  SDR2}                { SDR2 data transform and point file conversion }

{$UNDEF  demo}                { demo version upto 100 points max .}
{$UNDEF  key_file}            { check if PC-TS.SYS file in root dir & hidden }
{$UNDEF  chk_dsk}             { check if track 40 head 1 sector 32 exist }

{$UNDEF  acad_script}         { LNJ ACAD script line files drawing by Joe Rieng }
{$UNDEF  vert_profile}        { Verticle Profile, Verticle Curve   by Joe Rieng }
{$UNDEF  contour}             { Semi Automated Contouring with dig by Joe Rieng }
*)