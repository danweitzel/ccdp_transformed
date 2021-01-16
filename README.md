# Comparative Campaign Dynamics Project Data Transformation

The [Comparative Campaign Dynamics Project](https://www.mzes.uni-mannheim.de/d7/en/datasets/comparative-campaign-dynamics-dataset) offers an amazing data set about the statements political parties make about themselves (subject statements) and other parties (other statements) during election campaigns (Classified as the one month period before an election except for Portugal where it is the two weeks period). The data set includes campaign statements by parties in two elections each in ten European countries. 

In this repository I provide code that cleans and transforms the data that the CCDP makes publicly available on its website and makes it ready for social science analysis of party issue or valence discussions during election campaigns. Feel free to use the R script and processed data for your academic research. Issues in the code or data set can be reported through the GitHub page. 

**If you use the data set please use the following data citation:**

*Debus, Marc, Zeynep Somer-Topcu, and Margit Tavits. 2018. Comparative Campaign Dynamics Dataset. Mannheim: Mannheim Centre for European Social Research, University of Mannheim.*


| Country  |  Elections | Left-leaning Newspaper  | Right-leaning Newspaper  |
|---|---|---|---|
|Czech Republic |2010, 2013 |Právo |Mladá fronta Dnes |
|Denmark |2007, 2011 |Politiken |Jyllands-Posten |
|Germany |2009, 2013 | Süddeutsche Zeitung | Frankfurter Allgemeine |
|Hungary  | 2006, 2010|Népszabadság |Magyar Nemze |
|The Netherlands  | 2010, 2012 |de Volkskrant |De Telegraaf |
|Poland | 2007, 2011 |Gazeta Wyborcza | Rzeczpospolita|
|Portugal | 2009, 2011 | Público| Jornal de Notícias|
|Spain | 2008, 2011  |El País |El Mundo |
|Sweden |2010, 2014 | Dagens Nyheter| Aftonbladet|
|United Kingdom | 2005, 2010, 2015 | The Guardian| The Daily Telegraph |



The data sets in this repository provide the following data about party statements:
1. Issue position statements by parties about themselves and other parties.
2. Issue direction statements by parties about themselves and other parties.
3. Issue valence statements by parties about themselves and other parties.
4. Valence statements by parties about themselves and other parties.

In this respository I provide the code to transform the raw CCDP data set to a data set ready for analysis by social scientists. 

## Content
1. Scripts folder: Holds the script that downloads the CCDP data and transforms it to party election and party-pair election data 
2. 
