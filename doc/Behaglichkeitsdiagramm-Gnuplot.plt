set object 1 polygon from 17,30 to 20,20 to 26,20 to 27,30 to 21,80 to 17,80 to 16,70 to 17,30
set object 1 fc rgb "#ffd700" fillstyle solid 1.0 border lt -1
set object 2 polygon from 19,30 to 22,30 to 21,60 to 17,70 to 19,30
set object 2 fc rgb "#00cd00" fillstyle solid 1.0 border lt -1
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
plot -8*x + 206 title "gc_minor" linecolor rgb "green", -30*x + 690 title "gc_major" linecolor rgb "red"