# Device checks

The simulator has no AirPods, no lock screen and no Premium voice, so do
these checks on the iPad Pro 13-inch with the TestFlight build. Tick each
box when it works. Write what is wrong next to a box that fails.

## AirPods and lock screen

Put the AirPods in your ears and open the table.

- [ ] Press play on the AirPods. Vorlesen starts, and music from another app stops.
- [ ] Press pause on the AirPods. The voice stops at once.
- [ ] Wait 10 seconds after the pause, then press play again. Vorlesen starts again in Kursanzeige, and not the music app.
- [ ] Double-press the AirPods (next track). The cursor goes to the next row, and the voice reads it.
- [ ] Triple-press the AirPods (previous track). The cursor goes back, and the voice reads the row.
- [ ] Start Vorlesen and lock the iPad. The voice reads on to the end of the list.
- [ ] On the lock screen, the name of the instrument and the group show, e.g. „Nestlé“ and „Schweiz“.
- [ ] The play, pause, next and previous buttons on the lock screen do the same as on the AirPods.
- [ ] Open a chart. The AirPods next track shows and reads the next chart.
- [ ] Open the settings. The AirPods buttons do nothing.
- [ ] Take the AirPods out during Vorlesen. The voice stops and does not go on with the iPad speaker.
- [ ] A phone call or Siri during Vorlesen stops the voice. After it, the voice does not start alone.
- [ ] After Vorlesen ends, music from another app can play again.

## VoiceOver

Turn VoiceOver on: Settings › Accessibility › VoiceOver.

- [ ] Each bottom button reads its name and its hint, e.g. „Nächste … Wählt die nächste Zeile und liest sie vor.“
- [ ] The status line reads as one element, e.g. „Nestlé ausgewählt“.
- [ ] Double-tap Nächste. VoiceOver reads the new row once. The voice of the app is silent, so two voices never speak together.
- [ ] Double-tap Nächste on the last row. VoiceOver says „Ende der Liste.“
- [ ] Double-tap a group button, e.g. „USA“. VoiceOver says the group and the cursor row.
- [ ] Double-tap Vorlesen. The voice of the app reads, and VoiceOver does not read the rows too.
- [ ] A table row reads the name and the values, and the hint „Zeigt den Verlauf dieser Zeile.“
- [ ] Double-tap a row. Its chart opens.
- [ ] On the chart page, VoiceOver does not reach the buttons of the table under it.
- [ ] A three-finger swipe to the left on the chart page shows the next chart.
- [ ] In the settings, a checkbox reads its column and state, e.g. „1 Monat vorlesen, aus“. A double tap changes it.
- [ ] The checkbox of the name says that the name is always read, and a double tap does not change it.
- [ ] Swipe up or down on the tempo value. The tempo changes, and VoiceOver says the new tempo.
- [ ] Double-tap „Schneller“. VoiceOver says the new tempo. At „Schnell“ the focus stays on the button, and the hint says „Das ist schon das schnellste Tempo.“
- [ ] Each choice of Erscheinungsbild reads as selected or not.

## Voice and screen

- [ ] A tap on Nächste or Vorherige moves the yellow row without speech.
- [ ] Vorlesen in the table reads the name and the values of a row, e.g. „Nestlé, 77,96 Franken, Tag plus 0,5 Prozent.“, waits about 1 s, and reads the next row.
- [ ] Vorlesen on the chart page reads only the shown chart and then stops.
- [ ] A group change during Vorlesen stops and says the new group and the row.
- [ ] Quick taps on Nächste during Vorlesen never give two voices at the same time.
- [ ] The Premium voice from the iPad settings reads, if one is installed.
- [ ] Turn the iPad. The table and the chart page fit in portrait and in landscape, in light and in dark.
- [ ] After a new start of the app, each group shows its last cursor row again.

## Settings

- [ ] „Einstellungen“ in the top bar opens the settings with one tap. „‹ Kurse“ goes back to the table.
- [ ] „Dunkel“ makes the full app dark at once, also the chart page. „Hell“ makes it light again.
- [ ] „Wie iPad“: change light and dark in the Control Center. The app follows, and the line under the choices says „Jetzt: hell“ or „Jetzt: dunkel“.
- [ ] After a new start of the app, the chosen appearance, tempo and columns stay.
- [ ] „Probe hören“ reads the selected row of the table. A second tap stops it.
- [ ] „Langsamer“ and „Schneller“ change the tempo of the next text, also of Vorlesen in the table.
- [ ] Switch on „1-Mt.“ under Vorlesen. Vorlesen in the table then also says „1 Monat plus … Prozent“.
- [ ] Switch the range to „YTD“. The table header shows „YTD“, and the voice says „seit Jahresbeginn“.
- [ ] Switch off „Kurs“ and „Tag“. Vorlesen reads only the names.
- [ ] „Entfernen“ removes a row from the group, and the table no longer shows it.
- [ ] A wrong ticker, e.g. with a space, is not added, and the text stays in the fields.
- [ ] Turn the iPad. In landscape, Erscheinungsbild and Sprechtempo are side by side.
