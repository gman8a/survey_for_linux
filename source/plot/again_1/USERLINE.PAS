(*
Line#   LineType   Double split size
=====   ========   =================
15        0-9          .05 inches


Type 1 (regular)
===================================
 no_pen_segments   Pen_down  Pen_up

ex.

15 1    0    2  0.5  0.25


Type 2 (Boxed)
===============
no_pen_segments before box, segments, boxed letters
ex.

16 2    0    3  0.5 0.25 0.25  seg_repeat_cnt Letter_Size, Sewer


Type 3 (marker with single letter)

ex.

17 3    0    3  0.5 0.25 0.25    Marker_size, M#, Letter


Type 4 (regular line box )

ex.
L# Type   Dbl  L#
17 4      0    4     Letter_size, Letters
*)

procedure read_user_line_types;
  var f : text;
      i : integer;
  begin
    assign(f,'userline.dat');
    if exist('userline.dat') then
      begin
        reset(f);
        repeat
          inc(user_line_type_cnt);
          fillchar(user_line_types[user_line_type_cnt],
                   sizeof(user_line_types[user_line_type_cnt]),^@);
          with user_line_types[user_line_type_cnt] do
            begin
              read(f,line_no,line_type,double_split);
              if line_type in [1,2,3] then
                begin
                  read(f,no_pen_seg);
                  for i:=1 to no_pen_seg do read(f,pen_segments[i]);
                end;
              case line_type of
                1:readln(f);
                2:readln(f,letter_size,box_str);
                3:readln(f,marker_size,marker_no,box_str);
                4:readln(f,natural_line,letter_size,box_str);
              end{case};
              box_str:=parse(box_str,1,';');
            end;
        until eof(f);
        close(f);
      end;
  end;
