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

Test if all setup works

```Bash
Rscript setup.R
```

Start tool to monitor submission for the google form

```Bash
Rscript runMonitor.R
```
