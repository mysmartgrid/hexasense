set object 1 polygon from 16,75 to 17,85 to 21,80 to 25,60 to 27,30 to 26,20 to 20,20 to 17,35 to 16,75
set object 1 fc rgb "#888888" fillstyle solid 1.0 border lt -1
set object 2 polygon from 17,75 to 21,65 to 22,35 to 19,35 to 17,75
set object 2 fc rgb "#555555" fillstyle solid 1.0 border lt -1
set title "Raumbehaglichkeitsdiagramm nach Leusden und Freymark (1951)"
set label 1 "GUT" at 19,50 centre norotate front nopoint offset character 0, 0, 0 
set label 2 "TROCKEN" at 21,25 centre norotate front nopoint offset character 0, 0, 0 
set label 3 "WARM" at 23,45 centre norotate front nopoint offset character 0, 0, 0
set label 4 "LÜFTEN" at 19,75 centre norotate front nopoint offset character 0, 0, 0
set label 5 "KALT" at 17,50 centre norotate front nopoint offset character 0, 0, 0 
set xrange [14:30];  
set yrange[10:90];
set xlabel "Temperatur [°C]"  
set ylabel "Luftfeuchte [%r.h.]"
plot -8*x + 211 title "gc_minor" linecolor rgb "green", 15*x -250 title "gc_major" linecolor rgb "red"