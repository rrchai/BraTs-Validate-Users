# BraTs-Validate-Usersif

## Installation

Clone the repo

```Bash
git clone https://github.com/rrchai/BraTs-Validate-Users
```

Initiate Conda Environment

```Bash
conda env create -f environment.yml
conda activate brats-tool
```

Install r libraries

```Bash
RScript requirements.R
```

Modify config information in `config_exmaple.R`, such as google form questions and gmail address.

```
cp config_example.R config.R
```

## Usage

**Important**: for the first time running, please use Rstudio (or other interactive IDEs) to initiate `google authentication` for accessing to the google form. The `googlesheet4` package is used to read google sheet, [more details on googlesheet4](https://googlesheets4.tidyverse.org/index.html).

1. Open the `setup.R` file in the Rstudio
2. press <kbd>Control</kbd>/<kbd>Command</kbd> + <kbd>A</kbd> to select entire script
3. press <kbd>Control</kbd>/<kbd>Command</kbd> + <kbd>enter<kbd> to run all the codes
4. Press `1` in the console when it asks to select "1: Yes 2: No" and a browser window will pop up. Please sign in your google account which has access to the google sheet and complete the authentication.

If not the first time, simply run below code to test if all setup work and go to the next step if no errors.

```Bash
Rscript setup.R
```

Start tool to monitor submission for the google form

```Bash
Rscript runMonitor.R
```
