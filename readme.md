# LINE FOLLOWER TO RULE THEM ALL
Wielkie dzienki za udostępnienie i stworzenie pierwotnej wersi Filipowi Skawińskiemu


## HOW TO

Aplikację zaimportować do MIT APP Inventor, skompilować i zainstalować na telefonie.
Ewentualnie zainstalować .apk z repo.

Po podłączeniu do AP robota albo robota do sieci WiFi kliknąć Start na górze aplikacji. Jeżeli robot działa to przycisk zmieni kolor na zielony.
Robota należy skalibrować co trwa parenaście sekund a potem już można się bawić.

## Parametry

- Kp: Wartość proporcji regulatora PID,
- Ki: Wartość całki (nie dużo daje, wartość bardzo mała np. 0.001)
- Kd: Wartość pochodnej. Należy pamiętać, że Kd > Kp. Różne są metody ale u mnie działa np 2*Kp, 7*Kp.
- BaseSpeed: szybkość skręcania robota podczas działanie algorytmu PID.
- MaxSpeed: prędkość gdy robot jedzie w prostej linii
- TurnSpeed: prędkość gdy robot wyjedzie za linie i próbuje wrócić

## Schemat podłączeń

<img alt="Schemat" src="Schemat.png">

## BOM

<table>
  <tr>
    <td>ESP32-S3</td>
  </tr>
  <tr>
    <td>Silniki N20 1000-2000RPM 6V</td>
  </tr>
  <tr>
    <td>Listwa czujników IR</td>
  </tr>
  <tr>
    <td>Regulator napięcia</td>
  </tr>
  <tr>
    <td>Płytka prototypowa</td>
  </tr>
  <tr>
    <td>LiPo 2S 7.4V</td>
  </tr>
  <tr>
    <td>Headery i sockety</td>
  </tr>
  <tr>
    <td>Kabelki</td>
  </tr>
  <tr>
    <td>Koła</td>
  </tr>
</table>

