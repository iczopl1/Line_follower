# linefollowapk

Aplikacja do sterowania robotem typu linefollow

## dodanie .gitignore

## Wymagania
1.aplikacja łączy się za pomocą WiFI 
2.Korzystamy z protokołu UDP do przesyłania danych 
3.kod komunikacji jest w comunication.cpp jest to większość komunikacji ze strony robota
4. dodatkowo mamy komunikaty z robota typu
`  if (now - lastMillis >= interval) { 
    lastMillis = now;
    String pos = "Position: " + String(position);
    com_send(pos.c_str());
    com_send("!");
    
    request_sensorsRaw();
  }
` jest to wyciągniety kod z robota 
5.aplikacja ma być tylko na telefon android 
6.aplikacja ma zapisywać ustawienia 
7.gdy nagłe rozłączenie z robotem ma pujść próba ponownej komunikacji 3 requesty gdy nie uda się uzyskać odpowiedzi ma wyskoczyć powiadomienie o zerwanej komunikacji 
8.gdy tylko robot od nowa się połączy ma zostać sprawdzone czy nie uleg on ponownemu uruchomieniu utracił zapisane wartości jak uległ restartowi odpowiedni komunikat 
9.mam mieć minimum 9 przycisków do sterowania robotem typu Start_comunication, Stop_comunication, Start_calibration, Start_Robot,Stop_robot,Reset_Robot,Send_pparams,Request_params,Reset_app

10. mam mieć 7 pół wprowadzania minimum Kp,Ki,Kd,Max,Base,Turn,Lost_th
11,aplikacja ma mieć miejsce w pamięci na 5 zapisów wartości z pól wprowadzania po to by szybko przełączać się międz ustawieniami robota fajnie gdyby każdy config miał przycis by na niego się przełączyć
12.wizualizacja odczytanych wartości z czujników jest to robot który ma albo 8 albo 16 czujników koloru i chce by były te czujniki i w zależności czy wykrywają linie czy nie odpowiednio się zapalały powyżej nich chce mieć podgląd na raw wartości otrzymane od robota
13. Przesyłanie wiekszej ilości wartości do debagowania na przyszłość jak powysze podpunkty działają bez problemów bo na razie nie chce zmieniać kodu robota 
myśle nad przesyłaniem td,error,wyników pid (wejście ,wyjście),ustawień mocy silników

