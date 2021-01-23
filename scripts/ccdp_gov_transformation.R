#####################################################################################
##
##    File Name:        ccd_gov_transformation.R
##    Date:             2021-01-20
##    Author:           Daniel Weitzel
##    Email:            daniel.weitzel@univie.ac.at
##    Webpage:          www.danweitzel.net
##    Purpose:          Issue, Issue valence, and valence counts for self and other data
##    Date Used:        2021-01-23
##    Data Used:        "Self_03oct2016.dta" and "Other_03oct2016.dta"
##    Output File:      (none)
##    Data Output:      See end of file
##    Data Webpage:     (none)
##    Log File:         (none)
##    Notes:            (none)
##
#####################################################################################

## Setting working directory
setwd(githubdir)
setwd("ccdp_transformed")

## This loads the required packages, if they are not installed it also installs them
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, readstata13)

## Load the Comparative Campaign Dynamics Self and Other data from the website
df_self <- read.dta13("https://www.mzes.uni-mannheim.de/projekte/where_my_party/data/Self_v1.dta") %>% 
  rename(country_code = country,
         year = year_month)
df_other <- read.dta13("https://www.mzes.uni-mannheim.de/projekte/where_my_party/data/Other_v1.dta") %>% 
  rename(country_code = country,
         year = year_month)

## Load the party crosswalk. This file includes country, year, CCDP party code, and CCDP party name
## The code below prepares a subject (the party speaking in a dyad) and an other (the party being targeted in a dyad) file
## In the end it generates the dyadic party data set called ccd_parties. Other party files are dropped.
## The ccd_crosswalk.csv was manually coded

## Subject codes, this is the party making statements in the data

ccd_subjects <- read_csv("data_raw/ccd_crosswalk.csv") %>% 
  rename(country_code = country, 
         country_name = cmp_country_name, 
         subject_id   = cp_party,
         subject_name = cp_name,
         subject_cmp_code = cmp_code, 
         subject_parlgov_code = parlgov_code, 
         subject_poll_id = poll_pid, 
         subject_miguel_id = miguel_code, 
         subject_cses_imd = cses_imd) %>%
  dplyr::select(-c(cses_code)) %>% 
  filter(!(subject_id == 6 & country_code == "UK"))

## Other codes, this is the party receiving statements in the data
ccd_other <- read_csv("data_raw/ccd_crosswalk.csv") %>% 
  rename(country_code = country, 
         country_name = cmp_country_name, 
         other_id     = cp_party,
         other_name   = cp_name,
         other_cmp_code = cmp_code, 
         other_parlgov_code = parlgov_code, 
         other_poll_id = poll_pid, 
         other_miguel_id = miguel_code, 
         other_cses_imd = cses_imd) %>% 
  dplyr::select(-c(cses_code)) %>% 
  filter(!(other_id == 6 & country_code == "UK"))

## Merging subject and other codes in order to generate a dyadic data set of party pairs
ccd_parties <-
  ccd_subjects %>% 
  full_join(ccd_other, by = c("country_code", "country_name", "ccode", "year"))


################################################################
## Preparing the CCDP data set. 
## df_self contains all self statements a party made
## df_other contains all statements a party made about other actors
## Throughout this script: subject refers to speaking party, other to party being addressed


# SELF DATA SET - party speaking about itself

## This script prepares the self data set for transformation. 
## I drop any instance where there is no subject party, reduce the data set to the variables I need
## and rename the statement_type variables by making it lower case and separating its components by _
df_self <-
  df_self %>% 
  drop_na(subject) %>% 
  dplyr::select(country_code, year, subject, statement_type, var_value, direction, valen_issue,socialPol, socialPol_spend_dir) %>% 
  mutate(statement_type = str_to_lower(statement_type),
         statement_type = str_replace(statement_type, "issue", "_issue"),
         statement_type = str_replace(statement_type, "val", "_val"),
         var_value = ifelse(var_value == 2 & statement_type == "self_issue", paste(var_value, socialPol, sep = "_"), var_value)) %>% 
  rename(subject_id = subject)

## This code generates a new data set with the counts of each issue statement
## Each row is a party in an election, the issues that a party talks about itself are called self_issue_#
## where _# stands for the issue code in the CCDP code book. 
self_issue <-
  df_self %>% 
  filter(statement_type == "self_issue") %>% 
  dplyr::select(country_code, year, subject_id, statement_type, var_value) %>% 
  group_by(country_code, year, subject_id, statement_type, var_value) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value) %>% 
  pivot_wider(id = c(country_code, year, subject_id), names_from = c(statement_type, var_value), 
              names_sep = "_", values_from = n, values_fill = 0) 

## This code generates a new data set with issue statements and their direction
## Parties can talk about issues in a positive (pos), negative (neg), neutral (neu) or contradictory (con) nature
## When the issue is about social policy they can talk about the spending direction of the social policy issue
## which can be increasing, decreasing, neutral or contradictory (sp_inc, sp_dec, sp_neu, sp_con).
## The variables in this data set are called sel_issue_#_%
## where # stands for the issue number as specified in the code book (similar to data set above) and % stands for the direction
self_issue_direction <-
  df_self %>% 
  filter(statement_type == "self_issue") %>% 
  dplyr::select(country_code, year, subject_id, statement_type, var_value, direction, socialPol_spend_dir) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", 
                                          ifelse(direction == 99, "cont",
                                                 ifelse(is.na(direction), "none", NA))))),
         direction = ifelse(is.na(direction) & socialPol_spend_dir == -1, "sp_dec",
                            ifelse(is.na(direction) & socialPol_spend_dir == 0, "sp_neu",
                                   ifelse(is.na(direction) & socialPol_spend_dir == 1, "sp_inc",
                                          ifelse(is.na(direction) & socialPol_spend_dir == 99, "sp_con", direction)))),
         direction = ifelse(is.na(direction) & is.na(socialPol_spend_dir), "none", direction)) %>% 
  dplyr::select(-socialPol_spend_dir) %>% 
  group_by(country_code, year, subject_id, statement_type, var_value, direction) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value) %>% 
  pivot_wider(id = c(country_code, year, subject_id), names_from = c(statement_type, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(self_issue_total = rowSums(dplyr::select(., starts_with("self_issue"))))

## This code generates a new data set with issue valence statements and their direction
## Parties can also talk about valence attributes associated with an issue 
## The valence attributes can be about party honesty (phon), party competence (pcom), party unity (puni)
## leader honesty (lhon), leader competence (lcom), leader character (lcha), and other (other)
## each valence statement can be in a positive (pos), negative (neg), neutral (neu), or contradictory (con) direction.
## There can also be no direction of the valence statement (none)
## The variables are called self_issue_val_#_@_%, where self_issue_val refers to all self issue valence statements and
## # is the issue number from the CCDP, @ refers to the type of valence statement, and % is (as before) the direction of the 
## valence statemwent
self_issue_valence <-
  df_self %>% 
  filter(statement_type == "self_issue_val") %>% 
  dplyr::select(country_code, year, subject_id, statement_type, var_value, valen_issue, direction,socialPol_spend_dir) %>% 
  arrange(valen_issue, var_value) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", 
                                          ifelse(direction == 99, "cont",
                                                 ifelse(is.na(direction), "none", NA))))),
         var_value = ifelse(var_value == 1, "phon",
                            ifelse(var_value == 2, "pcom",
                                   ifelse(var_value == 3, "puni",
                                          ifelse(var_value == 4, "lhon",
                                                 ifelse(var_value == 5, "lcom",
                                                        ifelse(var_value == 6, "lcha",
                                                               ifelse(var_value == 7, "other", NA)))))))) %>% 
  group_by(country_code, year, subject_id, statement_type, var_value, valen_issue, direction) %>% 
  add_count %>% 
  unique %>% 
  pivot_wider(id = c(country_code, year, subject_id), names_from = c(statement_type, valen_issue, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(self_issue_val_total = rowSums(dplyr::select(., starts_with("self_issue"))))


## This code generates a self valence data set with direction
## Parties can not only make valence statementsabout themselves related to issues but also just valence statements about themselves
## These are coded ad self_val_% variables in the data set below. self_val_ refers to all statements by a aprty about its own nonissue related valence
## % is the direction of that statement, which can be positive (pos), negative (neg), or neutral.
self_val <-
  df_self %>% 
  filter(statement_type == "self_val") %>% 
  dplyr::select(country_code, year, subject_id, statement_type, var_value, direction) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", NA)))) %>% 
  group_by(country_code, year, subject_id, statement_type, var_value, direction) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value, direction) %>% 
  pivot_wider(id = c(country_code, year, subject_id), names_from = c(statement_type, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(self_val_total = rowSums(dplyr::select(., starts_with("self_val"))))


## This code merges all the data sets and generates a new data set called df_self_transformed
## It includes all types of self statements (issue, issue direction, issue valence and valence)
## all missing values are replaced with 0
df_self_transformed <-
  ccd_subjects %>% 
  left_join(self_issue) %>% 
  left_join(self_issue_direction) %>% 
  left_join(self_issue_valence) %>% 
  left_join(self_val) %>% 
  mutate_if(is.numeric , replace_na, replace = 0) %>% 
  as.data.frame()

## This takes all government codes and replaces them with the CP party codes of the parties in government
## This means that any statement by or about a government party are added to the total of the counts of the parties in government
gov_subject_self <- 
  df_self_transformed %>% 
  mutate(government_cp_code = ifelse(country_code == "DE" & year == 2009 & subject_id== 10, "3,4",
                                     ifelse(country_code == "DE" & year == 2013 & subject_id== 10, "3,5",
                                            ifelse(country_code == "CZ" & year == 2010	& subject_id== 9, "1,2",
                                                   ifelse(country_code == "CZ" & year == 2013	& subject_id== 9, "2,5",
                                                          ifelse(country_code == "DK" & year == 2007	& subject_id== 10, "1,5",
                                                                 ifelse(country_code == "DK" & year == 2011	& subject_id== 10, "1,5",
                                                                        ifelse(country_code == "HU" & year == 2006	& subject_id== 9, "4,6",
                                                                               ifelse(country_code == "HU" & year == 2010	& subject_id== 9, "4",
                                                                                      ifelse(country_code == "PL" & year == 2007	& subject_id== 9, "1,6,5",
                                                                                             ifelse(country_code == "PL" & year == 2011	& subject_id== 9, "2,4",
                                                                                                    ifelse(country_code == "SV" & year == 2010 & subject_id== 11, "6,4,5,7",
                                                                                                           ifelse(country_code == "SV" & year == 2014	& subject_id== 11, "6,4,5,7",
                                                                                                                  ifelse(country_code == "NL" & year == 2010	& subject_id== 11, "2,1",
                                                                                                                         ifelse(country_code == "NL" & year == 2012	& subject_id== 11, "3,2",
                                                                                                                                ifelse(country_code == "UK" & year == 2015	& subject_id== 6,	"3,2", NA)))))))))))))))) %>% 
  ungroup() %>% 
  filter(str_detect(subject_name, 'gov')) %>% 
  select(-subject_id) %>% 
  separate(government_cp_code, into = c("party1", "party2", "party3", "party4"), sep=",") %>% 
  pivot_longer(cols = starts_with("party"), names_to = "label", values_to = "subject_id") %>% 
  filter(!is.na(subject_id)) %>% 
  select(-c(label, subject_name, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd)) %>% 
  mutate(subject_id = as.numeric(subject_id))


df_self_transformed <-
  df_self_transformed %>% 
  filter(!str_detect(subject_name, 'gov')) %>% 
  dplyr::select(-c(subject_name, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd)) %>% 
  rbind(gov_subject_self) %>% 
  group_by(country_code, country_name, year, subject_id) %>% 
  summarise_all(funs(sum)) %>%
  left_join(ccd_subjects)

## Exporting the self data set
#write_csv(df_self_transformed, "data_processed/self_statements_gov.csv")
#save.dta13(df_self_transformed, "data_processed/self_statements_gov.dta")

rm(gov_subject_self)

################################
# OTHER DATA SET - party (subject) speaking about another party (other)

## All data sets and variables are coded in the same way the self data set was coded. Instead of self_ all variables start with other_
## Important difference: All of the "other" data sets are inherently dyadic. It is always a subject (speaking party) and other (receiving party) pair


## Preparing the other data set for transformation by reducing the data set size and transforming key variables
df_other <-
  df_other %>% 
  dplyr::select(country_code, year, subject, other, statement_type, var_value, direction, valen_issue, socialPol, socialPol_spend_dir)  %>% 
  mutate(statement_type = str_to_lower(statement_type),
         statement_type = str_replace(statement_type, "issue", "_issue"),
         statement_type = str_replace(statement_type, "val", "_val"),
         var_value = ifelse(var_value == 2 & statement_type == "other_issue", paste(var_value, socialPol, sep = "_"), var_value)) %>% 
  rename(subject_id = subject,
         other_id = other)

## Generating an issue data set based on the other data
## This code generates a new data set with the counts of each issue statement
## Each row is a subject-other pair in an election, the issues that the subject party talks about the other party are called other_issue_#
## where _# stands for the issue code in the CCDP code book. 
other_issue <-
  df_other %>% 
  filter(statement_type == "other_issue") %>% 
  dplyr::select(country_code, year, subject_id, other_id, statement_type, var_value) %>% 
  group_by(country_code, year, subject_id, other_id,statement_type, var_value) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value) %>% 
  pivot_wider(id = c(country_code, year, subject_id, other_id), names_from = c(statement_type, var_value), 
              names_sep = "_", values_from = n, values_fill = 0) 


## Generating an issue direction data set based on the other data set
## This code generates a new data set with issue statements and their direction
## Parties can talk about issues in a positive (pos), negative (neg), neutral (neu) or contradictory (con) nature
## When the issue is about social policy they can talk about the spending direction of the social policy issue
## which can be increasing, decreasing, neutral or contradictory (sp_inc, sp_dec, sp_neu, sp_con).
## The variables in this data set are called other_issue_#_%
## where # stands for the issue number as specified in the code book (similar to data set above) and % stands for the direction
## Once more each row is a subject-other pair in an election.
other_issue_direction <-
  df_other %>% 
  filter(statement_type == "other_issue") %>% 
  dplyr::select(country_code, year, subject_id, other_id, statement_type, var_value, direction, socialPol_spend_dir) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", 
                                          ifelse(direction == 99, "cont",
                                                 ifelse(is.na(direction), "none", NA))))),
         direction = ifelse(is.na(direction) & socialPol_spend_dir == -1, "sp_dec",
                            ifelse(is.na(direction) & socialPol_spend_dir == 0, "sp_neu",
                                   ifelse(is.na(direction) & socialPol_spend_dir == 1, "sp_inc",
                                          ifelse(is.na(direction) & socialPol_spend_dir == 99, "sp_con", direction)))),
         direction = ifelse(is.na(direction) & is.na(socialPol_spend_dir), "none", direction)) %>%
  dplyr::select(-socialPol_spend_dir) %>% 
  group_by(country_code, year, subject_id, other_id, statement_type, var_value, direction) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value) %>% 
  pivot_wider(id = c(country_code, year, subject_id, other_id), names_from = c(statement_type, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(other_issue_total = rowSums(dplyr::select(., starts_with("other_issue"))))

## Generating an other issue valence statement data set with directions
## This code generates a new data set with issue valence statements and their direction
## Parties can talk about other parties valence attributes associated with an issue 
## The valence attributes can be about that other party's: party honesty (phon), party competence (pcom), party unity (puni)
## leader honesty (lhon), leader competence (lcom), leader character (lcha), and other (other)
## each valence statement can be in a positive (pos), negative (neg), neutral (neu), or contradictory (con) direction.
## There can also be no direction of the valence statement (none)
## The variables are called other_issue_val_#_@_%, where other_issue_val refers to all issue valence statements the subject makes about other parties 
## and # is the issue number from the CCDP, @ refers to the type of valence statement, and % is (as before) the direction of the 
## valence statement
other_issue_valence <-
  df_other %>% 
  filter(statement_type == "other_issue_val") %>% 
  dplyr::select(country_code, year, subject_id, other_id, statement_type, var_value, valen_issue, direction) %>% 
  arrange(valen_issue, var_value) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", 
                                          ifelse(direction == 99, "cont",
                                                 ifelse(is.na(direction), "none", NA))))),
         var_value = ifelse(var_value == 1, "phon",
                            ifelse(var_value == 2, "pcom",
                                   ifelse(var_value == 3, "puni",
                                          ifelse(var_value == 4, "lhon",
                                                 ifelse(var_value == 5, "lcom",
                                                        ifelse(var_value == 6, "lcha",
                                                               ifelse(var_value == 7, "other", NA)))))))) %>% 
  group_by(country_code, year, subject_id, other_id, statement_type, var_value, valen_issue, direction) %>% 
  add_count %>% 
  unique %>% 
  pivot_wider(id = c(country_code, year, subject_id, other_id), names_from = c(statement_type, valen_issue, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(other_issue_val_total = rowSums(dplyr::select(., starts_with("other_issue"))))


## Generating an "other" valence statement data set with directions
## This code generates an "other" valence data set with direction
## Parties can not only make valence statements about other parties related to issues but also just valence statements about those other actors
## These are coded ad other_val_% variables in the data set below. other_val_ refers to all statements by a party about ianother party's nonissue related valence
## % is the direction of that statement, which can be positive (pos), negative (neg), or neutral.
other_val <-
  df_other %>% 
  filter(statement_type == "other_val") %>% 
  dplyr::select(country_code, year, subject_id, other_id, statement_type, var_value, direction) %>% 
  mutate(direction = ifelse(direction == 1, "pos", 
                            ifelse(direction == -1, "neg",
                                   ifelse(direction == 0, "neu", NA)))) %>% 
  group_by(country_code, year, subject_id, other_id, statement_type, var_value, direction) %>% 
  add_count %>% 
  unique %>% 
  arrange(var_value, direction) %>% 
  pivot_wider(id = c(country_code, year, subject_id, other_id), names_from = c(statement_type, var_value, direction), 
              names_sep = "_", values_from = n, values_fill = 0) %>% 
  ungroup %>% 
  rename_with(., ~ tolower(gsub("NA", "none", .x, fixed = TRUE))) %>% 
  mutate(other_val_total = rowSums(dplyr::select(., starts_with("other_val"))))

## Merging together all the other data sets and generating a new data set called df_other_transformed
df_other_transformed <-
  ccd_parties %>% 
  left_join(other_issue) %>% 
  left_join(other_issue_direction) %>% 
  left_join(other_issue_valence) %>% 
  left_join(other_val) %>% 
  mutate_if(is.numeric , replace_na, replace = 0) %>% 
  as.data.frame()

### This code flips subject and other. All statements are now changed from issued to received. 
### This means that the final data set will include the number of statements a party issued about other parties
### and also includes the number of statements a party received from other parties. Those variables are coded and named 
## identically to the waydescribed above. All of these variables start with rec_ and can be identified with this prefix,
df_other_transformed_receive <-
  df_other_transformed %>% 
  dplyr::select(-c(country_name, subject_name, other_name,
                   subject_name, subject_cmp_code, subject_parlgov_code,     
                   subject_poll_id, subject_miguel_id, subject_cses_imd,
                   other_name, other_cmp_code, other_parlgov_code,     
                   other_poll_id, other_miguel_id, other_cses_imd)) %>% 
  mutate(other2 = subject_id,
         subject2 = other_id) %>% 
  dplyr::select(-c(other_id, subject_id)) %>% 
  rename(other_id = other2,
         subject_id = subject2) %>% 
  rename_at(vars(starts_with('other_')), ~paste0('rec_',.)) %>% 
  rename(other_id = rec_other_id) %>% 
  dplyr::select(country_code, year, subject_id, other_id, everything()) %>% 
  as.data.frame()


## Joining the sending and receiving statements data sets in order to make a large, combined subject-other data set
df_other_transformed <-
  df_other_transformed %>% 
  left_join(df_other_transformed_receive)


gov_other <- 
  df_other_transformed %>% 
  mutate(government_cp_code = ifelse(country_code == "DE" & year == 2009 & other_id == 10, "3,4",
                                     ifelse(country_code == "DE" & year == 2013 & other_id == 10, "3,5",
                                            ifelse(country_code == "CZ" & year == 2010	& other_id == 9, "1,2",
                                                   ifelse(country_code == "CZ" & year == 2013	& other_id == 9, "2,5",
                                                          ifelse(country_code == "DK" & year == 2007	& other_id == 10, "1,5",
                                                                 ifelse(country_code == "DK" & year == 2011	& other_id == 10, "1,5",
                                                                        ifelse(country_code == "HU" & year == 2006	& other_id == 9, "4,6",
                                                                               ifelse(country_code == "HU" & year == 2010	& other_id == 9, "4",
                                                                                      ifelse(country_code == "PL" & year == 2007	& other_id == 9, "1,6,5",
                                                                                             ifelse(country_code == "PL" & year == 2011	& other_id == 9, "2,4",
                                                                                                    ifelse(country_code == "SV" & year == 2010 & other_id == 11, "6,4,5,7",
                                                                                                           ifelse(country_code == "SV" & year == 2014	& other_id == 11, "6,4,5,7",
                                                                                                                  ifelse(country_code == "NL" & year == 2010	& other_id == 11, "2,1",
                                                                                                                         ifelse(country_code == "NL" & year == 2012	& other_id == 11, "3,2",
                                                                                                                                ifelse(country_code == "UK" & year == 2015	& other_id == 6,	"3,2", NA)))))))))))))))) %>% 
  ungroup() %>% 
  filter(str_detect(other_name, 'gov')) %>% 
  filter(!str_detect(subject_name, 'gov')) %>% 
  select(-other_id, subject_name, other_name) %>% 
  separate(government_cp_code, into = c("party1", "party2", "party3", "party4"), sep=",") %>% 
  pivot_longer(cols = starts_with("party"), names_to = "label", values_to = "other_id") %>% 
  filter(!is.na(other_id)) %>% 
  dplyr::select(-c(label, subject_name, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd,
                   other_name, other_cmp_code, other_parlgov_code, other_poll_id, other_miguel_id, other_cses_imd)) %>% 
  mutate(subject_id = as.numeric(subject_id),
         other_id = as.numeric(other_id))


gov_subject_other <- 
  df_other_transformed %>% 
  mutate(government_cp_code = ifelse(country_code == "DE" & year == 2009 & subject_id == 10, "3,4",
                                     ifelse(country_code == "DE" & year == 2013 & subject_id == 10, "3,5",
                                            ifelse(country_code == "CZ" & year == 2010	& subject_id == 9, "1,2",
                                                   ifelse(country_code == "CZ" & year == 2013	& subject_id == 9, "2,5",
                                                          ifelse(country_code == "DK" & year == 2007	& subject_id == 10, "1,5",
                                                                 ifelse(country_code == "DK" & year == 2011	& subject_id == 10, "1,5",
                                                                        ifelse(country_code == "HU" & year == 2006	& subject_id == 9, "4,6",
                                                                               ifelse(country_code == "HU" & year == 2010	& subject_id == 9, "4",
                                                                                      ifelse(country_code == "PL" & year == 2007	& subject_id == 9, "1,6,5",
                                                                                             ifelse(country_code == "PL" & year == 2011	& subject_id == 9, "2,4",
                                                                                                    ifelse(country_code == "SV" & year == 2010 & subject_id == 11, "6,4,5,7",
                                                                                                           ifelse(country_code == "SV" & year == 2014	& subject_id == 11, "6,4,5,7",
                                                                                                                  ifelse(country_code == "NL" & year == 2010	& subject_id == 11, "2,1",
                                                                                                                         ifelse(country_code == "NL" & year == 2012	& subject_id == 11, "3,2",
                                                                                                                                ifelse(country_code == "UK" & year == 2015	& subject_id == 6,	"3,2", NA)))))))))))))))) %>% 
  ungroup() %>% 
  filter(!str_detect(other_name, 'gov')) %>% 
  filter(str_detect(subject_name, 'gov')) %>% 
  select(-subject_id, subject_name, other_name) %>% 
  separate(government_cp_code, into = c("party1", "party2", "party3", "party4"), sep=",") %>% 
  pivot_longer(cols = starts_with("party"), names_to = "label", values_to = "subject_id") %>% 
  filter(!is.na(subject_id)) %>% 
  dplyr::select(-c(label, subject_name, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd,
                   other_name, other_cmp_code, other_parlgov_code, other_poll_id, other_miguel_id, other_cses_imd)) %>% 
  mutate(subject_id = as.numeric(subject_id),
         other_id = as.numeric(other_id))



both_government_other <- 
  df_other_transformed %>% 
  ungroup() %>% 
  filter(str_detect(other_name, 'gov') & str_detect(subject_name, 'gov')) %>% 
  mutate(government_cp_code_subject = ifelse(country_code == "DE" & year == 2009 & subject_id == 10, "3,4",
                                             ifelse(country_code == "DE" & year == 2013 & subject_id == 10, "3,5",
                                                    ifelse(country_code == "CZ" & year == 2010	& subject_id == 9, "1,2",
                                                           ifelse(country_code == "CZ" & year == 2013	& subject_id == 9, "2,5",
                                                                  ifelse(country_code == "DK" & year == 2007	& subject_id == 10, "1,5",
                                                                         ifelse(country_code == "DK" & year == 2011	& subject_id == 10, "1,5",
                                                                                ifelse(country_code == "HU" & year == 2006	& subject_id == 9, "4,6",
                                                                                       ifelse(country_code == "HU" & year == 2010	& subject_id == 9, "4",
                                                                                              ifelse(country_code == "PL" & year == 2007	& subject_id == 9, "1,6,5",
                                                                                                     ifelse(country_code == "PL" & year == 2011	& subject_id == 9, "2,4",
                                                                                                            ifelse(country_code == "SV" & year == 2010 & subject_id == 11, "6,4,5,7",
                                                                                                                   ifelse(country_code == "SV" & year == 2014	& subject_id == 11, "6,4,5,7",
                                                                                                                          ifelse(country_code == "NL" & year == 2010	& subject_id == 11, "2,1",
                                                                                                                                 ifelse(country_code == "NL" & year == 2012	& subject_id == 11, "3,2",
                                                                                                                                        ifelse(country_code == "UK" & year == 2015	& subject_id == 6,	"3,2", NA))))))))))))))),
         government_cp_code_other = ifelse(country_code == "DE" & year == 2009 & other_id == 10, "3,4",
                                           ifelse(country_code == "DE" & year == 2013 & other_id == 10, "3,5",
                                                  ifelse(country_code == "CZ" & year == 2010	& other_id == 9, "1,2",
                                                         ifelse(country_code == "CZ" & year == 2013	& other_id == 9, "2,5",
                                                                ifelse(country_code == "DK" & year == 2007	& other_id == 10, "1,5",
                                                                       ifelse(country_code == "DK" & year == 2011	& other_id == 10, "1,5",
                                                                              ifelse(country_code == "HU" & year == 2006	& other_id == 9, "4,6",
                                                                                     ifelse(country_code == "HU" & year == 2010	& other_id == 9, "4",
                                                                                            ifelse(country_code == "PL" & year == 2007	& other_id == 9, "1,6,5",
                                                                                                   ifelse(country_code == "PL" & year == 2011	& other_id == 9, "2,4",
                                                                                                          ifelse(country_code == "SV" & year == 2010 & other_id == 11, "6,4,5,7",
                                                                                                                 ifelse(country_code == "SV" & year == 2014	& other_id == 11, "6,4,5,7",
                                                                                                                        ifelse(country_code == "NL" & year == 2010	& other_id == 11, "2,1",
                                                                                                                               ifelse(country_code == "NL" & year == 2012 & other_id == 11, "3,2",
                                                                                                                                      ifelse(country_code == "UK" & year == 2015	& other_id == 6,	"3,2", NA)))))))))))))))) %>% 
  dplyr::select(-c(subject_id, other_id, subject_name, other_name)) %>% 
  separate(government_cp_code_subject, into = c("party1", "party2", "party3", "party4"), sep=",") %>% 
  pivot_longer(cols = starts_with("party"), names_to = "label", values_to = "subject_id") %>% 
  filter(!is.na(subject_id)) %>% 
  select(-label) %>% 
  separate(government_cp_code_other, into = c("party1", "party2", "party3", "party4"), sep=",") %>% 
  pivot_longer(cols = starts_with("party"), names_to = "label", values_to = "other_id") %>% 
  filter(!is.na(other_id))  %>% 
  dplyr::select(-c(label, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd,
                   other_cmp_code, other_parlgov_code, other_poll_id, other_miguel_id, other_cses_imd)) %>% 
  mutate(subject_id = as.numeric(subject_id),
         other_id = as.numeric(other_id))


df_other_transformed  <-
  df_other_transformed  %>% 
  filter(!str_detect(subject_name, 'gov')) %>% 
  filter(!str_detect(other_name, 'gov')) %>% 
  dplyr::select(-c(subject_name, subject_cmp_code, subject_parlgov_code, subject_poll_id, subject_miguel_id, subject_cses_imd,
                   other_name, other_cmp_code, other_parlgov_code, other_poll_id, other_miguel_id, other_cses_imd)) %>% 
  rbind(gov_other, gov_subject_other, both_government_other) %>% 
  group_by(country_code, country_name, year, subject_id, other_id) %>% 
  summarise_all(funs(sum)) %>%
  left_join(ccd_parties)


## Exporting the self data set
#write_csv(df_other_transformed, "data_processed/other_statements_gov.csv")
#save.dta13(df_other_transformed, "data_processed/other_statements_gov.dta")

## Combining self and other data set
df_combined <-
  df_other_transformed %>% 
  left_join(df_self_transformed) 


## Exporting the full data set of self and other statements
#write_csv(df_combined, "data_processed/combined_statements_gov.csv")
#save.dta13(df_combined, "data_processed/combined_statements_gov.dta")

## Cleaning up
rm(ccd_other, ccd_parties, ccd_subjects, df_combined, df_other, df_other_transformed,
   df_self, df_self_transformed, other_issue, other_issue_direction, other_issue_valence,
   other_val, self_issue, self_issue_direction, self_issue_valence, self_val,
   df_other_transformed_receive, both_government_other, gov_subject_other, gov_other)

# fin

