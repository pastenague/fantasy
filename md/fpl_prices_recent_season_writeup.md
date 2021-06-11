I have trained a small neural network (3 hidden layers) on data obtained from [vaastav's excellent GitHub repo](https://github.com/vaastav/Fantasy-Premier-League) of FPL history. This neural network predicts a player's starting cost for the next season based on the following stats from their previous season:

* Their position (`GK`, `DEF`, `MID`, `FWD`)
* Starting Cost (`start_price`)
* Ending Cost (`end_price`)
* Minutes
* Goals
* Assists
* Yellows
* Reds
* Clean Sheets
* Own Goals
* Total Points (including bonus)

It should be noted that the network is blind to the player's club, so some players from top/bottom-of-the-table clubs may appear to be under/overpriced, respectively, in the network's predictions. In addition, the network assumes that each player's position remains the same - e.g., Dallas's price is predicted to be 6.5 if he were to remain a `DEF` next year.

I trained the network on 3/4 of the historical data from the repository, and tested it on the remaining 1/4. The [root mean squared error (RMSE)](https://en.wikipedia.org/wiki/Root-mean-square_deviation) for the prediction for both the train and test data was approximately 0.4.

Here's every player whose price is predicted to change next year based on the neural network's prediction. The `price_boost` column is the predicted change in price from the previous season.

**If you don't see a player listed here it means that the neural network predicted their price to remain the same as last year.**

# Risers

|player          |position | points| start_price| end_price| next_price| price_boost|
|:---------------|:--------|------:|-----------:|---------:|----------:|-----------:|
|Bamford         |FWD      |    194|         5.5|       6.6|        8.5|         3.0|
|Dallas          |DEF      |    171|         4.5|       5.5|        6.5|         2.0|
|Gündogan        |MID      |    157|         5.5|       5.5|        7.0|         1.5|
|Kane            |FWD      |    242|        10.5|      11.9|       12.0|         1.5|
|Son             |MID      |    228|         9.0|       9.6|       10.5|         1.5|
|Lingard         |MID      |    106|         6.0|       6.6|        7.5|         1.5|
|Cresswell       |DEF      |    153|         5.0|       5.7|        6.5|         1.5|
|Martínez        |GK       |    186|         4.5|       5.3|        5.5|         1.0|
|Grealish        |MID      |    135|         7.0|       7.5|        8.0|         1.0|
|Watkins         |FWD      |    168|         6.0|       6.3|        7.0|         1.0|
|Jorginho        |MID      |    114|         5.0|       4.7|        6.0|         1.0|
|Chilwell        |DEF      |    139|         5.5|       5.9|        6.5|         1.0|
|Benteke         |FWD      |    106|         5.5|       5.5|        6.5|         1.0|
|Calvert-Lewin   |FWD      |    165|         7.0|       7.5|        8.0|         1.0|
|Iheanacho       |FWD      |    110|         6.0|       6.2|        7.0|         1.0|
|Harrison        |MID      |    160|         5.5|       5.6|        6.5|         1.0|
|Raphinha        |MID      |    133|         5.5|       5.6|        6.5|         1.0|
|Salah           |MID      |    231|        12.0|      12.9|       13.0|         1.0|
|Stones          |DEF      |    128|         5.0|       5.1|        6.0|         1.0|
|Fernandes       |MID      |    244|        10.5|      11.3|       11.5|         1.0|
|Wilson          |FWD      |    134|         6.5|       6.5|        7.5|         1.0|
|Soucek          |MID      |    147|         5.0|       5.2|        6.0|         1.0|
|Coufal          |DEF      |    128|         4.5|       4.8|        5.5|         1.0|
|Chambers        |DEF      |     36|         4.5|       4.5|        5.0|         0.5|
|Holding         |DEF      |    105|         4.5|       4.3|        5.0|         0.5|
|Smith Rowe      |MID      |     74|         4.5|       4.2|        5.0|         0.5|
|Saka            |MID      |    114|         5.5|       5.1|        6.0|         0.5|
|Mings           |DEF      |    128|         5.0|       5.4|        5.5|         0.5|
|Targett         |DEF      |    138|         4.5|       5.0|        5.0|         0.5|
|El Ghazi        |MID      |    111|         6.0|       5.2|        6.5|         0.5|
|Konsa           |DEF      |    119|         4.5|       4.6|        5.0|         0.5|
|Traoré          |MID      |    135|         6.0|       5.8|        6.5|         0.5|
|Dunk            |DEF      |    130|         5.0|       4.8|        5.5|         0.5|
|Veltman         |DEF      |     96|         4.5|       4.3|        5.0|         0.5|
|Lamptey         |DEF      |     35|         4.5|       4.6|        5.0|         0.5|
|Welbeck         |FWD      |     89|         5.5|       5.5|        6.0|         0.5|
|Wood            |FWD      |    138|         6.5|       6.6|        7.0|         0.5|
|Vydra           |FWD      |     62|         5.0|       4.8|        5.5|         0.5|
|Zouma           |DEF      |    108|         5.0|       5.3|        5.5|         0.5|
|Mount           |MID      |    147|         7.0|       7.3|        7.5|         0.5|
|James           |DEF      |    112|         5.0|       5.1|        5.5|         0.5|
|Mendy           |GK       |    140|         5.0|       5.3|        5.5|         0.5|
|Zaha            |MID      |    136|         7.0|       7.1|        7.5|         0.5|
|Riedewald       |MID      |     64|         4.5|       4.4|        5.0|         0.5|
|Mitchell        |DEF      |     58|         4.0|       3.8|        4.5|         0.5|
|Eze             |MID      |    125|         6.0|       5.8|        6.5|         0.5|
|Keane           |DEF      |    127|         5.0|       5.0|        5.5|         0.5|
|Anguissa        |MID      |     76|         4.5|       4.4|        5.0|         0.5|
|Lemina          |MID      |     55|         4.5|       4.5|        5.0|         0.5|
|Lookman         |MID      |    107|         5.0|       4.7|        5.5|         0.5|
|Aina            |DEF      |    102|         4.5|       4.3|        5.0|         0.5|
|Vardy           |FWD      |    187|        10.0|      10.2|       10.5|         0.5|
|Amartey         |DEF      |     19|         4.0|       3.9|        4.5|         0.5|
|Maddison        |MID      |    133|         7.0|       7.2|        7.5|         0.5|
|Justin          |DEF      |    101|         4.5|       4.8|        5.0|         0.5|
|Castagne        |DEF      |     94|         5.5|       5.8|        6.0|         0.5|
|Alioski         |DEF      |    110|         4.5|       4.4|        5.0|         0.5|
|Struijk         |DEF      |     71|         4.0|       4.0|        4.5|         0.5|
|Meslier         |GK       |    154|         4.5|       4.8|        5.0|         0.5|
|Rodrigo         |FWD      |     89|         6.0|       5.7|        6.5|         0.5|
|Jones           |MID      |     50|         4.5|       4.4|        5.0|         0.5|
|Jota            |MID      |     86|         6.5|       6.9|        7.0|         0.5|
|Phillips        |DEF      |     68|         4.0|       4.2|        4.5|         0.5|
|Rhys Williams   |DEF      |     28|         4.0|       4.0|        4.5|         0.5|
|Cancelo         |DEF      |    138|         5.5|       5.8|        6.0|         0.5|
|Foden           |MID      |    135|         6.5|       6.1|        7.0|         0.5|
|Shaw            |DEF      |    124|         5.0|       5.5|        5.5|         0.5|
|McTominay       |MID      |     91|         5.0|       4.9|        5.5|         0.5|
|Wan-Bissaka     |DEF      |    144|         5.5|       5.8|        6.0|         0.5|
|Willock         |MID      |     79|         5.0|       4.9|        5.5|         0.5|
|Murphy          |MID      |     69|         5.0|       4.9|        5.5|         0.5|
|McGoldrick      |FWD      |    100|         5.5|       5.2|        6.0|         0.5|
|Bryan           |DEF      |     29|         4.0|       3.9|        4.5|         0.5|
|Armstrong       |MID      |    115|         5.5|       5.5|        6.0|         0.5|
|Vestergaard     |DEF      |     86|         4.5|       4.7|        5.0|         0.5|
|Ward-Prowse     |MID      |    156|         6.0|       5.9|        6.5|         0.5|
|Walker-Peters   |DEF      |     93|         4.5|       4.7|        5.0|         0.5|
|Adams           |FWD      |    137|         6.0|       5.7|        6.5|         0.5|
|Tella           |MID      |     36|         4.5|       4.3|        5.0|         0.5|
|Callum Robinson |FWD      |     79|         5.5|       5.2|        6.0|         0.5|
|Bartley         |DEF      |     79|         4.5|       4.4|        5.0|         0.5|
|Johnstone       |GK       |    140|         4.5|       4.6|        5.0|         0.5|
|Furlong         |DEF      |     79|         4.5|       4.5|        5.0|         0.5|
|Pereira         |MID      |    153|         6.0|       5.4|        6.5|         0.5|
|Antonio         |FWD      |    118|         6.5|       6.7|        7.0|         0.5|
|Johnson         |DEF      |     25|         4.0|       3.9|        4.5|         0.5|
|Dawson          |DEF      |     75|         4.5|       4.5|        5.0|         0.5|
|Kilman          |DEF      |     58|         4.0|       3.8|        4.5|         0.5|
|Neto            |MID      |    124|         5.5|       5.5|        6.0|         0.5|

# Fallers

|player          |position | points| start_price| end_price| next_price| price_boost|
|:---------------|:--------|------:|-----------:|---------:|----------:|-----------:|
|David Luiz      |DEF      |     41|         5.5|       5.4|        5.0|        -0.5|
|Cédric          |DEF      |     28|         5.0|       4.6|        4.5|        -0.5|
|Xhaka           |MID      |     70|         5.5|       5.2|        5.0|        -0.5|
|Ødegaard        |MID      |     40|         6.0|       5.6|        5.5|        -0.5|
|Lallana         |MID      |     58|         6.5|       6.2|        6.0|        -0.5|
|Jahanbakhsh     |MID      |     24|         5.5|       5.4|        5.0|        -0.5|
|Tarkowski       |DEF      |    109|         5.5|       5.3|        5.0|        -0.5|
|Rodriguez       |FWD      |     54|         6.0|       5.7|        5.5|        -0.5|
|Barnes          |FWD      |     52|         6.0|       6.0|        5.5|        -0.5|
|Giroud          |FWD      |     47|         7.0|       6.7|        6.5|        -0.5|
|Alonso          |DEF      |     57|         6.0|       5.6|        5.5|        -0.5|
|Kovacic         |MID      |     54|         5.5|       5.3|        5.0|        -0.5|
|Arrizabalaga    |GK       |     26|         5.0|       4.7|        4.5|        -0.5|
|Ziyech          |MID      |     70|         8.0|       7.9|        7.5|        -0.5|
|Abraham         |FWD      |     69|         7.5|       7.1|        7.0|        -0.5|
|Havertz         |MID      |     91|         8.5|       8.3|        8.0|        -0.5|
|Batshuayi       |FWD      |     41|         6.0|       5.7|        5.5|        -0.5|
|McArthur        |MID      |     45|         5.5|       5.2|        5.0|        -0.5|
|Townsend        |MID      |     94|         6.0|       5.5|        5.5|        -0.5|
|Milivojevic     |MID      |     63|         6.0|       5.6|        5.5|        -0.5|
|van Aanholt     |DEF      |     54|         5.5|       5.4|        5.0|        -0.5|
|Ayew            |FWD      |     70|         6.0|       5.6|        5.5|        -0.5|
|André Gomes     |MID      |     48|         5.5|       5.3|        5.0|        -0.5|
|Iwobi           |MID      |     65|         6.0|       5.9|        5.5|        -0.5|
|Davies          |MID      |     47|         5.5|       5.2|        5.0|        -0.5|
|Richarlison     |FWD      |    123|         8.0|       7.7|        7.5|        -0.5|
|Allan           |MID      |     47|         5.5|       5.2|        5.0|        -0.5|
|Loftus-Cheek    |MID      |     66|         6.0|       5.9|        5.5|        -0.5|
|Cairney         |MID      |     27|         5.5|       5.2|        5.0|        -0.5|
|Mitrović        |FWD      |     63|         6.0|       5.5|        5.5|        -0.5|
|Schmeichel      |GK       |    128|         5.5|       5.4|        5.0|        -0.5|
|Pereira         |DEF      |     27|         6.0|       5.9|        5.5|        -0.5|
|Pérez           |MID      |     58|         6.5|       6.0|        6.0|        -0.5|
|Söyüncü         |DEF      |     59|         5.5|       5.3|        5.0|        -0.5|
|Milner          |MID      |     44|         5.5|       5.3|        5.0|        -0.5|
|Shaqiri         |MID      |     26|         6.5|       6.4|        6.0|        -0.5|
|Fabinho         |MID      |     71|         5.5|       5.4|        5.0|        -0.5|
|Gomez           |DEF      |     10|         5.5|       5.2|        5.0|        -0.5|
|Keita           |MID      |     15|         5.5|       5.2|        5.0|        -0.5|
|Thiago          |MID      |     55|         6.0|       5.5|        5.5|        -0.5|
|De Bruyne       |MID      |    141|        11.5|      11.8|       11.0|        -0.5|
|Aké             |DEF      |     29|         5.5|       5.4|        5.0|        -0.5|
|Laporte         |DEF      |     58|         6.0|       6.0|        5.5|        -0.5|
|Bernardo Silva  |MID      |     94|         7.5|       7.4|        7.0|        -0.5|
|Mata            |MID      |     32|         6.0|       5.8|        5.5|        -0.5|
|de Gea          |GK       |     91|         5.5|       5.3|        5.0|        -0.5|
|Fred            |MID      |     69|         5.5|       5.3|        5.0|        -0.5|
|Henderson       |GK       |     44|         5.5|       5.2|        5.0|        -0.5|
|Bailly          |DEF      |     31|         5.0|       4.8|        4.5|        -0.5|
|James           |MID      |     43|         6.5|       6.2|        6.0|        -0.5|
|Telles          |DEF      |     25|         5.5|       5.3|        5.0|        -0.5|
|Shelvey         |MID      |     74|         5.5|       5.3|        5.0|        -0.5|
|Fernández       |DEF      |     53|         5.0|       4.7|        4.5|        -0.5|
|Gayle           |FWD      |     31|         6.0|       5.9|        5.5|        -0.5|
|Hayden          |MID      |     40|         5.0|       4.6|        4.5|        -0.5|
|Fraser          |MID      |     39|         6.0|       5.6|        5.5|        -0.5|
|Sharp           |FWD      |     39|         6.0|       5.5|        5.5|        -0.5|
|Basham          |DEF      |     51|         5.0|       4.6|        4.5|        -0.5|
|Fleck           |MID      |     70|         6.0|       5.6|        5.5|        -0.5|
|Norwood         |MID      |     54|         5.0|       4.5|        4.5|        -0.5|
|Baldock         |DEF      |     63|         5.5|       4.9|        5.0|        -0.5|
|Egan            |DEF      |     57|         5.0|       4.7|        4.5|        -0.5|
|Lundstram       |MID      |     48|         5.5|       4.8|        5.0|        -0.5|
|McBurnie        |FWD      |     44|         6.0|       5.6|        5.5|        -0.5|
|Minamino        |MID      |     48|         6.5|       6.0|        6.0|        -0.5|
|Redmond         |MID      |     67|         6.5|       6.4|        6.0|        -0.5|
|Stephens        |DEF      |     41|         5.0|       4.6|        4.5|        -0.5|
|Sissoko         |MID      |     44|         5.0|       4.7|        4.5|        -0.5|
|Lamela          |MID      |     28|         6.0|       5.7|        5.5|        -0.5|
|Dier            |DEF      |     77|         5.0|       4.6|        4.5|        -0.5|
|Lucas Moura     |MID      |     80|         7.0|       6.4|        6.5|        -0.5|
|Winks           |MID      |     19|         5.5|       5.1|        5.0|        -0.5|
|Sánchez         |DEF      |     43|         5.5|       5.2|        5.0|        -0.5|
|Doherty         |DEF      |     47|         6.0|       5.6|        5.5|        -0.5|
|Livermore       |MID      |     25|         5.0|       4.7|        4.5|        -0.5|
|Sawyers         |MID      |     33|         5.0|       4.6|        4.5|        -0.5|
|Ajayi           |DEF      |     51|         5.0|       4.8|        4.5|        -0.5|
|Snodgrass       |MID      |     14|         6.0|       5.6|        5.5|        -0.5|
|Diangana        |MID      |     39|         5.5|       5.0|        5.0|        -0.5|
|Grant           |FWD      |     41|         6.0|       5.6|        5.5|        -0.5|
|Noble           |MID      |     27|         5.0|       4.5|        4.5|        -0.5|
|Lanzini         |MID      |     28|         6.5|       6.4|        6.0|        -0.5|
|Haller          |FWD      |     41|         6.5|       6.1|        6.0|        -0.5|
|Moutinho        |MID      |     73|         5.5|       5.1|        5.0|        -0.5|
|Boly            |DEF      |     68|         5.5|       5.4|        5.0|        -0.5|
|Traoré          |MID      |     94|         6.5|       6.0|        6.0|        -0.5|
|Marçal          |DEF      |     19|         5.0|       4.7|        4.5|        -0.5|
|Willian         |MID      |     78|         8.0|       7.5|        7.0|        -1.0|
|Werner          |FWD      |    128|         9.5|       9.2|        8.5|        -1.0|
|Pulisic         |MID      |     82|         8.5|       8.3|        7.5|        -1.0|
|Firmino         |FWD      |    141|         9.5|       9.1|        8.5|        -1.0|
|Mané            |MID      |    176|        12.0|      11.8|       11.0|        -1.0|
|Jesus           |FWD      |    115|         9.5|       9.1|        8.5|        -1.0|
|Pogba           |MID      |     92|         8.0|       7.6|        7.0|        -1.0|
|Martial         |FWD      |     75|         9.0|       8.6|        8.0|        -1.0|
|van de Beek     |MID      |     32|         7.0|       6.6|        6.0|        -1.0|
|Stevens         |DEF      |     56|         5.5|       5.0|        4.5|        -1.0|
|Alli            |MID      |     30|         8.0|       7.4|        7.0|        -1.0|
|Bergwijn        |MID      |     55|         7.5|       7.0|        6.5|        -1.0|
|Lo Celso        |MID      |     35|         7.0|       6.9|        6.0|        -1.0|
|Jiménez         |FWD      |     43|         8.5|       8.1|        7.5|        -1.0|
|Willian José    |FWD      |     40|         7.0|       6.8|        6.0|        -1.0|
|Agüero          |FWD      |     38|        10.5|      10.3|        9.0|        -1.5|
|Sterling        |MID      |    154|        11.5|      10.9|       10.0|        -1.5|
|Aubameyang      |MID      |    131|        12.0|      11.3|       10.0|        -2.0|