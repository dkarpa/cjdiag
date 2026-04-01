# Immigration Conjoint Example Data

The Hainmueller & Hopkins (2015) immigration conjoint experiment.
Contains ~1400 respondents, each evaluating 5 pairs of immigrant
profiles (13,960 rows total). Nine attributes with ~50 levels, binary
forced-choice.

## Usage

``` r
immig
```

## Format

A data frame with 13,960 rows and 16 columns:

- CaseID:

  Respondent identifier

- contest_no:

  Task number (1-5)

- profile:

  Profile number within task (1 or 2)

- Gender:

  Immigrant gender: female, male

- Education:

  Education level (7 levels: no formal through graduate degree)

- LanguageSkills:

  English ability (4 levels)

- CountryofOrigin:

  Country of origin (10 levels)

- Job:

  Occupation (11 levels)

- JobExperience:

  Work experience (4 levels)

- JobPlans:

  Employment plans (4 levels)

- ReasonforApplication:

  Immigration reason (3 levels)

- PriorEntry:

  Prior US entry history (5 levels)

- Chosen_Immigrant:

  Binary outcome: 1 if chosen, 0 if not

## Source

Hainmueller, J. & Hopkins, D. (2015). The Hidden American Immigration
Consensus: A Conjoint Analysis of Attitudes toward Immigrants. *American
Journal of Political Science*, 59(3), 529-548.

## Examples

``` r
data(immig)
head(immig)
#>   CaseID contest_no profile Gender       Education           LanguageSkills
#> 1      4          1       1   male     high school tried English but unable
#> 2      4          1       2 female       no formal         used interpreter
#> 3      4          2       1 female graduate degree           fluent English
#> 4      4          2       2 female       4th grade           fluent English
#> 5      4          3       1 female     high school           broken English
#> 6      4          3       2   male  college degree           fluent English
#>   CountryofOrigin                 Job JobExperience                 JobPlans
#> 1            Iraq               nurse      5+ years   contract with employer
#> 2          France child care provider     3-5 years interviews with employer
#> 3           Sudan            gardener     3-5 years   contract with employer
#> 4         Germany construction worker      5+ years interviews with employer
#> 5     Philippines               nurse      5+ years interviews with employer
#> 6           Sudan child care provider          none   contract with employer
#>   ReasonforApplication             PriorEntry Chosen_Immigrant
#> 1      seek better job        once as tourist                1
#> 2      seek better job once w/o authorization                0
#> 3   escape persecution        once as tourist                0
#> 4  reunite with family                  never                1
#> 5      seek better job once w/o authorization                1
#> 6      seek better job                  never                0
table(immig$Chosen_Immigrant)
#> 
#>    0    1 
#> 1000 1000 
```
