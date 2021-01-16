# Comparative Campaign Dynamics Project Data Transformation

<p align="center">
<img src="figures/countries.png" width="250">
</p>

## Description

The [Comparative Campaign Dynamics Project](https://www.mzes.uni-mannheim.de/d7/en/datasets/comparative-campaign-dynamics-dataset) offers an amazing data set about the statements political parties make about themselves (*subject statements*) and other parties (*other statements*) during election campaigns (Classified as the one month period before an election except for Portugal where it is the two weeks period). The data set includes campaign statements by parties in two elections each in ten European countries. Coded are all election-relevant statements that were reported in the largest left-leaning and right-leaning daily broadsheet newspapers in a country. 

The CCDP provides data sets on its website that has newspaper articles about political parties as the unit of observation. Since the unit of analysis in social science research is rarely a newspaper article the data needs to be recoded for most projects. In this repository I provide code that cleans and transforms the data that the CCDP makes publicly available on its website to allow for social science analysis of party issue or valence discussions during election campaigns. I also add the widely used party identifier codes from the Comparative Manifesto Project so researchers can easily integrate ideological positions and election results for their analysis. Feel free to use the R script and processed data for your academic research. Issues in the code or data set can be reported through the GitHub page. 

**If you use the data set please add the following data citation to your manuscript:**

*Debus, Marc, Zeynep Somer-Topcu, and Margit Tavits. 2018. Comparative Campaign Dynamics Dataset. Mannheim: Mannheim Centre for European Social Research, University of Mannheim.*


## Content
1. The [ccd_crosswalk.csv](./data_raw/ccd_crosswalk.csv) file in the ``data_raw`` folder matches the Comparative Campaign Dynamics Project (CCDP) party identifier codes with the more widely used party identifier codes from the Comparative Manifesto Project (CMP). Researchers can use the CMP to extend the data set with ideological positions, election results, seat shares and more. 
2. The [ccdp_transformation.R](./scripts/ccdp_transformation.R) script in the ``scripts`` folder downloads the CCDP data and transforms it into three data sets that have parties in elections as the unit of observation. The script is annotated and each transformation is explained. Cleaning and coding are conducted such that they should be straightforward to understand and the R script works as a codebook. 
3. The ``data_processed`` folder holds three csv's that count the issue statements, issue-direction statements, issue-valence statements, and valence statements of political parties in elections. The [self_statements.csv](./data_processed/self_statements.csv) includes counts of all statements a political party made about itself. The [other_statements.csv](./data_processed/other_statements.csv) includes all statements a party made about and received from other political parties. The [combined_statements.csv](./data_processed/combined_statements.csv) combines the self_statements.csv and the other_statements.csv. The R script also includes code that will generate Stata 13 .dta files that can be uncommented and used.

## Variables in the data sets
The data sets in this repository provide the following data about party statements:
1. Issue position statements by parties about themselves and other parties.
2. Issue direction statements by parties about themselves and other parties.
3. Issue valence statements by parties about themselves and other parties.
4. Valence statements by parties about themselves and other parties.


## Countries, Elections, and Newspapers in the CCDP Data
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

## External Content
1. [CCDP Data sets](https://www.mzes.uni-mannheim.de/d7/en/datasets/comparative-campaign-dynamics-dataset)
2. [CCDP Codebook](http://www.mzes.uni-mannheim.de/publications/wp/wp-167.pdf)