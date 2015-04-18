--[[
   KahLua KonferPUG - an open roll loot distribution helper for PUGs.
     WWW: http://kahluamod.com/kpug
     SVN: http://kahluamod.com/svn/konferpug
     IRC: #KahLua on irc.freenode.net
     E-mail: cruciformer@gmail.com
   Please refer to the file LICENSE.txt for the Apache License, Version 2.0.

   Copyright 2008-2010 James Kean Johnston. All rights reserved.
   Copyright 2009-2010 Stefan Junghanns. All rights reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]

local K = LibStub:GetLibrary("KKore")

if (not K) then
  error ("KahLua KonferPUG: KahLua Kore konnte nicht gefunden werden.", 2)
end

local L = K:RegisterI18NTable("KKonferPUG", "deDE")
if (not L) then
  return
end

--
-- NOTE TO PEOPLE LOCALISING THIS FILE:
-- PLEASE BE SURE TO VIEW THE LOCALISATION INSTRUCTIONS FOUND AT
-- http://kahluamod.com/l10n BEFORE STARTING ANY TRANSLATIONS OF
-- THIS FILE. THANK YOU.
--
L["MODTITLE"] = "KonferPUG"
L["MODNAME"] = "konferpug"
L["MODABBREV"] = "KPUG"
L["CMDNAME"] = "kpug"
L["CMD_LOOT"] = "loot"
L["CMD_HISTORY"] = "history"
L["CMD_RAIDERS"] = "raiders"
L["CMD_CONFIG"] = "config"
L["CMD_HELP"] = "help"
L["CMD_VERSION"] = "version"
L["CMD_RESETPOS"] = "resetpos"
L["CMD_SUSPEND"] = "suspend"
L["CMD_RESUME"] = "resume"
L["CMD_ADDLOOT"] = "addloot"
L["CMD_ADDIGNORE"] = "addignore"
L["CMD_ADDDECAY"] = "adddecay"
L["CMD_EDITION"] = "edition"
L["CMD_SHOW"] = "show"
L["CMD_DECAY"] = "decay"
L["CMD_VERSIONCHECK"] = "versioncheck"

--
-- Main localisation strings start here
--

L["AUTOLOOT"] = "Dieses Item wurde von %s gewonnen. Drücke 'OK', um das Item %s automatisch zuzuteilen. Wenn du 'Abbrechen' drückst, wird das Item trotzdem von der Loot-Liste entfernt und du musst es %s mit dem Standard User Interface zuteilen."
L["AUTODENCHNR"] = "Niemand hat auf das Item gewürfelt. Entzauberer %q ist online und im Raid. Drücke 'Ok', um %s das Item zuzuteilen. Drücke 'Abbrechen' wenn du das Item manuell zuweisen möchtest (Das Item wird von der Loot-Liste entfernt, aber nicht aus dem Leichnam oder aus der Truhe)."
L["error: "] = "Fehler: "
L["Open Roll loot distribution helper for PUGs."] = "Würfel-Loot-Verteilungshelfer für PUGs."
L["%s<%s>%s %s (version %d) - %s"] = "%s<%s>%s %s (Version %d) - %s"
L["/%s [command [arg [arg...]]]"] = "/%s [command [arg [arg...]]]"
L["Usage: "] = "Gebrauch: "
L["  Opens the loot management window."] = "  Öffnet das Loot-Management."
L["  Opens the user list management window."] = "  Offnet das Nutzer-Listen-Management."
L["  Opens the decay list window."] = "  Offnet das Decay-Listen-Management."
L["  Suspend %s (no auto-open on loot)."] = "  Ausschluss %s (kein Auto-Öffnen bei Loot)."
L["  Resume normal %s operations."] = "  Fortsetzen der normalen %s Operationen."
L["  Set up various options."] = "  Setzen verschiedener Optionen."
L["/%s %s [itemid | itemlink]"] = "/%s %s [Item-ID | Item-Link]"
L["  Adds a new item to the loot list."] = "  Fügt ein neues Item zur Loot-Liste hinzu."
L["  Adds a new item to the item ignore list."] = "  Fügt ein neues Item zur Item-Ignore-Liste hinzu."
L["  Adds the specified player to the decay list with a decay count of 1."] = "  Fügt den ausgewählen Spieler zur Decay-Liste mit einem Decay-Zähler von 1."
L["Player %q not found in the raid."] = "Spieler %q nicht im Raid gefunden."
L["Player %q already in the decay list."] = "Spieler %q ist bereits auf der Decay-Liste."
L["%q is not a valid command. Type %s for help."] = "%q ist kein gültiges Kommando. Gib %s für Hilfe ein."
L["Auto-open Loot Panel When Corpse Looted"] = "Öffnet das Loot-Fenster automatisch, wenn ein Leichnam gelootet wird."
L["Display Tooltips in Loot List"] = "Zeigt Tooltipps in der Loot-List"
L["Announce Loot"] = "Loot verkünden"
L["Enable Chat Message Filter"] = "Aktiviert den Chat-Filter"
L["Roll Timeout"] = "Timeout für das Würfeln"
L["Roll Timeout Extension"] = "Erweiterung des Wurf-TimeOuts"
L["Auto-assign Loot When Roll Ends"] = "Auto-Zuweisung des Loots nach Würfelende"
L["Assign to Enchanter if no-one rolls"] = "Zuweisung an den Entzauberer wenn keiner würfelt"
L["Enable Off-spec Rolls"] = "Aktiviere Off-Spec Würfe"
L["Loot"] = "Loot"
L["Assign Loot"] = "Loot-Zuweisung"
L["History"] = "Historie"
L["Loot History"] = "Loot-Historie"
L["Raiders"] = "Raidmitglieder"
L["Raider Attributes"] = "Raidmitglieder-Eigenschaften"
L["Config"] = "Konfiguration"
L["Ignored Items"] = "Ignorierte Items"
L["Configure Options"] = "Konfigurationsoptionen"
L["can only add items when in a raid and you are the master looter."] = "kann nur Items hinzufügen, wenn du im Raid und Plündermeister bist."
L["item %d is an invalid item."] = "Item %d ist ein ungültiges Item."
L["Announce Winners in Raid"] = "Gewinner im Raid verkünden"
L["Start Roll"] = "Start Würfeln"
L["End Roll"] = "Wurfende"
L["Pause Roll"] = "Pause Würfeln"
L["Resume"] = "Weiter"
L["Remove Item"] = "Entfernen Item"
L["Remove"] = "Entfernen"
L["Switch Spec"] = "Wechsel Spec"
L["[Main Spec]"] = "Main-Spec"
L["[Off-spec]"] = "[Off-Spec]"
L["User Role 1"] = "Nutzerrolle 1"
L["User Role 2"] = "Nutzerrolle 2"
L["Not Set"] = "Nicht festgelegt"
L["Tank"] = "Tank"
L["Ranged DPS"] = "Ranged DPS"
L["Melee DPS"] = "Melee DPS"
L["Healer"] = "Healer"
L["Spellcaster"] = "Spellcaster"
L["User is an Enchanter"] = "Nutzer ist ein Verzauberer"
L["Rating"] = "Wertung"
L["Pro"] = "Profi"
L["Good"] = "Gut"
L["Average"] = "Durchschnitt"
L["Poor"] = "Arm"
L["Noob"] = "Noob"
L["Comments"] = "Kommentare"
L["Update"] = "Updaten"
L["Delete"] = "Löschen"
L["Chest"] = "Brust"
L["%s: loot from %s: "] = "%s: loot von %s: "
L["Roll for %s cancelled!"] = "Wurf für %s abgebrochen"
L["Roll for %s within %d seconds."] = "Würfeln für %s innerhalb %d Sekunden."
L["Roll for %s."] = "Würfeln für %s."
L["Roll closing in %s"] = "Würfeln endet in %s"
L["%s: roll closing in: %d"] = "%s: Würfe enden in: %d"
L["no-one rolled for %s."] = "Niemand hat für %s gewürfelt."
L["top main spec rollers: %s"] = "Top First-Need Würfler: %s"
L["top off-spec rollers: %s"] = "Top Second-Need Würfler: %s"
L["%s: the following users tied with %d: %s. Roll again."] = "%s: Folgende Nutzer würfelten unentschieden mit %d: %s. Würfelt erneut."
L["%s: sorry you are not allowed to roll right now."] = "%s: Sorry, dir ist im Moment nicht erlaubt, zu würfeln."
L['%s: type %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'] = '%s: Benutze %q für Main-Spec, %q für Off-Spec oder "/roll 1-1" um den Wurf abzubrechen.'
L['%s: type %q for main spec or "/roll 1-1" to cancel a roll.'] = '%s: Benutze %q für Main-Spec oder "/roll 1-1" um den Wurf abzubrechen.'
L['%s: invalid roll. Use %q for main spec, %q for off-spec or "/roll 1-1" to cancel a roll.'] = '%s: Ungültiger Wurf. Benutze %q für Main-Spec, %q für Off-Spec oder "/roll 1-1" um den Wurf abzubrechen.'
L['%s: invalid roll. Use %q for main spec or "/roll 1-1" to cancel a roll.'] = '%s: Ungültiger Wurf. Benutze %q für Main-Spec oder "/roll 1-1" um den Wurf abzubrechen.'
L["Announce Countdown"] = "Verkünden Count-Down"
L["%s: you are not eligible to receive this item - roll ignored."] = "%s: Du bist nicht berechtigt, dieses Item zu erhalten - Wurf ignoriert."
L["%s: you already rolled %d. New roll ignored."] = "%s: Du hast bereits %d gewürfelt. Neuer Wurf ignoriert."
L["%s: %s (group %d) won %s. Grats!"] = "%s: %s (Gruppe %d) hat %s gewonnen. GW!"
L["Note: player will need to pick item up manually."] = "Notiz: Spieler muss Item manuell aufnehmen."
L["Clear All"] = "Alles löschen"
L["Clear all except last week"] = "Alles außer letzte Woche löschen"
L["Clear all except last month"] = "Alles außer letztem Monat löschen"
L["When"] = "Wann"
L["What"] = "Was"
L["Who"] = "Wer"
L["How"] = "Wie"
L["Record Loot Assignment History"] = "Zeichnet die Loot-Zuteilung auf"
L["Disenchanted"] = "Entzaubert"
L["Won Roll"] = "Hat Wurf gewonnen"
L["Roll (Main)"] = "Wurf (Main)"
L["Roll (Off)"] = "Wurf (Off)"
L["Main Spec Minimum"] = "Main-Spec Minimum"
L["Off-spec Minimum"] = "Off-Spec Minimum"
L["Maximum"] = "Maximum"
L["invalid main spec roll range (%d > %d)."] = "Ungültiger Main-Spec-Würfel-Bereich (%d > %d)."
L["invalid off-spec roll range (%d > %d)."] = "Ungültiger Off-Spec-Würfel-Bereich (%d > %d)."
L["main spec and off-spec roll ranges cannot be the same."] = "Würfel-Bereich von Main-Spec und Off-Spec kann nicht gleich sein."
L['%s: invalid roll. Use %q or "/roll 1-1" to cancel a roll.'] = '%s: Ungültiger Wurf. Benutze %q oder "/roll 1-1" um den Wurf abzubrechen.'
L["Extras"] = "Extras"
L["Decay"] = "Decay (Reduzierung)"
L["Enable Roll Decay"] = "Erlaube Würfel-Decay"
L["Main Spec Decay Amount"] = "Main-Spec Decay-Anzahl"
L["Off-spec Decay Amount"] = "Off-Spec Decay-Anzahl"
L["Maximum Decay Count"] = "Maxiumum Decay-Zähler"
L["Apply to Main Spec Only"] = "Gültig nur für Main-Spec"
L["Broadcast"] = "Rundsenden"
L["Reset"] = "Reset"
L["Down from 5 second mark"] = "Unten vom 5-Sekunden-Marke"
L["At 5 second mark"] = "Bei 5-Sekunden-Marke"
L["At 5 and 10 second marks"] = "Bei 5- und 10-Sekunden-Marke"
L["%s: the following user(s) are roll-decayed:"] = "%s: folgende(r) Nutzer sind unter Würfel-Decay:"
L["%s:   %s by %d item(s) (%d)"] = "%s:   %s durch %d Item(s) (%d)"
L["Enable Countdown Timer"] = "Countdown Timer einschalten"
L["Enable Countdown Extension"] = "Countdown verlängerung einschalten"
L["Main Spec Roll"] = "Haupt Spec Wurf"
L["Off-spec Roll"] = "Neben Spec Wurf"
L["your version of %s is out of date. Please update it."] = "Deine Version von %s ist nicht aktuell. Bitte aktualisiere sie."
L["%s using version %s"] = "%s benutzt Version %s"

L["TIP001"] = "Aktiviere diese Option, um das KPUG Loot-Fenster automatisch zu öffnen, wenn du einen Leichnam plünderst, der ein gültiges Item enthält."
L["TIP002"] = "Aktiviere diese Option für die Anzeige des Item-Tooltipps wenn die Maus über einen Eintrag in der Loot-Liste geführt wird."
L["TIP003"] = "Verkünde im Raid-Chat den Loot, der in einem Leichnam/einer Truhe gefunden wurde."
L["TIP004"] = "Aktiviere diese Option, um geflüsterte eingehende Gebote bzw. die meisten ausgehenden Gebote und Warnungen zu verstecken. Das reduziert die Gefahr, reale Gebote zu verpassen."
L["TIP005"] = "Setzt die Dauer, wie lange auf eingehende Würfe gewartet wird, bevor der Sieger ermittelt wird. Wenn es gestartet ist, kannst du das Würfeln anhalten oder beenden."
L["TIP006"] = "Setzt die Anzahl der Sekunden, die den Würfel-Timer verlängern, wenn ein Wurf in den letzten 5 Sekunden des Countdowns eingegangen ist."
L["TIP007"] = "Sende eine Nachricht an den Raid, wenn ein gewinnendes Gebot erhalten und das Bieten geschlossen wurde."
L["TIP008"] = "Aktiviere diese Option, um das Loot automatisch dem höchsten Wurf zuzuweisen, wenn der Time-Out abgelaufen ist."
L["TIP009"] = "Aktiviere diese Option,  um automatisch das Loot einem Entzauberer zuzuweisen, wenn keiner auf das Item gewürfelt hat. Du musst vorher festgelegt haben, wer ein Entzauberer im Raid ist."
L["TIP010"] = "Start des Würfel-Countdown-Timers während dessen Interessierte auf den Loot würfeln können. Eine Raid-Warnung wird ausgegeben, die den Nutzern mitteilt, wie sie auf Off-Spec würfeln können, wie sie einen Wurf abbrechen können usw., und wie lange des Countdown ist.\n\nWenn du das Würfeln bereits gestartet hast, wird dieser Button das Würfeln beenden und dem höchsten Wurf das Item zuteilen. Benutze ihn, wenn du weisst, dass keine Würfe mehr auf das Item erfolgen."
L["TIP011"] = "Pausiert den aktuellen Würfel-Countdown, um den Nutzern mehr Zeit zu geben, über das Item nachzudenken."
L["TIP012"] = "Entfernt das ausgewählte Item von der Loot-Liste. Wenn du bereits das Würfeln gestartet hast, wird diese beendet und alle aktuellen Würfe werden gelöscht."
L["TIP014"] = "Entfernt das ausgewählte Item von der Loot-Liste."
L["TIP015"] = "Wechselt den ausgewählten Wurf zwischen Main-Spec und Off-Spec. Nützlich, um einen Nutzer-Fehler zu korrigieren. Der Nutzer kann es selbst korrigieren durch nochmaliges Würfeln mit dem korrekten Spec-Bereich (1-100 für Main-Spec, 101-200 für Off-Spec)."
L["TIP016"] = "Kennzeichnet den Nutzer als Entzauberer. Wenn niemand auf ein Item würfeln, wird es dem ersten Verzauberer, der im Raid gefunden wird, zugewiesen."
L["TIP017"] = "Wählt die Rolle(n) aus, den ein Nutzer einnehmen kann. Dies ist nützlich, wenn du zusätzliche Leute suchst, um den PUG zu füllen. Zwei Rollen können für jeden Nutzer definiert werden."
L["TIP018"] = "Bewertet die Leistung dieses Nutzers. Dies ist nützlich, wenn ein Nutzer besonders gut oder besonders schlecht abschneidet und du Leute zum Auffüllen des PUG suchst."
L["TIP019"] = "Klicken, um alle Änderungen für den Nutzer permanent zu übernehmen. Vorher werden keinen Änderungen am Nutzerprofil wirksam."
L["TIP020"] = "Klicken, um einen gespeicherten Nutzer aus der Nutzer-Datenbank zu löschen. Wenn der Nutzer aktuell im Raid ist, wird er weiter in der Raid-Liste angezeigt, seine gespeicherten Informationen werden aber entfernt und wenn er den Raid verlässt, erfolgt keine weitere Aufzeichnung für ihn."
L["TIP021"] = "Klicken, um ein aktuell ausgewähltes Item von der Ignore-Liste zu entfernen. Wenn das item das nächste Mal in der Loot-Liste auftaucht, wird es auch angezeigt."
L["TIP022"] = "Wähle diese Option, um eine Warnung über den Ablauf des Countdown-Timers an den Raid oder die Gruppe zu senden. Ist sie aktiviert, kannst du auswählen, ob eine Warnung nur für die letzten 5 Sekunden oder jede Sekunde der letzten 5 Sekunden ausgegeben wird."
L["TIP022.1"] = "Zeigt eine Raid-Warnung für die letzten 5 Sekunden bis Wurf-Ende an. Wird die Timeout-Zeit verlängert aufgrund späten Würfelns, wird der Countdown erneut angezeigt bei 5 Sekunden Restzeit."
L["TIP022.2"] = "Zeigt eine Raid-Warnung an sobald der Countdown 5 Sekunden erreicht hat, aber nicht für jede weitere Sekunde. Dies ist die Standardeinstellung."
L["TIP022.3"] = "Zeigt eine Raid-Warnung, wenn der Countdown der 10 Sekunden-Marke erreicht, und erneut bei der 5-Sekunden-Marke. Diese Warnungen werden wiederholt angezeigt, wenn der Würfel-Timeout verlängert wurde."
L["TIP024"] = "Aktiviere dies, damit der Würfel-Manager zwischen Main-Spec (1-100) und Off-Spec (101-200) unterscheidet. Wenn es deaktiviert ist, und ein Nutzer benutzt '/roll 101-200' wird das ignoriert."
L["TIP025"] = "Löscht die gesamte Loot-Historie. Beachte, dass nur deine lokale Loot-Historie gelöscht wird, es hat keine Auswirkung auf Historien anderer Administratoren."
L["TIP026"] = "Löscht die gesamte Loot-Historie mit Ausnahme der letzten 7 Tage. Beachte, dass nur deine lokale Loot-Historie gelöscht wird, es hat keine Auswirkung auf Historien anderer Administratoren."
L["TIP027"] = "Löscht die gesamte Loot-Historie mit Ausnahme des letzten Monat. Beachte, dass nur deine lokale Loot-Historie gelöscht wird, es hat keine Auswirkung auf Historien anderer Administratoren."
L["TIP028"] = "Aktiviert das Decay-Würfeln. Gewinnt ein Nutzer das Würfeln für ein Item, wird der maximale Betrag für das nächste Würfeln um einen bestimmten Wert reduziert (Decay-Effekt). Dadurch wird sichergestellt, dass kein einzelner Nutzer alle (oder zu viele) Würfe in einem Raid gewinnt. Es gibt zusätzliche Einstellungen, die steuern, wie das Decay (Reduzierung) funktioniert, die alle aktiviert sind, wenn diese Option aktiv ist. "
L["TIP029"] = "Setzt den Betrag, um den das Maximum eines Nutzers bei jedem Gewinn eines Würfelns reduziert wird."
L["TIP030"] = "Setzt die maximale Anzahl der Reduzierungen (Decay) der Wurf-Obergrenze eines Nutzers. Standardmäßig ist die Anzahl 4."
L["TIP031"] = "Wenn aktiviert, unterliegen nur Würfe auf MAin_Spec der Reduzierung (Decay). Wenn deaktiviert unterliegen sowohl Main-Spec als auch Off-Spec dem Decay."
L["TIP032"] = "Klicken für das Rundsenden der Liste aller Nutzer, die einem Decay unterliegen, an den Raid. Es werden keine Items, sondern nur die Decay-Nutzer und die Anzahl, wie oft sie dem Decay unterlagen, gesendet."
L["TIP033"] = "Klicken, um die Decay-Daten zurück zu setzen. In der Regel tun Sie dies zu Beginn eines Raids oder wenn Sie eine neue Instanz starten."
L["TIP034"] = "Erhöht den Decay-Zähler eines Nutzers um 1, bis zum Maximum des Decay-Zählers."
L["TIP035"] = "Erniedrigt den Decay-Zähler eines Nutzers um 1. Wird 0 erreicht, wird der Nutzer aus der Decay-Liste entfernt."
--
-- Shared Konfer dialog. These strings are used by all Konfer addons.
--
L["KONFER_SEL_TITLE"] = "Auswahl des aktiven %s Konfer-Moduls"
L["KONFER_SEL_HEADER"] = "Du hast %s Konfer-Module installiert und mehr als eines von ihnen ist aktiv und eingestellt auf automatisches Öffnen, wenn ein Leichnam oder eine Kiste/Truhe geplündert wird. Dies kann Konflikte verursachen, du solltest eines der Module als aktives auswählen. Alle anderen werden dann ausgeschlossen."
L["KONFER_SEL_DDTITLE"] = "Modul-Auswahl zum Aktivieren"
L["KONFER_ACTIVE"] = "aktiv"
L["KONFER_SUSPENDED"] = "ausgeschlossen"
L["KONFER_SUSPEND_OTHERS"] = "Du hast das %s Konfer-Modul gerade aktiviert, aber andere Konfer-Module sind ebenfalls aktiv. Mehrere Module zur selben Zeit aktiv zu haben, kann Probleme verursachen, besonders wenn mehr als eins sich beim Looten automatisch öffnet. Es wird empfohlen, die anderen Module zu deaktivieren. Wenn du dies tun willst und nur das ausgewählte aktivieren willst, drücke den 'OK'-Button. Wenn du sicher bist, dass mehrere Konfer-Module laufen sollen, dann drücke 'Abbrechen'."
