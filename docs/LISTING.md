# App Store listing (draft for Zain to approve)

Character counts checked against Apple's limits on 2026-10-22. Subtitle and keywords revised
2026-10-26 from App Store autocomplete and top-10 competition data
(`~/Desktop/Non-Work/app-keyword-research/nicfree_results.csv`). Combinations they cover:
vape tracker, quit vaping tracker, quit vape free, quit vaping counter, quit nicotine,
smoking tracker, cigarette counter, puff log. Apple suppresses autocomplete for "nicotine",
so its demand can't be read from suggestions; "quit nicotine" has 5 weak apps in its top 10.

| Field | Limit | Draft | Count |
|---|---|---|---|
| Name | 30 | NicFree: Quit Vape & Pouches | 28 |
| Subtitle | 30 | Nicotine & vaping tracker | 25 |
| Keywords | 100 | `free,counter,smoking,cigarette,snus,pouch,tobacco,cessation,stop,habit,sober,craving,saved,puff,log` | 99 |
| Promotional text | 170 | Your free days only ever add up. A slip never wipes them out. One purchase, no subscription, and nothing leaves your iPhone. | 124 |

Apple indexes the name, subtitle and keywords together, so no word appears twice across
them. "Zyn" is a trademark and stays out of every field. "dip" and "chew" were dropped on
2026-10-25: the app doesn't support those products, and keywords for things an app doesn't do
can be rejected under guideline 2.3.7.

## Description

*Promotional text for the 1.1.1 launch, changeable any time without review (161/170):* Now in English, Svenska, Deutsch, Español, Français and العربية. Your free days only ever add up, and a slip never wipes them out. One purchase, no subscription.


Quit vaping, nicotine pouches or cigarettes without the guilt trip.

Most quit apps count a streak, and a streak resets to zero the moment you slip. NicFree
counts your free days instead. That number only ever goes up. A slip adds a used day; it
never takes your free days away.

WHEN A CRAVING HITS
Tap one button. Breathe with the circle, see the reason you wrote in your own words, and
watch the timer. Most cravings pass in minutes, and NicFree shows you how long yours
actually last.

WATCH IT ADD UP
• Free days, cravings beaten, and money saved, all on one screen
• A sprout that grows with every free day, and gets a little thirsty after a slip
• A milestone path: 1 day, 3, 7, 14, 30, 60, 90, 180, a year

NOTHING TO KEEP UP WITH
Every day counts as free unless you log a slip. Away for a few days? NicFree asks once
about them when you're back. An evening check-in is there if you want one, off unless you
turn it on.

PRIVATE BY DESIGN
No account. No tracking. No data collected. Everything stays on your iPhone.

ONE PURCHASE, NO SUBSCRIPTION
The core app is free. One purchase unlocks Insights (what sets your cravings off, when
they come, how long they last) and your full history.

IN YOUR LANGUAGE
NicFree is in English, Svenska, Deutsch, Español, Français and العربية. Switch any time in the app's Settings, without changing your iPhone's language.

NicFree is not a medical device and does not give medical advice. If you are worried
about nicotine withdrawal, talk to a doctor or pharmacist.

## In-app purchase

| Field | Limit | Value |
|---|---|---|
| Type | | Non-consumable |
| Reference name | 64 | NicFree Unlock |
| Product ID | | `nicfree.unlock` (must match `PurchaseStore.unlockID`) |
| Price | | $9.99 (US), other storefronts auto-equalised |
| Display name | 30 | Unlock NicFree (14) |
| Description | 45 | Insights and your full history, for good. (41) |
| Review screenshot | | The paywall: History tab → Unlock, on the 6.9" simulator |

## App Review notes

No account or sign-in. The free app is fully usable. The one purchase (`nicfree.unlock`)
unlocks Insights and full History; both tabs show an Unlock button, and the paywall has
Restore purchase. NicFree helps people stop using nicotine. It does not sell or promote
nicotine products, and it gives no medical advice.

## Still needed from Zain

- Approve or edit the copy above
- Support URL: https://zainnajamkhan.github.io/nicfree-site/ (live)
- Privacy policy URL: https://zainnajamkhan.github.io/nicfree-site/privacy.html (live)
- Screenshots: 6.9" iPhone and 13" iPad, both required since the app is universal
- Age rating questionnaire: answer honestly about tobacco references

## Localized listings (added 2026-11-09, ship with the app's translations)

The app ships in Swedish, German, Spanish, French and Arabic from 1.1.1. Each App Store
localization below needs the same screenshots for now (English captions over the English
app is acceptable; localized captions are a later pass). Counts checked; no word repeats
across a locale's name, subtitle and keywords. "Zyn" appears in names only, never in keywords.

| Locale | Name (30) | Subtitle (30) | Keywords (100) |
|---|---|---|---|
| Swedish | NicFree: Sluta snusa & vejpa | Zyn, vitt snus & nikotinpåsar | `nikotin,påse,vape,röka,cigarett,sug,räknare,fri,abstinens,nikotinfri,dagar,snusfri,e-cigg,portion` |
| German | NicFree: Zyn & Vape aufhören | Nikotinbeutel & Snus Tracker | `rauchfrei,nikotin,dampfen,e-zigarette,rauchen,verlangen,zähler,entzug,frei,beutel,pouch,stopp,tage` |
| Spanish (Mexico) | NicFree: Deja el Vape y Zyn | Bolsitas de nicotina y vapeo | `vapear,dejar,fumar,bolsas,cigarro,tabaco,antojo,contador,snus,pod,libre,adicción,días,sin` |
| Spanish (Spain) | NicFree: Deja el vapeo y Zyn | Bolsas de nicotina y vapers | `vapear,dejar,fumar,bolsitas,cigarrillo,tabaco,ansiedad,contador,snus,pod,libre,adicción,días` |
| French (France, also Canada) | NicFree: Arrêter Zyn et Vape | Sachets de nicotine & puff | `vapoter,cigarette,tabac,sachet,snus,envie,compteur,sevrage,fumer,libre,jours,arrêt,pouch` |
| Arabic | NicFree: الإقلاع عن الفيب | أكياس النيكوتين والسجائر | `تدخين,نيكوتين,ترك,اقلاع,رغبة,عداد,سنوس,سحبة,فيبات,بدون,أيام,إدمان,سيجارة` |

### Promotional text (170)

- **Swedish:** Varje fri dag räknas, och ett snedsteg tar aldrig bort dem. Låt din planta växa, stå emot suget och håll allt privat i mobilen. Inget konto, ingen prenumeration.
- **German:** Jeder freie Tag zählt, und ein Ausrutscher nimmt dir keinen weg. Lass dein Pflänzchen wachsen, steh Verlangen durch, alles bleibt privat. Kein Konto, kein Abo.
- **Spanish:** Cada día sin nicotina cuenta, y un desliz nunca te lo quita. Haz crecer tu brote, supera los antojos y todo queda en tu teléfono. Sin cuenta, sin suscripción.
- **French:** Chaque jour sans nicotine compte, et un écart ne te l’enlève jamais. Fais grandir ta pousse, surmonte tes envies, tout reste sur ton téléphone. Sans abonnement.
- **Arabic:** كل يوم بلا نيكوتين يُحسب، والزلة لا تأخذه منك أبدًا. اجعل نبتتك تكبر، وتجاوز رغباتك، وكل شيء يبقى على هاتفك. بلا حساب، بلا اشتراك.

### Description

**Swedish**

Sluta med Zyn, nikotinpåsar, vape eller cigaretter, utan skuldkänslor.

De flesta appar räknar en svit som nollställs när du snubblar. NicFree räknar dina fria dagar i stället, och den siffran går bara uppåt. Ett snedsteg lägger till en dag med nikotin. Det tar aldrig bort dina fria dagar.

NÄR SUGET KOMMER
Tryck på en knapp. Andas med cirkeln, se din egen anledning och följ timern. De flesta sug går över på några minuter.

SE DET VÄXA
• Fria dagar, sug du stått emot och sparade pengar på en skärm
• En planta som växer för varje fri dag
• Milstolpar: 1 dag, 3, 7, 14, 30, 60, 90, 180, ett år

PRIVAT
Inget konto. Ingen spårning. Allt stannar på din iPhone.

ETT KÖP, INGEN PRENUMERATION
Grundappen är gratis. Ett köp låser upp Insikter och hela din historik.

PÅ DITT SPRÅK
NicFree finns på svenska, engelska, tyska, spanska, franska och arabiska. Byt när du vill i appens inställningar, utan att ändra språket på din iPhone.

NicFree är ingen medicinteknisk produkt och ger inga medicinska råd.

**German**

Hör mit Zyn, Nikotinbeuteln, Vapes oder Zigaretten auf, ohne schlechtes Gewissen.

Die meisten Apps zählen eine Serie, die bei einem Ausrutscher auf null fällt. NicFree zählt stattdessen deine freien Tage, und diese Zahl geht nur nach oben. Ein Ausrutscher fügt einen Tag mit Nikotin hinzu. Deine freien Tage nimmt er dir nie.

WENN DAS VERLANGEN KOMMT
Ein Tipp genügt. Atme mit dem Kreis, sieh deinen eigenen Grund und behalte den Timer im Blick. Das meiste Verlangen ist nach ein paar Minuten vorbei.

SIEH, WIE ES WÄCHST
• Freie Tage, ausgehaltenes Verlangen und gespartes Geld auf einen Blick
• Ein Pflänzchen, das mit jedem freien Tag wächst
• Meilensteine: 1 Tag, 3, 7, 14, 30, 60, 90, 180, ein Jahr

PRIVAT
Kein Konto. Kein Tracking. Alles bleibt auf deinem iPhone.

EIN KAUF, KEIN ABO
Die App ist kostenlos. Ein Kauf schaltet Einblicke und deinen ganzen Verlauf frei.

IN DEINER SPRACHE
NicFree gibt es auf Deutsch, Englisch, Schwedisch, Spanisch, Französisch und Arabisch. Wechsle jederzeit in den Einstellungen der App, ohne die Sprache deines iPhones zu ändern.

NicFree ist kein Medizinprodukt und gibt keinen medizinischen Rat.

**Spanish**

Deja Zyn, las bolsitas de nicotina, el vape o el cigarro, sin culpa.

La mayoría de las apps cuentan días seguidos y vuelven a cero con un desliz. NicFree cuenta tus días sin nicotina, y ese número solo sube. Un desliz suma un día con nicotina. Nunca te quita tus días sin nicotina.

CUANDO LLEGA UN ANTOJO
Toca un botón. Respira con el círculo, mira tu propia razón y sigue el temporizador. La mayoría de los antojos pasan en minutos.

MÍRALO CRECER
• Días sin nicotina, antojos superados y dinero ahorrado en una sola pantalla
• Un brote que crece con cada día sin nicotina
• Logros: 1 día, 3, 7, 14, 30, 60, 90, 180, un año

PRIVADO
Sin cuenta. Sin rastreo. Todo se queda en tu iPhone.

UN SOLO PAGO, SIN SUSCRIPCIÓN
La app es gratis. Un pago desbloquea Análisis y tu historial completo.

EN TU IDIOMA
NicFree está en español, inglés, sueco, alemán, francés y árabe. Cámbialo cuando quieras en los ajustes de la app, sin cambiar el idioma de tu iPhone.

NicFree no es un dispositivo médico y no da consejos médicos.

**French**

Arrête Zyn, les sachets de nicotine, la vape ou la cigarette, sans culpabiliser.

La plupart des apps comptent des jours d’affilée qui retombent à zéro au moindre écart. NicFree compte tes jours sans nicotine, et ce nombre ne fait que monter. Un écart ajoute un jour avec nicotine. Il ne t’enlève jamais tes jours sans nicotine.

QUAND UNE ENVIE ARRIVE
Touche un bouton. Respire avec le cercle, relis ta propre raison et suis le minuteur. La plupart des envies passent en quelques minutes.

REGARDE-LE GRANDIR
• Jours sans nicotine, envies surmontées et argent économisé sur un seul écran
• Une pousse qui grandit à chaque jour sans nicotine
• Étapes : 1 jour, 3, 7, 14, 30, 60, 90, 180, un an

PRIVÉ
Pas de compte. Pas de suivi. Tout reste sur ton iPhone.

UN SEUL ACHAT, SANS ABONNEMENT
L’app est gratuite. Un achat débloque les Analyses et tout ton historique.

DANS TA LANGUE
NicFree existe en français, anglais, suédois, allemand, espagnol et arabe. Change quand tu veux dans les réglages de l’app, sans changer la langue de ton iPhone.

NicFree n’est pas un dispositif médical et ne donne pas de conseils médicaux.

**Arabic**

توقف عن Zyn وأكياس النيكوتين والفيب والسجائر، دون شعور بالذنب.

معظم التطبيقات تعدّ أيامًا متتالية تعود إلى الصفر عند أول زلة. NicFree يعدّ أيامك بلا نيكوتين، وهذا الرقم يزيد فقط. الزلة تضيف يومًا مع نيكوتين، ولا تأخذ منك أيامك بلا نيكوتين أبدًا.

عندما تأتي الرغبة
اضغط زرًا واحدًا. تنفّس مع الدائرة، واقرأ سببك بكلماتك، وتابع المؤقت. معظم الرغبات تمرّ خلال دقائق.

شاهده يكبر
• الأيام بلا نيكوتين، والرغبات التي تجاوزتها، والمال الموفَّر في شاشة واحدة
• نبتة تكبر مع كل يوم بلا نيكوتين
• محطات: يوم، 3، 7، 14، 30، 60، 90، 180، سنة

خاص
لا حساب. لا تتبع. كل شيء يبقى على الـ iPhone.

شراء واحد، بلا اشتراك
التطبيق مجاني. شراء واحد يفتح الرؤى وسجلك الكامل.

بلغتك
NicFree متوفر بالعربية والإنجليزية والسويدية والألمانية والإسبانية والفرنسية. غيّر اللغة متى شئت من إعدادات التطبيق، دون تغيير لغة iPhone.

NicFree ليس جهازًا طبيًا ولا يقدّم نصائح طبية.
