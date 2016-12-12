# # Kodskelett för Hackathon IoT 
Kodskelett och instruktioner för grupptävling
med IoT-tema hos Dewire Consultants AB.

## Uppgiften
Uppgiften går ut på att bygga en uppkopplad enhet som med hjälp av olika sensorer kan användas som ett slags tangentbord. Med er lösning behöver ni klara av att skriva gemener [a-z] och mellanrumstecken. Se [Tävlingssystemet](#Tävlingssystemet) för fler detaljer.

## Material
Ni kommer att ha tillgång till följande material:
* Feather Huzzah som grundplatform vilket är en enhet som bygger på kretsen ESP8266 och är en microkontroller kombinerat med ett WiFi-chip. 
* Ett batteri för att kunna göra enheten självständig under tävligsmomentet.
* 64x48 OLED-skärm för att visa information från enheten när den går på batteri.
* En mängd av olika sensorer för att bygga själva "tangenterna" till erat tangentbord.

Microkontrollern kommer förinstallerad med  NodeMCU, en firmware för ESP8266, och ett gäng olika moduler t.ex. i2c, gpio, pwm etc. För att programmera enheten använder ni baudrate 115200 och vi rekommenderar IDEn ESPlorer.

####Begränsningar
Det finns inga beränsningar förutom att enheten är självständig (ej kopplad till en dator) under tävlingsmomentet.

####Länkar

Specifikation för Feather Huzzah:
https://learn.adafruit.com/adafruit-feather-huzzah-esp8266/overview

Här finns instruktioner för hur man flashar om enheten:
https://nodemcu.readthedocs.io/en/master/en/flash/

Dokumentation till NodeMCU och dess moduler:
http://nodemcu.readthedocs.io/

Lua: https://www.tutorialspoint.com/lua/

ESPlorer: https://esp8266.ru/esplorer/

Installationsguide: https://www.youtube.com/watch?v=-a2-p0GKIdw

#### Kodskelettet
Kodskelettet är utvecklat för NodeMCU v. 1.5.4.1 och kräver modulerna mqtt, wifi, net, i2c, u8g, node och timer.
Det är fritt att modifiera kodskelettet.
- `init.lua` körs atomatisk vid uppstart och ger er 5 sekunder innan main.lua körs. Den här tidan kan ni använda för att ostört kunna ladda up eller radera filer på enheten.
- `main.lua` är filen där ni kommer att implementera er lösning.
- `dewireContestConnection.lua` används för att upprätthålla anslutning till wifi och tävlingsservern.

## Tävlingssystemet
På sidan http://hackathon.sundsvall.dewire.com kan man finna tävlingssystemet. Här kan man se alla
anslutna deltagare och se hur tävlingen presenteras och fungerar. Tryck `Enter` för att 
starta tidtagning och `Esc` för att nollställa. 

#### Anslutning till tävlingssystemet
När enheten startats så anropas main.lua. Detta är mer eller mindre där
all kod som definierar programmet utgår ifrån i någon form. Notera att main.lua
innehåller en rad där ni måste byta ut standard-gruppnamnet mot erat eget gruppnamn.

Ändra
```
local groupName = "noname"
```
till erat gruppnamn, exempelvis:
```
local groupName = "NinjaBears";
```

Efter uppstart kommer appen därefter använda modulen DewireContestConnection för att ansluta 
till tävlingssystemet, och under tävlingen ska DCC-funktionen
```
dcc.send(string)
```
användas för att ladda upp sin skrivna textsträng med. Detta skall göras upprepat under tiden 
man varje gång en ny bokstav tillkommer eller tas bort, dock åtminstone när man skrivit klart, 
annars registreras inte tiden. För att förtydliga, hela din textsträng ska skickas in, rätt eller 
fel oavsett. Kalla ej på denna funktion överdrivet eller onödigt mycket, då det skapar onödig trafik
till tävlingssystemet.

För att skriva ut text på OLED-skärmen kan ni använda DCC-funktionen
```
dcc.printToLED(string, string)
```
som tar två textsträngar. Tänk på vilken information ni vill kunna se under tävligen då ni har kopplat ifrån enheten från datorn!

Kom ihåg att om send(string) används innan tävlingen startat så kan andra deltagare se hur snabbt ni skriver!

Vid problem, prata med någon från Dewire.

## Övrig info

* På t.ex. Ubuntu kan du behöva lägga till din användare i gruppen dialout för att få rättigheter til USB-enheter:
`sudo usermod -a -G dialout <din användare>`
Logga sedan ut och in användaren.
* Tävlingen kommer att genomföras på batteri. Det är ett 1-cells-lipo. Eran krets kommer alltså inte upp i de 5 volt som en del saker kräver.
* Kretsen har endast en analog ingång. Och den jobbar i spannet 0-1V. Oftast är i2c och SPI ett bättre alternativ när det gäller sensorer.
* Batteriet laddas när usb-kabeln är ikopplad. Se till att batteriet och kabeln är i under utvecklingen så batteriet inte är tomt vid tävlingen.
* Logicnivån för kretsen är 3.3V. Prova inte att köra 5V. Måste en verkligen så finns det logic-level-konverters.
* Det finns två LEDs på Feather Huzzah som går att kontrollera.
* Undvik busy wait då det kommer göra enheten okontaktbar.
* Ni kanske måste byta accesspunkt inför tävlingsmomentet!
